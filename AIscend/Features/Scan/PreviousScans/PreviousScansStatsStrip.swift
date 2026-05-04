//
//  PreviousScansStatsStrip.swift
//  AIscend
//

import SwiftUI

struct PreviousScansStatsStrip: View {
    let savedScansCount: Int
    let bestScore: Int?
    let latestScore: Int?

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            PreviousScanStatCard(value: "\(savedScansCount)", label: "Saved scans")
            PreviousScanStatCard(value: scoreText(bestScore), label: "Best score")
            PreviousScanStatCard(value: scoreText(latestScore), label: "Latest score")
        }
    }

    private func scoreText(_ score: Int?) -> String {
        guard let score, score > 0 else {
            return "--"
        }

        return "\(score)"
    }
}

private struct PreviousScanStatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
            Text(value)
                .aiscendTextStyle(.metricCompact)
                .lineLimit(1)
                .minimumScaleFactor(0.76)

            Text(label)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.16)

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 14, x: 0, y: 8)
    }
}
