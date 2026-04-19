//
//  RoutineDashboardView.swift
//  AIscend
//
//  Created by Codex on 4/7/26.
//

import Foundation
import Charts
import SwiftUI
import UIKit

struct RoutineDashboardView: View {
    @Bindable var model: AppModel
    let session: AuthSessionStore
    @ObservedObject var dailyCheckInStore: DailyCheckInStore
    @ObservedObject var dailyPhotoStore: DailyPhotoStore
    @ObservedObject var badgeManager: BadgeManager
    var onOpenAdvisor: () -> Void = {}
    var onOpenRoutine: () -> Void = {}
    var onOpenCheckIn: () -> Void = {}
    var onOpenConsistency: () -> Void = {}
    var onOpenDailyPhoto: () -> Void = {}
    var onCaptureDailyPhoto: () -> Void = {}
    var onOpenScan: () -> Void = {}
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
        let sourceName = (session.user?.displayName ?? model.profile.displayName)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmed = sourceName
        guard !trimmed.isEmpty else {
            return "Climber"
        }

        return trimmed.split(separator: " ").first.map(String.init) ?? trimmed
    }

    private var avatarInitials: String {
        if let sessionInitials = session.user?.initials, !sessionInitials.isEmpty {
            return sessionInitials
        }

        let parts = model.profile.displayName
            .split(separator: " ")
            .map(String.init)

        if parts.count >= 2 {
            return String(parts.prefix(2).compactMap(\.first)).uppercased()
        }

        let fallback = String(model.profile.displayName.prefix(2)).uppercased()
        return fallback.isEmpty ? "AI" : fallback
    }

    private var avatarRemoteURL: URL? {
        session.user?.photoURL
    }

    private var avatarLocalURL: URL? {
        model.profileAvatarURL
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

    private var isPremiumUnlocked: Bool {
        badgeManager.earnedBadges.contains(where: { $0.id == .premiumUnlocked })
    }

    var body: some View {
        ZStack {
            AIscendBackdrop()
            reportAmbientLayer

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    reportHeader
                    reportScoreRow
                    optimizationBanner
                    reportChartCard
                    cohortBanner
                    reportSummaryRow
                    dailyPhotosAccessWidget
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, AIscendTheme.Layout.floatingTabBarClearance)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var projectedScore: Int {
        min(snapshot.score + max(3, Int(snapshot.delta.rounded())), 99)
    }

    private var highlightedTrendPoint: DashboardTrendPoint {
        let midpoint = snapshot.trendPoints.count / 2
        return snapshot.trendPoints.indices.contains(midpoint)
            ? snapshot.trendPoints[midpoint]
            : (snapshot.trendPoints.last ?? DashboardTrendPoint(label: "Now", score: Double(snapshot.score)))
    }

    private var cohortHeadline: String {
        "Ahead of \(max(1, 100 - snapshot.percentile))% of current reads"
    }

    private var streakProgress: Double {
        min(max(Double(liveStreakDays) / 14, 0.08), 1)
    }

    private var featuredDailyPhotoEntry: DailyPhotoEntry? {
        dailyPhotoStore.todayEntry ?? dailyPhotoStore.recentEntries(limit: 1).first
    }

    private var dailyPhotoArchiveLabel: String {
        dailyPhotoStore.captureCount == 1 ? "1 day saved" : "\(dailyPhotoStore.captureCount) days saved"
    }

    private var dailyPhotoStatusLabel: String {
        dailyPhotoStore.hasPhotoToday ? "Captured" : "Open"
    }

    private var dailyPhotoHeadline: String {
        dailyPhotoStore.hasPhotoToday ? "Today's photo is already in." : "Today's photo is still waiting."
    }

    private var dailyPhotoDetail: String {
        if dailyPhotoStore.hasPhotoToday {
            return dailyPhotoStore.captureCount > 1
                ? "Retake it if you want a sharper frame, or open the archive to compare the run."
                : "Your first frame is saved. Keep the ritual moving or open the archive to review it."
        }

        return "Use the in-app camera to snap a clean frame now, then let the archive build itself day by day."
    }

    private var dailyPhotoPrimaryActionTitle: String {
        dailyPhotoStore.hasPhotoToday ? "Retake Today's Photo" : "Take Today's Photo"
    }

    private var dailyPhotoSecondaryActionTitle: String {
        dailyPhotoStore.captureCount > 0 ? "Open Daily Photos" : "View Archive"
    }

    private var reportAmbientLayer: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.accentPrimary.opacity(0.54),
                            AIscendTheme.Colors.accentDeep.opacity(0.24),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 420, height: 420)
                .blur(radius: 36)
                .offset(x: 120, y: -220)

            Circle()
                .fill(AIscendTheme.Colors.accentGlow.opacity(0.14))
                .frame(width: 280, height: 280)
                .blur(radius: 28)
                .offset(x: -150, y: -120)
        }
        .ignoresSafeArea()
    }

    private var reportHeader: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                AIscendBadge(
                    title: todayLabel,
                    symbol: "calendar",
                    style: .neutral
                )

                Text("Last report")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)

                Text("\(model.greeting), \(firstName)")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(AIscendTheme.Colors.textSecondary)

                Text(snapshot.headerSubtitle)
                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textMuted)
            }

            Spacer(minLength: AIscendTheme.Spacing.small)

            HStack(spacing: AIscendTheme.Spacing.small) {
                AIscendTopBarButton(symbol: "camera.aperture", highlighted: true, action: onOpenScan)

                Button(action: onOpenAccount) {
                    ProfileAvatarView(
                        localURL: avatarLocalURL,
                        remoteURL: avatarRemoteURL,
                        initials: avatarInitials,
                        size: 44
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open account")
            }
        }
    }

    private var reportScoreRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AIscendTheme.Spacing.small) {
                reportMetricCard(
                    title: "Current score",
                    value: "\(snapshot.score)",
                    detail: snapshot.tier,
                    highlighted: false
                )

                reportMetricCard(
                    title: "Predicted score",
                    value: "\(projectedScore)",
                    detail: "Next cycle",
                    highlighted: true
                )
            }

            VStack(spacing: AIscendTheme.Spacing.small) {
                reportMetricCard(
                    title: "Current score",
                    value: "\(snapshot.score)",
                    detail: snapshot.tier,
                    highlighted: false
                )

                reportMetricCard(
                    title: "Predicted score",
                    value: "\(projectedScore)",
                    detail: "Next cycle",
                    highlighted: true
                )
            }
        }
    }

    private var optimizationBanner: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Image(systemName: "arrow.up.right")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AIscendTheme.Colors.accentGlow)

            Text("Optimize up to +\(String(format: "%.1f", snapshot.delta)) pts")
                .font(.system(size: 21, weight: .semibold, design: .rounded))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)

            Spacer(minLength: 0)

            AIscendBadge(
                title: model.profile.focusTrack.title,
                symbol: model.profile.focusTrack.symbol,
                style: .accent
            )
        }
        .padding(.horizontal, AIscendTheme.Spacing.large)
        .padding(.vertical, AIscendTheme.Spacing.mediumLarge)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private var reportChartCard: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                    Text("Score / cycle")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                    Text(snapshot.heroStatement)
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: AIscendTheme.Spacing.small)

                Text("\(Int(highlightedTrendPoint.score))")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .padding(.horizontal, AIscendTheme.Spacing.small)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AIscendTheme.Colors.accentPrimary)
                    )
            }

            Chart {
                ForEach(snapshot.trendPoints) { point in
                    AreaMark(
                        x: .value("Period", point.label),
                        yStart: .value("Baseline", minTrendValue),
                        yEnd: .value("Score", point.score)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                AIscendTheme.Colors.accentPrimary.opacity(0.22),
                                AIscendTheme.Colors.accentGlow.opacity(0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Period", point.label),
                        y: .value("Score", point.score)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(AIscendTheme.Colors.accentGlow)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                }

                RuleMark(x: .value("Selected", highlightedTrendPoint.label))
                    .foregroundStyle(AIscendTheme.Colors.textMuted.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

                PointMark(
                    x: .value("Selected", highlightedTrendPoint.label),
                    y: .value("Score", highlightedTrendPoint.score)
                )
                .symbolSize(260)
                .foregroundStyle(AIscendTheme.Colors.accentGlow)

                PointMark(
                    x: .value("Selected", highlightedTrendPoint.label),
                    y: .value("Score", highlightedTrendPoint.score)
                )
                .symbolSize(90)
                .foregroundStyle(Color.white)
            }
            .chartLegend(.hidden)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: snapshot.trendPoints.map(\.label)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0))
                    AxisTick(stroke: StrokeStyle(lineWidth: 0))
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(AIscendTheme.Colors.textMuted)
                        }
                    }
                }
            }
            .chartYScale(domain: minTrendValue...(maxTrendValue + 4))
            .frame(height: 220)
        }
        .padding(AIscendTheme.Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "151515").opacity(0.98),
                            AIscendTheme.Colors.surfaceMuted.opacity(0.96)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.34), radius: 24, x: 0, y: 16)
    }

    private var cohortBanner: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Text(cohortHeadline)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)

            Spacer(minLength: 0)

            Image(systemName: "globe.americas.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.accentGlow)
        }
        .padding(.horizontal, AIscendTheme.Spacing.large)
        .padding(.vertical, AIscendTheme.Spacing.mediumLarge)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private var reportSummaryRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AIscendTheme.Spacing.small) {
                reportSummaryCard(
                    title: "Routine complete",
                    value: model.progressLabel,
                    detail: checkedInToday ? "Check-in protected" : nextMoveTitle,
                    progress: max(model.progress, 0.08)
                )

                reportSummaryCard(
                    title: "Streak live",
                    value: "\(liveStreakDays)d",
                    detail: checkedInToday ? "Momentum protected" : dailySignalTitle,
                    progress: streakProgress
                )
            }

            VStack(spacing: AIscendTheme.Spacing.small) {
                reportSummaryCard(
                    title: "Routine complete",
                    value: model.progressLabel,
                    detail: checkedInToday ? "Check-in protected" : nextMoveTitle,
                    progress: max(model.progress, 0.08)
                )

                reportSummaryCard(
                    title: "Streak live",
                    value: "\(liveStreakDays)d",
                    detail: checkedInToday ? "Momentum protected" : dailySignalTitle,
                    progress: streakProgress
                )
            }
        }
    }

    private var dailyPhotosAccessWidget: some View {
        DashboardGlassCard(tone: .hero) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        AIscendBadge(
                            title: dailyPhotoStore.hasPhotoToday ? "Today's photo captured" : "Today's photo open",
                            symbol: dailyPhotoStore.hasPhotoToday ? "checkmark.seal.fill" : "camera.aperture",
                            style: .accent
                        )

                        Text("Today's photo")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(AIscendTheme.Colors.textPrimary)

                        Text(dailyPhotoHeadline)
                            .aiscendTextStyle(.sectionTitle, color: AIscendTheme.Colors.textPrimary)

                        Text(dailyPhotoDetail)
                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                    }

                    Spacer(minLength: 0)

                    AIscendTopBarButton(symbol: "arrow.up.right", highlighted: true, action: onOpenDailyPhoto)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                        DailyPhotosWidgetPreviewCard(
                            store: dailyPhotoStore,
                            entry: featuredDailyPhotoEntry,
                            isTodayCaptured: dailyPhotoStore.hasPhotoToday
                        )

                        VStack(spacing: AIscendTheme.Spacing.small) {
                            DailyPhotosWidgetMetaPill(
                                title: "Archive",
                                value: dailyPhotoArchiveLabel,
                                symbol: "photo.stack.fill"
                            )
                            DailyPhotosWidgetMetaPill(
                                title: "Run",
                                value: "\(dailyPhotoStore.currentStreakDays())d",
                                symbol: "sparkles.rectangle.stack.fill"
                            )
                            DailyPhotosWidgetMetaPill(
                                title: "Status",
                                value: dailyPhotoStatusLabel,
                                symbol: dailyPhotoStore.hasPhotoToday ? "checkmark.circle.fill" : "sun.max.fill"
                            )
                        }
                        .frame(width: 220)
                    }

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        DailyPhotosWidgetPreviewCard(
                            store: dailyPhotoStore,
                            entry: featuredDailyPhotoEntry,
                            isTodayCaptured: dailyPhotoStore.hasPhotoToday
                        )

                        HStack(spacing: AIscendTheme.Spacing.small) {
                            DailyPhotosWidgetMetaPill(
                                title: "Archive",
                                value: dailyPhotoArchiveLabel,
                                symbol: "photo.stack.fill"
                            )
                            DailyPhotosWidgetMetaPill(
                                title: "Run",
                                value: "\(dailyPhotoStore.currentStreakDays())d",
                                symbol: "sparkles.rectangle.stack.fill"
                            )
                            DailyPhotosWidgetMetaPill(
                                title: "Status",
                                value: dailyPhotoStatusLabel,
                                symbol: dailyPhotoStore.hasPhotoToday ? "checkmark.circle.fill" : "sun.max.fill"
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        Button(action: onCaptureDailyPhoto) {
                            AIscendButtonLabel(
                                title: dailyPhotoPrimaryActionTitle,
                                leadingSymbol: dailyPhotoStore.hasPhotoToday ? "camera.fill" : "camera.aperture"
                            )
                        }
                        .buttonStyle(AIscendButtonStyle(variant: .primary))

                        Button(action: onOpenDailyPhoto) {
                            AIscendButtonLabel(
                                title: dailyPhotoSecondaryActionTitle,
                                leadingSymbol: "square.grid.2x2.fill"
                            )
                        }
                        .buttonStyle(AIscendButtonStyle(variant: .secondary))
                    }

                    VStack(spacing: AIscendTheme.Spacing.small) {
                        Button(action: onCaptureDailyPhoto) {
                            AIscendButtonLabel(
                                title: dailyPhotoPrimaryActionTitle,
                                leadingSymbol: dailyPhotoStore.hasPhotoToday ? "camera.fill" : "camera.aperture"
                            )
                        }
                        .buttonStyle(AIscendButtonStyle(variant: .primary))

                        Button(action: onOpenDailyPhoto) {
                            AIscendButtonLabel(
                                title: dailyPhotoSecondaryActionTitle,
                                leadingSymbol: "square.grid.2x2.fill"
                            )
                        }
                        .buttonStyle(AIscendButtonStyle(variant: .secondary))
                    }
                }
            }
        }
    }

    private var minTrendValue: Double {
        let values = snapshot.trendPoints.map(\.score)
        return max((values.min() ?? Double(snapshot.score)) - 4, 0)
    }

    private var maxTrendValue: Double {
        snapshot.trendPoints.map(\.score).max() ?? Double(snapshot.score)
    }

    private func reportMetricCard(title: String, value: String, detail: String, highlighted: Bool) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
            Text(title)
                .aiscendTextStyle(.caption, color: highlighted ? Color.white.opacity(0.78) : AIscendTheme.Colors.textMuted)

            Text(value)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(AIscendTheme.Colors.textPrimary)

            Text(detail)
                .aiscendTextStyle(.caption, color: highlighted ? Color.white.opacity(0.78) : AIscendTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    highlighted
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [
                                AIscendTheme.Colors.accentSoft,
                                AIscendTheme.Colors.accentPrimary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    : AnyShapeStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "161616").opacity(0.96),
                                AIscendTheme.Colors.surfaceMuted.opacity(0.94)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(highlighted ? Color.white.opacity(0.14) : AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private func reportSummaryCard(title: String, value: String, detail: String, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(AIscendTheme.Colors.textPrimary)

            Text(detail)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                .lineLimit(2)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.accentPrimary,
                                    AIscendTheme.Colors.accentGlow
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(20, geometry.size.width * progress))
                }
            }
            .frame(height: 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "151515").opacity(0.98),
                            AIscendTheme.Colors.surfaceMuted.opacity(0.96)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private var primaryRail: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
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
            .dashboardReveal(isVisible: hasAppeared, delay: 0.26)
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
                title: "Archive",
                subtitle: "Today’s photo and recent baselines in one place."
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

