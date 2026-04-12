//
//  ShareCardView.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import SwiftUI

struct AIScendShareCardView: View {
    let payload: AIScendSharePayload
    let template: AIScendShareTemplate
    let privacyMode: AIScendSharePrivacyMode

    private var metrics: [AIScendShareMetric] {
        payload.displayedMetrics(for: privacyMode)
    }

    private var identityLine: String? {
        payload.displayedIdentity(for: privacyMode)
    }

    private var heroValue: String {
        payload.displayedHeroValue(for: privacyMode)
    }

    private var heroSuffix: String? {
        payload.displayedHeroSuffix(for: privacyMode)
    }

    var body: some View {
        ZStack {
            background

            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.borderStrong,
                                    accentColor.opacity(0.32),
                                    AIscendTheme.Colors.borderSubtle
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .padding(14)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                header

                switch template {
                case .obsidian:
                    obsidianBody
                case .precision:
                    precisionBody
                case .signal:
                    signalBody
                }

                Spacer(minLength: 0)

                footer
            }
            .padding(28)
        }
        .aspectRatio(4.0 / 5.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.30), radius: 30, x: 0, y: 18)
        .shadow(color: accentColor.opacity(0.18), radius: 28, x: 0, y: 0)
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "090B10"),
                    Color(hex: "10131A"),
                    Color(hex: "0B0E13")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.06)

            Circle()
                .fill(accentColor.opacity(0.22))
                .frame(width: 260, height: 260)
                .blur(radius: 44)
                .offset(x: 126, y: -190)

            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 180, height: 180)
                .blur(radius: 26)
                .offset(x: -150, y: -220)

            Circle()
                .fill(accentColor.opacity(0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 36)
                .offset(x: -160, y: 260)

            LinearGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.16),
                    Color.black.opacity(0.34)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    AIscendBadge(
                        title: payload.eyebrow,
                        symbol: payload.symbol,
                        style: .accent
                    )

                    AIscendBadge(
                        title: privacyMode.title,
                        symbol: privacyMode == .named ? "person.crop.circle" : "lock.fill",
                        style: .subtle
                    )
                }

                if let identityLine {
                    Text(identityLine)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                }
            }

            Spacer(minLength: 0)

            AIscendBrandMark(size: 36, showsWordmark: false)
        }
    }

    private var obsidianBody: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            heroCluster(alignment: .leading)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                Text(payload.title)
                    .font(.system(size: 34, weight: .bold, design: .default))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(payload.subtitle)
                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let callout = payload.callout {
                AIScendShareCallout(text: callout, accent: payload.accent)
            }

            AIScendShareMetricGrid(metrics: metrics, accent: payload.accent)
        }
    }

    private var precisionBody: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            HStack(alignment: .top, spacing: AIscendTheme.Spacing.mediumLarge) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    Text(payload.title)
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)

                    Text(payload.supportingLine)
                        .aiscendTextStyle(.cardTitle, color: accentColor)

                    Text(payload.subtitle)
                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                }

                Spacer(minLength: 0)

                AIScendShareHeroPlate(
                    heroValue: heroValue,
                    heroSuffix: heroSuffix,
                    accent: payload.accent
                )
                .frame(width: 160, height: 188)
            }

            VStack(spacing: AIscendTheme.Spacing.small) {
                ForEach(metrics) { metric in
                    AIScendShareMetricRow(metric: metric, accent: payload.accent)
                }
            }

            if let callout = payload.callout {
                AIScendShareCallout(text: callout, accent: payload.accent)
            }
        }
    }

    private var signalBody: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            Text(payload.title.uppercased())
                .aiscendTextStyle(.eyebrow, color: accentColor)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                heroCluster(alignment: .leading)

                Text(payload.subtitle)
                    .font(.system(size: 24, weight: .semibold, design: .default))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(payload.supportingLine)
                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !metrics.isEmpty {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        ForEach(metrics) { metric in
                            AIScendShareMetricCapsule(metric: metric, accent: payload.accent)
                        }
                    }

                    VStack(spacing: AIscendTheme.Spacing.small) {
                        ForEach(metrics) { metric in
                            AIScendShareMetricCapsule(metric: metric, accent: payload.accent)
                        }
                    }
                }
            }

            if let callout = payload.callout {
                AIScendShareCallout(text: callout, accent: payload.accent)
            }
        }
    }

    private var footer: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(payload.footer)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                Text(payload.shareCaption)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Image(systemName: payload.symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(accentColor)
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.04))
                )
                .overlay(
                    Circle()
                        .stroke(accentColor.opacity(0.28), lineWidth: 1)
                )
        }
    }

    private func heroCluster(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: AIscendTheme.Spacing.small) {
            Text(heroValue)
                .font(.system(size: heroFontSize, weight: .bold, design: .default))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            if let heroSuffix, !heroSuffix.isEmpty {
                Text(heroSuffix.uppercased())
                    .aiscendTextStyle(.caption, color: accentColor)
            }
        }
    }

    private var accentColor: Color {
        payload.accent.tint
    }

    private var heroFontSize: CGFloat {
        switch template {
        case .obsidian:
            94
        case .precision:
            72
        case .signal:
            80
        }
    }
}

