//
//  MainTabContainer.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import SwiftUI
import UIKit

enum MainTabDestination: String, CaseIterable, Identifiable {
    case home
    case routine
    case scan
    case chat
    case more

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home:
            "Dashboard"
        case .routine:
            "Routine"
        case .scan:
            "Scan"
        case .chat:
            "Chat"
        case .more:
            "More"
        }
    }

    var symbol: String {
        switch self {
        case .home:
            "house.fill"
        case .routine:
            "square.grid.2x2.fill"
        case .scan:
            "plus"
        case .chat:
            "message.fill"
        case .more:
            "ellipsis.circle.fill"
        }
    }
}

struct MainTabContainer: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("aiscend.dailyCheckIn.lastRoutineStreakPromptDay")
    private var lastRoutineStreakPromptDay = ""
    @AppStorage("aiscend.onboarding.didAutoOpenInitialScanUserID")
    private var didAutoOpenInitialScanUserID = ""

    @Bindable var model: AppModel
    @Bindable var session: AuthSessionStore

    @State private var selectedTab: MainTabDestination = Self.resolveInitialSelectedTab()
    @State private var homePath: [HomeDestination] = []
    @State private var showingDailyPhotoCapture = false
    @State private var showingDailyPhotoArchive = false
    @State private var showingDailyCheckIn = false
    @State private var showingStreaks = false
    @State private var showingInitialWelcome = false
    @State private var showingScanCapture = false
    @State private var showingScanResults = false
    @State private var showingGlowUpTracker = false
    @State private var activeGlowUpRoutine: GlowupRoutinePresentation?
    @State private var activePremiumPaywall: AIScendPremiumPaywallPresentation?
    @State private var showingRoadmap = false
    @State private var showingNutrition = false
    @State private var routineHydrationNavigationRequest = 0
    @State private var pendingChatPrompt: String?
    @State private var isKeyboardPresented = false
    @State private var usesQuickFadeSelection = false
    @State private var subscriptionQuota: AIscendChatQuota = .unknown
    @StateObject private var premiumAccessManager = PremiumAccessManager.shared
    @StateObject private var badgeManager = BadgeManager()
    @StateObject private var dailyCheckInStore = DailyCheckInStore()
    @StateObject private var dailyPhotoStore = DailyPhotoStore()
    @StateObject private var hydrationStore = HydrationTrackingStore()
    @StateObject private var electrolyteStore = ElectrolyteTrackingStore()
    @StateObject private var nutritionStore = NutritionStore()
    @StateObject private var notificationManager = NotificationManager()
    @Namespace private var tabNamespace

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                selectedTabContent
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.clear)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if shouldShowTabBar {
                    GlassTabBar(
                        selectedTab: selectedTab,
                        usesQuickFadeSelection: usesQuickFadeSelection,
                        namespace: tabNamespace,
                        bottomInset: geometry.safeAreaInsets.bottom,
                        onSelect: select
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.clear)
        .animation(.easeOut(duration: 0.22), value: shouldShowTabBar)
        .task(id: session.user?.id) {
            dailyPhotoStore.applyAuthenticatedUserID(session.user?.id)
            hydrationStore.applyAuthenticatedUserID(session.user?.id)
            electrolyteStore.applyAuthenticatedUserID(session.user?.id)
            nutritionStore.applyAuthenticatedUserID(session.user?.id)
            model.refreshForCurrentDate()
            dailyCheckInStore.refreshForCurrentDate()
            hydrationStore.importLegacyIfNeeded(
                waterCups: model.trackerState.waterIntake,
                waterGoalCups: model.trackerState.waterGoal
            )
            electrolyteStore.importLegacyIfNeeded(servings: model.trackerState.electrolyteIntake)
            if session.user != nil {
                await notificationManager.activateRemindersForSignedInUser()
            }
            await premiumAccessManager.start(userID: session.user?.id, email: session.user?.email)
            await refreshSubscriptionStatus()
            if !queueInitialScanFlowAfterSignUpIfNeeded() {
                maybePresentDailyPhotoPrompt(.firstOpen)
                maybePresentRoutineStreakPromptIfNeeded()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                model.refreshForCurrentDate()
                dailyCheckInStore.refreshForCurrentDate()
                maybePresentDailyPhotoPrompt(.engagement)
                maybePresentRoutineStreakPromptIfNeeded()
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if oldValue != newValue {
                maybePresentDailyPhotoPrompt(.engagement)
                if newValue == .routine {
                    maybePresentRoutineStreakPromptIfNeeded()
                }
            }
        }
        .onChange(of: hasPremiumAccess) { _, isPremium in
            AIScendSuperwallAnalytics.updateSubscriptionStatus(isPremium: isPremium)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.easeOut(duration: 0.22)) {
                isKeyboardPresented = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.22)) {
                isKeyboardPresented = false
            }
        }
        .sheet(isPresented: $showingDailyPhotoCapture) {
            DailyPhotoCaptureSheet(
                store: dailyPhotoStore,
                onDismiss: { showingDailyPhotoCapture = false }
            )
        }
        .fullScreenCover(isPresented: $showingDailyPhotoArchive) {
            DailyPhotoArchiveView(
                store: dailyPhotoStore,
                onDismiss: { showingDailyPhotoArchive = false }
            )
        }
        .sheet(isPresented: $showingDailyCheckIn) {
            DailyCheckInView(
                dailyCheckInStore: dailyCheckInStore,
                badgeManager: badgeManager,
                notificationManager: notificationManager,
                isPremium: hasPremiumAccess,
                onComplete: {},
                onDismiss: { showingDailyCheckIn = false }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingStreaks) {
            StreaksView(
                dailyCheckInStore: dailyCheckInStore,
                badgeManager: badgeManager,
                notificationManager: notificationManager,
                onOpenCheckIn: {
                    showingStreaks = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        showingDailyCheckIn = true
                    }
                },
                onDismiss: { showingStreaks = false }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showingInitialWelcome) {
            PostSignInWelcomeView {
                showingInitialWelcome = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                    select(.scan)
                    showingScanCapture = true
                }
            }
            .interactiveDismissDisabled(true)
        }
        .fullScreenCover(isPresented: $showingScanCapture) {
            ScanCaptureFlowView(
                session: session,
                badgeManager: badgeManager,
                dailyCheckInStore: dailyCheckInStore,
                notificationManager: notificationManager,
                isPremium: hasPremiumAccess,
                onOpenRoutine: {
                    select(.routine)
                    showingScanCapture = false
                },
                onOpenGlowUpPlan: { result in
                    presentGlowUpRoutine(from: result, dismissing: .scanCapture)
                },
                onOpenChat: {
                    select(.chat)
                    showingScanCapture = false
                },
                onReturnHome: {
                    select(.home)
                    showingScanCapture = false
                },
                onDismiss: {
                    showingScanCapture = false
                }
            )
        }
        .fullScreenCover(isPresented: $showingScanResults) {
            ScanResultsFlowView(
                session: session,
                badgeManager: badgeManager,
                dailyCheckInStore: dailyCheckInStore,
                notificationManager: notificationManager,
                isUserPremium: hasPremiumAccess,
                onOpenScan: {
                    select(.scan)
                    showingScanResults = false
                },
                onOpenRoutine: {
                    select(.routine)
                    showingScanResults = false
                },
                onOpenGlowUpPlan: { result in
                    presentGlowUpRoutine(from: result, dismissing: .scanResults)
                },
                onOpenChat: {
                    select(.chat)
                    showingScanResults = false
                },
                onReturnHome: {
                    select(.home)
                    showingScanResults = false
                },
                onDismiss: {
                    showingScanResults = false
                }
            )
        }
        .fullScreenCover(isPresented: $showingGlowUpTracker) {
            GlowUpTrackerView {
                showingGlowUpTracker = false
            }
        }
        .fullScreenCover(item: $activeGlowUpRoutine) { presentation in
            GlowupRoutineFlowView(
                scanResult: presentation.scanResult,
                authenticatedUserID: session.user?.id,
                onOpenChat: {
                    activeGlowUpRoutine = nil
                    select(.chat)
                },
                onFinish: {
                    activeGlowUpRoutine = nil
                    select(.home)
                },
                onDismiss: {
                    activeGlowUpRoutine = nil
                    select(.home)
                }
            )
        }
        .fullScreenCover(item: $activePremiumPaywall) { presentation in
            AIScendPremiumPaywallView(
                variant: presentation.variant,
                offer: presentation.offer,
                onDismiss: {
                    activePremiumPaywall = nil
                },
                onPurchase: { productId in
                    Task {
                        if await premiumAccessManager.purchase(productID: productId) {
                            activePremiumPaywall = nil
                            await refreshSubscriptionStatus()
                        }
                    }
                },
                onRestore: {
                    Task {
                        if await premiumAccessManager.restorePurchases() {
                            activePremiumPaywall = nil
                        }
                        await refreshSubscriptionStatus()
                    }
                }
            )
        }
        .fullScreenCover(isPresented: $showingRoadmap) {
            AIScendRoadmapView(
                onDismiss: {
                    showingRoadmap = false
                },
                onOpenScan: {
                    select(.scan)
                }
            )
        }
        .fullScreenCover(isPresented: $showingNutrition) {
            NutritionDashboardView(store: nutritionStore) {
                showingNutrition = false
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        switch selectedTab {
        case .home:
            homeTab
        case .routine:
            routineTab
        case .scan:
            scanTab
        case .chat:
            chatTab
        case .more:
            moreTab
        }
    }

    private var homeTab: some View {
        NavigationStack(path: $homePath) {
            RoutineDashboardView(
                model: model,
                session: session,
                dailyCheckInStore: dailyCheckInStore,
                dailyPhotoStore: dailyPhotoStore,
                hydrationStore: hydrationStore,
                electrolyteStore: electrolyteStore,
                badgeManager: badgeManager,
                isPremium: hasPremiumAccess,
                onOpenAdvisor: { select(.chat) },
                onOpenHydrationChat: openHydrationChat,
                onOpenRoutine: { select(.routine) },
                onOpenCheckIn: { showingDailyCheckIn = true },
                onOpenConsistency: { showingStreaks = true },
                onOpenDailyPhoto: {
                    requirePremium(.dailyPhotoProgress, source: "dashboard-daily-photo-archive") {
                        showingDailyPhotoArchive = true
                    }
                },
                onCaptureDailyPhoto: {
                    requirePremium(.dailyPhotoProgress, source: "dashboard-daily-photo-capture") {
                        showingDailyPhotoCapture = true
                    }
                },
                onOpenRoadmap: {
                    requirePremium(.aiRoadmap, source: "dashboard-roadmap") {
                        showingRoadmap = true
                    }
                },
                onOpenScan: { select(.scan) },
                onOpenGlowUpRoutine: {
                    openSavedGlowUpRoutine()
                },
                onOpenHydration: openRoutineHydration,
                onOpenAccount: openHomeProfile,
                onRefine: { model.resetOnboarding() }
            )
            .navigationDestination(for: HomeDestination.self) { destination in
                switch destination {
                case .profile:
                    AccountView(
                        model: model,
                        session: session,
                        dailyCheckInStore: dailyCheckInStore,
                        badgeManager: badgeManager,
                        notificationManager: notificationManager
                    )
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var routineTab: some View {
        NavigationStack {
            RoutineCleanSlateView(
                model: model,
                dailyCheckInStore: dailyCheckInStore,
                hydrationStore: hydrationStore,
                electrolyteStore: electrolyteStore,
                badgeManager: badgeManager,
                authenticatedUserID: session.user?.id,
                onOpenCheckIn: { showingDailyCheckIn = true },
                onOpenConsistency: { showingStreaks = true },
                onOpenHydrationChat: openHydrationChat,
                onOpenNutrition: {
                    requirePremium(.nutritionStrategy, source: "routine-nutrition") {
                        showingNutrition = true
                    }
                },
                onOpenGlowUpRoutine: {
                    openSavedGlowUpRoutine()
                },
                hydrationNavigationRequest: routineHydrationNavigationRequest,
                onRefine: { model.resetOnboarding() }
            )
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var scanTab: some View {
        NavigationStack {
            AIscendScanStudioView(
                model: model,
                session: session,
                badgeManager: badgeManager,
                dailyCheckInStore: dailyCheckInStore,
                notificationManager: notificationManager,
                isPremium: hasPremiumAccess,
                onOpenChat: { select(.chat) },
                onOpenRoutine: { select(.routine) },
                onOpenGlowUpPlan: { result in
                    presentGlowUpRoutine(from: result, dismissing: .none)
                },
                onOpenGlowUpTracker: {
                    requirePremium(.glowUpProgress, source: "scan-archive-tracker") {
                        showingGlowUpTracker = true
                    }
                },
                onRequestPremiumFeature: { feature, source in
                    presentPremiumPaywall(for: feature, source: source)
                }
            )
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var chatTab: some View {
        NavigationStack {
            AIscendChatScreenContainer(
                session: session,
                pendingDraft: $pendingChatPrompt,
                onPremiumUpsell: {
                    presentPremiumPaywall(for: .chatQuota, source: "chat-quota")
                }
            )
                .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var moreTab: some View {
        NavigationStack {
            MoreHubView(
                model: model,
                session: session,
                dailyCheckInStore: dailyCheckInStore,
                badgeManager: badgeManager,
                notificationManager: notificationManager
            )
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var isPresentingBlockingModal: Bool {
        showingDailyPhotoCapture
            || showingDailyPhotoArchive
            || showingDailyCheckIn
            || showingStreaks
            || showingInitialWelcome
            || showingScanCapture
            || showingScanResults
            || showingGlowUpTracker
            || activeGlowUpRoutine != nil
            || activePremiumPaywall != nil
            || showingRoadmap
            || showingNutrition
    }

    private var hasPremiumAccess: Bool {
        premiumAccessManager.isPremium
    }

    private var accessPlan: AIScendUserAccessPlan {
        let isPremium = premiumAccessManager.isPremium
        return isPremium ? .premium : .free
    }

    private enum GlowUpPresentationDismissal {
        case none
        case scanCapture
        case scanResults
    }

    private func presentGlowUpRoutine(from result: PersistedScanRecord, dismissing dismissal: GlowUpPresentationDismissal) {
        select(.routine)

        switch dismissal {
        case .none:
            activeGlowUpRoutine = GlowupRoutinePresentation(scanResult: result)
        case .scanCapture:
            showingScanCapture = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                activeGlowUpRoutine = GlowupRoutinePresentation(scanResult: result)
            }
        case .scanResults:
            showingScanResults = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                activeGlowUpRoutine = GlowupRoutinePresentation(scanResult: result)
            }
        }
    }

    private func refreshSubscriptionStatus() async {
        async let repositoryQuota = AIscendChatRepository().loadQuota(
            for: session.user?.email,
            userID: session.user?.id
        )
        async let authQuota = AIscendChatService().loadAuthQuotaSnapshot()

        subscriptionQuota = mergeQuota(repository: await repositoryQuota, auth: await authQuota)
        if premiumAccessManager.isPremium {
            subscriptionQuota.isPremium = true
        }
        AIScendSuperwallAnalytics.updateSubscriptionStatus(isPremium: hasPremiumAccess)
    }

    private func mergeQuota(repository: AIscendChatQuota, auth: AIscendChatQuota) -> AIscendChatQuota {
        var merged = repository
        merged.isPremium = repository.isPremium || auth.isPremium

        if merged.remainingChats == nil {
            merged.remainingChats = auth.remainingChats
        }

        if merged.monthlyLimit == nil {
            merged.monthlyLimit = auth.monthlyLimit
        }

        if merged.usedChats == nil {
            merged.usedChats = auth.usedChats
        }

        merged.trialEligible = repository.trialEligible && auth.trialEligible

        if merged.sourceDescription == nil {
            merged.sourceDescription = auth.sourceDescription
        }

        return merged
    }

    private var shouldShowTabBar: Bool {
        !(selectedTab == .chat && isKeyboardPresented) && !showingInitialWelcome
    }

    private func tabIndex(for tab: MainTabDestination) -> Int {
        MainTabDestination.allCases.firstIndex(of: tab) ?? 0
    }

    private func tabDistance(from source: MainTabDestination, to destination: MainTabDestination) -> Int {
        abs(tabIndex(for: destination) - tabIndex(for: source))
    }

    private func maybePresentDailyPhotoPrompt(_ trigger: DailyPhotoPromptTrigger) {
        guard !Self.shouldDisableDailyPhotoPromptsForUITests() else {
            return
        }

        guard !isPresentingBlockingModal else {
            return
        }

        guard dailyPhotoStore.shouldPresentPrompt(for: trigger) else {
            return
        }

        showingDailyPhotoCapture = true
    }

    private func queueInitialScanFlowAfterSignUpIfNeeded() -> Bool {
        guard let userID = session.user?.id, !userID.isEmpty else {
            return false
        }

        guard model.hasCompletedEntryOnboarding, !model.hasCompletedOnboarding else {
            return false
        }

        guard didAutoOpenInitialScanUserID != userID else {
            return false
        }

        didAutoOpenInitialScanUserID = userID

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 520_000_000)
            guard session.user?.id == userID, !isPresentingBlockingModal else {
                return
            }

            showingInitialWelcome = true
        }

        return true
    }

    private func maybePresentRoutineStreakPromptIfNeeded(now: Date = .now) {
        guard !Self.shouldDisableDailyStreakPromptsForUITests() else {
            return
        }

        guard selectedTab == .routine else {
            return
        }

        guard !isPresentingBlockingModal else {
            return
        }

        let todayKey = DailyCheckInStore.ymd(for: now)
        guard lastRoutineStreakPromptDay != todayKey else {
            return
        }

        lastRoutineStreakPromptDay = todayKey
        showingStreaks = true
    }

    private func select(_ tab: MainTabDestination) {
        guard tab != selectedTab else {
            return
        }

        if selectedTab == .home && tab != .home {
            homePath.removeAll()
        }

        UIImpactFeedbackGenerator(style: .soft).impactOccurred()

        let shouldQuickFade = tabDistance(from: selectedTab, to: tab) > 2
        usesQuickFadeSelection = shouldQuickFade

        // Performance: keep the tab-bar highlight animated while the large tab content swaps without inherited animation.
        selectedTab = tab
    }

    private func openHomeProfile() {
        guard homePath.last != .profile else {
            return
        }

        homePath.append(.profile)
    }

    private func openSavedGlowUpRoutine() {
        requirePremium(.glowUpRoutine, source: "saved-glowup-routine") {
            activeGlowUpRoutine = .saved
        }
    }

    private func requirePremium(
        _ feature: AIScendPremiumFeature,
        source: String,
        action: () -> Void
    ) {
        guard accessPlan.canOpen(feature) else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            presentPremiumPaywall(for: feature, source: source)
            return
        }

        action()
    }

    private func presentPremiumPaywall(
        for feature: AIScendPremiumFeature,
        source: String
    ) {
        AIScendSuperwallAnalytics.trackPaywallRequest(
            feature: feature,
            accessPlan: accessPlan,
            source: source
        )
        AIScendSuperwallAnalytics.trackPlacementIfKnown(source, feature: feature, accessPlan: accessPlan)

        activePremiumPaywall = AIScendPremiumPaywallPresentation(
            variant: feature.paywallVariant,
            offer: feature.paywallOffer
        )
    }

    private func openHydrationChat(_ prompt: String) {
        pendingChatPrompt = prompt
        if selectedTab != .chat {
            select(.chat)
        }
    }

    private func openRoutineHydration() {
        routineHydrationNavigationRequest += 1
        if selectedTab != .routine {
            select(.routine)
        }
    }
}

private extension MainTabContainer {
    static func resolveInitialSelectedTab(
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> MainTabDestination {
        guard let configuredTab = arguments.first(where: { $0.hasPrefix("--uitest-start-tab=") }) else {
            return .home
        }

        let rawValue = String(configuredTab.dropFirst("--uitest-start-tab=".count))
        return MainTabDestination(rawValue: rawValue) ?? .home
    }

    static func shouldDisableDailyPhotoPromptsForUITests(
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> Bool {
        arguments.contains("--uitest-disable-daily-photo-prompts")
    }

    static func shouldDisableDailyStreakPromptsForUITests(
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> Bool {
        arguments.contains("--uitest-disable-daily-streak-prompts")
    }

    enum HomeDestination: Hashable {
        case profile
    }
}

private struct PostSignInWelcomeView: View {
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var scanLineMoves = false
    @State private var markBreathes = false

    var body: some View {
        ZStack {
            AIscendBackdrop()

            LinearGradient(
                colors: [
                    AIscendTheme.Colors.accentGlow.opacity(0.16),
                    .clear,
                    AIscendTheme.Colors.accentPrimary.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 44)

                AIscendBrandMark(size: 64, showsWordmark: false)
                    .scaleEffect(markBreathes ? 1.04 : 0.98)
                    .shadow(color: AIscendTheme.Colors.accentGlow.opacity(markBreathes ? 0.38 : 0.18), radius: 28, y: 12)
                    .padding(.bottom, 34)

                PostSignInFaceStage(scanLineMoves: scanLineMoves)
                    .frame(width: 214, height: 214)
                    .padding(.bottom, 34)

                VStack(spacing: 12) {
                    Text("Welcome to AIScend")
                        .font(.system(size: 39, weight: .heavy, design: .rounded))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    Text("Your glowup starts here.")
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .foregroundStyle(AIscendTheme.Colors.accentGlow)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 34)

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.8)
                    onContinue()
                } label: {
                    HStack(spacing: 12) {
                        Text("Continue")
                            .font(.system(size: 19, weight: .heavy, design: .rounded))

                        Image(systemName: "arrow.right")
                            .font(.system(size: 17, weight: .black))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AIscendTheme.Colors.accentGlow)
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.34), lineWidth: 1)
                    )
                    .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.32), radius: 24, y: 12)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 18)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.58, dampingFraction: 0.86)) {
                appeared = true
            }

            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                markBreathes = true
            }

            withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true)) {
                scanLineMoves = true
            }
        }
    }
}

