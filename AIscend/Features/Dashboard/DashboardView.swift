//
//  DashboardView.swift
//  AIscend
//
//  Created by Codex on 4/11/26.
//

import Foundation
import SwiftUI

struct DashboardView: View {
    @Bindable var model: AppModel
    @ObservedObject var dailyCheckInStore: DailyCheckInStore
    @ObservedObject var dailyPhotoStore: DailyPhotoStore
    @ObservedObject var badgeManager: BadgeManager
    var onOpenAdvisor: () -> Void = {}
    var onOpenRoutine: () -> Void = {}
    var onOpenCheckIn: () -> Void = {}
    var onOpenConsistency: () -> Void = {}
    var onOpenDailyPhoto: () -> Void = {}
    var onCaptureDailyPhoto: () -> Void = {}
    var onOpenAccount: () -> Void = {}
    var onRefine: () -> Void = {}

    @State private var hasAppeared = false
    @State private var showingPremium = false
    @StateObject private var shareCoordinator = ShareCoordinator()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM"
        return formatter
    }()

    private var snapshot: DashboardSnapshot {
        .live(from: model)
    }

    private var firstName: String {
        let trimmed = model.profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "Climber"
        }

        return trimmed.split(separator: " ").first.map(String.init) ?? trimmed
    }

    private var avatarInitials: String {
        let parts = model.profile.displayName
            .split(separator: " ")
            .map(String.init)

        if parts.count >= 2 {
            return String(parts.prefix(2).compactMap(\.first)).uppercased()
        }

        let fallback = String(model.profile.displayName.prefix(2)).uppercased()
        return fallback.isEmpty ? "AI" : fallback
    }

    private var scanCountLabel: String {
        let count = snapshot.scans.count
        return count == 1 ? "1 baseline" : "\(count) baselines"
    }

    private var liveStreakDays: Int {
        dailyCheckInStore.snapshot.currentStreak
    }

    private var checkedInToday: Bool {
        dailyCheckInStore.hasCheckedInToday
    }

    private var routinePreviewSteps: [RoutineStep] {
        let allSteps = model.routineSections.flatMap(\.steps)
        let openSteps = allSteps.filter { !$0.isComplete }
        let completedSteps = allSteps.filter(\.isComplete)
        return Array((openSteps + completedSteps).prefix(3))
    }

    private var nextOpenStep: RoutineStep? {
        model.nextOpenStep
    }

    private var todayLabel: String {
        Self.dateFormatter.string(from: .now)
    }

    private var dailySignalTitle: String {
        checkedInToday ? "Protected" : "Open"
    }

    private var dailySignalDetail: String {
        checkedInToday
            ? "Check-in logged. Keep the day clean and avoid unnecessary drift."
            : "The day is still open. Close it out before attention gets noisy."
    }

    private var nextMoveTitle: String {
        nextOpenStep?.title ?? "Routine complete"
    }

    private var nextMoveDetail: String {
        nextOpenStep?.detail ?? "Everything is checked off. Reopen the routine if you want to recalibrate."
    }

    private var focusAccent: RoutineAccent {
        switch model.profile.focusTrack {
        case .momentum:
            .dawn
        case .mastery:
            .sky
        case .balance:
            .mint
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AIscendBackdrop()
                DashboardAmbientLayer()

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                            DashboardWelcomeHeader(
                                greeting: "\(model.greeting), \(firstName)",
                                subtitle: snapshot.headerSubtitle,
                                dateLabel: todayLabel,
                                streakDays: liveStreakDays,
                                checkedInToday: checkedInToday,
                                initials: avatarInitials,
                                onOpenStreaks: onOpenConsistency,
                                onOpenAccount: onOpenAccount
                            )
                            .dashboardReveal(isVisible: hasAppeared, delay: 0.02)

                            DashboardCommandDeckCard(
                                snapshot: snapshot,
                                focusTitle: model.profile.focusTrack.title,
                                goalSummary: model.analysisGoalSummary,
                                nextMoveTitle: nextMoveTitle,
                                nextMoveDetail: nextMoveDetail,
                                progressLabel: model.progressLabel,
                                wakeLabel: model.profile.wakeLabel,
                                scanCountLabel: scanCountLabel,
                                onPrimary: onOpenAdvisor,
                                onSecondary: onOpenRoutine
                            )
                            .dashboardReveal(isVisible: hasAppeared, delay: 0.08)

                            DashboardActionDeck { action in
                                handle(action, proxy: proxy)
                            }
                            .dashboardReveal(isVisible: hasAppeared, delay: 0.14)

                            DashboardStatusStrip(
                                focusTitle: model.profile.focusTrack.title,
                                focusDetail: model.profile.anchorSummary,
                                nextMoveTitle: nextMoveTitle,
                                nextMoveDetail: nextMoveDetail,
                                signalTitle: dailySignalTitle,
                                signalDetail: dailySignalDetail,
                                signalMeta: "\(liveStreakDays)-day streak • wake by \(model.profile.wakeLabel)",
                                focusAccent: focusAccent,
                                signalAccent: checkedInToday ? .mint : .dawn
                            )
                            .dashboardReveal(isVisible: hasAppeared, delay: 0.20)

                            if geometry.size.width >= 760 {
                                HStack(alignment: .top, spacing: AIscendTheme.Spacing.large) {
                                    primaryRail
                                        .frame(maxWidth: .infinity, alignment: .topLeading)

                                    secondaryRail
                                        .frame(maxWidth: .infinity, alignment: .topLeading)
                                }
                            } else {
                                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                                    primaryRail
                                    secondaryRail
                                }
                            }
                        }
                        .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                        .padding(.top, AIscendTheme.Spacing.large)
                        .padding(.bottom, AIscendTheme.Spacing.xxLarge + AIscendTheme.Spacing.large)
                    }
                }
            }
        }
        .sheet(isPresented: $showingPremium) {
            DashboardPremiumUpsellSheet(
                premiumURL: AIscendChatConfiguration.live.premiumURL,
                onDismiss: { showingPremium = false }
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
        .preferredColorScheme(.dark)
        .onAppear {
            hasAppeared = true
        }
    }

    private var primaryRail: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            DashboardRailSection(
                eyebrow: "Signal Board",
                title: "Measured movement",
                subtitle: "A cleaner read on progress, leverage, and the pace of improvement."
            ) {
                DashboardProgressCard(snapshot: snapshot)
            }
            .id(DashboardSectionID.analytics)
            .dashboardReveal(isVisible: hasAppeared, delay: 0.26)

            DashboardRailSection(
                eyebrow: "Operating Layer",
                title: "Today's routine stack",
                subtitle: "Protect the small actions that keep the overall read compounding upward."
            ) {
                DashboardRoutineCard(
                    progress: model.progress,
                    streakDays: liveStreakDays,
                    checkedInToday: checkedInToday,
                    steps: routinePreviewSteps,
                    onToggle: toggle,
                    onShare: {
                        shareCoordinator.present(
                            .routineProgress(
                                progress: model.progress,
                                streakDays: liveStreakDays,
                                nextStep: model.nextOpenStep,
                                identityLine: AIScendSharePayload.identityLine(displayName: model.profile.displayName)
                            )
                        )
                    },
                    onOpenCheckIn: onOpenCheckIn,
                    onOpenConsistency: onOpenConsistency,
                    onOpenRoutine: onOpenRoutine
                )
            }
            .id(DashboardSectionID.routine)
            .dashboardReveal(isVisible: hasAppeared, delay: 0.32)
        }
    }

    private var secondaryRail: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            DashboardRailSection(
                eyebrow: "Priority Read",
                title: "Where the leverage sits",
                subtitle: "Short signal cards so the dashboard stays sharp instead of turning into a feed."
            ) {
                DashboardInsightsDeck(insights: snapshot.insights)
            }
            .id(DashboardSectionID.insights)
            .dashboardReveal(isVisible: hasAppeared, delay: 0.38)

            DashboardRailSection(
                eyebrow: "Local Archive",
                title: "Daily capture and baselines",
                subtitle: "A daily photo keeps the record honest, while recent baselines keep context close."
            ) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                    DashboardDailyPhotoCard(
                        store: dailyPhotoStore,
                        onOpenArchive: onOpenDailyPhoto,
                        onCapture: onCaptureDailyPhoto
                    )

                    DashboardScanArchiveCard(scans: snapshot.scans)
                }
            }
            .id(DashboardSectionID.scans)
            .dashboardReveal(isVisible: hasAppeared, delay: 0.44)

            DashboardRailSection(
                eyebrow: "Advanced Layer",
                title: "Deeper reports when you want them",
                subtitle: "Premium should feel like more resolution, not a louder app."
            ) {
                DashboardPremiumCard {
                    showingPremium = true
                }
            }
            .id(DashboardSectionID.premium)
            .dashboardReveal(isVisible: hasAppeared, delay: 0.50)
        }
    }

    private func handle(_ action: DashboardQuickAction, proxy: ScrollViewProxy) {
        switch action {
        case .advisor:
            onOpenAdvisor()
        case .progress:
            scroll(to: .analytics, proxy: proxy)
        case .routine:
            onOpenRoutine()
        case .insights:
            scroll(to: .insights, proxy: proxy)
        case .archive:
            scroll(to: .scans, proxy: proxy)
        case .refine:
            withAnimation(AIscendTheme.Motion.reveal) {
                onRefine()
            }
        }
    }

    private func scroll(to section: DashboardSectionID, proxy: ScrollViewProxy) {
        withAnimation(AIscendTheme.Motion.reveal) {
            proxy.scrollTo(section, anchor: .top)
        }
    }

    private func toggle(_ step: RoutineStep) {
        withAnimation(AIscendTheme.Motion.reveal) {
            model.toggleStep(step.id)
        }

        badgeManager.recordRoutineProgress(
            progress: model.progress,
            streak: dailyCheckInStore.snapshot.currentStreak
        )
    }
}

