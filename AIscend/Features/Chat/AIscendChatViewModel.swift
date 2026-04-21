//
//  AIscendChatViewModel.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class AIscendChatViewModel {
    var draft: String = ""
    var messages: [AIscendChatMessage] = []
    var threads: [AIscendChatThread] = []
    var quota: AIscendChatQuota = .unknown
    var isBootstrapping: Bool = false
    var isSending: Bool = false
    var isAwaitingReply: Bool = false
    var isHistoryPresented: Bool = false
    var isPremiumUpsellPresented: Bool = false
    var errorMessage: String?
    var transientNotice: String?
    var scrollTrigger: Int = 0
    var composerFocusRequestToken: Int = 0

    private(set) var isDraftConversation: Bool = true
    private(set) var activeThreadID: String?
    private(set) var activeTitle: String = AIscendChatTitleBuilder.untitledFallback
    private(set) var currentCreatedAt: Date?

    let configuration: AIscendChatConfiguration
    let filters: AIscendChatFilters?

    @ObservationIgnored private let session: AuthSessionStore
    @ObservationIgnored private let repository: AIscendChatRepositoryProtocol
    @ObservationIgnored private let service: AIscendChatServiceProtocol
    @ObservationIgnored private var loadedIdentityKey: String?
    @ObservationIgnored private var toastTask: Task<Void, Never>?

    init(
        session: AuthSessionStore,
        repository: AIscendChatRepositoryProtocol = AIscendChatRepository(),
        service: AIscendChatServiceProtocol = AIscendChatService(),
        configuration: AIscendChatConfiguration = .live,
        filters: AIscendChatFilters? = nil
    ) {
        self.session = session
        self.repository = repository
        self.service = service
        self.configuration = configuration
        self.filters = filters
    }

    var currentTitle: String {
        if !isAuthenticated && messages.isEmpty && activeThreadID == nil {
            return "Private Advisor"
        }

        return activeTitle
    }

    var currentSubtitle: String {
        if quota.isPremium {
            return "Premium session"
        }

        if quota.isExhausted {
            return "Monthly access paused"
        }

        if let remainingChats = quota.remainingChats {
            return "\(remainingChats) chats remaining"
        }

        return "Secure advisor workspace"
    }

    var groupedThreads: [AIscendChatHistorySection] {
        AIscendChatGrouping.sections(from: threads)
    }

    var isAuthenticated: Bool {
        session.phase == .signedIn && chatIdentity != nil
    }

    var showQuotaBanner: Bool {
        quota.shouldShowUpsell
    }

    var workspaceState: AIscendChatWorkspaceState {
        AIscendChatWorkspaceState.resolve(
            isAuthenticated: isAuthenticated,
            isBootstrapping: isBootstrapping,
            threads: threads,
            messages: messages,
            prefersFreshConversation: prefersFreshConversation
        )
    }

    var canSend: Bool {
        let trimmedDraft = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        return isAuthenticated && !trimmedDraft.isEmpty && !isSending
    }

    var shouldBlockNewConversation: Bool {
        quota.isExhausted && activeThreadID == nil && messages.isEmpty
    }

    var showEmptyState: Bool {
        workspaceState == .empty || workspaceState == .draft
    }

    var premiumURL: URL? {
        configuration.premiumURL
    }

    func syncWithSession(force: Bool = false) async {
        let identityKey = session.user?.id ?? "signed-out"

        guard isAuthenticated else {
            loadedIdentityKey = identityKey
            threads = []
            messages = []
            quota = .unknown
            activeThreadID = nil
            isDraftConversation = true
            activeTitle = AIscendChatTitleBuilder.untitledFallback
            currentCreatedAt = nil
            isBootstrapping = false
            isAwaitingReply = false
            isSending = false
            return
        }

        guard force || loadedIdentityKey != identityKey else {
            return
        }

        loadedIdentityKey = identityKey
        await loadWorkspace()
    }

    func loadWorkspace() async {
        guard let chatIdentity else {
            errorMessage = AIscendChatError.missingEmail.localizedDescription
            return
        }

        let shouldShowLoadingState = messages.isEmpty && threads.isEmpty && !prefersFreshConversation
        if shouldShowLoadingState {
            isBootstrapping = true
        }
        errorMessage = nil

        do {
            async let loadedThreads = repository.loadThreads(for: chatIdentity.email, userID: chatIdentity.userID)
            async let repositoryQuota = repository.loadQuota(for: chatIdentity.email, userID: chatIdentity.userID)
            async let authQuota = service.loadAuthQuotaSnapshot()

            let threads = try await loadedThreads
            let mergedQuota = mergeQuota(repository: await repositoryQuota, auth: await authQuota)

            self.threads = threads
            quota = mergedQuota
            restoreActiveConversation(from: threads)
        } catch {
            errorMessage = userFacingMessage(for: error)
        }

        isBootstrapping = false
    }

    func startNewConversation() {
        isDraftConversation = true
        activeThreadID = nil
        activeTitle = AIscendChatTitleBuilder.untitledFallback
        currentCreatedAt = nil
        messages = []
        errorMessage = nil
        isHistoryPresented = false
        scrollTrigger += 1
    }

    func preparePrefilledDraft(_ prompt: String) {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            return
        }

        startNewConversation()
        draft = trimmedPrompt
        composerFocusRequestToken += 1
    }

    func presentHistory() {
        isHistoryPresented = true
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    func dismissHistory() {
        isHistoryPresented = false
    }

    func selectThread(_ thread: AIscendChatThread) {
        isDraftConversation = false
        activate(thread)
        isHistoryPresented = false
    }

    func sendCurrentDraft() async {
        let trimmedDraft = draft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedDraft.isEmpty else {
            return
        }

        guard let chatIdentity else {
            errorMessage = AIscendChatError.missingEmail.localizedDescription
            return
        }

        if shouldBlockNewConversation {
            errorMessage = AIscendChatError.quotaExhausted.localizedDescription
            isPremiumUpsellPresented = true
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }

        draft = ""
        errorMessage = nil
        isSending = true
        isAwaitingReply = true

        if currentCreatedAt == nil {
            currentCreatedAt = .now
        }

        let userMessage = AIscendChatMessage.user(trimmedDraft)
        isDraftConversation = false
        messages.append(userMessage)

        if activeThreadID == nil && messages.filter({ $0.sender == .user }).count == 1 {
            activeTitle = AIscendChatTitleBuilder.title(from: trimmedDraft)
        }

        scrollTrigger += 1

        do {
            let result = try await service.sendQuery(
                message: trimmedDraft,
                email: chatIdentity.email,
                userID: chatIdentity.userID,
                filters: filters
            )

            isAwaitingReply = false

            let assistantID = UUID().uuidString
            messages.append(
                AIscendChatMessage(
                    id: assistantID,
                    sender: .bot,
                    text: "",
                    sources: []
                )
            )
            scrollTrigger += 1

            await revealAssistantMessage(
                answer: result.answer,
                sources: result.sources,
                assistantMessageID: assistantID
            )

            let persistedThread = buildPersistedThread(
                email: chatIdentity.requestEmail,
                sources: result.sources
            )

            let savedThread = try await repository.save(thread: persistedThread, userID: userID)
            upsert(savedThread)
            activate(savedThread, closeHistory: false)

            await refreshQuota(for: chatIdentity)

            do {
                let refreshedThreads = try await repository.loadThreads(for: chatIdentity.email, userID: chatIdentity.userID)
                threads = refreshedThreads

                if let refreshedThread = refreshedThreads.first(where: { $0.id == savedThread.id }) {
                    activate(refreshedThread, closeHistory: false)
                }
            } catch {
                errorMessage = userFacingMessage(for: error)
            }

            isSending = false
        } catch {
            isAwaitingReply = false
            isSending = false
            errorMessage = userFacingMessage(for: error)
        }
    }

    func copiedAssistantMessage() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        showTransientNotice("Copied")
    }

    func clearError() {
        errorMessage = nil
    }

    func presentPremiumUpsell() {
        isPremiumUpsellPresented = true
    }

    func dismissPremiumUpsell() {
        isPremiumUpsellPresented = false
    }
}

