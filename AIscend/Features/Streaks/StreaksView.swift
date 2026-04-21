//
//  StreaksView.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import SwiftUI

struct StreaksView: View {
    @ObservedObject var dailyCheckInStore: DailyCheckInStore
    @ObservedObject var badgeManager: BadgeManager
    @ObservedObject var notificationManager: NotificationManager

    let onOpenCheckIn: () -> Void
    let onDismiss: () -> Void

    @StateObject private var shareCoordinator = ShareCoordinator()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 7)

    private var snapshot: StreakSnapshot {
        dailyCheckInStore.snapshot
    }

    private var todayRecord: DailyCheckInRecord? {
        dailyCheckInStore.record(for: .now)
    }

    private var earnedHighlights: [AIScendBadge] {
        Array(badgeManager.earnedBadges.prefix(4))
    }

    private var nextLockedHighlights: [AIScendBadge] {
        badgeManager.nextLockedBadges
    }

    private var nextMilestoneDistance: Int {
        max(snapshot.nextMilestone - snapshot.currentStreak, 0)
    }

    private var heroWeek: [StreakDayModel] {
        Array(snapshot.recentDays.suffix(7))
    }

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
                    topBar
                    heroCard
                    streakSummaryCard
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, AIscendTheme.Spacing.xxLarge)
            }
        }
        .task {
            await notificationManager.refreshAuthorizationStatus()
        }
        .sheet(item: $shareCoordinator.activePayload) { payload in
            SharePreviewView(
                payload: payload,
                onDismiss: { shareCoordinator.dismiss() }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .overlay(alignment: .top) {
            if let badge = badgeManager.latestUnlockedBadge {
                StreaksBadgeUnlockBanner(badge: badge)
                    .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                    .padding(.top, 92)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack {
            AIscendBadge(
                title: "Daily streak",
                symbol: "flame.fill",
                style: .accent
            )

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.88))
                    )
                    .overlay(
                        Circle()
                            .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var heroCard: some View {
        DashboardGlassCard(tone: .hero) {
            VStack(alignment: .center, spacing: AIscendTheme.Spacing.large) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AIscendTheme.Colors.accentAmber.opacity(0.34),
                                    AIscendTheme.Colors.accentDeep.opacity(0.18),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 14,
                                endRadius: 110
                            )
                        )
                        .frame(width: 180, height: 180)

                    Image(systemName: snapshot.checkedInToday ? "flame.fill" : "flame")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundStyle(AIscendTheme.Colors.accentAmber)
                }

                VStack(spacing: AIscendTheme.Spacing.xxSmall) {
                    ViewThatFits {
                        streakCountBlock(numberSize: 90, labelSize: 26)
                        streakCountBlock(numberSize: 74, labelSize: 22)
                    }

                    Text(snapshot.checkedInToday ? "You're on fire." : "Your check-in is still open.")
                        .aiscendTextStyle(.sectionTitle)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AIscendTheme.Spacing.small)

                    Text(snapshot.motivationalLine)
                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AIscendTheme.Spacing.small)
                }

                StreakHeroWeekRow(days: heroWeek)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        Button(action: onOpenCheckIn) {
                            AIscendButtonLabel(
                                title: snapshot.checkedInToday ? "Review Check-In" : "Check In",
                                leadingSymbol: "calendar.badge.checkmark"
                            )
                        }
                        .buttonStyle(AIscendButtonStyle(variant: .primary))

                        Button {
                            shareCoordinator.present(
                                .streakMilestone(snapshot: snapshot)
                            )
                        } label: {
                            AIscendButtonLabel(title: "Share", leadingSymbol: "square.and.arrow.up")
                        }
                        .buttonStyle(AIscendButtonStyle(variant: .secondary))
                    }

                    VStack(spacing: AIscendTheme.Spacing.small) {
                        Button(action: onOpenCheckIn) {
                            AIscendButtonLabel(
                                title: snapshot.checkedInToday ? "Review Check-In" : "Check In",
                                leadingSymbol: "calendar.badge.checkmark"
                            )
                        }
                        .buttonStyle(AIscendButtonStyle(variant: .primary))

                        Button {
                            shareCoordinator.present(
                                .streakMilestone(snapshot: snapshot)
                            )
                        } label: {
                            AIscendButtonLabel(title: "Share", leadingSymbol: "square.and.arrow.up")
                        }
                        .buttonStyle(AIscendButtonStyle(variant: .secondary))
                    }
                }
            }
        }
    }

    private var streakSummaryCard: some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "Check-in status",
                    title: snapshot.checkedInToday ? "Today's check-in is locked" : "Protect today's chain",
                    subtitle: snapshot.checkedInToday
                    ? "Your daily streak is protected. Refresh the note only if you want a cleaner reflection."
                    : "A quick check-in keeps the streak alive and makes the progress feel real."
                )

                HStack(spacing: AIscendTheme.Spacing.small) {
                    StreaksMetricChip(title: "Current", value: "\(snapshot.currentStreak)d")
                    StreaksMetricChip(title: "Best", value: "\(snapshot.bestStreak)d")
                    StreaksMetricChip(title: "Check-ins", value: "\(snapshot.totalCheckIns)")
                }

                HStack(spacing: AIscendTheme.Spacing.small) {
                    StreaksMetricChip(title: "Next goal", value: "\(snapshot.nextMilestone)d")
                    StreaksMetricChip(title: "Badges", value: "\(badgeManager.earnedCount)")
                    StreaksMetricChip(title: "Rate", value: "\(Int((snapshot.recentCompletionRate * 100).rounded()))%")
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    HStack {
                        Text(snapshot.milestoneLabel)
                            .aiscendTextStyle(.cardTitle)

                        Spacer()

                        Text(nextMilestoneDistance == 0 ? "Ready now" : "\(nextMilestoneDistance)d left")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                    }

                    StreakMilestoneProgressBar(progress: snapshot.progressToNextMilestone)
                }

                if snapshot.usedFreezeRecently {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AIscendTheme.Colors.accentGlow)

                        Text("A freeze protected the streak recently. \(snapshot.freezesRemaining) remaining.")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                    }
                    .padding(AIscendTheme.Spacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                            .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                            .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                    )
                }
            }
        }
    }

    private func streakCountBlock(numberSize: CGFloat, labelSize: CGFloat) -> some View {
        VStack(spacing: AIscendTheme.Spacing.xxSmall) {
            Text("\(snapshot.currentStreak)")
                .font(.system(size: numberSize, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(AIscendTheme.Colors.accentAmber)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(snapshot.currentStreak == 1 ? "day streak" : "days streak")
                .font(.system(size: labelSize, weight: .medium, design: .rounded))
                .foregroundStyle(AIscendTheme.Colors.accentAmber)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private var todayStatusCard: some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "Today",
                    title: snapshot.checkedInToday ? "Today's chain is protected" : "Today's chain is still open",
                    subtitle: snapshot.checkedInToday
                    ? "Your consistency loop is live for today. Refresh it if you want a cleaner note."
                    : "A fast check-in closes the day and keeps the run psychologically intact."
                )

                HStack(spacing: AIscendTheme.Spacing.small) {
                    StreaksMetricChip(title: "Check-ins", value: "\(snapshot.totalCheckIns)")
                    StreaksMetricChip(title: "Badges", value: "\(badgeManager.earnedCount)")
                    StreaksMetricChip(title: "Next", value: "\(snapshot.nextMilestone)d")
                }

                if snapshot.usedFreezeRecently {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AIscendTheme.Colors.accentGlow)

                        Text("A streak freeze was used automatically. \(snapshot.freezesRemaining) remaining.")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                    }
                    .padding(AIscendTheme.Spacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                            .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                            .stroke(AIscendTheme.Colors.accentGlow.opacity(0.18), lineWidth: 1)
                    )
                }

                if let todayRecord {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                        Text(todayRecord.mood.title)
                            .aiscendTextStyle(.cardTitle)

                        Text(todayRecord.note.isEmpty ? "No note logged. Clean signal, minimal noise." : todayRecord.note)
                            .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)

                        HStack(spacing: AIscendTheme.Spacing.small) {
                            StreakStatusPill(
                                title: todayRecord.routineCompleted ? "Routine handled" : "Routine not marked",
                                symbol: todayRecord.routineCompleted ? "checkmark.seal.fill" : "circle",
                                accent: todayRecord.routineCompleted ? .sky : .dawn
                            )
                            StreakStatusPill(
                                title: todayRecord.selfCareCompleted ? "Self-care handled" : "Self-care not marked",
                                symbol: todayRecord.selfCareCompleted ? "sparkles" : "circle",
                                accent: todayRecord.selfCareCompleted ? .mint : .dawn
                            )
                        }
                    }
                    .padding(AIscendTheme.Spacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                            .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                            .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                    )
                }

                Button(action: onOpenCheckIn) {
                    AIscendButtonLabel(
                        title: snapshot.checkedInToday ? "Review Today's Check-In" : "Complete Daily Check-In",
                        leadingSymbol: "calendar.badge.checkmark"
                    )
                }
                .buttonStyle(AIscendButtonStyle(variant: .primary))
            }
        }
    }

    private var streakHistoryCard: some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "History",
                    title: "Don't break the chain",
                    subtitle: "AIScend keeps recent check-ins visible so discipline feels real and dropping the run feels expensive."
                )

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(snapshot.recentDays) { day in
                        StreakHistoryTile(day: day)
                    }
                }

                HStack(spacing: AIscendTheme.Spacing.small) {
                    StreakLegendDot(color: AIscendTheme.Colors.accentPrimary.opacity(0.88), title: "Checked in")
                    StreakLegendDot(color: AIscendTheme.Colors.surfaceHighlight.opacity(0.88), title: "Open")
                    StreakLegendDot(color: Color(hex: "181218"), title: "Missed")
                }
            }
        }
    }

    private var achievementCard: some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "Badges",
                    title: "Status markers",
                    subtitle: "Earned markers reinforce follow-through without turning AIScend into cheap gamification."
                )

                if earnedHighlights.isEmpty {
                    Text("Run your first check-in and first scan result to start populating the badge vault.")
                        .aiscendTextStyle(.body)
                } else {
                    LazyVStack(spacing: AIscendTheme.Spacing.small) {
                        ForEach(earnedHighlights) { badge in
                            StreakBadgeRow(
                                badge: badge,
                                buttonTitle: "Share",
                                onTap: {
                                    shareCoordinator.present(
                                        .badgeUnlock(
                                            badge: badge,
                                            totalBadges: badgeManager.earnedCount,
                                            currentStreak: snapshot.currentStreak
                                        )
                                    )
                                }
                            )
                        }
                    }
                }

                if !nextLockedHighlights.isEmpty {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        Text("Coming next")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                        ForEach(nextLockedHighlights) { badge in
                            StreakBadgeRow(
                                badge: badge,
                                buttonTitle: "Target",
                                onTap: {}
                            )
                            .opacity(0.84)
                        }
                    }
                    .padding(.top, AIscendTheme.Spacing.small)
                }
            }
        }
    }

    private var reminderCard: some View {
        DashboardGlassCard(tone: .premium) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "Retention reminders",
                    title: "Keep the system quietly active",
                    subtitle: notificationManager.authorizationState.detail
                )

                HStack(spacing: AIscendTheme.Spacing.small) {
                    AIscendBadge(
                        title: notificationManager.authorizationState.badgeTitle,
                        symbol: "bell.badge.fill",
                        style: notificationManager.authorizationState == .enabled ? .success : .neutral
                    )

                    StreaksMetricChip(title: "Live", value: "\(notificationManager.preferences.enabledCount)")
                }

                VStack(spacing: AIscendTheme.Spacing.small) {
                    ForEach(AIScendReminderKind.allCases) { kind in
                        StreakReminderToggleRow(
                            kind: kind,
                            isEnabled: notificationManager.isEnabled(kind)
                        ) { isEnabled in
                            Task {
                                await notificationManager.setReminderEnabled(isEnabled, for: kind)
                            }
                        }
                    }
                }

                if notificationManager.authorizationState != .enabled {
                    Button {
                        Task {
                            if notificationManager.preferences.anyEnabled {
                                await notificationManager.scheduleDefaultAIScendReminders()
                            } else {
                                await notificationManager.enableAllReminders()
                            }
                        }
                    } label: {
                        AIscendButtonLabel(title: "Enable Notifications", leadingSymbol: "bell.badge.fill")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .secondary))
                }
            }
        }
    }
}