private struct DashboardWelcomeHeader: View {
    let greeting: String
    let subtitle: String
    let dateLabel: String
    let streakDays: Int
    let checkedInToday: Bool
    let initials: String
    let onOpenStreaks: () -> Void
    let onOpenAccount: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack(alignment: .center, spacing: AIscendTheme.Spacing.small) {
                AIscendBadge(
                    title: dateLabel,
                    symbol: "calendar",
                    style: .neutral
                )

                Spacer(minLength: AIscendTheme.Spacing.small)

                Button(action: onOpenStreaks) {
                    HStack(spacing: AIscendTheme.Spacing.xSmall) {
                        Image(systemName: checkedInToday ? "checkmark.seal.fill" : "flame.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AIscendTheme.Colors.accentGlow)

                        Text("\(streakDays)d")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                    }
                    .padding(.horizontal, AIscendTheme.Spacing.small)
                    .padding(.vertical, AIscendTheme.Spacing.xSmall)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.88))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                Button(action: onOpenAccount) {
                    Text(initials)
                        .font(.system(size: 13, weight: .bold, design: .default))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .frame(width: 42, height: 42)
                        .background(
                            Circle()
                                .fill(RoutineAccent.sky.gradient.opacity(0.25))
                        )
                        .overlay(
                            Circle()
                                .stroke(AIscendTheme.Colors.accentGlow.opacity(0.34), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open account")
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                Text(greeting)
                    .font(.system(size: 38, weight: .bold, design: .default))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .lineLimit(2)

                Text(subtitle)
                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct DashboardCommandDeckCard: View {
    let snapshot: DashboardSnapshot
    let focusTitle: String
    let goalSummary: String
    let nextMoveTitle: String
    let nextMoveDetail: String
    let progressLabel: String
    let wakeLabel: String
    let scanCountLabel: String
    let onPrimary: () -> Void
    let onSecondary: () -> Void

    var body: some View {
        DashboardGlassCard(tone: .hero) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: AIscendTheme.Spacing.xLarge) {
                    commandDeckCopy
                    Spacer(minLength: 0)
                    commandDeckStats
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
                    commandDeckCopy
                    commandDeckStats
                }
            }
        }
    }

    private var commandDeckCopy: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendBadge(
                title: "Command Deck",
                symbol: "sparkles",
                style: .accent
            )

            Text("The dashboard is now tuned for quick reads and clean action.")
                .aiscendTextStyle(.sectionTitle)

            Text(snapshot.heroStatement)
                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    DashboardInlinePill(title: focusTitle, symbol: "scope")
                    DashboardInlinePill(title: goalSummary, symbol: "sparkles")
                    DashboardInlinePill(title: scanCountLabel, symbol: "camera.aperture")
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                    DashboardInlinePill(title: focusTitle, symbol: "scope")
                    DashboardInlinePill(title: goalSummary, symbol: "sparkles")
                    DashboardInlinePill(title: scanCountLabel, symbol: "camera.aperture")
                }
            }

