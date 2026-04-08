//
//  AIscendChatModels.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import Foundation

typealias AIscendChatFilters = [String: String]

enum AIscendChatSender: String, Codable, Hashable {
    case bot
    case user
}

struct AIscendChatSource: Identifiable, Codable, Hashable {
    let label: String
    let title: String?
    let detail: String?
    let url: String?
    let type: String?

    var id: String {
        [
            title,
            label,
            detail,
            url,
            type
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: "|")
    }

    var displayTitle: String {
        let trimmedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedTitle.isEmpty {
            return trimmedTitle
        }

        return label
    }
}

struct AIscendChatMessage: Identifiable, Codable, Hashable {
    let id: String
    let sender: AIscendChatSender
    var text: String
    var sources: [AIscendChatSource]

    init(
        id: String = UUID().uuidString,
        sender: AIscendChatSender,
        text: String,
        sources: [AIscendChatSource] = []
    ) {
        self.id = id
        self.sender = sender
        self.text = text
        self.sources = sources
    }

    static func user(_ text: String) -> AIscendChatMessage {
        AIscendChatMessage(sender: .user, text: text)
    }

    static func bot(_ text: String, sources: [AIscendChatSource] = []) -> AIscendChatMessage {
        AIscendChatMessage(sender: .bot, text: text, sources: sources)
    }
}

struct AIscendChatThread: Identifiable, Equatable {
    let id: String
    let documentID: String?
    let email: String
    var title: String
    var messages: [AIscendChatMessage]
    var updatedAt: Date
    var createdAt: Date
    var sources: [AIscendChatSource]

    init(
        id: String? = nil,
        email: String,
        title: String,
        messages: [AIscendChatMessage],
        updatedAt: Date,
        createdAt: Date,
        sources: [AIscendChatSource] = []
    ) {
        self.documentID = id
        self.id = id ?? "draft-\(UUID().uuidString)"
        self.email = email
        self.title = title
        self.messages = messages
        self.updatedAt = updatedAt
        self.createdAt = createdAt
        self.sources = sources
    }

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }

        return AIscendChatTitleBuilder.untitledFallback
    }
}

enum AIscendChatGroupKey: String, CaseIterable, Codable {
    case today
    case yesterday
    case thisWeek
    case previous

    var title: String {
        switch self {
        case .today:
            "Today"
        case .yesterday:
            "Yesterday"
        case .thisWeek:
            "This Week"
        case .previous:
            "Previously"
        }
    }
}

struct AIscendChatHistorySection: Identifiable, Equatable {
    let key: AIscendChatGroupKey
    let threads: [AIscendChatThread]

    var id: String { key.rawValue }
}

struct AIscendChatQuota: Equatable {
    var isPremium: Bool
    var remainingChats: Int?
    var monthlyLimit: Int?
    var usedChats: Int?
    var trialEligible: Bool
    var sourceDescription: String?

    init(
        isPremium: Bool = false,
        remainingChats: Int? = nil,
        monthlyLimit: Int? = nil,
        usedChats: Int? = nil,
        trialEligible: Bool = true,
        sourceDescription: String? = nil
    ) {
        self.isPremium = isPremium
        self.remainingChats = remainingChats
        self.monthlyLimit = monthlyLimit
        self.usedChats = usedChats
        self.trialEligible = trialEligible
        self.sourceDescription = sourceDescription
    }

    static let unknown = AIscendChatQuota()

    var isLow: Bool {
        guard !isPremium, let remainingChats else {
            return false
        }

        return remainingChats <= 3
    }

    var isExhausted: Bool {
        guard !isPremium, let remainingChats else {
            return false
        }

        return remainingChats <= 0
    }

    var shouldShowUpsell: Bool {
        !isPremium && (isLow || isExhausted)
    }

    var headline: String {
        if isPremium {
            return "Premium access active"
        }

        if isExhausted {
            return trialEligible ? "Start your 7-day Premium trial" : "Unlock unlimited advisor conversations"
        }

        if let remainingChats {
            return "\(remainingChats) chats left this month"
        }

        return "Limited monthly advisor access"
    }

    var detail: String {
        if isPremium {
            return "Unlimited advisor conversations, priority access, and a cleaner runway for longer sessions."
        }

        if isExhausted {
            return "Continue with unlimited chats and faster responses through Premium."
        }

        if let remainingChats, remainingChats <= 3 {
            return "Keep the conversation open with unlimited advisor chats through Premium."
        }

        if let monthlyLimit, let usedChats {
            return "\(usedChats) of \(monthlyLimit) monthly chats used."
        }

        return "Free access is active with monthly chat limits."
    }

    var compactLabel: String {
        if isPremium {
            return "Unlimited"
        }

        if let remainingChats {
            return "\(max(remainingChats, 0)) left"
        }

        return "Limited"
    }
}

