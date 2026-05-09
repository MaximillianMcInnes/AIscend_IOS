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

    var body: some View {
        Button(action: onOpenConsistency) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: AIscendTheme.Spacing.medium) {
                        todayTitle

                        Spacer(minLength: AIscendTheme.Spacing.small)

                        premiumPill
                        streakCount
                    }

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                        HStack(alignment: .center, spacing: AIscendTheme.Spacing.small) {
                            todayTitle
                            Spacer(minLength: 0)
                            streakCount
                        }

                        premiumPill
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(weekDays) { day in
                        DailyStreakDayMarker(day: day)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AIscendTheme.Spacing.large)
            .padding(.top, AIscendTheme.Spacing.large)
            .padding(.bottom, AIscendTheme.Spacing.mediumLarge)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "223149").opacity(0.98),
                                Color(hex: "182236").opacity(0.98),
                                Color(hex: "151C2C").opacity(0.98)
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
                                        Color.white.opacity(0.07),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.30), radius: 18, x: 0, y: 14)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            checkedInToday
            ? "\(liveStreakDays) day streak protected today"
            : "\(liveStreakDays) day streak open today"
        )
    }

    private var todayTitle: some View {
        HStack(alignment: .center, spacing: AIscendTheme.Spacing.small) {
            Text("Today")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Image(systemName: "chevron.down")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AIscendTheme.Colors.textPrimary.opacity(0.92))
                .offset(y: 2)
        }
    }

    private var premiumPill: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .bold))

            Text("Go Premium")
                .font(.system(size: 17, weight: .bold, design: .rounded))
        }
        .foregroundStyle(Color.black.opacity(0.92))
        .padding(.horizontal, AIscendTheme.Spacing.large)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "FFD15B"),
                            Color(hex: "FFE799")
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
    }

    private var streakCount: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            Text("\(liveStreakDays)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .monospacedDigit()

            Image(systemName: "bolt.fill")
                .font(.system(size: 21, weight: .bold))
        }
        .foregroundStyle(AIscendTheme.Colors.textPrimary)
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
                    .fill(Color.white.opacity(0.88))

                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: "20304A"))
            }
            .frame(width: 36, height: 36)
        } else if day.isToday {
            Circle()
                .stroke(
                    Color.white.opacity(0.86),
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
