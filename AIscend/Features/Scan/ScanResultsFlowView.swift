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
    let allowsPostResultActions: Bool

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
        allowsPostResultActions: Bool = true,
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
        self.allowsPostResultActions = allowsPostResultActions
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
        .sheet(isPresented: $showingDailyCheckIn, content: dailyCheckInSheet)
        .sheet(isPresented: $showingStreakHub, content: streakHubSheet)
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

            if allowsPostResultActions, let result = viewModel.result {
                badgeManager.recordResultsViewed(accessLevel: result.accessLevel)
            }
        }
        .onChange(of: viewModel.currentPageIndex) { oldValue, newValue in
            viewModel.handlePageChange(from: oldValue, to: newValue)

            if allowsPostResultActions, !viewModel.isPremium, viewModel.currentPageID == .premiumPush {
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
                        if allowsPostResultActions {
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
                        }

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
            if allowsPostResultActions, let badge = badgeManager.latestUnlockedBadge {
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
                ScanResultsPageHost(
                    page: page,
                    pageIndex: index,
                    viewModel: viewModel,
                    badgeManager: badgeManager,
                    dailyCheckInStore: dailyCheckInStore,
                    onShare: { page in
                        presentShare(for: page)
                    },
                    onPresentPaywall: { variant, dismissable, sourceKey, force in
                        presentPaywall(
                            variant,
                            dismissable: dismissable,
                            sourceKey: sourceKey,
                            force: force
                        )
                    },
                    allowsPostResultActions: allowsPostResultActions,
                    onOpenRoutine: onOpenRoutine,
                    onOpenChat: onOpenChat,
                    onOpenCheckIn: {
                        guard allowsPostResultActions else { return }
                        showingDailyCheckIn = true
                    },
                    onOpenStreakHub: {
                        guard allowsPostResultActions else { return }
                        showingStreakHub = true
                    },
                    onReturnHome: onReturnHome
                )
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
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
        guard allowsPostResultActions else {
            paywallCoordinator.dismiss()
            return
        }

        paywallCoordinator.dismiss()

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 180_000_000)
            showingUpgrade = true
        }
    }

    private func presentPaywall(
        _ variant: PaywallVariant,
        dismissable: Bool,
        sourceKey: String?,
        force: Bool
    ) {
        guard allowsPostResultActions else {
            return
        }

        paywallCoordinator.present(
            variant,
            dismissable: dismissable,
            sourceKey: sourceKey,
            force: force
        )
    }

    private func presentShare(for page: ScanResultsPageID) {
        guard let payload = viewModel.sharePayload(for: page) else {
            return
        }

        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        shareCoordinator.present(payload)
    }

    @ViewBuilder
    private func dailyCheckInSheet() -> some View {
        if allowsPostResultActions {
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
    }

    @ViewBuilder
    private func streakHubSheet() -> some View {
        if allowsPostResultActions {
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