private struct StreakHeroWeekRow: View {
    let days: [StreakDayModel]

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            ForEach(days) { day in
                VStack(spacing: AIscendTheme.Spacing.xxSmall) {
                    Text(String(day.weekdayLabel.prefix(1)))
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                    ZStack {
                        Circle()
                            .fill(fillColor(for: day))
                            .frame(width: 30, height: 30)

                        if day.status == .completed {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "1A1410"))
                        } else if day.status == .pending {
                            Circle()
                                .stroke(AIscendTheme.Colors.accentAmber.opacity(0.45), lineWidth: 1.5)
                                .frame(width: 30, height: 30)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private func fillColor(for day: StreakDayModel) -> Color {
        switch day.status {
        case .completed:
            AIscendTheme.Colors.accentAmber
        case .pending:
            Color.clear
        case .missed:
            Color(hex: "231A15")
        case .future:
            Color(hex: "181616")
        }
    }
}

private struct StreaksMetricChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
            Text(value)
                .aiscendTextStyle(.cardTitle)

            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
        }
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.78))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct StreakStatusPill: View {
    let title: String
    let symbol: String
    let accent: RoutineAccent

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(accent.tint)

            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
        }
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

private struct StreakMilestoneProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.84))

                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AIscendTheme.Colors.accentGlow,
                                AIscendTheme.Colors.accentPrimary
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(proxy.size.width * progress, 16))
                    .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.24), radius: 12, x: 0, y: 0)
            }
        }
        .frame(height: 10)
    }
}

