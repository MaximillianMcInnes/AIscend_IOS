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
            "Today"
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

    @Bindable var model: AppModel
    @Bindable var session: AuthSessionStore

    @State private var selectedTab: MainTabDestination = .home
    @State private var showingDailyPhotoCapture = false
    @State private var showingDailyPhotoArchive = false
    @State private var showingDailyCheckIn = false
    @State private var showingStreaks = false
    @State private var showingScanCapture = false
    @State private var showingScanResults = false
    @State private var isKeyboardPresented = false
    @State private var usesQuickFadeSelection = false
    @StateObject private var badgeManager = BadgeManager()
    @StateObject private var dailyCheckInStore = DailyCheckInStore()
    @StateObject private var dailyPhotoStore = DailyPhotoStore()
    @StateObject private var notificationManager = NotificationManager()
    @Namespace private var tabNamespace

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                homeTab
                    .opacity(selectedTab == .home ? 1 : 0)
                    .allowsHitTesting(selectedTab == .home)
                    .zIndex(selectedTab == .home ? 1 : 0)

                routineTab
                    .opacity(selectedTab == .routine ? 1 : 0)
                    .allowsHitTesting(selectedTab == .routine)
                    .zIndex(selectedTab == .routine ? 1 : 0)

                scanTab
                    .opacity(selectedTab == .scan ? 1 : 0)
                    .allowsHitTesting(selectedTab == .scan)
                    .zIndex(selectedTab == .scan ? 1 : 0)

                chatTab
                    .opacity(selectedTab == .chat ? 1 : 0)
                    .allowsHitTesting(selectedTab == .chat)
                    .zIndex(selectedTab == .chat ? 1 : 0)

                moreTab
                    .opacity(selectedTab == .more ? 1 : 0)
                    .allowsHitTesting(selectedTab == .more)
                    .zIndex(selectedTab == .more ? 1 : 0)
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
            dailyCheckInStore.refreshForCurrentDate()
            maybePresentDailyPhotoPrompt(.firstOpen)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                dailyCheckInStore.refreshForCurrentDate()
                maybePresentDailyPhotoPrompt(.engagement)
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if oldValue != newValue {
                maybePresentDailyPhotoPrompt(.engagement)
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

    private var homeTab: some View {
        NavigationStack {
            RoutineDashboardView(
                model: model,
                dailyCheckInStore: dailyCheckInStore,
                dailyPhotoStore: dailyPhotoStore,
                badgeManager: badgeManager,
                onOpenAdvisor: { select(.chat) },
                onOpenRoutine: { select(.routine) },
                onOpenCheckIn: { showingDailyCheckIn = true },
                onOpenConsistency: { showingStreaks = true },
                onOpenDailyPhoto: { showingDailyPhotoArchive = true },
                onCaptureDailyPhoto: { showingDailyPhotoCapture = true },
                onOpenScan: { select(.scan) },
                onOpenAccount: { select(.more) },
                onRefine: { model.resetOnboarding() }
            )
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var routineTab: some View {
        NavigationStack {
            RoutineCleanSlateView(
                model: model,
                dailyCheckInStore: dailyCheckInStore,
                badgeManager: badgeManager,
                onOpenCheckIn: { showingDailyCheckIn = true },
                onOpenConsistency: { showingStreaks = true },
                onRefine: { model.resetOnboarding() }
            )
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var scanTab: some View {
        NavigationStack {
            AIscendScanStudioView(
                model: model,
                onOpenLatestResult: { showingScanResults = true },
                onBeginCapture: { showingScanCapture = true },
                onOpenChat: { select(.chat) },
                onOpenRoutine: { select(.routine) }
            )
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var chatTab: some View {
        NavigationStack {
            AIscendChatScreenContainer(session: session)
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
        guard !isPresentingBlockingModal else {
            return
        }

        guard dailyPhotoStore.shouldPresentPrompt(for: trigger) else {
            return
        }

        showingDailyPhotoCapture = true
    }

    private func select(_ tab: MainTabDestination) {
        guard tab != selectedTab else {
            return
        }

        UIImpactFeedbackGenerator(style: .soft).impactOccurred()

        let shouldQuickFade = tabDistance(from: selectedTab, to: tab) > 2
        usesQuickFadeSelection = shouldQuickFade

        withAnimation(shouldQuickFade ? .easeOut(duration: 0.18) : .spring(response: 0.34, dampingFraction: 0.86)) {
            selectedTab = tab
        }
    }
}

#Preview {
    MainTabContainer(model: AppModel(), session: AuthSessionStore())
}
