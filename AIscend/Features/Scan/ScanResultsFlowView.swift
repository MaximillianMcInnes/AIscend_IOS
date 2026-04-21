//
//  ScanResultsFlowView.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import SwiftUI

struct ScanResultsFlowView: View {
    let initialResult: PersistedScanRecord?
    let onOpenScan: () -> Void
    let onOpenRoutine: () -> Void
    let onOpenChat: () -> Void
    let onReturnHome: () -> Void
    let onDismiss: () -> Void

    @ObservedObject private var badgeManager: BadgeManager
    @ObservedObject private var dailyCheckInStore: DailyCheckInStore
    @ObservedObject private var notificationManager: NotificationManager
    @StateObject private var viewModel: ScanResultsViewModel
    @StateObject private var paywallCoordinator = PaywallCoordinator()
    @StateObject private var shareCoordinator = ShareCoordinator()
    @State private var showingUpgrade = false
    @State private var showingDailyCheckIn = false
    @State private var showingStreakHub = false

    init(
        session: AuthSessionStore,
        initialResult: PersistedScanRecord? = nil,
        badgeManager: BadgeManager,
        dailyCheckInStore: DailyCheckInStore,
        notificationManager: NotificationManager,
        repository: ScanResultsRepositoryProtocol = ScanResultsRepository(),
        onOpenScan: @escaping () -> Void = {},
        onOpenRoutine: @escaping () -> Void = {},
        onOpenChat: @escaping () -> Void = {},
        onReturnHome: @escaping () -> Void = {},
        onDismiss: @escaping () -> Void = {}
    ) {
        self.initialResult = initialResult
        self.onOpenScan = onOpenScan
        self.onOpenRoutine = onOpenRoutine
        self.onOpenChat = onOpenChat
        self.onReturnHome = onReturnHome
        self.onDismiss = onDismiss
        self._badgeManager = ObservedObject(wrappedValue: badgeManager)
        self._dailyCheckInStore = ObservedObject(wrappedValue: dailyCheckInStore)
        self._notificationManager = ObservedObject(wrappedValue: notificationManager)
        _viewModel = StateObject(
            wrappedValue: ScanResultsViewModel(
                session: session,
                repository: repository
            )
        )
    }

