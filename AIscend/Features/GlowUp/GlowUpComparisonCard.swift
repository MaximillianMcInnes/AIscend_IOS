//
//  GlowUpComparisonCard.swift
//  AIscend
//

import SwiftUI

struct GlowUpComparisonCard: View {
    let comparison: GlowUpComparison

    private var deltaText: String {
        guard let delta = comparison.overallDelta else {
            return "--"
        }

        let prefix = delta >= 0 ? "+" : "-"
        return "\(prefix)\(String(format: "%.1f", abs(delta)))"
    }

    private var daysBetween: Int {
        Calendar.current.dateComponents([.day], from: comparison.baseline.date, to: comparison.latest.date).day ?? 0
    }

    var body: some View {
        DashboardGlassCard(tone: .hero) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        AIscendBadge(
                            title: "Latest vs baseline",
                            symbol: "chart.line.uptrend.xyaxis",
                            style: .accent
                        )

                        Text(comparison.summary.overallTrend)
                            .aiscendTextStyle(.sectionTitle)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: AIscendTheme.Spacing.small)

                    VStack(alignment: .trailing, spacing: AIscendTheme.Spacing.xxSmall) {
                        Text(deltaText)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(deltaColor)
                            .monospacedDigit()

                        Text("overall")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        summaryPill(title: "Window", value: windowText, symbol: "calendar")
                        summaryPill(title: "Best signal", value: comparison.summary.bestImprovedArea, symbol: "sparkles")
                        summaryPill(title: "Review", value: comparison.summary.areaNeedingAttention, symbol: "scope")
                    }

                    VStack(spacing: AIscendTheme.Spacing.small) {
                        summaryPill(title: "Window", value: windowText, symbol: "calendar")
                        summaryPill(title: "Best signal", value: comparison.summary.bestImprovedArea, symbol: "sparkles")
                        summaryPill(title: "Review", value: comparison.summary.areaNeedingAttention, symbol: "scope")
                    }
                }

                HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AIscendTheme.Colors.accentGlow)
                        .padding(.top, 3)

                    Text(comparison.summary.consistencyNote)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(AIscendTheme.Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                        .fill(Color.white.opacity(0.055))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                        .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                )
            }
        }
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

    private var windowText: String {
        if daysBetween <= 0 {
            return "Same day"
        }

        return "\(daysBetween)d"
    }

    private func summaryPill(title: String, value: String, symbol: String) -> some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            AIscendIconOrb(symbol: symbol, accent: .sky, size: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                Text(value)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
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
}