struct AIScendShareEntryButton: View {
    let title: String
    let action: () -> Void

    init(
        title: String = "Share",
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AIscendTheme.Spacing.xSmall) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 12, weight: .semibold))

                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                    .lineLimit(1)
            }
            .padding(.horizontal, AIscendTheme.Spacing.small)
            .padding(.vertical, AIscendTheme.Spacing.xSmall)
            .background(
                Capsule(style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.88))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AIScendShareHeroPlate: View {
    let heroValue: String
    let heroSuffix: String?
    let accent: RoutineAccent

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.06),
                            Color.black.opacity(0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(accent.tint.opacity(0.26), lineWidth: 1)

            Circle()
                .fill(accent.tint.opacity(0.18))
                .frame(width: 110, height: 110)
                .blur(radius: 20)

            VStack(spacing: AIscendTheme.Spacing.xSmall) {
                Text(heroValue)
                    .font(.system(size: 46, weight: .bold, design: .default))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .minimumScaleFactor(0.7)

                if let heroSuffix, !heroSuffix.isEmpty {
                    Text(heroSuffix.uppercased())
                        .aiscendTextStyle(.caption, color: accent.tint)
                }
            }
        }
    }
}

private struct AIScendShareMetricGrid: View {
    let metrics: [AIScendShareMetric]
    let accent: RoutineAccent

    private let columns = [
        GridItem(.flexible(), spacing: AIscendTheme.Spacing.small),
        GridItem(.flexible(), spacing: AIscendTheme.Spacing.small)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: AIscendTheme.Spacing.small) {
            ForEach(metrics) { metric in
                AIScendShareMetricCard(metric: metric, accent: accent)
            }
        }
    }
}

private struct AIScendShareMetricCard: View {
    let metric: AIScendShareMetric
    let accent: RoutineAccent

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
            Text(metric.title)
                .aiscendTextStyle(.caption, color: accent.tint)

            Text(metric.value)
                .aiscendTextStyle(.cardTitle)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text(metric.detail)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct AIScendShareMetricRow: View {
    let metric: AIScendShareMetric
    let accent: RoutineAccent

    var body: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            Circle()
                .fill(accent.tint.opacity(0.18))
                .overlay(
                    Circle()
                        .stroke(accent.tint.opacity(0.34), lineWidth: 1)
                )
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(metric.title)
                        .aiscendTextStyle(.caption, color: accent.tint)

                    Spacer(minLength: 0)

                    Text(metric.value)
                        .aiscendTextStyle(.cardTitle)
                        .multilineTextAlignment(.trailing)
                }

                Text(metric.detail)
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
            }
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct AIScendShareMetricCapsule: View {
    let metric: AIScendShareMetric
    let accent: RoutineAccent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(metric.value)
                .aiscendTextStyle(.cardTitle)

            Text(metric.title)
                .aiscendTextStyle(.caption, color: accent.tint)
        }
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct AIScendShareCallout: View {
    let text: String
    let accent: RoutineAccent

    var body: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(accent.tint)
                .padding(.top, 3)

            Text(text)
                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(accent.tint.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(accent.tint.opacity(0.22), lineWidth: 1)
        )
    }
}

#Preview("Share Card") {
    ZStack {
        AIscendBackdrop()

        AIScendShareCardView(
            payload: .scanResult(from: .previewPremium, identityLine: "premium@aiscend.app"),
            template: .obsidian,
            privacyMode: .privateMode
        )
        .padding(24)
    }
    .preferredColorScheme(.dark)
}
