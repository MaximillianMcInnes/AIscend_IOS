//
//  PremiumPushResultsPage.swift
//  AIscend
//

import SwiftUI

struct PremiumPushResultsPage: View {
    let pageIndex: Int
    let totalPages: Int
    let title: String
    let subtitle: String
    let onUpgrade: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ResultsSectionShell(
            pageIndex: pageIndex,
            totalPages: totalPages,
            title: title,
            subtitle: subtitle,
            badge: "Premium"
        ) {
            DashboardGlassCard(tone: .premium) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    HStack(spacing: AIscendTheme.Spacing.large) {
                        AIscendIconOrb(symbol: "sparkles.rectangle.stack.fill", accent: .sky, size: 70)

                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                            Text("Upgrade unlocks the deeper read")
                                .aiscendTextStyle(.sectionTitle)

                            Text("Jawline structure, skin quality, side profile detail, and the complete improvement path sit behind the full report.")
                                .aiscendTextStyle(.body)
                        }
                    }

                    VStack(spacing: AIscendTheme.Spacing.small) {
                        PremiumBenefitRow(text: "Jaw rating and lower-third guidance")
                        PremiumBenefitRow(text: "Skin quality scoring and context")
                        PremiumBenefitRow(text: "Side profile analysis with projection detail")
                    }

                    Button(action: onUpgrade) {
                        AIscendButtonLabel(title: "Unlock Premium", leadingSymbol: "crown.fill")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .primary))

                    Button(action: onContinue) {
                        AIscendButtonLabel(title: "Continue with current result", leadingSymbol: "arrow.right")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .secondary))

                    Text("Your current result remains available either way. Premium just expands the depth, not the pressure.")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                }
            }
        }
    }
}