            DashboardInsetPanel {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                    Text("Next move")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                    Text(nextMoveTitle)
                        .aiscendTextStyle(.cardTitle)

                    Text(nextMoveDetail)
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                }
            }
            .padding(.top, AIscendTheme.Spacing.xSmall)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    Button(action: onPrimary) {
                        AIscendButtonLabel(title: "Continue Analysis", leadingSymbol: "waveform.path.ecg")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .primary))

                    Button(action: onSecondary) {
                        AIscendButtonLabel(title: "Open Routine", leadingSymbol: "square.grid.2x2.fill")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .secondary))
                }

                VStack(spacing: AIscendTheme.Spacing.small) {
                    Button(action: onPrimary) {
                        AIscendButtonLabel(title: "Continue Analysis", leadingSymbol: "waveform.path.ecg")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .primary))

                    Button(action: onSecondary) {
                        AIscendButtonLabel(title: "Open Routine", leadingSymbol: "square.grid.2x2.fill")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .secondary))
                }
            }
        }
    }

    private var commandDeckStats: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack {
                Spacer(minLength: 0)
                DashboardHeroOrb(score: snapshot.score, percentile: snapshot.percentile)
                Spacer(minLength: 0)
            }

            DashboardInsetPanel {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    DashboardMetricRow(
                        label: "Current score",
                        value: "\(snapshot.score) / 100",
                        detail: snapshot.tier
                    )

                    DashboardMetricRow(
                        label: "Routine adherence",
                        value: progressLabel,
                        detail: "Live completion"
                    )

                    DashboardMetricRow(
                        label: "Monthly shift",
                        value: dashboardSignedMetric(snapshot.delta),
                        detail: "Since last scan"
                    )

                    DashboardMetricRow(
                        label: "Wake anchor",
                        value: wakeLabel,
                        detail: "Protected start"
                    )
                }
            }
        }
        .frame(maxWidth: 290)
    }
}

