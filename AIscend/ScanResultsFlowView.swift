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
            OverviewResultsSection(
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
            PlacementResultsSection(
                pageIndex: index,
                totalPages: viewModel.pageCount,
                title: viewModel.title(for: page),
                subtitle: viewModel.subtitle(for: page),
                result: viewModel.result,
                onShare: { presentShare(for: .placement) },
                onContinue: viewModel.advance
            )
        case .harmony:
            HarmonyResultsSection(
                pageIndex: index,
                totalPages: viewModel.pageCount,
                title: viewModel.title(for: page),
                subtitle: viewModel.subtitle(for: page),
                traits: viewModel.harmonyTraits(),
                onShare: { presentShare(for: .harmony) },
                onContinue: viewModel.advance
            )
        case .eyes:
            FeatureResultsSection(
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
            FeatureResultsSection(
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
            FeatureResultsSection(
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
                    paywallCoordinator.present(.deepReport, dismissable: true, sourceKey: "jaw-premium", force: true)
                }
            )
        case .sideProfile:
            FeatureResultsSection(
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
                    paywallCoordinator.present(.deepReport, dismissable: true, sourceKey: "side-premium", force: true)
                }
            )
        case .premiumPush:
            PremiumPushSection(
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
            DoneResultsFlowSection(
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

private struct ResultsAmbientLayer: View {
    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    AIscendTheme.Colors.accentGlow.opacity(0.18),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 12,
                endRadius: 320
            )
            .offset(x: 140, y: -160)

            RadialGradient(
                colors: [
                    Color.white.opacity(0.05),
                    .clear
                ],
                center: .topLeading,
                startRadius: 10,
                endRadius: 220
            )
            .offset(x: -150, y: -180)

            RadialGradient(
                colors: [
                    AIscendTheme.Colors.accentPrimary.opacity(0.12),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 300
            )
            .offset(x: -120, y: 260)
        }
        .ignoresSafeArea()
    }
}

private struct ResultsCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color(hex: "10141B").opacity(0.84))
                        .overlay(Circle().fill(.ultraThinMaterial).opacity(0.55))
                )
                .overlay(
                    Circle()
                        .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.32), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }
}

private struct ResultsMomentumCapsule: View {
    let streakDays: Int
    let badgeCount: Int
    let checkedInToday: Bool

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            HStack(spacing: 6) {
                Image(systemName: checkedInToday ? "checkmark.seal.fill" : "flame.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AIscendTheme.Colors.accentGlow)

                Text("\(max(streakDays, 0))d")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
            }

            Rectangle()
                .fill(AIscendTheme.Colors.borderSubtle)
                .frame(width: 1, height: 12)

            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AIscendTheme.Colors.accentGlow)

                Text("\(badgeCount)")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
            }
        }
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .background(
            Capsule(style: .continuous)
                .fill(Color(hex: "10141B").opacity(0.84))
                .overlay(Capsule(style: .continuous).fill(.ultraThinMaterial).opacity(0.55))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.30), radius: 18, x: 0, y: 10)
    }
}

private struct ResultsBadgeUnlockBanner: View {
    let badge: AIScendBadge

    var body: some View {
        HStack(alignment: .center, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: badge.symbol, accent: badge.accent, size: 46)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text("Badge Unlocked")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                Text(badge.title)
                    .aiscendTextStyle(.cardTitle)

                Text(badge.detail)
                    .aiscendTextStyle(.secondaryBody)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(Color(hex: "11151C").opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.34)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.accentGlow.opacity(0.34), lineWidth: 1)
        )
        .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.16), radius: 20, x: 0, y: 8)
    }
}

private struct ResultsSectionShell<Content: View>: View {
    let pageIndex: Int
    let totalPages: Int
    let title: String
    let subtitle: String
    let badge: String?
    let shareActionTitle: String?
    let onShare: (() -> Void)?
    let content: Content

