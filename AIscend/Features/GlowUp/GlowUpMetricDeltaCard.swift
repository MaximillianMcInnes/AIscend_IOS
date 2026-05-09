//
//  GlowUpMetricDeltaCard.swift
//  AIscend
//

import SwiftUI

struct GlowUpMetricDeltaCard: View {
    let delta: GlowUpMetricDelta
    let mode: GlowUpMetricView

    private var deltaText: String {
        guard let value = delta.delta else {
            return "--"
        }

        let prefix = value >= 0 ? "+" : "-"
        return "\(prefix)\(String(format: "%.1f", abs(value)))"
    }

    var body: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: delta.symbol, accent: accent, size: 46)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                HStack(alignment: .firstTextBaseline, spacing: AIscendTheme.Spacing.small) {
                    Text(delta.title)
                        .aiscendTextStyle(.cardTitle)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)

                    Spacer(minLength: 0)

                    Text(mode == .scoreDeltas ? deltaText : delta.state.label)
                        .aiscendTextStyle(.caption, color: stateColor)
                        .lineLimit(1)
                }

                Text(delta.narrative)
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if mode == .scoreDeltas {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        scorePill(title: "Baseline", value: delta.previousValue)
                        scorePill(title: "Latest", value: delta.latestValue)
                    }
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
                            AIscendTheme.Colors.surfaceGlass.opacity(0.74),
                            AIscendTheme.Colors.cardGradientEnd.opacity(0.96)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private var accent: RoutineAccent {
        switch delta.state {
        case .improved:
            .mint
        case .declined:
            .dawn
        case .stable, .insufficientData:
            .sky
        }
    }

    private var stateColor: Color {
        switch delta.state {
        case .improved:
            AIscendTheme.Colors.success
        case .declined:
            AIscendTheme.Colors.warning
        case .stable:
            AIscendTheme.Colors.accentGlow
        case .insufficientData:
            AIscendTheme.Colors.textMuted
        }
    }

    private var borderColor: Color {
        switch delta.state {
        case .improved:
            AIscendTheme.Colors.success.opacity(0.26)
        case .declined:
            AIscendTheme.Colors.warning.opacity(0.24)
        case .stable:
            AIscendTheme.Colors.accentGlow.opacity(0.20)
        case .insufficientData:
            AIscendTheme.Colors.borderSubtle
        }
    }

    private func scorePill(title: String, value: Double?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            Text(formatted(value))
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(Color.white.opacity(0.055))
        )
    }

    private func formatted(_ value: Double?) -> String {
        guard let value else {
            return "--"
        }

        return String(format: "%.1f", value)
    }
}

