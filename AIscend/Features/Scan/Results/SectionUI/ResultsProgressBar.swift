//
//  ResultsProgressBar.swift
//  AIscend
//

import SwiftUI

struct ResultsProgressBar: View {
    let step: Int
    let total: Int
    var showLabel: Bool = true

    private var progress: Double {
        guard total > 0 else {
            return 0
        }

        return min(max(Double(step) / Double(total), 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
            if showLabel {
                HStack {
                    Text("Progress")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                    Spacer()

                    Text("\(min(max(step, 0), max(total, 1))) / \(max(total, 1))")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                        .monospacedDigit()
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.08))

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.accentGlow,
                                    AIscendTheme.Colors.accentPrimary,
                                    Color(hex: "E858FF")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geometry.size.width * progress, progress > 0 ? 8 : 0))
                        .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.35), radius: 12, x: 0, y: 0)
                }
            }
            .frame(height: 8)
        }
    }
}