private struct PostSignInFaceStage: View {
    let scanLineMoves: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 44, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle.opacity(0.78), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 44, style: .continuous)
                        .fill(Color.white.opacity(0.045))
                )

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AIscendTheme.Colors.accentGlow.opacity(0.76), lineWidth: 3)
                .frame(width: 124, height: 158)
                .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.32), radius: 22)

            Image(systemName: "faceid")
                .font(.system(size: 74, weight: .semibold))
                .foregroundStyle(.white.opacity(0.94))

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            AIscendTheme.Colors.accentGlow.opacity(0.86),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 154, height: 4)
                .offset(y: scanLineMoves ? 72 : -72)

            VStack {
                HStack {
                    scanDot(delayIndex: 0)
                    scanDot(delayIndex: 1)
                    scanDot(delayIndex: 2)
                    Spacer(minLength: 0)
                }
                .padding(18)

                Spacer(minLength: 0)
            }
        }
    }

    private func scanDot(delayIndex: Int) -> some View {
        Circle()
            .fill(AIscendTheme.Colors.accentGlow.opacity(delayIndex == 1 ? 0.92 : 0.52))
            .frame(width: 8, height: 8)
            .scaleEffect(scanLineMoves && delayIndex == 1 ? 1.28 : 1)
            .animation(.easeInOut(duration: 0.72).repeatForever(autoreverses: true).delay(Double(delayIndex) * 0.12), value: scanLineMoves)
    }
}

#Preview {
    MainTabContainer(model: AppModel(), session: AuthSessionStore())
}
