//
//  GlowUpShareCard.swift
//  AIscend
//

import SwiftUI

struct GlowUpShareCard: View {
    let comparison: GlowUpComparison
    let isPrivacyModeEnabled: Bool

    var body: some View {
        DashboardGlassCard(tone: .standard) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        AIscendBadge(
                            title: isPrivacyModeEnabled ? "Private mode on" : "Photo preview enabled",
                            symbol: isPrivacyModeEnabled ? "eye.slash.fill" : "eye.fill",
                            style: .accent
                        )

                        Text("Share preview")
                            .aiscendTextStyle(.sectionTitle)

                        Text("A privacy-first summary card for progress conversations. Raw photos stay hidden while private mode is enabled.")
                            .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                    }

                    Spacer(minLength: AIscendTheme.Spacing.small)

                    Text(deltaText)
                        .aiscendTextStyle(.metricCompact, color: deltaColor)
                        .monospacedDigit()
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    shareRow(title: "Overall", value: comparison.summary.overallTrend)
                    shareRow(title: "Best signal", value: comparison.summary.bestImprovedArea)
                    shareRow(title: "Review", value: comparison.summary.areaNeedingAttention)
                }
            }
        }
    }

    private var deltaText: String {
        guard let delta = comparison.overallDelta else {
            return "--"
        }

        return "\(delta >= 0 ? "+" : "-")\(String(format: "%.1f", abs(delta)))"
    }

    private var deltaColor: Color {
        guard let delta = comparison.overallDelta else {
            return AIscendTheme.Colors.textMuted
        }

        if delta >= 1 {
            return AIscendTheme.Colors.success
        }

        if delta <= -1 {
            return AIscendTheme.Colors.warning
        }

        return AIscendTheme.Colors.accentGlow
    }

    private func shareRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            Text(value)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(Color.white.opacity(0.055))
        )
    }
}

