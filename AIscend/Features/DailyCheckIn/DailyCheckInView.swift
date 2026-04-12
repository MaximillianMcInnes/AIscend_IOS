//
//  DailyCheckInView.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import SwiftUI
import UIKit

struct DailyCheckInView: View {
    @ObservedObject var dailyCheckInStore: DailyCheckInStore
    @ObservedObject var badgeManager: BadgeManager
    @ObservedObject var notificationManager: NotificationManager

    let isPremium: Bool
    let onComplete: () -> Void
    let onDismiss: () -> Void

    @State private var selectedMood: DailyCheckInMood = .lockedIn
    @State private var note: String = ""
    @State private var routineCompleted = true
    @State private var selfCareCompleted = true
    @State private var completionMessage: String?

    private var snapshot: StreakSnapshot {
        dailyCheckInStore.snapshot
    }

    private var nextBadge: AIScendBadge? {
        badgeManager.nextLockedBadges.first
    }

    private var daysToMilestone: Int {
        max(snapshot.nextMilestone - snapshot.currentStreak, 0)
    }

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
                    topBar
                    heroCard
                    commitmentCard
                    reflectionCard
                    reminderCard
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, AIscendTheme.Spacing.xxLarge)
            }
        }
        .task {
            await notificationManager.refreshAuthorizationStatus()
            hydrateExistingRecordIfNeeded()
        }
        .overlay(alignment: .top) {
            if let badge = badgeManager.latestUnlockedBadge {
                DailyCheckInUnlockBanner(badge: badge)
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
                title: snapshot.checkedInToday ? "Protected Today" : "Daily Check-In",
                symbol: snapshot.checkedInToday ? "checkmark.seal.fill" : "calendar.badge.checkmark",
                style: snapshot.checkedInToday ? .success : .accent
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
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                AIscendSectionHeader(
                    eyebrow: isPremium ? "Premium discipline layer" : "Consistency loop",
                    title: snapshot.checkedInToday ? "Today's signal is already protected" : "Close today cleanly",
                    subtitle: "AIScend keeps the daily check-up compact so consistency feels sharp, not annoying."
                )

                HStack(spacing: AIscendTheme.Spacing.small) {
                    CheckInMetricChip(
                        title: "Current streak",
                        value: "\(snapshot.currentStreak)d"
                    )
                    CheckInMetricChip(
                        title: "Best streak",
                        value: "\(snapshot.bestStreak)d"
                    )
                    CheckInMetricChip(
                        title: "Badges",
                        value: "\(badgeManager.earnedCount)"
                    )
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    HStack {
                        Text(snapshot.milestoneLabel)
                            .aiscendTextStyle(.cardTitle)

                        Spacer()

                        Text(daysToMilestone == 0 ? "Unlocked now" : "\(daysToMilestone)d remaining")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                    }

                    DailyCheckInProgressBar(progress: snapshot.progressToNextMilestone)

                    Text(completionMessage ?? snapshot.motivationalLine)
                        .aiscendTextStyle(.body, color: completionMessage == nil ? AIscendTheme.Colors.textSecondary : AIscendTheme.Colors.accentGlow)
                }

                if let nextBadge {
                    HStack(spacing: AIscendTheme.Spacing.medium) {
                        AIscendIconOrb(symbol: nextBadge.symbol, accent: nextBadge.accent, size: 42)

                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                            Text("Next marker")
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                            Text(nextBadge.title)
                                .aiscendTextStyle(.cardTitle)

                            Text(nextBadge.unlockHint)
                                .aiscendTextStyle(.secondaryBody)
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
            }
        }
    }

    private var commitmentCard: some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "Proof",
                    title: "What stayed under control today?",
                    subtitle: "A tight reflection loop keeps the streak credible and makes the routine feel earned."
                )

                DailyCheckInToggleTile(
                    title: "Routine handled",
                    subtitle: "Mark the day as operationally clean.",
                    symbol: "checkmark.seal.fill",
                    accent: .sky,
                    isOn: routineCompleted,
                    action: { routineCompleted.toggle() }
                )

                DailyCheckInToggleTile(
                    title: "Self-care completed",
                    subtitle: "Confirm the maintenance layer stayed live.",
                    symbol: "sparkles",
                    accent: .mint,
                    isOn: selfCareCompleted,
                    action: { selfCareCompleted.toggle() }
                )

                if let existing = dailyCheckInStore.record(for: .now) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                        Text("Today's saved status")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                        Text(existing.mood.title)
                            .aiscendTextStyle(.cardTitle)

                        if !existing.note.isEmpty {
                            Text(existing.note)
                                .aiscendTextStyle(.secondaryBody)
                        }
                    }
                    .padding(AIscendTheme.Spacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                            .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.68))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                            .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                    )
                }
            }
        }
    }

    private var reflectionCard: some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "Signal",
                    title: "How did today land?",
                    subtitle: "Keep it concise. AIScend is trying to preserve honesty, not harvest journaling."
                )

                VStack(spacing: AIscendTheme.Spacing.small) {
                    ForEach(DailyCheckInMood.allCases) { mood in
                        DailyMoodRow(
                            mood: mood,
                            isSelected: mood == selectedMood,
                            action: { selectedMood = mood }
                        )
                    }
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    Text("Optional note")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)

                    TextEditor(text: $note)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .font(.system(size: 15, weight: .regular, design: .default))
                        .frame(minHeight: 110)
                        .padding(AIscendTheme.Spacing.small)
                        .background(
                            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                                .fill(AIscendTheme.Colors.fieldFill)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                        )
                }

                Button(action: submitCheckIn) {
                    AIscendButtonLabel(
                        title: snapshot.checkedInToday ? "Refresh Today's Check-In" : "Complete Daily Check-In",
                        leadingSymbol: "checkmark.circle.fill"
                    )
                }
                .buttonStyle(AIscendButtonStyle(variant: .primary))
            }
        }
    }

    private var reminderCard: some View {
        DashboardGlassCard(tone: .premium) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "Retention",
                    title: "Let AIScend protect the chain",
                    subtitle: notificationManager.authorizationState.detail
                )

                HStack(spacing: AIscendTheme.Spacing.small) {
                    CheckInMetricChip(
                        title: "Reminders live",
                        value: "\(notificationManager.preferences.enabledCount)"
                    )
                    CheckInMetricChip(
                        title: "Status",
                        value: notificationManager.authorizationState.badgeTitle
                    )
                }

                Button {
                    Task {
                        if notificationManager.preferences.anyEnabled {
                            await notificationManager.scheduleDefaultAIScendReminders()
                        } else {
                            await notificationManager.enableAllReminders()
                        }
                    }
                } label: {
                    AIscendButtonLabel(
                        title: notificationManager.preferences.anyEnabled ? "Refresh Reminder Schedule" : "Enable Daily Reminders",
                        leadingSymbol: "bell.badge.fill"
                    )
                }
                .buttonStyle(AIscendButtonStyle(variant: .secondary))
            }
        }
    }

    private func hydrateExistingRecordIfNeeded() {
        guard let existing = dailyCheckInStore.record(for: .now) else {
            return
        }

        selectedMood = existing.mood
        note = existing.note
        routineCompleted = existing.routineCompleted
        selfCareCompleted = existing.selfCareCompleted
    }

    private func submitCheckIn() {
        let outcome = dailyCheckInStore.checkInToday(
            mood: selectedMood,
            note: note,
            routineCompleted: routineCompleted,
            selfCareCompleted: selfCareCompleted
        )

        badgeManager.recordDailyCheckIn(
            outcome: outcome,
            allRecords: dailyCheckInStore.recordsByDay
        )
        badgeManager.recordRoutineProgress(
            progress: routineCompleted ? 1 : 0,
            streak: outcome.snapshot.currentStreak
        )

        if outcome.wasNewCheckIn {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            completionMessage = "Check-in complete. Your \(outcome.snapshot.currentStreak)-day streak is protected."
        } else {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            completionMessage = "Today's check-in was updated. The chain stays intact."
        }

        Task {
            await notificationManager.syncScheduledReminders(requestAuthorizationIfNeeded: false)
        }

        onComplete()
    }
}

