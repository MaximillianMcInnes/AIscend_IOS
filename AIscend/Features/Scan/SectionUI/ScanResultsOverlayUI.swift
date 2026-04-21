//
//  ScanResultsOverlayUI.swift
//  AIscend
//

import SwiftUI

struct ResultsCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color(hex: "10141B").opacity(0.84))
                        .overlay(Circle().fill(.ultraThinMaterial).opacity(0.55))
                )
                .overlay(
                    Circle()
                        .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.32), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }
}

struct ResultsMomentumCapsule: View {
    let streakDays: Int
    let badgeCount: Int
    let checkedInToday: Bool

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            HStack(spacing: 6) {
                Image(systemName: checkedInToday ? "checkmark.seal.fill" : "flame.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AIscendTheme.Colors.accentGlow)

                Text("\(max(streakDays, 0))d")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
            }

            Rectangle()
                .fill(AIscendTheme.Colors.borderSubtle)
                .frame(width: 1, height: 12)

            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AIscendTheme.Colors.accentGlow)

                Text("\(badgeCount)")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
            }
        }
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .background(
            Capsule(style: .continuous)
                .fill(Color(hex: "10141B").opacity(0.84))
                .overlay(Capsule(style: .continuous).fill(.ultraThinMaterial).opacity(0.55))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.30), radius: 18, x: 0, y: 10)
    }
}

struct ResultsBadgeUnlockBanner: View {
    let badge: AIScendBadge

    var body: some View {
        HStack(alignment: .center, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: badge.symbol, accent: badge.accent, size: 46)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text("Badge Unlocked")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                Text(badge.title)
                    .aiscendTextStyle(.cardTitle)

                Text(badge.detail)
                    .aiscendTextStyle(.secondaryBody)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(Color(hex: "11151C").opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.34)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.accentGlow.opacity(0.34), lineWidth: 1)
        )
        .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.16), radius: 20, x: 0, y: 8)
    }
}