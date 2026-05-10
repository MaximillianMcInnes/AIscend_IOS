//
//  DailyStreakSection.swift
//  AIscend
//

import SwiftUI

struct DailyStreakSection: View {
    let liveStreakDays: Int
    let checkedInToday: Bool
    let onOpenConsistency: () -> Void

    private var weekDays: [DailyStreakWeekday] {
        DailyStreakWeekday.currentWeek(checkedInToday: checkedInToday, streakDays: liveStreakDays)
    }

    private var statusTitle: String {
        if checkedInToday {
            return "Protected today"
        }

        return liveStreakDays > 0 ? "Keep the chain alive" : "Start today"
    }

    var body: some View {
        Button(action: onOpenConsistency) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                    titleBlock

                    Spacer(minLength: AIscendTheme.Spacing.small)

                    streakCount
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                    HStack(alignment: .center) {
                        Text("Weekly chain")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)

                        Spacer(minLength: 0)

                        Text(checkedInToday ? "Locked" : "Open")
                            .aiscendTextStyle(.caption, color: checkedInToday ? AIscendTheme.Colors.accentGlow : AIscendTheme.Colors.accentAmber)
                    }

                    HStack(alignment: .bottom, spacing: 0) {
                        ForEach(weekDays) { day in
                            DailyStreakDayMarker(day: day)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(AIscendTheme.Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.055))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AIscendTheme.Spacing.large)
            .padding(.vertical, AIscendTheme.Spacing.large)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "21143F").opacity(0.98),
                                AIscendTheme.Colors.accentDeep.opacity(0.90),
                                Color(hex: "120C22").opacity(0.98)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AIscendTheme.Colors.accentSoft.opacity(0.24),
                                        Color.clear,
                                        AIscendTheme.Colors.accentGlow.opacity(0.12)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AIscendTheme.Colors.accentGlow.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: AIscendTheme.Colors.accentDeep.opacity(0.24), radius: 22, x: 0, y: 14)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            checkedInToday
            ? "\(liveStreakDays) day streak protected today"
            : "\(liveStreakDays) day streak open today"
        )
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
            Text("Today")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(statusTitle)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AIscendTheme.Colors.textSecondary)
                .lineLimit(1)
        }
    }

    private var streakCount: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Image(systemName: checkedInToday ? "flame.fill" : "flame")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AIscendTheme.Colors.accentGlow)

            Text("\(liveStreakDays)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .monospacedDigit()

            Text("days")
                .font(.system(size: 13, weight: .bold, design: .rounded))
        }
        .foregroundStyle(AIscendTheme.Colors.textPrimary)
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.10))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AIscendTheme.Colors.accentGlow.opacity(0.24), lineWidth: 1)
        )
    }
}

private struct DailyStreakWeekday: Identifiable {
    let id: Int
    let symbol: String
    let isToday: Bool
    let isCompleted: Bool
    let isFuture: Bool

    static func currentWeek(checkedInToday: Bool, streakDays: Int, now: Date = .now) -> [DailyStreakWeekday] {
        let calendar = Calendar.current
        let weekdaySymbols = calendar.veryShortStandaloneWeekdaySymbols
        let todayIndex = max(0, calendar.component(.weekday, from: now) - 1)
        let completedDaysAvailable = max(0, streakDays - (checkedInToday ? 1 : 0))

        return (0..<7).map { index in
            let isToday = index == todayIndex
            let isPast = index < todayIndex
            let daysBack = todayIndex - index
            let completedPastDay = isPast && daysBack <= completedDaysAvailable

            return DailyStreakWeekday(
                id: index,
                symbol: weekdaySymbols.indices.contains(index) ? weekdaySymbols[index] : "",
                isToday: isToday,
                isCompleted: isToday ? checkedInToday : completedPastDay,
                isFuture: index > todayIndex
            )
        }
    }
}

private struct DailyStreakDayMarker: View {
    let day: DailyStreakWeekday

    var body: some View {
        VStack(spacing: AIscendTheme.Spacing.small) {
            ZStack(alignment: .top) {
                Text(day.symbol)
                    .font(.system(size: 18, weight: day.isToday ? .bold : .medium, design: .rounded))
                    .foregroundStyle(day.isToday ? AIscendTheme.Colors.textPrimary : Color.white.opacity(0.54))
                    .frame(height: 24)

                if day.isToday {
                    Circle()
                        .fill(Color.white.opacity(0.48))
                        .frame(width: 5, height: 5)
                        .offset(y: -9)
                }
            }

            marker
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var marker: some View {
        if day.isCompleted {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AIscendTheme.Colors.accentGlow,
                                AIscendTheme.Colors.accentPrimary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 36, height: 36)
        } else if day.isToday {
            Circle()
                .stroke(
                    AIscendTheme.Colors.accentGlow.opacity(0.9),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [7, 7])
                )
                .frame(width: 36, height: 36)
        } else {
            Circle()
                .stroke(Color.white.opacity(day.isFuture ? 0.42 : 0.28), lineWidth: 3)
                .frame(width: 36, height: 36)
        }
    }
}
