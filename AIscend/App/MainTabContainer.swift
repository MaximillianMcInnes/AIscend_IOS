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

    @Bindable var model: AppModel
    @Bindable var session: AuthSessionStore

    @State private var selectedTab: MainTabDestination = Self.resolveInitialSelectedTab()
    @State private var homePath: [HomeDestination] = []
    @State private var showingDailyPhotoCapture = false
    @State private var showingDailyPhotoArchive = false
    @State private var showingDailyCheckIn = false
    @State private var showingStreaks = false
    @State private var showingScanCapture = false
    @State private var showingScanResults = false
    @State private var pendingChatPrompt: String?
    @State private var isKeyboardPresented = false
    @State private var usesQuickFadeSelection = false
    @StateObject private var badgeManager = BadgeManager()
    @StateObject private var dailyCheckInStore = DailyCheckInStore()
    @StateObject private var dailyPhotoStore = DailyPhotoStore()
    @StateObject private var hydrationStore = HydrationTrackingStore()
    @StateObject private var electrolyteStore = ElectrolyteTrackingStore()
    @StateObject private var notificationManager = NotificationManager()
    @Namespace private var tabNamespace

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                selectedTabContent
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.clear)
            .overlay(alignment: .bottom) {
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
            maybePresentDailyPhotoPrompt(.firstOpen)
            maybePresentRoutineStreakPromptIfNeeded()
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
                isPremium: badgeManager.earnedBadges.contains(where: { $0.id == .premiumUnlocked }),
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
        .fullScreenCover(isPresented: $showingScanCapture) {
            ScanCaptureFlowView(
                session: session,
                badgeManager: badgeManager,
                dailyCheckInStore: dailyCheckInStore,
                notificationManager: notificationManager,
                onOpenRoutine: {
                    select(.routine)
                    showingScanCapture = false
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
                onOpenScan: {
                    select(.scan)
                    showingScanResults = false
                },
                onOpenRoutine: {
                    select(.routine)
                    showingScanResults = false
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
                onOpenAdvisor: { select(.chat) },
                onOpenHydrationChat: openHydrationChat,
                onOpenRoutine: { select(.routine) },
                onOpenCheckIn: { showingDailyCheckIn = true },
                onOpenConsistency: { showingStreaks = true },
                onOpenDailyPhoto: { showingDailyPhotoArchive = true },
                onCaptureDailyPhoto: { showingDailyPhotoCapture = true },
                onOpenScan: { select(.scan) },
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
                onOpenCheckIn: { showingDailyCheckIn = true },
                onOpenConsistency: { showingStreaks = true },
                onOpenHydrationChat: openHydrationChat,
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
                onOpenChat: { select(.chat) },
                onOpenRoutine: { select(.routine) }
            )
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var chatTab: some View {
        NavigationStack {
            AIscendChatScreenContainer(session: session, pendingDraft: $pendingChatPrompt)
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
        showingDailyPhotoCapture || showingDailyPhotoArchive || showingDailyCheckIn || showingStreaks || showingScanCapture || showingScanResults
    }

    private var shouldShowTabBar: Bool {
        !(selectedTab == .chat && isKeyboardPresented)
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

        withAnimation(shouldQuickFade ? .easeOut(duration: 0.18) : .spring(response: 0.34, dampingFraction: 0.86)) {
            selectedTab = tab
        }
    }

    private func openHomeProfile() {
        guard homePath.last != .profile else {
            return
        }

        homePath.append(.profile)
    }

    private func openHydrationChat(_ prompt: String) {
        pendingChatPrompt = prompt
        if selectedTab != .chat {
            select(.chat)
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

#Preview {
    MainTabContainer(model: AppModel(), session: AuthSessionStore())
}
