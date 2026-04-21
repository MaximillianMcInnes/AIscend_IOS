//
//  RatingsResultsPage.swift
//  AIscend
//

import SwiftUI

struct RatingsResultsPage: View {
    let pageIndex: Int
    let totalPages: Int
    let title: String
    let subtitle: String
    let result: PersistedScanRecord?
    let scoreCards: [ResultsMetricCardModel]
    let onShare: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ResultsSectionShell(
            pageIndex: pageIndex,
            totalPages: totalPages,
            title: title,
            subtitle: subtitle,
            badge: "Scan Reveal",
            shareActionTitle: "Share score",
            onShare: onShare
        ) {
            DashboardGlassCard(tone: .hero) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    ResultsPhotoStrip(
                        frontURL: url(from: result?.meta.frontUrl),
                        sideURL: url(from: result?.meta.sideUrl)
                    )

                    HStack(alignment: .center, spacing: AIscendTheme.Spacing.large) {
                        ResultsScoreOrb(score: result?.overallScore ?? 72)

                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                            Text(result?.tierTitle ?? "Prime")
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                            Text("Overall read")
                                .aiscendTextStyle(.cardTitle)

                            Text(result?.headline ?? "AIScend sees a strong base with visible upside.")
                                .aiscendTextStyle(.body)
                        }
                    }
                }
            }

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: AIscendTheme.Spacing.small
            ) {
                ForEach(scoreCards) { card in
                    ResultsMetricPanel(card: card)
                }
            }

            ResultsPrimaryButton(
                title: "Continue to Placement",
                symbol: "arrow.right"
            ) {
                onContinue()
            }
        }
    }

    private func url(from rawValue: String?) -> URL? {
        guard let rawValue else { return nil }
        return URL(string: rawValue)
    }
}