//
//  AIscendChatQuotaBanner.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import SwiftUI

struct AIscendChatQuotaBanner: View {
    enum Style {
        case prominent
        case compact
    }

    let quota: AIscendChatQuota
    let style: Style
    let onUpgradeTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                    AIscendBadge(
                        title: quota.isExhausted ? "Premium" : "Access",
                        symbol: quota.isExhausted ? "sparkles" : "waveform.path.ecg",
                        style: .accent
                    )

                    Text(quota.headline)
                        .aiscendTextStyle(style == .prominent ? .cardTitle : .body, color: AIscendTheme.Colors.textPrimary)

                    Text(quota.detail)
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                }

                Spacer(minLength: 0)

                Text(quota.compactLabel)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                    .padding(.horizontal, AIscendTheme.Spacing.small)
                    .padding(.vertical, 7)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }

            Button(action: onUpgradeTap) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    Text(quota.trialEligible ? "Start your 7-day trial" : "Unlock Premium")
                        .aiscendTextStyle(.buttonLabel, color: AIscendTheme.Colors.textPrimary)

                    Spacer(minLength: 0)

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                }
                .padding(.horizontal, AIscendTheme.Spacing.mediumLarge)
                .padding(.vertical, AIscendTheme.Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.accentSoft.opacity(0.88),
                                    AIscendTheme.Colors.accentPrimary.opacity(0.88)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AIscendTheme.Colors.accentGlow.opacity(0.34), lineWidth: 1)
                )
                .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.26), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(.plain)
        }
        .padding(style == .prominent ? AIscendTheme.Spacing.large : AIscendTheme.Spacing.mediumLarge)
        .background(
            RoundedRectangle(cornerRadius: style == .prominent ? 28 : 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "1B1624").opacity(0.94),
                            Color(hex: "13151D").opacity(0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: style == .prominent ? 28 : 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.accentGlow.opacity(0.08),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: style == .prominent ? 28 : 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.accentGlow.opacity(0.32),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.28), radius: 24, x: 0, y: 10)
        .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.12), radius: 28, x: 0, y: 0)
    }
}
