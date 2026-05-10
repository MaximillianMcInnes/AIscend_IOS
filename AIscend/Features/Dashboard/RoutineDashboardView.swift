//
//  RoutineDashboardView.swift
//  AIscend
//
//  Created by Codex on 4/7/26.
//

import Foundation
import SwiftUI
import UIKit

struct RoutineDashboardView: View {
    @Bindable var model: AppModel
    let session: AuthSessionStore
    @ObservedObject var dailyCheckInStore: DailyCheckInStore
    @ObservedObject var dailyPhotoStore: DailyPhotoStore
    @ObservedObject var hydrationStore: HydrationTrackingStore
    @ObservedObject var electrolyteStore: ElectrolyteTrackingStore
    @ObservedObject var badgeManager: BadgeManager
    let isPremium: Bool
    @StateObject private var scanTrendStore = DashboardScanTrendStore()
    var onOpenAdvisor: () -> Void = {}
    var onOpenHydrationChat: (String) -> Void = { _ in }
    var onOpenRoutine: () -> Void = {}
    var onOpenCheckIn: () -> Void = {}
    var onOpenConsistency: () -> Void = {}
    var onOpenDailyPhoto: () -> Void = {}
    var onCaptureDailyPhoto: () -> Void = {}
    var onOpenRoadmap: () -> Void = {}
    var onOpenScan: () -> Void = {}
    var onOpenAccount: () -> Void = {}
    var onRefine: () -> Void = {}

    @State private var showingHydration = false

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

        guard !sourceName.isEmpty else {
            return "Climber"
        }

        return sourceName.split(separator: " ").first.map(String.init) ?? sourceName
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

    private var liveStreakDays: Int {
        dailyCheckInStore.snapshot.currentStreak
    }

    private var checkedInToday: Bool {
        dailyCheckInStore.hasCheckedInToday
    }

    private var todayLabel: String {
        Self.dateFormatter.string(from: .now)
    }

    private var liveTrendModel: DashboardScanTrendModel? {
        if case .loaded(let model) = scanTrendStore.phase {
            return model
        }

        return nil
    }

    private var dashboardCurrentScore: Double {
        liveTrendModel?.latestScore ?? Double(snapshot.score)
    }

    private var dashboardPredictedScore: Double {
        liveTrendModel?.predictedScore
            ?? DashboardScanTrendModel.fallback(from: snapshot).predictedScore
    }

    private var currentScoreDetail: String {
        liveTrendModel == nil ? snapshot.tier : "Latest saved scan"
    }