private struct StreakHistoryTile: View {
    let day: StreakDayModel

    var body: some View {
        VStack(spacing: 6) {
            Text(day.weekdayLabel)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            Text(day.dayNumber)
                .aiscendTextStyle(.cardTitle, color: foreground)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .stroke(border, lineWidth: 1)
        )
    }

    private var fill: Color {
        switch day.status {
        case .completed:
            AIscendTheme.Colors.accentPrimary.opacity(0.30)
        case .pending:
            AIscendTheme.Colors.surfaceHighlight.opacity(0.86)
        case .missed:
            Color(hex: "181218").opacity(0.92)
        case .future:
            AIscendTheme.Colors.secondaryBackground.opacity(0.84)
        }
    }

    private var border: Color {
        switch day.status {
        case .completed:
            AIscendTheme.Colors.accentGlow.opacity(0.42)
        case .pending:
            AIscendTheme.Colors.borderStrong
        case .missed, .future:
            AIscendTheme.Colors.borderSubtle
        }
    }

    private var foreground: Color {
        switch day.status {
        case .completed:
            AIscendTheme.Colors.textPrimary
        case .pending:
            AIscendTheme.Colors.accentGlow
        case .missed:
            AIscendTheme.Colors.textMuted
        case .future:
            AIscendTheme.Colors.textSecondary
        }
    }
}