    init(
        pageIndex: Int,
        totalPages: Int,
        title: String,
        subtitle: String,
        badge: String? = nil,
        shareActionTitle: String? = nil,
        onShare: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.pageIndex = pageIndex
        self.totalPages = totalPages
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.shareActionTitle = shareActionTitle
        self.onShare = onShare
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
                    topChrome
                    content
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, geometry.safeAreaInsets.top + AIscendTheme.Spacing.medium)
                .padding(.bottom, 180)
            }
        }
    }

    private var topChrome: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack {
                AIscendBadge(
                    title: badge ?? "Results",
                    symbol: badge == "Premium" ? "sparkles.rectangle.stack.fill" : "lock.shield.fill",
                    style: badge == "Premium" ? .accent : .neutral
                )

                Spacer()

                VStack(alignment: .trailing, spacing: AIscendTheme.Spacing.xSmall) {
                    if let onShare {
                        AIScendShareEntryButton(title: shareActionTitle ?? "Share", action: onShare)
                    }

                    Text("\(pageIndex + 1) / \(totalPages)")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                        .padding(.horizontal, AIscendTheme.Spacing.small)
                        .padding(.vertical, AIscendTheme.Spacing.xSmall)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.84))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                        )
                }
            }

            AIscendSectionHeader(
                title: title,
                subtitle: subtitle,
                prominence: .hero
            )
        }
    }
}

private struct OverviewResultsSection: View {
    let pageIndex: Int
    let totalPages: Int
    let title: String
    let subtitle: String
    let result: PersistedScanRecord?
    let scoreCards: [ResultsMetricCardModel]
    let onShare: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ResultsSectionShell(
            pageIndex: pageIndex,
            totalPages: totalPages,
            title: title,
            subtitle: subtitle,
            badge: "Scan Reveal",
            shareActionTitle: "Share score",
            onShare: onShare
        ) {
            DashboardGlassCard(tone: .hero) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    ResultsPhotoStrip(
                        frontURL: url(from: result?.meta.frontUrl),
                        sideURL: url(from: result?.meta.sideUrl)
                    )

                    HStack(alignment: .center, spacing: AIscendTheme.Spacing.large) {
                        ResultsScoreOrb(score: result?.overallScore ?? 72)

                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                            Text(result?.tierTitle ?? "Prime")
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                            Text("Overall read")
                                .aiscendTextStyle(.cardTitle)

                            Text(result?.headline ?? "AIScend sees a strong base with visible upside.")
                                .aiscendTextStyle(.body)
                        }
                    }
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
                ForEach(scoreCards) { card in
                    ResultsMetricPanel(card: card)
                }
            }

            ResultsPrimaryButton(
                title: "Continue to Placement",
                symbol: "arrow.right"
            ) {
                onContinue()
            }
        }
    }

    private func url(from rawValue: String?) -> URL? {
        guard let rawValue else {
            return nil
        }

        return URL(string: rawValue)
    }
}

private struct PlacementResultsSection: View {
    let pageIndex: Int
    let totalPages: Int
    let title: String
    let subtitle: String
    let result: PersistedScanRecord?
    let onShare: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ResultsSectionShell(
            pageIndex: pageIndex,
            totalPages: totalPages,
            title: title,
            subtitle: subtitle,
            shareActionTitle: "Share placement",
            onShare: onShare
        ) {
            DashboardGlassCard(tone: .hero) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    HStack(alignment: .center, spacing: AIscendTheme.Spacing.large) {
                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                            Text("Top \(result?.percentile ?? 18)%")
                                .aiscendTextStyle(.metric)

                            Text("Current placement")
                                .aiscendTextStyle(.cardTitle)

                            Text(result?.placementNarrative ?? "AIScend places this scan into a stronger-than-average band.")
                                .aiscendTextStyle(.body)
                        }

                        Spacer()

                        ResultsPercentileRing(percentile: result?.percentile ?? 18)
                    }

                    HStack(spacing: AIscendTheme.Spacing.small) {
                        PlacementBadge(
                            title: result?.tierTitle ?? "Prime",
                            detail: "AIScend class"
                        )
                        PlacementBadge(
                            title: result?.accessLevel == .premium ? "Full Report" : "Preview + Upside",
                            detail: "Access state"
                        )
                    }
                }
            }

            DashboardGlassCard {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                    Text("What this means")
                        .aiscendTextStyle(.sectionTitle)

                    Text("The placement screen is designed to reward attention. AIScend is not just scoring the scan, it is contextualising how the total presentation lands right now and how much room still exists above it.")
                        .aiscendTextStyle(.body)
                }
            }

            ResultsPrimaryButton(
                title: "Continue to Harmony",
                symbol: "arrow.right"
            ) {
                onContinue()
            }
        }
    }
}