private struct DashboardActionDeck: View {
    let onSelect: (DashboardQuickAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            HStack {
                Text("Quick jumps")
                    .aiscendTextStyle(.sectionTitle)

                Spacer(minLength: 0)

                Text("Tap once to move the board")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    ForEach(DashboardQuickAction.allCases) { action in
                        Button {
                            onSelect(action)
                        } label: {
                            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                                AIscendIconOrb(symbol: action.symbol, accent: action.accent, size: 42)

                                Text(action.title)
                                    .aiscendTextStyle(.cardTitle)

                                Text(action.detail)
                                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                            }
                            .frame(width: 148, alignment: .topLeading)
                            .frame(minHeight: 124, alignment: .topLeading)
                            .padding(AIscendTheme.Spacing.mediumLarge)
                        }
                        .buttonStyle(DashboardActionDeckButtonStyle())
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

private struct DashboardStatusStrip: View {
    let focusTitle: String
    let focusDetail: String
    let nextMoveTitle: String
    let nextMoveDetail: String
    let signalTitle: String
    let signalDetail: String
    let signalMeta: String
    let focusAccent: RoutineAccent
    let signalAccent: RoutineAccent

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AIscendTheme.Spacing.small) {
                DashboardPulseCard(
                    eyebrow: "Focus track",
                    title: focusTitle,
                    detail: focusDetail,
                    accent: focusAccent
                )

                DashboardPulseCard(
                    eyebrow: "Next move",
                    title: nextMoveTitle,
                    detail: nextMoveDetail,
                    accent: .sky
                )

                DashboardPulseCard(
                    eyebrow: "Daily signal",
                    title: signalTitle,
                    detail: signalDetail,
                    meta: signalMeta,
                    accent: signalAccent
                )
            }

            VStack(spacing: AIscendTheme.Spacing.small) {
                DashboardPulseCard(
                    eyebrow: "Focus track",
                    title: focusTitle,
                    detail: focusDetail,
                    accent: focusAccent
                )

                DashboardPulseCard(
                    eyebrow: "Next move",
                    title: nextMoveTitle,
                    detail: nextMoveDetail,
                    accent: .sky
                )

                DashboardPulseCard(
                    eyebrow: "Daily signal",
                    title: signalTitle,
                    detail: signalDetail,
                    meta: signalMeta,
                    accent: signalAccent
                )
            }
        }
    }
}

