//
//  PlacementResultsPage.swift
//  AIscend
//

import SwiftUI

struct PlacementResultsPage: View {
    let pageIndex: Int
    let totalPages: Int
    let title: String
    let subtitle: String
    let result: PersistedScanRecord?
    let onShare: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ResultsSectionShell(
            pageIndex: pageIndex,
            totalPages: totalPages,
            title: title,
            subtitle: subtitle,
            shareActionTitle: "Share placement",
            onShare: onShare
        ) {
            DashboardGlassCard(tone: .hero) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    HStack(alignment: .center, spacing: AIscendTheme.Spacing.large) {
                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                            Text("Top \(result?.percentile ?? 18)%")
                                .aiscendTextStyle(.metric)

                            Text("Current placement")
                                .aiscendTextStyle(.cardTitle)

                            Text(result?.placementNarrative ?? "AIScend places this scan into a stronger-than-average band.")
                                .aiscendTextStyle(.body)
                        }

                        Spacer()

                        ResultsPercentileRing(percentile: result?.percentile ?? 18)
                    }

                    HStack(spacing: AIscendTheme.Spacing.small) {
                        PlacementBadge(
                            title: result?.tierTitle ?? "Prime",
                            detail: "AIScend class"
                        )

                        PlacementBadge(
                            title: result?.accessLevel == .premium ? "Full Report" : "Preview + Upside",
                            detail: "Access state"
                        )
                    }
                }
            }

            DashboardGlassCard {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                    Text("What this means")
                        .aiscendTextStyle(.sectionTitle)

                    Text("The placement screen is designed to reward attention. AIScend is not just scoring the scan, it is contextualising how the total presentation lands right now and how much room still exists above it.")
                        .aiscendTextStyle(.body)
                }
            }

            ResultsPrimaryButton(
                title: "Continue to Harmony",
                symbol: "arrow.right"
            ) {
                onContinue()
            }
        }
    }
}