private struct DailyPhotosWidgetMetaPill: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            ZStack {
                Circle()
                    .fill(AIscendTheme.Colors.surfaceInteractive.opacity(0.86))
                    .frame(width: 34, height: 34)

                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AIscendTheme.Colors.accentGlow)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                Text(value)
                    .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.medium)
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

private struct DailyPhotosWidgetPreviewCard: View {
    @ObservedObject var store: DailyPhotoStore
    let entry: DailyPhotoEntry?
    let isTodayCaptured: Bool

    private var surfaceShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
    }

    private var previewLabel: String {
        if isTodayCaptured {
            return "Saved today"
        }

        return entry == nil ? "Camera ready" : "Latest saved"
    }

    private var title: String {
        guard let entry else {
            return "Take one clean frame"
        }

        if isTodayCaptured {
            return entry.createdAt.formatted(date: .omitted, time: .shortened)
        }

        if let date = DailyPhotoStore.date(from: entry.ymd) {
            return date.formatted(.dateTime.month(.abbreviated).day())
        }

        return entry.ymd
    }

    private var detail: String {
        if isTodayCaptured {
            return "Your photo is saved locally and ready for the archive."
        }

        if entry != nil {
            return "Your latest frame stays here until you capture today's."
        }

        return "Open the in-app camera and save one photo to start the timeline."
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            surfaceShape
                .fill(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.surfaceHighlight.opacity(0.96),
                            AIscendTheme.Colors.surfaceMuted.opacity(0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let entry,
               let url = store.imageURL(for: entry),
               let image = UIImage(contentsOfFile: url.path)
            {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    AIscendIconOrb(symbol: "camera.aperture", accent: .sky, size: 54)

                    Text("No photo yet")
                        .aiscendTextStyle(.cardTitle)

                    Text("The first capture turns this panel into your daily visual check-in.")
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                }
                .padding(AIscendTheme.Spacing.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            LinearGradient(
                colors: [
                    Color.clear,
                    AIscendTheme.Colors.overlayDark.opacity(0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(previewLabel.uppercased())
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                Text(title)
                    .aiscendTextStyle(.sectionTitle)

                Text(detail)
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                    .lineLimit(3)
            }
            .padding(AIscendTheme.Spacing.large)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 208)
        .clipShape(surfaceShape)
        .overlay(
            surfaceShape
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
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
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            HStack(alignment: .center, spacing: AIscendTheme.Spacing.small) {
                AIscendBadge(
                    title: dateLabel,
                    symbol: "calendar",
                    style: .neutral
                )

                Spacer(minLength: AIscendTheme.Spacing.small)

                Button(action: onOpenStreaks) {
                    AIscendStatChip(
                        title: checkedInToday ? "Streak protected" : "Live streak",
                        value: "\(streakDays)d",
                        symbol: checkedInToday ? "checkmark.seal.fill" : "flame.fill",
                        accent: checkedInToday ? .mint : .dawn
                    )
                }
                .buttonStyle(.plain)

                Button(action: onOpenAccount) {
                    ZStack {
                        Circle()
                            .fill(RoutineAccent.sky.gradient.opacity(0.20))

                        Text(initials)
                            .font(.system(size: 13, weight: .bold, design: .default))
                            .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    }
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(AIscendTheme.Colors.accentGlow.opacity(0.34), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open account")
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                Text("Today")
                    .aiscendTextStyle(.eyebrow, color: AIscendTheme.Colors.accentGlow)

                Text(greeting)
                    .font(.system(size: 40, weight: .bold, design: .default))
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
    let progressLabel: String
    let scanCountLabel: String
    let isPremiumUnlocked: Bool
    let onOpenAdvisor: () -> Void
    let onOpenRoutine: () -> Void
    let onOpenScan: () -> Void
    let onOpenHistory: () -> Void
    let onOpenUpgrade: () -> Void

    @State private var window: DashboardChartWindow = .month
    @State private var selectedIndex: Int?

    var body: some View {
        let chartState = DashboardScoreboardState(snapshot: snapshot, window: window)

        DashboardGlassCard(tone: .hero) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: AIscendTheme.Spacing.mediumLarge) {
                        heroIntro

                        Spacer(minLength: AIscendTheme.Spacing.medium)

                        dashboardWindowToggle
                    }

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                        heroIntro
                        dashboardWindowToggle
                    }
                }

                ViewThatFits(in: .horizontal) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        AIscendStatChip(
                            title: "Tier",
                            value: snapshot.tier,
                            symbol: "crown.fill",
                            accent: .sky
                        )
                        AIscendStatChip(
                            title: "Progress",
                            value: progressLabel,
                            symbol: "checkmark.seal.fill",
                            accent: .mint
                        )
                        AIscendStatChip(
                            title: "Archive",
                            value: scanCountLabel,
                            symbol: "camera.aperture",
                            accent: .dawn
                        )
                    }

                    HStack(spacing: AIscendTheme.Spacing.small) {
                        AIscendStatChip(
                            title: "Tier",
                            value: snapshot.tier,
                            symbol: "crown.fill",
                            accent: .sky
                        )
                        AIscendStatChip(
                            title: "Progress",
                            value: progressLabel,
                            symbol: "checkmark.seal.fill",
                            accent: .mint
                        )
                    }
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                    DashboardHeroMetricRow(state: chartState)

                    DashboardInsightBanner(
                        title: chartState.liftBannerText,
                        symbol: "arrow.up.right"
                    )

                    DashboardForecastChart(
                        state: chartState,
                        selection: chartState.selection(for: selectedIndex),
                        selectedIndex: $selectedIndex
                    )
                    .frame(height: 290)

                    DashboardChartComparisonBanner(
                        title: snapshot.percentile <= 50
                        ? "Tracking in the top \(snapshot.percentile)% of current reads"
                        : "Ahead of \(100 - snapshot.percentile)% of current reads",
                        subtitle: chartState.statusBannerText
                    )

                    DashboardCompactMetricRow(state: chartState)
                }
                .padding(AIscendTheme.Spacing.large)
                .background(
                    RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                        .fill(Color.black.opacity(0.24))
                        .overlay(
                            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.04),
                                            AIscendTheme.Colors.accentPrimary.opacity(0.10),
                                            Color.clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                        .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                )

                DashboardScoreCTA(
                    isPremiumUnlocked: isPremiumUnlocked,
                    onOpenAdvisor: onOpenAdvisor,
                    onOpenRoutine: onOpenRoutine,
                    onOpenScan: onOpenScan,
                    onOpenHistory: onOpenHistory,
                    onOpenUpgrade: onOpenUpgrade
                )
            }
        }
    }

    private var heroIntro: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
            AIscendBadge(
                title: "Today's next best move",
                symbol: "sparkles",
                style: .accent
            )

            Text(snapshot.heroStatement)
                .aiscendTextStyle(.screenTitle, color: AIscendTheme.Colors.textPrimary)

            Text("\(scanCountLabel) on file • \(progressLabel) routine complete")
                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
        }
    }

    private var dashboardWindowToggle: some View {
        DashboardSegmentedToggle(
            value: window,
            options: DashboardChartWindow.allCases
        ) { mode in
            window = mode
            selectedIndex = nil
        }
    }
}