private struct HarmonyResultsSection: View {
    let pageIndex: Int
    let totalPages: Int
    let title: String
    let subtitle: String
    let traits: [ScanTraitRowModel]
    let onShare: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ResultsSectionShell(
            pageIndex: pageIndex,
            totalPages: totalPages,
            title: title,
            subtitle: subtitle,
            shareActionTitle: "Share highlight",
            onShare: onShare
        ) {
            DashboardGlassCard(tone: .hero) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    Text("AIScend is looking for how the face holds together as a whole. These are the harmony variables contributing most to the current read.")
                        .aiscendTextStyle(.body)

                    VStack(spacing: AIscendTheme.Spacing.small) {
                        ForEach(traits) { trait in
                            HarmonyHighlightRow(trait: trait)
                        }
                    }
                }
            }

            ResultsPrimaryButton(
                title: "Continue to Feature Detail",
                symbol: "arrow.right"
            ) {
                onContinue()
            }
        }
    }
}

private struct FeatureResultsSection: View {
    let pageIndex: Int
    let totalPages: Int
    let title: String
    let subtitle: String
    let badge: String?
    let traits: [ScanTraitRowModel]
    let showsInlineUpsell: Bool
    let onShare: () -> Void
    let onContinue: () -> Void
    let onUpgrade: () -> Void

    var body: some View {
        ResultsSectionShell(
            pageIndex: pageIndex,
            totalPages: totalPages,
            title: title,
            subtitle: subtitle,
            badge: badge,
            shareActionTitle: "Share highlight",
            onShare: onShare
        ) {
            DashboardGlassCard {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                    ForEach(traits) { trait in
                        ExpandableTraitRow(
                            trait: trait,
                            onUpgrade: onUpgrade
                        )
                    }
                }
            }

            if showsInlineUpsell {
                DashboardGlassCard(tone: .premium) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                        AIscendBadge(
                            title: "Premium detail",
                            symbol: "lock.fill",
                            style: .accent
                        )

                        Text("Jaw detail, side profile analysis, and the deeper eye-area interpretation unlock once the report moves beyond preview mode.")
                            .aiscendTextStyle(.body)

                        Button(action: onUpgrade) {
                            AIscendButtonLabel(title: "Unlock Premium", leadingSymbol: "sparkles")
                        }
                        .buttonStyle(AIscendButtonStyle(variant: .secondary))
                    }
                }
            }

            ResultsPrimaryButton(
                title: "Continue",
                symbol: "arrow.right"
            ) {
                onContinue()
            }
        }
    }
}

private struct PremiumPushSection: View {
    let pageIndex: Int
    let totalPages: Int
    let title: String
    let subtitle: String
    let onUpgrade: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ResultsSectionShell(
            pageIndex: pageIndex,
            totalPages: totalPages,
            title: title,
            subtitle: subtitle,
            badge: "Premium"
        ) {
            DashboardGlassCard(tone: .premium) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    HStack(spacing: AIscendTheme.Spacing.large) {
                        AIscendIconOrb(symbol: "sparkles.rectangle.stack.fill", accent: .sky, size: 70)

                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                            Text("Upgrade unlocks the deeper read")
                                .aiscendTextStyle(.sectionTitle)

                            Text("Jawline structure, skin quality, side profile detail, and the complete improvement path sit behind the full report.")
                                .aiscendTextStyle(.body)
                        }
                    }

                    VStack(spacing: AIscendTheme.Spacing.small) {
                        PremiumBenefitRow(text: "Jaw rating and lower-third guidance")
                        PremiumBenefitRow(text: "Skin quality scoring and context")
                        PremiumBenefitRow(text: "Side profile analysis with projection detail")
                    }