struct AIscendChatRAGResult: Equatable {
    let answer: String
    let usedContext: String?
    let sources: [AIscendChatSource]
}

enum AIscendChatError: LocalizedError, Equatable {
    case notAuthenticated
    case missingEmail
    case missingBackendBaseURL
    case invalidResponse
    case firestoreUnavailable
    case quotaExhausted
    case backend(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            "Sign in to access your private advisor conversations."
        case .missingEmail:
            "AIScend could not resolve the signed-in email needed for chat history."
        case .missingBackendBaseURL:
            "Add `AISCEND_API_BASE_URL` to the app configuration before calling the advisor backend."
        case .invalidResponse:
            "The advisor returned an unreadable response. Please try again."
        case .firestoreUnavailable:
            "Firestore is not linked in this build, so chat history cannot load."
        case .quotaExhausted:
            "Free access is currently exhausted for new conversations."
        case .backend(let message):
            message
        }
    }
}

struct AIscendChatConfiguration {
    let backendBaseURL: URL?
    let premiumURL: URL?
    let chatCollectionCandidates: [String]
    let quotaCollectionCandidates: [String]
    let lowQuotaThreshold: Int
    let fallbackFreeMonthlyLimit: Int?

    static let live = AIscendChatConfiguration(
        backendBaseURL: urlValue(for: "AISCEND_API_BASE_URL"),
        premiumURL: urlValue(for: "AISCEND_PREMIUM_URL"),
        chatCollectionCandidates: uniqueValues(
            [
                stringValue(for: "AISCEND_CHAT_COLLECTION"),
                "CHATBOT_CHATS",
                "chatbotChats",
                "chatbot_chats"
            ]
        ),
        quotaCollectionCandidates: uniqueValues(
            [
                stringValue(for: "AISCEND_QUOTA_COLLECTION"),
                "CHATBOT_USAGE",
                "chatbotUsage",
                "chatbot_usage",
                "users",
                "user_profiles",
                "subscriptions"
            ]
        ),
        lowQuotaThreshold: intValue(for: "AISCEND_LOW_QUOTA_THRESHOLD") ?? 3,
        fallbackFreeMonthlyLimit: intValue(for: "AISCEND_FREE_MONTHLY_CHAT_LIMIT")
    )

    private static func stringValue(for key: String) -> String? {
        if let environmentValue = ProcessInfo.processInfo.environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !environmentValue.isEmpty
        {
            return environmentValue
        }

        if let infoValue = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            let trimmed = infoValue.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        return nil
    }

    private static func intValue(for key: String) -> Int? {
        if let stringValue = stringValue(for: key) {
            return Int(stringValue)
        }

        if let numericValue = Bundle.main.object(forInfoDictionaryKey: key) as? NSNumber {
            return numericValue.intValue
        }

        return nil
    }

    private static func urlValue(for key: String) -> URL? {
        guard let rawValue = stringValue(for: key) else {
            return nil
        }

        return URL(string: rawValue)
    }

    private static func uniqueValues(_ values: [String?]) -> [String] {
        var seen = Set<String>()
        var results: [String] = []

        for value in values.compactMap({ $0?.trimmingCharacters(in: .whitespacesAndNewlines) }) where !value.isEmpty {
            if seen.insert(value).inserted {
                results.append(value)
            }
        }

        return results
    }
}

enum AIscendChatTitleBuilder {
    static let untitledFallback = "New Conversation"

    static func title(from firstUserMessage: String) -> String {
        let cleaned = firstUserMessage
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else {
            return untitledFallback
        }

        let words = cleaned.split(separator: " ").map(String.init)
        let joinedWords = words.prefix(7).joined(separator: " ")
        let bounded = String(joinedWords.prefix(54)).trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned == bounded || (words.count <= 7 && cleaned.count <= 54) {
            return cleaned
        }

        return "\(bounded)…"
    }
}

enum AIscendChatGrouping {
    static func sections(
        from threads: [AIscendChatThread],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [AIscendChatHistorySection] {
        let grouped = Dictionary(grouping: threads.sorted { $0.updatedAt > $1.updatedAt }) { thread in
            key(for: thread.updatedAt, now: now, calendar: calendar)
        }

        return AIscendChatGroupKey.allCases.compactMap { key in
            guard let threads = grouped[key], !threads.isEmpty else {
                return nil
            }

            return AIscendChatHistorySection(key: key, threads: threads)
        }
    }

    static func key(
        for date: Date,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> AIscendChatGroupKey {
        if calendar.isDate(date, inSameDayAs: now) {
            return .today
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday)
        {
            return .yesterday
        }

        if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now),
           date >= weekAgo
        {
            return .thisWeek
        }

        return .previous
    }
}