private enum DashboardChartWindow: String, CaseIterable, Identifiable {
    case month
    case year

    var id: String { rawValue }

    var title: String {
        switch self {
        case .month:
            "Month"
        case .year:
            "Year"
        }
    }
}

private struct DashboardScoreEntry: Identifiable {
    let id = UUID()
    let index: Int
    let label: String
    let shortLabel: String
    let actual: Double?
    let predicted: Double?

    var displayedValue: Double? {
        actual ?? predicted
    }
}

private struct DashboardSelection {
    let label: String
    let value: Double
    let isForecast: Bool
}

private struct DashboardScoreboardState {
    let window: DashboardChartWindow
    let entries: [DashboardScoreEntry]
    let currentScore: Double
    let targetScore: Double
    let bestScore: Double
    let delta: Double

    init(snapshot: DashboardSnapshot, window: DashboardChartWindow, now: Date = .now) {
        self.window = window
        self.currentScore = Double(snapshot.score)
        self.targetScore = dashboardTargetScore(from: Double(snapshot.score))
        self.bestScore = snapshot.trendPoints.map(\.score).max() ?? Double(snapshot.score)
        self.delta = snapshot.delta
        self.entries = DashboardScoreboardState.buildEntries(snapshot: snapshot, window: window, now: now)
    }