                    Button(action: onUpgrade) {
                        AIscendButtonLabel(title: "Unlock Premium", leadingSymbol: "crown.fill")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .primary))

                    Button(action: onContinue) {
                        AIscendButtonLabel(title: "Continue with current result", leadingSymbol: "arrow.right")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .secondary))

                    Text("Your current result remains available either way. Premium just expands the depth, not the pressure.")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                }
            }
        }
    }
}

private struct DoneResultsFlowSection: View {
    let pageIndex: Int
    let totalPages: Int
    let title: String
    let subtitle: String
    let isPremium: Bool
    let cards: [ResultsCompletionCardModel]
    let primaryTitle: String
    let onPrimary: () -> Void
    let onOpenChat: () -> Void
    let onOpenCheckIn: () -> Void
    let onOpenStreakHub: () -> Void
    let streakDays: Int
    let checkedInToday: Bool
    let badgeCount: Int
    let onShare: () -> Void
    let onReturnHome: () -> Void

    var body: some View {
        ResultsSectionShell(
            pageIndex: pageIndex,
            totalPages: totalPages,
            title: title,
            subtitle: subtitle,
            badge: "Completion",
            shareActionTitle: "Share result",
            onShare: onShare
        ) {
            DashboardGlassCard(tone: .hero) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    ForEach(cards) { card in
                        ResultsCompletionCard(card: card)
                    }
                }
            }

            DashboardGlassCard(tone: .premium) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                    AIscendSectionHeader(
                        eyebrow: "Accountability",
                        title: checkedInToday ? "Today's check-in is protected" : "Start the daily accountability loop",
                        subtitle: checkedInToday
                            ? "Your streak stays intact. The consistency layer is already working in the background."
                            : "Lock in the day, protect the streak, and give the result a reason to keep mattering tomorrow."
                    )

                    HStack(spacing: AIscendTheme.Spacing.small) {
                        PlacementBadge(
                            title: "\(streakDays)d",
                            detail: "Current streak"
                        )
                        PlacementBadge(
                            title: "\(badgeCount)",
                            detail: "Badges unlocked"
                        )
                    }

                    Button(action: onOpenCheckIn) {
                        AIscendButtonLabel(
                            title: checkedInToday ? "Review Daily Check-In" : "Start Daily Check-In",
                            leadingSymbol: "calendar.badge.checkmark"
                        )
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .secondary))

                    Button(action: onOpenStreakHub) {
                        AIscendButtonLabel(title: "Open Consistency Hub", leadingSymbol: "flame.fill")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .ghost))
                }
            }

            Button(action: onPrimary) {
                AIscendButtonLabel(title: primaryTitle, leadingSymbol: isPremium ? "scope" : "crown.fill")
            }
            .buttonStyle(AIscendButtonStyle(variant: .primary))

            Button(action: onOpenChat) {
                AIscendButtonLabel(title: "Ask Advisor To Explain", leadingSymbol: "message.fill")
            }
            .buttonStyle(AIscendButtonStyle(variant: .secondary))

            Button(action: onReturnHome) {
                AIscendButtonLabel(title: isPremium ? "Back to Dashboard" : "Maybe Later", leadingSymbol: "house.fill")
            }
            .buttonStyle(AIscendButtonStyle(variant: .ghost))
        }
    }
}

private struct ResultsDotsBar: View {
    let totalPages: Int
    let currentPage: Int
    let onTap: (Int) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<totalPages, id: \.self) { index in
                Button {
                    onTap(index)
                } label: {
                    Capsule(style: .continuous)
                        .fill(
                            index == currentPage
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [
                                        AIscendTheme.Colors.accentGlow,
                                        AIscendTheme.Colors.accentPrimary
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            : AnyShapeStyle(AIscendTheme.Colors.surfaceHighlight.opacity(0.84))
                        )
                        .frame(width: index == currentPage ? 26 : 8, height: 8)
                        .shadow(
                            color: index == currentPage
                            ? AIscendTheme.Colors.accentPrimary.opacity(0.30)
                            : .clear,
                            radius: 10,
                            x: 0,
                            y: 0
                        )
                        .animation(.spring(response: 0.32, dampingFraction: 0.84), value: currentPage)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AIscendTheme.Spacing.large)
        .padding(.vertical, AIscendTheme.Spacing.medium)
        .background(
            Capsule(style: .continuous)
                .fill(Color(hex: "0C1017").opacity(0.82))
                .overlay(Capsule(style: .continuous).fill(.ultraThinMaterial).opacity(0.62))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.34), radius: 18, x: 0, y: 12)
    }
}

