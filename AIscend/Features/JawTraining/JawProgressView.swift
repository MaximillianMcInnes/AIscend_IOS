//
//  JawProgressView.swift
//  AIscend
//
//  Created by Codex on 5/7/26.
//

import SwiftUI

struct JawProgressView: View {
    @ObservedObject var store: JawTrainingStore

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendSectionHeader(
                eyebrow: "Tracking",
                title: "Consistency signal",
                subtitle: "Completion is tracked locally. Keep the work gentle, repeatable, and pain-free."
            )

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    progressMetric(
                        title: "Today",
                        value: store.hasCompletedToday ? "Done" : "Open",
                        symbol: store.hasCompletedToday ? "checkmark.seal.fill" : "circle",
                        accent: store.hasCompletedToday ? .mint : .sky
                    )

                    progressMetric(
                        title: "Streak",
                        value: "\(store.currentStreak)d",
                        symbol: "flame.fill",
                        accent: .dawn
                    )

                    progressMetric(
                        title: "Week",
                        value: "\(store.weeklyCompletionCount)/7",
                        symbol: "calendar",
                        accent: .sky
                    )
                }

                VStack(spacing: AIscendTheme.Spacing.small) {
                    progressMetric(
                        title: "Today",
                        value: store.hasCompletedToday ? "Done" : "Open",
                        symbol: store.hasCompletedToday ? "checkmark.seal.fill" : "circle",
                        accent: store.hasCompletedToday ? .mint : .sky
                    )

                    progressMetric(
                        title: "Streak",
                        value: "\(store.currentStreak)d",
                        symbol: "flame.fill",
                        accent: .dawn
                    )

                    progressMetric(
                        title: "Week",
                        value: "\(store.weeklyCompletionCount)/7",
                        symbol: "calendar",
                        accent: .sky
                    )
                }
            }

            HStack(spacing: AIscendTheme.Spacing.small) {
                ForEach(store.weeklyProgress) { day in
                    VStack(spacing: AIscendTheme.Spacing.xSmall) {
                        Text(day.weekday)
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                            .lineLimit(1)

                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    day.isCompleted
                                        ? AnyShapeStyle(RoutineAccent.sky.gradient)
                                        : AnyShapeStyle(AIscendTheme.Colors.surfaceHighlight.opacity(0.64))
                                )
                                .frame(height: 48)

                            Image(systemName: day.isCompleted ? "checkmark" : "minus")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(day.isCompleted ? .white : AIscendTheme.Colors.textMuted)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.elevated)
    }

    private func progressMetric(title: String, value: String, symbol: String, accent: RoutineAccent) -> some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            AIscendIconOrb(symbol: symbol, accent: accent, size: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                Text(value)
                    .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.68))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(accent.tint.opacity(0.22), lineWidth: 1)
        )
    }
}