    var yDomain: ClosedRange<Double> {
        dashboardYDomain(for: entries)
    }

    var yTicks: [Double] {
        dashboardNiceTicks(for: yDomain, desired: 4)
    }

    var forecastValue: Double {
        entries.last(where: { $0.predicted != nil })?.predicted ?? targetScore
    }

    var upside: Double {
        max(0, forecastValue - currentScore)
    }

    var forecastTitle: String {
        window == .year ? "EOY forecast" : "Projected score"
    }

    var forecastSubtitle: String {
        window == .year ? "Based on current pace" : "Short-range trend"
    }

    var latestActualLabel: String {
        lastActualEntry?.label ?? "Latest read"
    }

    var liftBannerText: String {
        if upside >= 0.1 {
            return "Projected lift \(upside.formattedScore) points over this \(window.title.lowercased())"
        }

        return "Holding close to your current level through this \(window.title.lowercased())"
    }

    var statusBannerText: String {
        if delta >= 0 {
            return "Momentum is up \(dashboardSignedMetric(delta)) across the last 30 days"
        }

        return "Last 30 days softened by \(abs(delta).formattedScore); forecast still trends upward"
    }

    var fallbackSelection: DashboardSelection? {
        if let lastActual = entries.last(where: { $0.actual != nil }), let value = lastActual.actual {
            return DashboardSelection(label: lastActual.label, value: value, isForecast: false)
        }

        guard let last = entries.last, let value = last.displayedValue else {
            return nil
        }

        return DashboardSelection(label: last.label, value: value, isForecast: last.actual == nil)
    }

