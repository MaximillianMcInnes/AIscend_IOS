//
//  HarmonyResultsPage.swift
//  AIscend
//

import SwiftUI

struct HarmonyResultsPage: View {
    let pageIndex: Int
    let totalPages: Int
    let title: String
    let subtitle: String
    let traits: [ScanTraitRowModel]
    let onShare: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ResultsSectionShell(
            pageIndex: pageIndex,
            totalPages: totalPages,
            title: title,
            subtitle: subtitle,
            shareActionTitle: "Share highlight",
            onShare: onShare
        ) {
            DashboardGlassCard(tone: .hero) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    Text("AIScend is looking for how the face holds together as a whole. These are the harmony variables contributing most to the current read.")
                        .aiscendTextStyle(.body)

                    VStack(spacing: AIscendTheme.Spacing.small) {
                        ForEach(traits) { trait in
                            HarmonyHighlightRow(trait: trait)
                        }
                    }
                }
            }

            ResultsPrimaryButton(
                title: "Continue to Feature Detail",
                symbol: "arrow.right"
            ) {
                onContinue()
            }
        }
    }
}