private struct DailyMoodRow: View {
    let mood: DailyCheckInMood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AIscendTheme.Spacing.medium) {
                Circle()
                    .fill(isSelected ? AIscendTheme.Colors.accentGlow : AIscendTheme.Colors.surfaceHighlight)
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                    Text(mood.title)
                        .aiscendTextStyle(.cardTitle)

                    Text(mood.subtitle)
                        .aiscendTextStyle(.secondaryBody)
                }

                Spacer()
            }
            .padding(AIscendTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                    .fill(isSelected ? AIscendTheme.Colors.accentPrimary.opacity(0.20) : AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                    .stroke(isSelected ? AIscendTheme.Colors.accentGlow.opacity(0.42) : AIscendTheme.Colors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct CheckInMetricChip: View {
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

private struct DailyCheckInToggleTile: View {
    let title: String
    let subtitle: String
    let symbol: String
    let accent: RoutineAccent
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AIscendTheme.Spacing.medium) {
                AIscendIconOrb(symbol: symbol, accent: accent, size: 42)

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                    Text(title)
                        .aiscendTextStyle(.cardTitle)

                    Text(subtitle)
                        .aiscendTextStyle(.secondaryBody)
                }

                Spacer()

                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isOn ? accent.tint : AIscendTheme.Colors.textMuted)
            }
            .padding(AIscendTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(isOn ? 0.84 : 0.66))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .stroke(isOn ? accent.tint.opacity(0.34) : AIscendTheme.Colors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct DailyCheckInProgressBar: View {
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
                    .frame(width: max(proxy.size.width * progress, 18))
                    .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.24), radius: 12, x: 0, y: 0)
            }
        }
        .frame(height: 10)
    }
}

private struct DailyCheckInUnlockBanner: View {
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