    func selection(for selectedIndex: Int?) -> DashboardSelection? {
        guard let selectedIndex,
              let match = entries.first(where: { $0.index == selectedIndex }),
              let value = match.displayedValue else {
            return fallbackSelection
        }

        return DashboardSelection(label: match.label, value: value, isForecast: match.actual == nil)
    }

    var xAxisLabelIndices: [Int] {
        guard !entries.isEmpty else {
            return []
        }

        let strideSize: Int
        switch window {
        case .month:
            strideSize = 2
        case .year:
            strideSize = max(2, Int(ceil(Double(entries.count) / 5)))
        }

        return entries.enumerated().compactMap { offset, entry in
            let isEdge = offset == 0 || offset == entries.count - 1
            return isEdge || offset.isMultiple(of: strideSize) ? entry.index : nil
        }
    }

    var emphasizedYTicks: [Double] {
        guard let first = yTicks.first, let last = yTicks.last else {
            return []
        }

        if yTicks.count <= 3 {
            return yTicks
        }

        let middle = yTicks[yTicks.count / 2]
        return [first, middle, last]
    }

    var lastActualEntry: DashboardScoreEntry? {
        entries.last(where: { $0.actual != nil })
    }

    private static func buildEntries(snapshot: DashboardSnapshot, window: DashboardChartWindow, now: Date) -> [DashboardScoreEntry] {
        switch window {
        case .month:
            return buildMonthEntries(snapshot: snapshot, now: now)
        case .year:
            return buildYearEntries(snapshot: snapshot, now: now)
        }
    }

    private static func buildMonthEntries(snapshot: DashboardSnapshot, now: Date) -> [DashboardScoreEntry] {
        let calendar = Calendar.current
        let actualScores = Array(snapshot.trendPoints.map(\.score).suffix(5))
        let actualCount = max(actualScores.count, 3)
        let predictedCount = 3
        let startDate = calendar.date(byAdding: .day, value: -7 * max(actualCount - 1, 0), to: now) ?? now

        let normalizedActuals = actualScores.isEmpty
        ? Array(repeating: Double(snapshot.score), count: actualCount)
        : padActuals(actualScores, to: actualCount)

        let target = dashboardTargetScore(from: Double(snapshot.score))
        let future = dashboardPlannedSequence(from: normalizedActuals.last ?? Double(snapshot.score), to: target, steps: predictedCount)

        let labelFormatter = DateFormatter()
        labelFormatter.dateFormat = "MMM d"
        let shortFormatter = DateFormatter()
        shortFormatter.dateFormat = "d"

        return (0..<(actualCount + predictedCount)).map { index in
            let date = calendar.date(byAdding: .day, value: 7 * index, to: startDate) ?? now
            let actual = index < actualCount ? normalizedActuals[index] : nil
            let predicted: Double?

            if index < actualCount - 1 {
                predicted = nil
            } else if index == actualCount - 1 {
                predicted = dashboardApplyUplift(
                    normalizedActuals.last ?? Double(snapshot.score),
                    lastActual: normalizedActuals.last ?? Double(snapshot.score),
                    target: target
                )
            } else {
                predicted = dashboardApplyUplift(
                    future[index - actualCount],
                    lastActual: normalizedActuals.last ?? Double(snapshot.score),
                    target: target
                )
            }

            return DashboardScoreEntry(
                index: index,
                label: labelFormatter.string(from: date),
                shortLabel: shortFormatter.string(from: date),
                actual: actual,
                predicted: predicted
            )
        }
    }

    private static func buildYearEntries(snapshot: DashboardSnapshot, now: Date) -> [DashboardScoreEntry] {
        let calendar = Calendar.current
        let actualScores = snapshot.trendPoints.map(\.score)
        let actualCount = max(actualScores.count, 4)
        let normalizedActuals = actualScores.isEmpty
        ? Array(repeating: Double(snapshot.score), count: actualCount)
        : padActuals(actualScores, to: actualCount)

        let startMonth = calendar.date(byAdding: .month, value: -(actualCount - 1), to: now) ?? now
        let currentMonthIndex = calendar.component(.month, from: now)
        let futureCount = max(0, 12 - currentMonthIndex)
        let target = dashboardTargetScore(from: Double(snapshot.score))
        let future = dashboardPlannedSequence(from: normalizedActuals.last ?? Double(snapshot.score), to: target, steps: futureCount)

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        return (0..<(actualCount + futureCount)).map { index in
            let date = calendar.date(byAdding: .month, value: index, to: startMonth) ?? now
            let actual = index < actualCount ? normalizedActuals[index] : nil
            let predicted: Double?

            if index < actualCount - 1 {
                predicted = nil
            } else if index == actualCount - 1 {
                predicted = dashboardApplyUplift(
                    normalizedActuals.last ?? Double(snapshot.score),
                    lastActual: normalizedActuals.last ?? Double(snapshot.score),
                    target: target
                )
            } else {
                predicted = dashboardApplyUplift(
                    future[index - actualCount],
                    lastActual: normalizedActuals.last ?? Double(snapshot.score),
                    target: target
                )
            }

            let label = formatter.string(from: date)
            return DashboardScoreEntry(
                index: index,
                label: label,
                shortLabel: label,
                actual: actual,
                predicted: predicted
            )
        }
    }

