//
//  PreviousScansHeader.swift
//  AIscend
//

import SwiftUI

struct PreviousScansHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            HStack(spacing: AIscendTheme.Spacing.xSmall) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AIscendTheme.Colors.accentGlow)

                Text("Scan archive")
                    .aiscendTextStyle(.eyebrow, color: AIscendTheme.Colors.accentGlow)
            }
            .padding(.horizontal, AIscendTheme.Spacing.small)
            .padding(.vertical, 8)
            .background {
                ZStack {
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.18)

                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.07))
                }
            }
            .overlay(
                Capsule(style: .continuous)
                    .stroke(AIscendTheme.Colors.accentGlow.opacity(0.26), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text("Previous scans")
                    .aiscendTextStyle(.screenTitle)

                Text("Your saved facial analysis archive")
                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
