//
//  RoadmapPriorityCard.swift
//  AIscend
//

import SwiftUI

extension RoadmapPriorityCategory {
    var symbol: String {
        switch self {
        case .skin:
            "sparkles"
        case .hair:
            "comb.fill"
        case .eyebrows:
            "eye.fill"
        case .facialPosture:
            "figure.stand"
        case .sleepRecovery:
            "moon.zzz.fill"
        case .hydration:
            "drop.fill"
        case .styleGrooming:
            "suitcase.fill"
        case .scanSpecificWeakPoint:
            "scope"
        }
    }

    var accent: RoutineAccent {
        switch self {
        case .skin, .hydration:
            .mint
        case .sleepRecovery, .styleGrooming:
            .dawn
        case .hair, .eyebrows, .facialPosture, .scanSpecificWeakPoint:
            .sky
        }
    }
}

struct RoadmapPriorityCard: View {
    let priority: RoadmapPriority

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                AIscendIconOrb(symbol: priority.category.symbol, accent: priority.category.accent, size: 48)

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                    AIscendBadge(
                        title: priority.category.title,
                        symbol: "target",
                        style: .neutral
                    )

                    Text(priority.title)
                        .aiscendTextStyle(.cardTitle)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: AIscendTheme.Spacing.small)
            }

            Text(priority.reason)
                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: AIscendTheme.Spacing.small) {
                scorePill(title: "Impact", value: priority.impactScore, color: AIscendTheme.Colors.accentGlow)
                scorePill(title: "Difficulty", value: priority.difficultyScore, color: AIscendTheme.Colors.accentCyan)
            }

            HStack(spacing: AIscendTheme.Spacing.xSmall) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AIscendTheme.Colors.accentGlow)

                Text("Visible signal estimate: \(priority.timeToVisibleChange)")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                ForEach(priority.dailyActions.prefix(2), id: \.self) { action in
                    actionRow(action)
                }

                ForEach(priority.weeklyActions.prefix(1), id: \.self) { action in
                    actionRow(action)
                }
            }
        }
        .padding(AIscendTheme.Spacing.mediumLarge)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.065),
                            AIscendTheme.Colors.surfaceGlass.opacity(0.76),
                            AIscendTheme.Colors.cardGradientEnd.opacity(0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private func scorePill(title: String, value: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
            HStack {
                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                Spacer(minLength: 0)

                Text("\(value)/10")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                    .monospacedDigit()
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.075))

                    Capsule(style: .continuous)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(value) / 10)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
        .padding(AIscendTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(Color.white.opacity(0.045))
        )
    }

    private func actionRow(_ action: String) -> some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.xSmall) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.accentGlow)
                .padding(.top, 2)

            Text(action)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

