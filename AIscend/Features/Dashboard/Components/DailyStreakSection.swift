//
//  DailyStreakSection.swift
//  AIscend
//

import SwiftUI

struct DailyStreakSection: View {
    let liveStreakDays: Int
    let checkedInToday: Bool
    let onOpenConsistency: () -> Void

    var body: some View {
        Button(action: onOpenConsistency) {
            HStack(alignment: .center, spacing: AIscendTheme.Spacing.medium) {
                ZStack {
                    Circle()
                        .fill(
                            (checkedInToday ? AIscendTheme.Colors.success : AIscendTheme.Colors.accentAmber)
                                .opacity(0.18)
                        )

                    Image(systemName: checkedInToday ? "checkmark.seal.fill" : "flame.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            checkedInToday ? AIscendTheme.Colors.success : AIscendTheme.Colors.accentAmber
                        )
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                    Text("Daily streak")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                    Text(checkedInToday ? "Today's streak is protected" : "Today's streak is still open")
                        .aiscendTextStyle(.cardTitle)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(
                        checkedInToday
                        ? "The run is safe for today. Tap to review your consistency."
                        : "Close the day out to keep the chain alive."
                    )
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                    .lineLimit(2)
                }

                Spacer(minLength: AIscendTheme.Spacing.small)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(liveStreakDays)d")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)

                    Text(checkedInToday ? "Protected" : "Open")
                        .aiscendTextStyle(
                            .caption,
                            color: checkedInToday ? AIscendTheme.Colors.success : AIscendTheme.Colors.accentAmber
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AIscendTheme.Spacing.mediumLarge)
            .padding(.vertical, AIscendTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.82))
                    .overlay(
                        RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                            .fill(Color.white.opacity(0.03))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}