    private static func padActuals(_ values: [Double], to count: Int) -> [Double] {
        guard let first = values.first else {
            return Array(repeating: 70, count: count)
        }

        if values.count >= count {
            return Array(values.suffix(count))
        }

        return Array(repeating: first, count: count - values.count) + values
    }

    func closestIndex(to value: Int) -> Int? {
        entries.min(by: { abs($0.index - value) < abs($1.index - value) })?.index
    }
}

private struct DashboardSegmentedToggle: View {
    let value: DashboardChartWindow
    let options: [DashboardChartWindow]
    let onChange: (DashboardChartWindow) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options) { option in
                Button {
                    onChange(option)
                } label: {
                    Text(option.title)
                        .aiscendTextStyle(.caption, color: value == option ? .white : AIscendTheme.Colors.textSecondary)
                        .frame(minWidth: 66)
                        .padding(.vertical, 10)
                        .padding(.horizontal, AIscendTheme.Spacing.small)
                        .background(
                            Capsule(style: .continuous)
                                .fill(value == option ? AIscendTheme.Colors.accentPrimary : .clear)
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(
                                    value == option ? AIscendTheme.Colors.accentGlow.opacity(0.55) : Color.clear,
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.24))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct DashboardHeroMetricRow: View {
    let state: DashboardScoreboardState

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            DashboardHeroMetricCard(
                title: "Current score",
                value: state.currentScore.formattedScore,
                subtitle: state.latestActualLabel,
                style: .neutral
            )

            DashboardHeroMetricCard(
                title: state.forecastTitle,
                value: state.forecastValue.formattedScore,
                subtitle: state.forecastSubtitle,
                style: .accent
            )
        }
    }
}

private struct DashboardInsightBanner: View {
    let title: String
    let symbol: String

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.accentGlow)

            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(Color.black.opacity(0.34))
                .overlay(
                    RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.04),
                                    AIscendTheme.Colors.accentPrimary.opacity(0.16),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderStrong.opacity(0.48), lineWidth: 1)
        )
    }
}

private struct DashboardCompactMetricRow: View {
    let state: DashboardScoreboardState

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            DashboardCompactMetricCard(
                title: "Best score",
                value: state.bestScore.formattedScore,
                fillFraction: CGFloat(max(0.18, min(state.bestScore / 100, 1))),
                accent: AIscendTheme.Colors.accentGlow
            )

            DashboardCompactMetricCard(
                title: "30-day change",
                value: dashboardSignedMetric(state.delta),
                fillFraction: CGFloat(max(0.18, min(abs(state.delta) / 4.0, 1))),
                accent: state.delta >= 0 ? AIscendTheme.Colors.accentPrimary : AIscendTheme.Colors.textMuted
            )
        }
    }
}

private enum DashboardHeroMetricCardStyle {
    case neutral
    case accent
}

private struct DashboardHeroMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let style: DashboardHeroMetricCardStyle

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(style == .accent ? Color.white.opacity(0.82) : AIscendTheme.Colors.textSecondary)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(style == .accent ? Color.white.opacity(0.74) : AIscendTheme.Colors.textMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .padding(AIscendTheme.Spacing.medium)
        .background(background)
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(style == .accent ? Color.white.opacity(0.10) : AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)

        switch style {
        case .neutral:
            shape
                .fill(Color.black.opacity(0.34))
                .overlay(
                    shape.fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.04),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
        case .accent:
            shape
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "A855F7"),
                            AIscendTheme.Colors.accentSoft,
                            AIscendTheme.Colors.accentPrimary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    shape.fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
        }
    }
}

private struct DashboardCompactMetricCard: View {
    let title: String
    let value: String
    let fillFraction: CGFloat
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AIscendTheme.Colors.textSecondary)

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(AIscendTheme.Colors.textPrimary)

            GeometryReader { proxy in
                let width = max(18, proxy.size.width * min(max(fillFraction, 0), 1))

                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.08))

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    accent,
                                    accent.opacity(0.55)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: width)
                }
            }
            .frame(height: 8)
        }
        .frame(maxWidth: .infinity, minHeight: 124, alignment: .leading)
        .padding(AIscendTheme.Spacing.mediumLarge)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(Color.black.opacity(0.30))
                .overlay(
                    RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.03),
                                    accent.opacity(0.10),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct DashboardChartComparisonBanner: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .center, spacing: AIscendTheme.Spacing.small) {
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.accentGlow)
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(0.06), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AIscendTheme.Colors.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(Color.black.opacity(0.34))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct DashboardChartPlotSurface: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: "0B0A10"))

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.025),
                            AIscendTheme.Colors.accentPrimary.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { index in
                    if index != 0 {
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 1)
                    }

                    if index < 3 {
                        Spacer()
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 10)
        }
    }
}

private struct DashboardChartFocusOverlay: View {
    let point: CGPoint
    let plotFrame: CGRect
    let value: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.accentGlow.opacity(0.02),
                            AIscendTheme.Colors.accentGlow.opacity(0.22),
                            AIscendTheme.Colors.accentGlow.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2, height: plotFrame.height - 8)
                .offset(x: point.x - 1, y: plotFrame.minY + 4)

            Circle()
                .fill(AIscendTheme.Colors.accentGlow.opacity(0.30))
                .frame(width: 90, height: 90)
                .blur(radius: 18)
                .position(x: point.x, y: point.y)

            Circle()
                .fill(Color(hex: "A855F7"))
                .frame(width: 18, height: 18)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                )
                .position(x: point.x, y: point.y)

            Circle()
                .fill(.white)
                .frame(width: 8, height: 8)
                .position(x: point.x, y: point.y)

            DashboardChartValuePill(value: value)
                .position(
                    x: min(max(point.x, plotFrame.minX + 48), plotFrame.maxX - 48),
                    y: max(plotFrame.minY + 16, point.y - 34)
                )
        }
        .allowsHitTesting(false)
    }
}

private struct DashboardForecastChart: View {
    let state: DashboardScoreboardState
    let selection: DashboardSelection?
    @Binding var selectedIndex: Int?