private struct ResultsSyncCapsule: View {
    let text: String
    let state: ScanAutoSaveState

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))

            Text(text)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
        }
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .background(
            Capsule(style: .continuous)
                .fill(Color(hex: "11151C").opacity(0.92))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private var symbol: String {
        switch state {
        case .syncing:
            "arrow.triangle.2.circlepath"
        case .saved:
            "checkmark.circle.fill"
        case .localOnly:
            "iphone"
        case .failed:
            "exclamationmark.triangle.fill"
        case .idle, .skipped:
            "lock.fill"
        }
    }

    private var borderColor: Color {
        switch state {
        case .failed:
            AIscendTheme.Colors.warning.opacity(0.38)
        case .saved:
            AIscendTheme.Colors.accentGlow.opacity(0.36)
        case .localOnly:
            AIscendTheme.Colors.borderStrong
        case .syncing, .idle, .skipped:
            AIscendTheme.Colors.borderSubtle
        }
    }
}

private struct ResultsPhotoStrip: View {
    let frontURL: URL?
    let sideURL: URL?

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            ResultsPhotoCard(
                title: "Front",
                url: frontURL,
                prominence: .primary
            )

            ResultsPhotoCard(
                title: "Profile",
                url: sideURL,
                prominence: .secondary
            )
        }
    }
}

private struct ResultsPhotoCard: View {
    enum Prominence {
        case primary
        case secondary
    }

    let title: String
    let url: URL?
    let prominence: Prominence

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: "12161D"))

            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        ResultsPhotoPlaceholder()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else {
                ResultsPhotoPlaceholder()
            }

            LinearGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.74)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                .padding(AIscendTheme.Spacing.medium)
        }
        .frame(maxWidth: .infinity)
        .frame(height: prominence == .primary ? 250 : 210)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
        )
    }
}

private struct ResultsPhotoPlaceholder: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(hex: "171C24"),
                Color(hex: "0F131A")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Circle()
                .fill(AIscendTheme.Colors.accentGlow.opacity(0.18))
                .frame(width: 120, height: 120)
                .blur(radius: 18)
        )
    }
}

private struct ResultsScoreOrb: View {
    let score: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 12)

            Circle()
                .trim(from: 0.08, to: CGFloat(0.08 + (min(max(score / 100, 0), 1) * 0.84)))
                .stroke(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.accentGlow,
                            AIscendTheme.Colors.accentPrimary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.30), radius: 20, x: 0, y: 0)

            VStack(spacing: 2) {
                Text(ScanJSONValue.formatted(number: score.rounded()))
                    .aiscendTextStyle(.metric)

                Text("AIScend")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
            }
        }
        .frame(width: 150, height: 150)
    }
}

private struct ResultsMetricPanel: View {
    let card: ResultsMetricCardModel

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: card.symbol, accent: card.accent, size: 42)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(card.value)
                    .aiscendTextStyle(.metricCompact)

                Text(card.title)
                    .aiscendTextStyle(.cardTitle)

                Text(card.detail)
                    .aiscendTextStyle(.secondaryBody)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.mediumLarge)
        .aiscendPanel(.standard)
    }
}

private struct ResultsPercentileRing: View {
    let percentile: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.03))

            Circle()
                .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)

            VStack(spacing: 4) {
                Text("#\(percentile)")
                    .aiscendTextStyle(.metricCompact)

                Text("Percentile")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }
        }
        .frame(width: 124, height: 124)
        .background(
            Circle()
                .fill(AIscendTheme.Colors.accentGlow.opacity(0.14))
                .blur(radius: 22)
        )
    }
}