    var body: some View {
        ZStack {
            AIscendBackdrop()
            ResultsAmbientLayer()

            content
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if viewModel.loadState == .ready {
                bottomChrome
            }
        }
        .sheet(isPresented: $showingUpgrade) {
            AIscendUpgradeView(
                premiumURL: AIscendChatConfiguration.live.premiumURL,
                onDismiss: { showingUpgrade = false }
            )
        }
        .sheet(item: $shareCoordinator.activePayload) { payload in
            SharePreviewView(
                payload: payload,
                onDismiss: { shareCoordinator.dismiss() }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingDailyCheckIn) {
            DailyCheckInView(
                dailyCheckInStore: dailyCheckInStore,
                badgeManager: badgeManager,
                notificationManager: notificationManager,
                isPremium: viewModel.isPremium,
                onComplete: {},
                onDismiss: { showingDailyCheckIn = false }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingStreakHub) {
            StreakHubView(
                dailyCheckInStore: dailyCheckInStore,
                badgeManager: badgeManager,
                notificationManager: notificationManager,
                onOpenCheckIn: {
                    showingStreakHub = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        showingDailyCheckIn = true
                    }
                },
                onDismiss: { showingStreakHub = false }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(item: $paywallCoordinator.activePresentation) { presentation in
            PaywallView(
                presentation: presentation,
                onPrimary: { handlePaywallPrimary() },
                onSecondary: { paywallCoordinator.dismiss() },
                onDismiss: { paywallCoordinator.dismiss() }
            )
        }
        .task(id: initialResult?.meta.scanId ?? initialResult?.saveFingerprint ?? "latest-scan-result") {
            await viewModel.load(initialResult: initialResult)
            await notificationManager.refreshAuthorizationStatus()

            if let result = viewModel.result {
                badgeManager.recordResultsViewed(accessLevel: result.accessLevel)
            }
        }
        .onChange(of: viewModel.currentPageIndex) { oldValue, newValue in
            viewModel.handlePageChange(from: oldValue, to: newValue)

            if !viewModel.isPremium, viewModel.currentPageID == .premiumPush {
                paywallCoordinator.present(
                    .rewardLoop,
                    dismissable: true,
                    sourceKey: "reward-loop-\(viewModel.result?.saveFingerprint ?? "latest")"
                )
            }
        }
        .overlay {
            GeometryReader { geometry in
                VStack {
                    HStack {
                        Button {
                            showingStreakHub = true
                        } label: {
                            ResultsMomentumCapsule(
                                streakDays: dailyCheckInStore.snapshot.currentStreak,
                                badgeCount: badgeManager.earnedBadges.count,
                                checkedInToday: dailyCheckInStore.hasCheckedInToday
                            )
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: AIscendTheme.Spacing.small)

                        ResultsCloseButton(action: onDismiss)
                    }
                    .padding(.top, geometry.safeAreaInsets.top + AIscendTheme.Spacing.small)
                    .padding(.horizontal, AIscendTheme.Spacing.screenInset)

                    Spacer()
                }
            }
            .allowsHitTesting(true)
        }
        .overlay(alignment: .top) {
            if let badge = badgeManager.latestUnlockedBadge {
                ResultsBadgeUnlockBanner(badge: badge)
                    .padding(.top, 106)
                    .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .loading:
            ScanResultsLoadingState()
        case .empty:
            ScanResultsEmptyState(onOpenScan: onOpenScan)
        case .ready:
            resultsPager
        }
    }

    private var resultsPager: some View {
        TabView(selection: $viewModel.currentPageIndex) {
            ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, page in
                resultsPage(page, index: index)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    @ViewBuilder
    private func resultsPage(_ page: ScanResultsPageID, index: Int) -> some View {
        switch page {
        case .overview:
            RatingsResultsPage(
                pageIndex: index,
                totalPages: viewModel.pageCount,
                title: viewModel.title(for: page),
                subtitle: viewModel.subtitle(for: page),
                result: viewModel.result,
                scoreCards: viewModel.scoreCards,
                onShare: { presentShare(for: .overview) },
                onContinue: viewModel.advance
            )

        case .placement:
            PlacementResultsPage(
                pageIndex: index,
                totalPages: viewModel.pageCount,
                title: viewModel.title(for: page),
                subtitle: viewModel.subtitle(for: page),
                result: viewModel.result,
                onShare: { presentShare(for: .placement) },
                onContinue: viewModel.advance
            )

        case .harmony:
            HarmonyResultsPage(
                pageIndex: index,
                totalPages: viewModel.pageCount,
                title: viewModel.title(for: page),
                subtitle: viewModel.subtitle(for: page),
                traits: viewModel.harmonyTraits(),
                onShare: { presentShare(for: .harmony) },
                onContinue: viewModel.advance
            )

        case .eyes:
            FeatureResultsPage(
                pageIndex: index,
                totalPages: viewModel.pageCount,
                title: viewModel.title(for: page),
                subtitle: viewModel.subtitle(for: page),
                badge: viewModel.isPremium ? nil : "Preview",
                traits: viewModel.sectionTraits(for: .eyes),
                showsInlineUpsell: !viewModel.isPremium,
                onShare: { presentShare(for: .eyes) },
                onContinue: viewModel.advance,
                onUpgrade: {
                    paywallCoordinator.present(
                        .lockedInsight,
                        dismissable: true,
                        sourceKey: "locked-eyes"
                    )
                }
            )

        case .lips:
            FeatureResultsPage(
                pageIndex: index,
                totalPages: viewModel.pageCount,
                title: viewModel.title(for: page),
                subtitle: viewModel.subtitle(for: page),
                badge: nil,
                traits: viewModel.sectionTraits(for: .lips),
                showsInlineUpsell: false,
                onShare: { presentShare(for: .lips) },
                onContinue: viewModel.advance,
                onUpgrade: {
                    paywallCoordinator.present(
                        .deepReport,
                        dismissable: true,
                        sourceKey: "lips-premium"
                    )
                }
            )

        case .jaw:
            FeatureResultsPage(
                pageIndex: index,
                totalPages: viewModel.pageCount,
                title: viewModel.title(for: page),
                subtitle: viewModel.subtitle(for: page),
                badge: "Premium",
                traits: viewModel.sectionTraits(for: .jaw),
                showsInlineUpsell: false,
                onShare: { presentShare(for: .jaw) },
                onContinue: viewModel.advance,
                onUpgrade: {
                    paywallCoordinator.present(
                        .deepReport,
                        dismissable: true,
                        sourceKey: "jaw-premium",
                        force: true
                    )
                }
            )

        case .sideProfile:
            FeatureResultsPage(
                pageIndex: index,
                totalPages: viewModel.pageCount,
                title: viewModel.title(for: page),
                subtitle: viewModel.subtitle(for: page),
                badge: "Premium",
                traits: viewModel.sectionTraits(for: .sideProfile),
                showsInlineUpsell: false,
                onShare: { presentShare(for: .sideProfile) },
                onContinue: viewModel.advance,
                onUpgrade: {
                    paywallCoordinator.present(
                        .deepReport,
                        dismissable: true,
                        sourceKey: "side-premium",
                        force: true
                    )
                }
            )

        case .premiumPush:
            PremiumPushResultsPage(
                pageIndex: index,
                totalPages: viewModel.pageCount,
                title: viewModel.title(for: page),
                subtitle: viewModel.subtitle(for: page),
                onUpgrade: {
                    paywallCoordinator.present(
                        .rewardLoop,
                        dismissable: true,
                        sourceKey: "premium-push-primary",
                        force: true
                    )
                },
                onContinue: viewModel.advance
            )

        case .done:
            DoneResultsPage(
                pageIndex: index,
                totalPages: viewModel.pageCount,
                title: viewModel.title(for: page),
                subtitle: viewModel.subtitle(for: page),
                isPremium: viewModel.isPremium,
                cards: viewModel.completionCards,
                primaryTitle: viewModel.primaryDoneTitle(),
                onPrimary: {
                    if viewModel.isPremium {
                        badgeManager.recordGlowUpOpened()
                        onOpenRoutine()
                    } else {
                        paywallCoordinator.present(
                            .glowUpGate,
                            dismissable: true,
                            sourceKey: "glow-up-gate",
                            force: true
                        )
                    }
                },
                onOpenChat: {
                    badgeManager.recordAdvisorOpened()
                    onOpenChat()
                },
                onOpenCheckIn: { showingDailyCheckIn = true },
                onOpenStreakHub: { showingStreakHub = true },
                streakDays: dailyCheckInStore.snapshot.currentStreak,
                checkedInToday: dailyCheckInStore.hasCheckedInToday,
                badgeCount: badgeManager.earnedBadges.count,
                onShare: { presentShare(for: .done) },
                onReturnHome: onReturnHome
            )
        }
    }

    private var bottomChrome: some View {
        VStack(spacing: AIscendTheme.Spacing.small) {
            if let syncStatusLine = viewModel.syncStatusLine {
                ResultsSyncCapsule(
                    text: syncStatusLine,
                    state: viewModel.autoSaveState
                )
            }

            ResultsDotsBar(
                totalPages: viewModel.pageCount,
                currentPage: viewModel.currentPageIndex,
                onTap: viewModel.goToPage
            )
        }
        .padding(.horizontal, AIscendTheme.Spacing.screenInset)
        .padding(.top, AIscendTheme.Spacing.small)
        .padding(.bottom, AIscendTheme.Spacing.small)
    }

    private func handlePaywallPrimary() {
        paywallCoordinator.dismiss()

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 180_000_000)
            showingUpgrade = true
        }
    }

    private func presentShare(for page: ScanResultsPageID) {
        guard let payload = viewModel.sharePayload(for: page) else {
            return
        }

        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        shareCoordinator.present(payload)
    }
}

#Preview("Premium Result") {
    ScanResultsFlowView(
        session: AuthSessionStore(),
        initialResult: .previewPremium,
        badgeManager: BadgeManager(),
        dailyCheckInStore: DailyCheckInStore(),
        notificationManager: NotificationManager()
    )
}

#Preview("Free Result") {
    ScanResultsFlowView(
        session: AuthSessionStore(),
        initialResult: .previewFree,
        badgeManager: BadgeManager(),
        dailyCheckInStore: DailyCheckInStore(),
        notificationManager: NotificationManager()
    )
}
