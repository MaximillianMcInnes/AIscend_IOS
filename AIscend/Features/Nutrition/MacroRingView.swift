//
//  MacroRingView.swift
//  AIscend
//

import SwiftUI

struct MacroRingView: View {
    let title: String
    let value: Double
    let target: Double
    let unit: String
    let tint: Color
    var lineWidth: CGFloat = 10

    @State private var reveal = false

    private var progress: Double {
        guard target > 0 else {
            return 0
        }

        return min(max(value / target, 0), 1)
    }

    var body: some View {
        VStack(spacing: AIscendTheme.Spacing.small) {
            ZStack {
                Circle()
                    .stroke(AIscendTheme.Colors.surfaceHighlight.opacity(0.82), lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: reveal ? progress : 0)
                    .stroke(
                        AngularGradient(
                            colors: [
                                tint.opacity(0.32),
                                tint,
                                AIscendTheme.Colors.textPrimary.opacity(0.84),
                                tint.opacity(0.52)
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: tint.opacity(0.24), radius: 10, x: 0, y: 0)

                VStack(spacing: 2) {
                    Text(compact(value))
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .monospacedDigit()

                    Text(unit)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                }
            }
            .frame(width: 96, height: 96)

            VStack(spacing: 2) {
                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                    .lineLimit(1)

                Text("\(Int((progress * 100).rounded()))%")
                    .aiscendTextStyle(.caption, color: tint)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.72, dampingFraction: 0.86).delay(0.08)) {
                reveal = true
            }
        }
        .onChange(of: value) { _, _ in
            reveal = false
            withAnimation(.spring(response: 0.72, dampingFraction: 0.86)) {
                reveal = true
            }
        }
    }

    private func compact(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        }

        if value.rounded() == value {
            return "\(Int(value))"
        }

        return String(format: "%.1f", value)
    }
}

