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
    case profile

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
        case .profile:
            "Me"
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
        case .profile:
            "person.fill"
        }
    }
}

struct MainTabContainer: View {
    @Environment(\.scenePhase) private var scenePhase

    @Bindable var model: AppModel
    @Bindable var session: AuthSessionStore

    @State private var selectedTab: MainTabDestination = .home
    @State private var showingDailyPhotoCapture = false
    @State private var showingDailyCheckIn = false
    @State private var showingStreaks = false
    @State private var showingScanCapture = false
    @State private var showingScanResults = false
    @StateObject private var badgeManager = BadgeManager()
    @StateObject private var dailyCheckInStore = DailyCheckInStore()
    @StateObject private var dailyPhotoStore = DailyPhotoStore()
    @StateObject private var notificationManager = NotificationManager()
    @Namespace private var tabNamespace

    var body: some View {
        GeometryReader { geometry in
            TabView(selection: $selectedTab) {
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
                        onOpenDailyPhoto: { showingDailyPhotoCapture = true },
                        onOpenScan: { select(.scan) },
                        onOpenAccount: { select(.profile) },
                        onRefine: { model.resetOnboarding() }
                    )
                    .toolbar(.hidden, for: .navigationBar)
                }
                .tag(MainTabDestination.home)

                NavigationStack {
                    RoutineBlueprintView(
                        model: model,
                        dailyCheckInStore: dailyCheckInStore,
                        badgeManager: badgeManager,
                        onOpenCheckIn: { showingDailyCheckIn = true },
                        onOpenConsistency: { showingStreaks = true }
                    )
                    .toolbar(.hidden, for: .navigationBar)
                }
                .tag(MainTabDestination.routine)

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
                .tag(MainTabDestination.scan)

                NavigationStack {
                    AIscendChatScreenContainer(session: session)
                        .toolbar(.hidden, for: .navigationBar)
                }
                .tag(MainTabDestination.chat)

                NavigationStack {
                    AccountView(
                        model: model,
                        session: session,
                        dailyCheckInStore: dailyCheckInStore,
                        badgeManager: badgeManager,
                        notificationManager: notificationManager
                    )
                    .toolbar(.hidden, for: .navigationBar)
                }
                .tag(MainTabDestination.profile)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.clear)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                GlassTabBar(
                    selectedTab: selectedTab,
                    namespace: tabNamespace,
                    bottomInset: geometry.safeAreaInsets.bottom,
                    onSelect: select
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.clear)
        .task(id: session.user?.id) {
            dailyPhotoStore.applyAuthenticatedUserID(session.user?.id)
            maybePresentDailyPhotoPrompt(.firstOpen)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                maybePresentDailyPhotoPrompt(.engagement)
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if oldValue != newValue {
                maybePresentDailyPhotoPrompt(.engagement)
            }
        }
        .sheet(isPresented: $showingDailyPhotoCapture) {
            DailyPhotoCaptureSheet(
                store: dailyPhotoStore,
                onDismiss: { showingDailyPhotoCapture = false }
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

    private var isPresentingBlockingModal: Bool {
        showingDailyPhotoCapture || showingDailyCheckIn || showingStreaks || showingScanCapture || showingScanResults
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

        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            selectedTab = tab
        }
    }
}

#Preview {
    MainTabContainer(model: AppModel(), session: AuthSessionStore())
}
