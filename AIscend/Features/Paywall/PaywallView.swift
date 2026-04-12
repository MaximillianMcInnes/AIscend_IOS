//
//  PaywallView.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import SwiftUI

struct PaywallView: View {
    let presentation: PaywallPresentation
    let onPrimary: () -> Void
    let onSecondary: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
                    topBar
                    heroCard
                    benefitsCard
                    proofCard
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, 180)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomActions
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.small)
                .padding(.bottom, AIscendTheme.Spacing.small)
                .background(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.appBackground.opacity(0),
                            AIscendTheme.Colors.appBackground.opacity(0.82),
                            AIscendTheme.Colors.appBackground.opacity(0.98)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .interactiveDismissDisabled(!presentation.isDismissable)
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack {
            AIscendBadge(
                title: presentation.variant.badgeTitle,
                symbol: "crown.fill",
                style: .accent
            )

            Spacer()

            if presentation.isDismissable {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .frame(width: 38, height: 38)
                        .background(
                            Circle()
                                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.88))
                        )
                        .overlay(
                            Circle()
                                .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var heroCard: some View {
        DashboardGlassCard(tone: .premium) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                AIscendIconOrb(
                    symbol: "sparkles.rectangle.stack.fill",
                    accent: .sky,
                    size: 76
                )

                AIscendSectionHeader(
                    eyebrow: presentation.variant.signalLine,
                    title: presentation.variant.title,
                    subtitle: presentation.variant.subtitle,
                    prominence: .hero
                )

                HStack(spacing: AIscendTheme.Spacing.small) {
                    PaywallMetricChip(title: "7 days free", detail: "Start now")
                    PaywallMetricChip(title: "Full report", detail: "Unlocked")
                    PaywallMetricChip(title: "Daily loop", detail: "Protected")
                }
            }
        }
    }

    private var benefitsCard: some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                Text("What unlocks immediately")
                    .aiscendTextStyle(.sectionTitle)

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    ForEach(presentation.variant.benefits, id: \.self) { item in
                        HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AIscendTheme.Colors.accentGlow)
                                .padding(.top, 2)

                            Text(item)
                                .aiscendTextStyle(.body)
                        }
                    }
                }
            }
        }
    }

    private var proofCard: some View {
        DashboardGlassCard(tone: .hero) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                AIscendBadge(
                    title: "Why it converts",
                    symbol: "bolt.fill",
                    style: .neutral
                )

                Text("AIScend premium is not a cosmetic upsell. It is the layer that turns a strong reveal into a sharper plan, a stronger streak, and a system you can actually keep coming back to.")
                    .aiscendTextStyle(.body)
            }
        }
    }

    private var bottomActions: some View {
        VStack(spacing: AIscendTheme.Spacing.small) {
            Button(action: onPrimary) {
                AIscendButtonLabel(title: presentation.variant.primaryTitle, leadingSymbol: "crown.fill")
            }
            .buttonStyle(AIscendButtonStyle(variant: .primary))

            if let secondaryTitle = presentation.variant.secondaryTitle {
                Button(action: onSecondary) {
                    AIscendButtonLabel(title: secondaryTitle, leadingSymbol: "arrow.uturn.left")
                }
                .buttonStyle(AIscendButtonStyle(variant: .secondary))
            }

            Text("Cancel any time. Premium is designed to deepen the result, not trap the user.")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

private struct PaywallMetricChip: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
            Text(title)
                .aiscendTextStyle(.cardTitle)

            Text(detail)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
        }
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.78))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}
