//
//  HydrationIntelligenceCard.swift
//  AIscend
//

import SwiftUI

struct HydrationIntelligenceCard: View {
    let macros: NutritionMacros
    let targets: NutritionMacroTargets
    let score: Int
    let onLogWater: () -> Void

    private var waterProgress: Double {
        min(max(macros.water / max(targets.water, 0.1), 0), 1)
    }

    var body: some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "Hydration Intelligence",
                    title: "Water retention control",
                    subtitle: "Water, sodium, and potassium determine how clean tomorrow's facial read feels."
                )

                HStack(spacing: AIscendTheme.Spacing.medium) {
                    MacroRingView(
                        title: "Water",
                        value: macros.water,
                        target: targets.water,
                        unit: "L",
                        tint: AIscendTheme.Colors.accentCyan,
                        lineWidth: 9
                    )
                    .frame(width: 118)

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        metricLine(title: "Hydration Quality", value: "\(score)/100")
                        metricLine(title: "Sodium Load", value: "\(Int(macros.sodium))mg")
                        metricLine(title: "Potassium", value: "\(Int(macros.potassium))mg")
                    }
                }

                Button(action: onLogWater) {
                    AIscendButtonLabel(title: "Log 500ml Water", leadingSymbol: "drop.fill")
                }
                .buttonStyle(AIscendButtonStyle(variant: .secondary))
            }
        }
    }

    private func metricLine(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            Spacer()

            Text(value)
                .aiscendTextStyle(.buttonLabel, color: AIscendTheme.Colors.textPrimary)
                .monospacedDigit()
        }
        .padding(.vertical, 7)
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.64))
        )
    }
}