    private var predictedScoreDetail: String {
        liveTrendModel == nil ? "Projected path" : "Graph projection"
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

    var body: some View {
        ZStack {
            AIscendBackdrop()
            reportAmbientLayer

            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    dashboardContent(in: geometry)
                        .frame(maxWidth: .infinity)
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear
                        .frame(
                            height: AIscendTheme.Layout.floatingTabBarClearance
                            + AIscendTheme.Spacing.large
                        )
                }
            }
        }
        .sheet(isPresented: $showingHydration) {
            HydrationTrackingScreen(
                store: hydrationStore,
                electrolyteStore: electrolyteStore,
                onOpenChat: { prompt in
                    showingHydration = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onOpenHydrationChat(prompt)
                    }
                }
            )
        }
        .task(id: session.user?.id) {
            await scanTrendStore.loadScans(for: session.user)
        }
        .preferredColorScheme(.dark)
    }

    private func dashboardContent(in geometry: GeometryProxy) -> some View {
        let outerPadding = geometry.size.width >= 760
            ? AIscendTheme.Spacing.xxLarge
            : AIscendTheme.Spacing.screenInset

        let centeredMaxWidth: CGFloat = geometry.size.width >= 1100
            ? 900
            : geometry.size.width >= 760
            ? 760
            : max(0, geometry.size.width - (outerPadding * 2))

        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    reportHeader
                    reportScoreRow

                    ChartSection(
                        snapshot: snapshot,
                        trendPhase: scanTrendStore.phase,
                        onOpenScan: onOpenScan
                    )

                    roadmapWidget
                    dailyPhotosAccessWidget

                    HydrationSection(
                        hydrationStore: hydrationStore,
                        electrolyteStore: electrolyteStore,
                        onOpenHydration: {
                            showingHydration = true
                        },
                        onOpenChat: onOpenHydrationChat
                    )
                }
                .frame(maxWidth: centeredMaxWidth, alignment: .leading)
                .padding(.horizontal, outerPadding)
                .padding(.top, AIscendTheme.Spacing.xLarge)
                .padding(.bottom, AIscendTheme.Spacing.large)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .top)
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
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                    reportHeaderCopy
                    Spacer(minLength: AIscendTheme.Spacing.small)
                    reportHeaderActions
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                    reportHeaderCopy
                    reportHeaderActions
                }
            }

            DailyStreakSection(
                liveStreakDays: liveStreakDays,
                checkedInToday: checkedInToday,
                onOpenConsistency: onOpenConsistency
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var reportHeaderCopy: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            AIscendBadge(
                title: todayLabel,
                symbol: "calendar",
                style: .neutral
            )

            Text("Dashboard")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)

            Text("\(model.greeting), \(firstName)")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(AIscendTheme.Colors.textSecondary)

            Text(snapshot.headerSubtitle)
                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var reportHeaderActions: some View {
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

    private var reportScoreRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
                reportMetricCard(
                    title: "Current score",
                    value: scoreText(dashboardCurrentScore),
                    detail: currentScoreDetail,
                    highlighted: false
                )

                reportMetricCard(
                    title: "Predicted score",
                    value: scoreText(dashboardPredictedScore),
                    detail: predictedScoreDetail,
                    highlighted: true
                )
            }

            VStack(spacing: AIscendTheme.Spacing.small) {
                reportMetricCard(
                    title: "Current score",
                    value: scoreText(dashboardCurrentScore),
                    detail: currentScoreDetail,
                    highlighted: false
                )

                reportMetricCard(
                    title: "Predicted score",
                    value: scoreText(dashboardPredictedScore),
                    detail: predictedScoreDetail,
                    highlighted: true
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var roadmapWidget: some View {
        DashboardGlassCard(tone: .premium) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        AIscendBadge(
                            title: "30 / 60 / 90 system",
                            symbol: "map.fill",
                            style: .accent
                        )

                        Text("AI Roadmap")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(AIscendTheme.Colors.textPrimary)

                        Text("Turn scan signals and goals into a focused 90-day optimisation path for grooming, recovery, posture, hydration, and presentation.")
                            .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    AIscendIconOrb(symbol: "point.topleft.down.curvedto.point.bottomright.up", accent: .sky, size: 54)
                }

                HStack(spacing: AIscendTheme.Spacing.small) {
                    roadmapMetaPill(title: "Plan", value: "90 days", symbol: "calendar")
                    roadmapMetaPill(title: "Focus", value: "Top 5", symbol: "target")
                }

                Button(action: onOpenRoadmap) {
                    AIscendButtonLabel(
                        title: "Open AI Roadmap",
                        leadingSymbol: "map.fill"
                    )
                }
                .buttonStyle(AIscendButtonStyle(variant: .primary))
            }
        }
    }

    private func roadmapMetaPill(title: String, value: String, symbol: String) -> some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.accentGlow)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                Text(value)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.58))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private var dailyPhotosAccessWidget: some View {
        DashboardGlassCard(tone: .hero) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        AIscendBadge(
                            title: dailyPhotoStore.hasPhotoToday ? "Captured today" : "Open today",
                            symbol: dailyPhotoStore.hasPhotoToday ? "checkmark.seal.fill" : "camera.aperture",
                            style: .accent
                        )

                        Text("Today's photo")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(AIscendTheme.Colors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)

                        Text(dailyPhotoHeadline)
                            .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
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
                        .frame(width: 210)

                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                            Text(dailyPhotoDetail)
                                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)

                            VStack(spacing: AIscendTheme.Spacing.small) {
                                DailyPhotosWidgetMetaPill(
                                    title: "Saved",
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
                        }
                    }

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                        DailyPhotosWidgetPreviewCard(
                            store: dailyPhotoStore,
                            entry: featuredDailyPhotoEntry,
                            isTodayCaptured: dailyPhotoStore.hasPhotoToday
                        )
                        .frame(maxWidth: 320)
                        .frame(maxWidth: .infinity, alignment: .center)

                        Text(dailyPhotoDetail)
                            .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: AIscendTheme.Spacing.small) {
                            DailyPhotosWidgetMetaPill(
                                title: "Saved",
                                value: dailyPhotoArchiveLabel,
                                symbol: "photo.stack.fill"
                            )
                            .frame(maxWidth: .infinity)

                            DailyPhotosWidgetMetaPill(
                                title: "Run",
                                value: "\(dailyPhotoStore.currentStreakDays())d",
                                symbol: "sparkles.rectangle.stack.fill"
                            )
                            .frame(maxWidth: .infinity)

                            DailyPhotosWidgetMetaPill(
                                title: "Status",
                                value: dailyPhotoStatusLabel,
                                symbol: dailyPhotoStore.hasPhotoToday ? "checkmark.circle.fill" : "sun.max.fill"
                            )
                            .frame(maxWidth: .infinity)
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
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
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

    private func scoreText(_ value: Double) -> String {
        String(format: "%.1f", value)
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
                    .frame(width: 30, height: 30)

                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AIscendTheme.Colors.accentGlow)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                    .lineLimit(1)

                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct DailyPhotosWidgetPreviewCard: View {
    @ObservedObject var store: DailyPhotoStore
    let entry: DailyPhotoEntry?
    let isTodayCaptured: Bool

    private var surfaceShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
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

            if let entry, let url = store.imageURL(for: entry) {
                AIscendCachedImage(localURL: url, maxPixelDimension: 900, contentMode: .fill) {
                    placeholderContent
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            } else {
                placeholderContent
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
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .padding(AIscendTheme.Spacing.mediumLarge)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .clipShape(surfaceShape)
        .overlay(
            surfaceShape
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private var placeholderContent: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.accentDeep.opacity(0.40),
                    AIscendTheme.Colors.surfaceMuted.opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                AIscendIconOrb(symbol: "camera.aperture", accent: .sky, size: 48)

                Text("No photo yet")
                    .aiscendTextStyle(.cardTitle)

                Text("Save one clean frame to start the timeline.")
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                    .lineLimit(2)
            }
            .padding(AIscendTheme.Spacing.mediumLarge)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
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
        hydrationStore: HydrationTrackingStore(),
        electrolyteStore: ElectrolyteTrackingStore(),
        badgeManager: BadgeManager(),
        isPremium: false
    )
}
