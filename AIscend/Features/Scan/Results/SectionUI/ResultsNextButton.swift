//
//  ResultsNextButton.swift
//  AIscend
//

import SwiftUI

struct ResultsNextButton: View {
    let title: String
    var systemImage: String = "arrow.right"
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AIscendTheme.Spacing.xSmall) {
                Text(title)
                    .aiscendTextStyle(.buttonLabel, color: AIscendTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .padding(.horizontal, AIscendTheme.Spacing.medium)
            .background(buttonBackground)
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(isEnabled ? 0.16 : 0.08), lineWidth: 1)
            )
            .shadow(
                color: AIscendTheme.Colors.accentGlow.opacity(isEnabled ? 0.28 : 0),
                radius: 18,
                x: 0,
                y: 8
            )
            .opacity(isEnabled ? 1 : 0.46)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private var buttonBackground: some View {
        Capsule(style: .continuous)
            .fill(
                LinearGradient(
                    colors: isEnabled
                    ? [
                        AIscendTheme.Colors.accentPrimary,
                        Color(hex: "9C4DFF"),
                        Color(hex: "E858FF").opacity(0.82)
                    ]
                    : [
                        Color.white.opacity(0.08),
                        Color.white.opacity(0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}