    var body: some View {
        let highlightedEntry = resolvedHighlightedEntry
        let highlightedSelection = selection ?? state.fallbackSelection

        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Score / Time")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)

                    if let highlightedSelection {
                        Text(highlightedSelection.isForecast ? "Projected for \(highlightedSelection.label)" : "Logged on \(highlightedSelection.label)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(AIscendTheme.Colors.textSecondary)
                    }
                }

                Spacer(minLength: AIscendTheme.Spacing.small)

                Text(state.window.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.82))
                    .padding(.horizontal, AIscendTheme.Spacing.small)
                    .padding(.vertical, 7)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
            }
            .padding(.horizontal, AIscendTheme.Spacing.mediumLarge)
            .padding(.top, AIscendTheme.Spacing.mediumLarge)

            Chart {
                if let highlightedEntry {
                    RuleMark(x: .value("Selection", highlightedEntry.index))
                        .foregroundStyle(AIscendTheme.Colors.accentGlow.opacity(selectedIndex == nil ? 0.10 : 0.18))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 6]))
                }

                ForEach(state.entries) { entry in
                    if let actual = entry.actual {
                        LineMark(
                            x: .value("Index", entry.index),
                            y: .value("Score", actual)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(AIscendTheme.Colors.accentPrimary.opacity(0.22))
                        .lineStyle(StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))

                        LineMark(
                            x: .value("Index", entry.index),
                            y: .value("Score", actual)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.accentGlow,
                                    AIscendTheme.Colors.accentSoft,
                                    Color(hex: "7C3AED")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineStyle(StrokeStyle(lineWidth: 3.4, lineCap: .round, lineJoin: .round))
                    }

                    if let predicted = entry.predicted {
                        LineMark(
                            x: .value("Index", entry.index),
                            y: .value("Score", predicted)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(AIscendTheme.Colors.accentGlow.opacity(0.52))
                        .lineStyle(StrokeStyle(lineWidth: 2.3, lineCap: .round, lineJoin: .round, dash: [6, 6]))
                    }
                }
            }
            .chartLegend(.hidden)
            .chartYScale(domain: state.yDomain)
            .chartPlotStyle { plotArea in
                plotArea
                    .background {
                        DashboardChartPlotSurface()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .chartXAxis {
                AxisMarks(values: state.xAxisLabelIndices) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0))
                    AxisTick(stroke: StrokeStyle(lineWidth: 0))

                    AxisValueLabel {
                        if let index = value.as(Int.self),
                           let entry = state.entries.first(where: { $0.index == index }) {
                            Text(entry.shortLabel)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(AIscendTheme.Colors.textMuted)
                        }
                    }
                }
            }
            .chartYAxis(.hidden)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    let plotFrame = proxy.plotFrame.map { geometry[$0] }

                    ZStack(alignment: .topLeading) {
                        if let plotFrame,
                           let highlightedEntry,
                           let highlightedValue = highlightedEntry.displayedValue,
                           let point = chartPoint(
                            for: highlightedEntry,
                            value: highlightedValue,
                            proxy: proxy,
                            plotFrame: plotFrame
                           ) {
                            DashboardChartFocusOverlay(
                                point: point,
                                plotFrame: plotFrame,
                                value: highlightedValue.formattedScore
                            )
                        }

                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        guard let plotFrame else {
                                            return
                                        }

                                        let xPosition = value.location.x - plotFrame.origin.x
                                        guard xPosition >= 0, xPosition <= plotFrame.size.width else {
                                            return
                                        }

                                        guard let index = proxy.value(atX: xPosition, as: Int.self) else {
                                            return
                                        }

                                        selectedIndex = state.closestIndex(to: index)
                                    }
                                    .onEnded { _ in
                                        selectedIndex = nil
                                    }
                            )
                    }
                }
            }
            .padding(.horizontal, AIscendTheme.Spacing.medium)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Text(selectedIndex == nil ? "Hold anywhere on the graph to inspect the latest movement." : "Release to return to the current read.")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
            .padding(.horizontal, AIscendTheme.Spacing.mediumLarge)
            .padding(.bottom, AIscendTheme.Spacing.mediumLarge)
        }
        .background(chartBackground)
        .clipShape(RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                .stroke(AIscendTheme.Colors.borderStrong.opacity(0.6), lineWidth: 1)
        )
    }

    private var resolvedHighlightedEntry: DashboardScoreEntry? {
        if let selectedIndex,
           let selectedEntry = state.entries.first(where: { $0.index == selectedIndex }) {
            return selectedEntry
        }

        return state.lastActualEntry ?? state.entries.last
    }

    private func chartPoint(
        for entry: DashboardScoreEntry,
        value: Double,
        proxy: ChartProxy,
        plotFrame: CGRect
    ) -> CGPoint? {
        guard let xPosition = proxy.position(forX: entry.index),
              let yPosition = proxy.position(forY: value) else {
            return nil
        }

        return CGPoint(
            x: plotFrame.origin.x + xPosition,
            y: plotFrame.origin.y + yPosition
        )
    }

    private var chartBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                .fill(Color(hex: "09090D"))

            RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.04),
                            Color(hex: "201136").opacity(0.94),
                            Color(hex: "09090D")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(AIscendTheme.Colors.accentGlow.opacity(0.18))
                .frame(width: 240, height: 240)
                .blur(radius: 44)
                .offset(x: 120, y: -118)

            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 140, height: 140)
                .blur(radius: 40)
                .offset(x: 28, y: -74)
        }
    }
}

private struct DashboardChartValuePill: View {
    let value: String

    var body: some View {
        Text(value)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(AIscendTheme.Colors.accentPrimary)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
    }
}

private struct DashboardLegendDot: View {
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
        }
    }
}

private struct DashboardScoreCTA: View {
    let isPremiumUnlocked: Bool
    let onOpenAdvisor: () -> Void
    let onOpenRoutine: () -> Void
    let onOpenScan: () -> Void
    let onOpenHistory: () -> Void
    let onOpenUpgrade: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
                Image(systemName: isPremiumUnlocked ? "crown.fill" : "sparkles")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                    Text(isPremiumUnlocked ? "PREMIUM ACTIVE" : "LEVEL UP")
                        .aiscendTextStyle(.caption, color: Color.white.opacity(0.88))