private struct PlacementBadge: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
            Text(title)
                .aiscendTextStyle(.cardTitle)

            Text(detail)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
        }
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct HarmonyHighlightRow: View {
    let trait: ScanTraitRowModel

    var body: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: "sparkles", accent: .sky, size: 42)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                HStack {
                    Text(trait.label)
                        .aiscendTextStyle(.cardTitle)

                    Spacer()

                    Text(trait.value)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                }

                Text(trait.explanation)
                    .aiscendTextStyle(.body)
            }
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct ExpandableTraitRow: View {
    let trait: ScanTraitRowModel
    let onUpgrade: () -> Void

    @State private var isExpanded = false

    var body: some View {
        Button {
            if trait.locked {
                onUpgrade()
            } else {
                withAnimation(.easeInOut(duration: 0.22)) {
                    isExpanded.toggle()
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trait.label)
                            .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary.opacity(trait.locked ? 0.78 : 1))

                        Text(trait.value)
                            .aiscendTextStyle(.caption, color: trait.locked ? AIscendTheme.Colors.textMuted : AIscendTheme.Colors.accentGlow)
                    }

                    Spacer()

                    Image(systemName: trait.locked ? "lock.fill" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(trait.locked ? AIscendTheme.Colors.textMuted : AIscendTheme.Colors.textSecondary)
                        .rotationEffect(.degrees(trait.locked ? 0 : (isExpanded ? 180 : 0)))
                }

                if isExpanded || trait.locked {
                    Text(trait.explanation)
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(AIscendTheme.Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
            .fill(
                trait.locked
                ? Color(hex: "17131D").opacity(0.92)
                : AIscendTheme.Colors.surfaceHighlight.opacity(0.72)
            )
    }

    private var borderColor: Color {
        trait.locked
        ? AIscendTheme.Colors.accentGlow.opacity(0.24)
        : AIscendTheme.Colors.borderSubtle
    }
}

private struct PremiumBenefitRow: View {
    let text: String

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.accentGlow)

            Text(text)
                .aiscendTextStyle(.body)
        }
    }
}

private struct ResultsCompletionCard: View {
    let card: ResultsCompletionCardModel

    var body: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: card.symbol, accent: card.accent, size: 42)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(card.title)
                    .aiscendTextStyle(.cardTitle)

                Text(card.detail)
                    .aiscendTextStyle(.body)
            }
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct ResultsPrimaryButton: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AIscendButtonLabel(title: title, leadingSymbol: symbol)
        }
        .buttonStyle(AIscendButtonStyle(variant: .primary))
    }
}

private struct ScanResultsLoadingState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            AIscendBrandMark(size: 60)

            AIscendBadge(
                title: "Result reveal",
                symbol: "sparkles.rectangle.stack.fill",
                style: .accent
            )

            AIscendLoadingIndicator()

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                Text("Preparing the result sequence")
                    .aiscendTextStyle(.sectionTitle)

                Text("AIScend is validating the latest scan, checking archive state, and building the guided reveal.")
                    .aiscendTextStyle(.body)
            }
        }
        .frame(maxWidth: 460, alignment: .leading)
        .padding(AIscendTheme.Spacing.xLarge)
        .aiscendChatGlassCard(cornerRadius: 30, glowOpacity: 0.12)
        .padding(AIscendTheme.Spacing.screenInset)
    }
}

private struct ScanResultsEmptyState: View {
    let onOpenScan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            AIscendBadge(
                title: "No scan found",
                symbol: "viewfinder.circle.fill",
                style: .neutral
            )

            AIscendSectionHeader(
                title: "No scan result is ready right now",
                subtitle: "Run a fresh capture to open the full AIScend reveal flow and unlock the latest result sequence."
            )

            Button(action: onOpenScan) {
                AIscendButtonLabel(title: "Go To Scan", leadingSymbol: "camera.aperture")
            }
            .buttonStyle(AIscendButtonStyle(variant: .primary))
        }
        .frame(maxWidth: 460, alignment: .leading)
        .padding(AIscendTheme.Spacing.xLarge)
        .aiscendChatGlassCard(cornerRadius: 30, glowOpacity: 0.10)
        .padding(AIscendTheme.Spacing.screenInset)
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
