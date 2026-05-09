//
//  NutritionInsightsCard.swift
//  AIscend
//

import SwiftUI

struct NutritionInsightsCard: View {
    let insights: [NutritionInsight]
    let recommendations: [NutritionRecommendation]

    var body: some View {
        DashboardGlassCard(tone: .premium) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "AI Intelligence",
                    title: "Aesthetic food signals",
                    subtitle: "AIScend translates intake into facial, recovery, and skin impact."
                )

                VStack(spacing: AIscendTheme.Spacing.small) {
                    ForEach(insights) { insight in
                        NutritionSignalRow(
                            symbol: insight.symbol,
                            title: insight.title,
                            detail: insight.detail,
                            badge: insight.severity.badge,
                            accent: accent(for: insight.severity)
                        )
                    }
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    Text("Next best actions")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                    ForEach(recommendations.prefix(3)) { recommendation in
                        HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
                            Image(systemName: recommendation.symbol)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AIscendTheme.Colors.accentGlow)
                                .frame(width: 26, height: 26)
                                .background(Circle().fill(AIscendTheme.Colors.accentPrimary.opacity(0.16)))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(recommendation.title)
                                    .aiscendTextStyle(.buttonLabel, color: AIscendTheme.Colors.textPrimary)

                                Text(recommendation.detail)
                                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
    }

    private func accent(for severity: NutritionInsightSeverity) -> Color {
        switch severity {
        case .advantage:
            return AIscendTheme.Colors.success
        case .watch:
            return AIscendTheme.Colors.accentAmber
        case .risk:
            return AIscendTheme.Colors.error
        }
    }
}

private struct NutritionSignalRow: View {
    let symbol: String
    let title: String
    let detail: String
    let badge: String
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            ZStack {
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                    .fill(accent.opacity(0.14))

                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accent)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
                        .lineLimit(2)

                    Spacer(minLength: AIscendTheme.Spacing.small)

                    Text(badge)
                        .aiscendTextStyle(.caption, color: accent)
                }

                Text(detail)
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(accent.opacity(0.16), lineWidth: 1)
        )
    }
}