                    Text(isPremiumUnlocked ? "Deeper reports are unlocked" : "Unlock advanced insights with Premium")
                        .font(.system(size: 17, weight: .bold, design: .default))
                        .foregroundStyle(.white)

                    Text(
                        isPremiumUnlocked
                        ? "Use the advisor and archive together to turn the trend into sharper decisions."
                        : "Forecasting, deeper trait reads, and stronger archive access sit behind the premium layer."
                    )
                    .aiscendTextStyle(.secondaryBody, color: Color.white.opacity(0.86))
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    primaryButton
                    secondaryButton
                }

                VStack(spacing: AIscendTheme.Spacing.small) {
                    primaryButton
                    secondaryButton
                }
            }
        }
        .padding(AIscendTheme.Spacing.large)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }

    private var primaryButton: some View {
        Button(action: isPremiumUnlocked ? onOpenAdvisor : onOpenUpgrade) {
            AIscendButtonLabel(
                title: isPremiumUnlocked ? "Continue Analysis" : "Unlock Premium",
                leadingSymbol: isPremiumUnlocked ? "waveform.path.ecg" : "crown.fill"
            )
        }
        .buttonStyle(AIscendButtonStyle(variant: .primary))
    }

    private var secondaryButton: some View {
        Button(action: isPremiumUnlocked ? onOpenHistory : onOpenScan) {
            AIscendButtonLabel(
                title: isPremiumUnlocked ? "View Archive" : "Open Scan Studio",
                leadingSymbol: isPremiumUnlocked ? "clock.arrow.circlepath" : "camera.fill"
            )
        }
        .buttonStyle(AIscendButtonStyle(variant: .secondary))
    }

    private var background: some ShapeStyle {
        LinearGradient(
            colors: isPremiumUnlocked
            ? [Color(hex: "6D28D9").opacity(0.82), Color(hex: "A21CAF").opacity(0.72), Color(hex: "BE185D").opacity(0.68)]
            : [Color(hex: "4338CA").opacity(0.82), Color(hex: "7C3AED").opacity(0.72), Color(hex: "C026D3").opacity(0.68)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

private struct DashboardActionDeck: View {
    let onSelect: (DashboardQuickAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack {
                Text("Navigation")
                    .aiscendTextStyle(.sectionTitle)

                Spacer(minLength: 0)

                Text("Jump straight to the area you want")
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
                            .frame(minHeight: 132, alignment: .topLeading)
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
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                        .fill(Color.white.opacity(0.025))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(accent.tint.opacity(0.24), lineWidth: 1)
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isVisible: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible || reduceMotion ? 0 : 18)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.48).delay(delay), value: isVisible)
    }
}

private extension View {
    func dashboardReveal(isVisible: Bool, delay: Double) -> some View {
        modifier(DashboardRevealModifier(isVisible: isVisible, delay: delay))
    }
}

private extension Double {
    var formattedScore: String {
        String(format: "%.1f", self)
    }
}

private func dashboardTargetScore(from lastScore: Double) -> Double {
    let scaled = 85 + (lastScore - 50) * 0.25
    return min(92, max(85, scaled))
}

private func dashboardPlannedSequence(
    from start: Double,
    to target: Double,
    steps: Int,
    closeFraction: Double = 0.9,
    alpha: Double = 0.6,
    exponent: Double = 1.6
) -> [Double] {
    guard steps > 0 else {
        return []
    }

    let finalTarget = max(target, start + 0.1)
    let stepCount = max(1, steps)
    let kBase = -log(max(0.000001, 1 - closeFraction))
    let k = kBase / max(0.000001, Double(stepCount) * alpha)

    return (1...steps).map { step in
        let progress = Double(step) / Double(stepCount)
        let easedProgress = 1 - pow(1 - progress, exponent)
        return finalTarget - (finalTarget - start) * exp(-k * easedProgress)
    }
}

private func dashboardApplyUplift(_ value: Double, lastActual: Double, target: Double) -> Double {
    let uplift = max(0.75, 0.1 * (target - lastActual))
    return min(95, value + uplift)
}

private func dashboardYDomain(for entries: [DashboardScoreEntry]) -> ClosedRange<Double> {
    let values = entries.flatMap { entry in
        [entry.actual, entry.predicted].compactMap { $0 }
    }

    guard let minimum = values.min(), let maximum = values.max() else {
        return 0...100
    }

    let padding = max(0.8, (maximum - minimum) * 0.12)
    let lowerBound = max(0, minimum - padding)
    let upperBound = min(100, maximum + padding)

    if upperBound - lowerBound < 3 {
        return max(0, lowerBound - 1.5)...min(100, upperBound + 1.5)
    }

    return lowerBound...upperBound
}

private func dashboardNiceTicks(for domain: ClosedRange<Double>, desired: Int = 4) -> [Double] {
    let lowerBound = domain.lowerBound
    let upperBound = domain.upperBound
    let span = max(0.0001, upperBound - lowerBound)
    let roughStep = span / Double(max(1, desired - 1))
    let power = pow(10.0, floor(log10(roughStep)))
    let candidates = [1.0, 2.0, 2.5, 5.0, 10.0].map { $0 * power }
    let step = candidates.min(by: { abs($0 - roughStep) < abs($1 - roughStep) }) ?? roughStep
    let start = ceil(lowerBound / step) * step
    let end = floor(upperBound / step) * step

    var ticks: [Double] = []
    var value = start
    while value <= end + 0.000001 {
        ticks.append((value * 100).rounded() / 100)
        value += step
    }

    if ticks.count >= 2 {
        return ticks
    }

    let roundedLower = lowerBound.rounded()
    let roundedUpper = upperBound.rounded()
    if roundedLower == roundedUpper {
        return [roundedLower, min(100, roundedUpper + 1)]
    }

    return [roundedLower, roundedUpper]
}

private func dashboardSignedMetric(_ value: Double) -> String {
    let sign = value >= 0 ? "+" : ""
    return "\(sign)\(String(format: "%.1f", value))"
}

#Preview {
    RoutineDashboardView(
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
        session: AuthSessionStore(),
        dailyCheckInStore: DailyCheckInStore(),
        dailyPhotoStore: DailyPhotoStore(),
        badgeManager: BadgeManager()
    )
}