private struct DashboardPulseCard: View {
    let eyebrow: String
    let title: String
    let detail: String
    var meta: String? = nil
    let accent: RoutineAccent

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            HStack(spacing: AIscendTheme.Spacing.xSmall) {
                Circle()
                    .fill(accent.tint)
                    .frame(width: 8, height: 8)

                Text(eyebrow.uppercased())
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
            }

            Text(title)
                .aiscendTextStyle(.cardTitle)
                .lineLimit(2)

            Text(detail)
                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if let meta, !meta.isEmpty {
                Text(meta)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                    .padding(.top, AIscendTheme.Spacing.xxSmall)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 158, alignment: .topLeading)
        .padding(AIscendTheme.Spacing.mediumLarge)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.secondaryBackground.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(accent.tint.opacity(0.26), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 14, x: 0, y: 10)
    }
}

private struct DashboardRailSection<Content: View>: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    private let content: Content

    init(
        eyebrow: String,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            DashboardSectionHeading(
                eyebrow: eyebrow,
                title: title,
                subtitle: subtitle
            )

            content
        }
    }
}

private struct DashboardInsetPanel<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AIscendTheme.Spacing.mediumLarge)
            .background(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
            )
    }
}

private struct DashboardInlinePill: View {
    let title: String
    let symbol: String

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))

            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
        }
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, AIscendTheme.Spacing.xSmall)
        .background(
            Capsule(style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.86))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct DashboardMetricRow: View {
    let label: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                Spacer(minLength: AIscendTheme.Spacing.small)

                Text(value)
                    .aiscendTextStyle(.cardTitle)
            }

            Text(detail)
                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
        }
        .padding(.vertical, AIscendTheme.Spacing.xSmall)
    }
}

private struct DashboardActionDeckButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .fill(AIscendTheme.Colors.secondaryBackground.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 14, x: 0, y: 10)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.94 : 1)
            .animation(AIscendTheme.Motion.press, value: configuration.isPressed)
    }
}

private struct DashboardRevealModifier: ViewModifier {
    let isVisible: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 18)
            .animation(.easeOut(duration: 0.48).delay(delay), value: isVisible)
    }
}

private extension View {
    func dashboardReveal(isVisible: Bool, delay: Double) -> some View {
        modifier(DashboardRevealModifier(isVisible: isVisible, delay: delay))
    }
}

private func dashboardSignedMetric(_ value: Double) -> String {
    let sign = value >= 0 ? "+" : ""
    return "\(sign)\(String(format: "%.1f", value))"
}

#Preview {
    DashboardView(
        model: {
            let model = AppModel()
            model.profile.name = "Max Voss"
            model.profile.intention = "Sharpen lower-face structure, protect presentation quality, and keep the total read moving upward."
            model.profile.focusTrack = .mastery
            model.profile.anchors = [.movement, .planning, .reflection]
            model.analysisGoals = [.jawline, .skin, .symmetry]
            model.toggleStep("mission")
            model.toggleStep("deep-work")
            return model
        }(),
        dailyCheckInStore: DailyCheckInStore(),
        dailyPhotoStore: DailyPhotoStore(),
        badgeManager: BadgeManager()
    )
}