private struct StreakLegendDot: View {
    let color: Color
    let title: String

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)

            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
        }
    }
}

private struct StreakBadgeRow: View {
    let badge: AIScendBadge
    let buttonTitle: String
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: badge.symbol, accent: badge.accent, size: 44)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(badge.title)
                    .aiscendTextStyle(.cardTitle)

                Text(buttonTitle == "Target" ? badge.unlockHint : badge.detail)
                    .aiscendTextStyle(.body)

                Text(buttonTitle == "Target" ? "Next unlock" : badge.category.title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
            }

            Spacer(minLength: 0)

            Button(action: onTap) {
                Text(buttonTitle)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
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
            .buttonStyle(.plain)
            .disabled(buttonTitle == "Target")
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct StreakReminderToggleRow: View {
    let kind: AIScendReminderKind
    let isEnabled: Bool
    let onChange: (Bool) -> Void

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: symbol, accent: accent, size: 40)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(kind.title)
                    .aiscendTextStyle(.cardTitle)

                Text(kind.subtitle)
                    .aiscendTextStyle(.secondaryBody)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: onChange
            ))
            .labelsHidden()
            .tint(AIscendTheme.Colors.accentPrimary)
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private var symbol: String {
        switch kind {
        case .dailyCheckIn:
            "calendar.badge.checkmark"
        case .streakProtection:
            "flame.fill"
        case .routine:
            "checkmark.seal.fill"
        }
    }

    private var accent: RoutineAccent {
        switch kind {
        case .dailyCheckIn:
            .sky
        case .streakProtection:
            .mint
        case .routine:
            .dawn
        }
    }
}

private struct StreaksBadgeUnlockBanner: View {
    let badge: AIScendBadge

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: badge.symbol, accent: badge.accent, size: 44)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text("Badge unlocked")
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
                        .opacity(0.30)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.32), radius: 18, x: 0, y: 10)
    }
}