private extension AIscendChatViewModel {
    var prefersFreshConversation: Bool {
        isDraftConversation && activeThreadID == nil && messages.isEmpty
    }

    var chatIdentity: AIscendChatIdentity? {
        AIscendChatIdentity(userID: userID, email: userEmail)
    }

    var userID: String? {
        let trimmed = session.user?.id.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    var userEmail: String? {
        let trimmed = session.user?.email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed.lowercased()
    }

    func restoreActiveConversation(from threads: [AIscendChatThread]) {
        if let activeThreadID,
           let activeThread = threads.first(where: { $0.id == activeThreadID })
        {
            if activeThread.hasRenderableMessages || !threads.contains(where: \.hasRenderableMessages) {
                activate(activeThread, closeHistory: false)
                return
            }
        }

        if prefersFreshConversation {
            activeThreadID = nil
            activeTitle = AIscendChatTitleBuilder.untitledFallback
            currentCreatedAt = nil
            return
        }

        if let latestRenderableThread = threads.first(where: \.hasRenderableMessages) {
            activate(latestRenderableThread, closeHistory: false)
            return
        }

        if let activeThreadID,
           let activeThread = threads.first(where: { $0.id == activeThreadID })
        {
            activate(activeThread, closeHistory: false)
            return
        }

        if messages.isEmpty, let latestThread = threads.first {
            activate(latestThread, closeHistory: false)
            return
        }

        if messages.isEmpty {
            activeThreadID = nil
            activeTitle = AIscendChatTitleBuilder.untitledFallback
            currentCreatedAt = nil
        }
    }

    func activate(_ thread: AIscendChatThread, closeHistory: Bool = true) {
        isDraftConversation = false
        activeThreadID = thread.id
        activeTitle = thread.displayTitle
        currentCreatedAt = thread.createdAt
        messages = thread.messages

        if closeHistory {
            isHistoryPresented = false
        }

        scrollTrigger += 1
    }

    func buildPersistedThread(
        email: String,
        sources: [AIscendChatSource]
    ) -> AIscendChatThread {
        AIscendChatThread(
            id: activeThreadID,
            email: email,
            title: activeTitle,
            messages: messages,
            updatedAt: .now,
            createdAt: currentCreatedAt ?? .now,
            sources: sources
        )
    }

    func upsert(_ thread: AIscendChatThread) {
        if let index = threads.firstIndex(where: { $0.id == thread.id }) {
            threads[index] = thread
        } else {
            threads.insert(thread, at: 0)
        }

        threads.sort { $0.updatedAt > $1.updatedAt }
    }

    func mergeQuota(repository: AIscendChatQuota, auth: AIscendChatQuota) -> AIscendChatQuota {
        var merged = repository

        if auth.isPremium {
            merged.isPremium = true
        }

        if merged.remainingChats == nil {
            merged.remainingChats = auth.remainingChats
        }

        if merged.monthlyLimit == nil {
            merged.monthlyLimit = auth.monthlyLimit
        }

        if merged.usedChats == nil {
            merged.usedChats = auth.usedChats
        }

        if merged.sourceDescription == nil {
            merged.sourceDescription = auth.sourceDescription
        }

        merged.trialEligible = repository.trialEligible || auth.trialEligible

        if !merged.isPremium, let threshold = configuration.fallbackFreeMonthlyLimit, merged.monthlyLimit == nil {
            merged.monthlyLimit = threshold
        }

        return merged
    }

    func refreshQuota(for identity: AIscendChatIdentity) async {
        async let repositoryQuota = repository.loadQuota(for: identity.email, userID: identity.userID)
        async let authQuota = service.loadAuthQuotaSnapshot()
        quota = mergeQuota(repository: await repositoryQuota, auth: await authQuota)
    }

    func revealAssistantMessage(
        answer: String,
        sources: [AIscendChatSource],
        assistantMessageID: String
    ) async {
        let segments = revealSegments(for: answer)
        var revealedText = ""

        for segment in segments {
            revealedText.append(segment)

            guard let messageIndex = messages.firstIndex(where: { $0.id == assistantMessageID }) else {
                continue
            }

            messages[messageIndex].text = revealedText
            scrollTrigger += 1

            try? await Task.sleep(nanoseconds: 24_000_000)
        }

        if let messageIndex = messages.firstIndex(where: { $0.id == assistantMessageID }) {
            messages[messageIndex].text = answer
            messages[messageIndex].sources = sources
        }

        scrollTrigger += 1
    }

    func revealSegments(for answer: String) -> [String] {
        let characters = Array(answer)
        guard !characters.isEmpty else {
            return []
        }

        var segments: [String] = []
        var index = 0

        while index < characters.count {
            let chunkSize = index < 120 ? 12 : 24
            let upperBound = min(index + chunkSize, characters.count)
            let chunk = String(characters[index..<upperBound])
            segments.append(chunk)
            index = upperBound
        }

        return segments
    }

    func showTransientNotice(_ notice: String) {
        transientNotice = notice
        toastTask?.cancel()
        toastTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            transientNotice = nil
        }
    }

    func userFacingMessage(for error: Error) -> String {
        if let chatError = error as? AIscendChatError {
            return chatError.localizedDescription
        }

        return error.localizedDescription
    }
}
