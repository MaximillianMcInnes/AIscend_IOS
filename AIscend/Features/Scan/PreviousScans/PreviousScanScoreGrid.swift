//
//  PreviousScanScoreGrid.swift
//  AIscend
//

import SwiftUI

struct PreviousScanScoreGrid: View {
    let score: String
    let tier: String
    let percentile: String

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            PreviousScanScoreTile(label: "Score", value: score)
            PreviousScanScoreTile(label: "Tier", value: tier)
            PreviousScanScoreTile(label: "Top", value: percentile)
        }
    }
}

private struct PreviousScanScoreTile: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
            Text(label)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                .lineLimit(1)

            Text(value)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.065))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.09), lineWidth: 1)
        )
    }
}
