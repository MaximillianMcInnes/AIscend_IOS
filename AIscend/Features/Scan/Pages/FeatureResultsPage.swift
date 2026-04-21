//
//  FeatureResultsPage.swift
//  AIscend
//

import SwiftUI

struct FeatureResultsPage: View {
    let pageIndex: Int
    let totalPages: Int
    let title: String
    let subtitle: String
    let badge: String?
    let traits: [ScanTraitRowModel]
    let showsInlineUpsell: Bool
    let onShare: () -> Void
    let onContinue: () -> Void
    let onUpgrade: () -> Void

    var body: some View {
        ResultsSectionShell(
            pageIndex: pageIndex,
            totalPages: totalPages,
            title: title,
            subtitle: subtitle,
            badge: badge,
            shareActionTitle: "Share highlight",
            onShare: onShare
        ) {
            DashboardGlassCard {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                    ForEach(traits) { trait in
                        ExpandableTraitRow(
                            trait: trait,
                            onUpgrade: onUpgrade
                        )
                    }
                }
            }

            if showsInlineUpsell {
                DashboardGlassCard(tone: .premium) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                        AIscendBadge(
                            title: "Premium detail",
                            symbol: "lock.fill",
                            style: .accent
                        )

                        Text("Jaw detail, side profile analysis, and the deeper eye-area interpretation unlock once the report moves beyond preview mode.")
                            .aiscendTextStyle(.body)

                        Button(action: onUpgrade) {
                            AIscendButtonLabel(title: "Unlock Premium", leadingSymbol: "sparkles")
                        }
                        .buttonStyle(AIscendButtonStyle(variant: .secondary))
                    }
                }
            }

            ResultsPrimaryButton(
                title: "Continue",
                symbol: "arrow.right"
            ) {
                onContinue()
            }
        }
    }
}