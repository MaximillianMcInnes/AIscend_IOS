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
    case scan
    case chat
    case routine

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home:
            "Home"
        case .scan:
            "Scan"
        case .chat:
            "Chat"
        case .routine:
            "Routine"
        }
    }

    var symbol: String {
        switch self {
        case .home:
            "house.fill"
        case .scan:
            "viewfinder.circle.fill"
        case .chat:
            "message.fill"
        case .routine:
            "square.grid.2x2.fill"
        }
    }
}

struct MainTabContainer: View {
    @Bindable var model: AppModel
    @Bindable var session: AuthSessionStore

    @State private var selectedTab: MainTabDestination = .home
    @State private var showingAccount = false
    @State private var showingDailyCheckIn = false
    @State private var showingStreaks = false
    @State private var showingScanResults = false
    @StateObject private var badgeManager = BadgeManager()
    @StateObject private var dailyCheckInStore = DailyCheckInStore()
    @StateObject private var notificationManager = NotificationManager()
    @Namespace private var tabNamespace

    var body: some View {
        ZStack {
            persistentTab(.home) {
                NavigationStack {
                    RoutineDashboardView(
                        model: model,
                        dailyCheckInStore: dailyCheckInStore,
                        badgeManager: badgeManager,
                        onOpenAdvisor: { select(.chat) },
                        onOpenRoutine: { select(.routine) },
                        onOpenCheckIn: { showingDailyCheckIn = true },
                        onOpenConsistency: { showingStreaks = true },
                        onOpenAccount: { showingAccount = true },
                        onRefine: { model.resetOnboarding() }
                    )
                    .toolbar(.hidden, for: .navigationBar)
                }
            }

            persistentTab(.scan) {
                NavigationStack {
                    AIscendScanStudioView(
                        model: model,
                        onOpenLatestResult: { showingScanResults = true },
                        onOpenChat: { select(.chat) },
                        onOpenRoutine: { select(.routine) }
                    )
                    .toolbar(.hidden, for: .navigationBar)
                }
            }

            persistentTab(.chat) {
                NavigationStack {
                    AIscendChatScreenContainer(session: session)
                        .toolbar(.hidden, for: .navigationBar)
                }
            }

            persistentTab(.routine) {
                NavigationStack {
                    RoutineBlueprintView(
                        model: model,
                        dailyCheckInStore: dailyCheckInStore,
                        badgeManager: badgeManager,
                        onOpenCheckIn: { showingDailyCheckIn = true },
                        onOpenConsistency: { showingStreaks = true }
                    )
                        .aiscendNavigationChrome()
                }
            }
        }
        .background(AIscendTheme.Colors.appBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            GlassTabBar(
                selectedTab: selectedTab,
                namespace: tabNamespace,
                onSelect: select
            )
            .padding(.horizontal, AIscendTheme.Spacing.medium)
            .padding(.top, AIscendTheme.Spacing.small)
            .padding(.bottom, AIscendTheme.Spacing.small)
        }
        .sheet(isPresented: $showingAccount) {
            NavigationStack {
                AccountView(
                    model: model,
                    session: session,
                    dailyCheckInStore: dailyCheckInStore,
                    badgeManager: badgeManager,
                    notificationManager: notificationManager
                )
                    .aiscendNavigationChrome()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
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
    private func persistentTab<Content: View>(
        _ tab: MainTabDestination,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .opacity(selectedTab == tab ? 1 : 0)
            .allowsHitTesting(selectedTab == tab)
            .accessibilityHidden(selectedTab != tab)
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
            .zIndex(selectedTab == tab ? 1 : 0)
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
