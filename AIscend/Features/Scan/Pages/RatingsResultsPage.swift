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
        ResultsFullscreenShell(
            title: "Your results",
            subtitle: subtitle,
            step: pageIndex + 1,
            total: totalPages,
            showsBottomCTA: false,
            topRight: {
                AIScendShareEntryButton(title: "Share", action: onShare)
            },
            bottomCTA: {
                EmptyView()
            }
        ) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                ResultsOverviewHero(
                    result: result,
                    pageIndex: pageIndex,
                    totalPages: totalPages
                )

                ResultsOverviewScoreGrid(items: overviewScores)

                ResultsNextButton(
                    title: "Continue to Placement",
                    action: onContinue
                )
            }
        }
    }

    private var overviewScores: [ResultsOverviewScoreItem] {
        let fallback = result?.overallScore ?? 72
        return [
            ResultsOverviewScoreItem(title: "Overall", value: result?.overallScore ?? fallback),
            ResultsOverviewScoreItem(title: "Potential", value: result?.potentialScore ?? min(fallback + 6, 99)),
            ResultsOverviewScoreItem(title: "Eyes", value: result?.payload.scores.eyes ?? max(fallback - 3, 0)),
            ResultsOverviewScoreItem(title: "Skin", value: result?.payload.scores.skin ?? max(fallback - 4, 0)),
            ResultsOverviewScoreItem(title: "Jaw", value: result?.payload.scores.jaw ?? max(fallback - 1, 0)),
            ResultsOverviewScoreItem(title: "Side", value: result?.payload.scores.side ?? max(fallback - 2, 0))
        ]
    }
}

private struct ResultsOverviewHero: View {
    let result: PersistedScanRecord?
    let pageIndex: Int
    let totalPages: Int

    var body: some View {
        ResultsAuroraPanel(intensity: .hero, cornerRadius: 32) {
            VStack(spacing: AIscendTheme.Spacing.large) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    ResultsPhotoCard(
                        title: "Front",
                        rawValue: result?.meta.frontUrl
                    )

                    ResultsPhotoCard(
                        title: "Profile",
                        rawValue: result?.meta.sideUrl
                    )
                }

                VStack(spacing: AIscendTheme.Spacing.medium) {
                    ResultsBrandPill()

                    HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                            Text(result?.tierTitle ?? "Prime")
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                                .textCase(.uppercase)

                            Text(result?.headline ?? "AIScend sees a strong base with visible upside.")
                                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: AIscendTheme.Spacing.small)

                        VStack(alignment: .trailing, spacing: 6) {
                            Text("\(pageIndex + 1)/\(max(totalPages, 1))")
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                                .monospacedDigit()

                            ResultsMicroProgress(step: pageIndex + 1, total: totalPages)
                                .frame(width: 110)
                        }
                    }
                }
            }
        }
    }
}

private struct ResultsBrandPill: View {
    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            Image(systemName: "triangle")
                .font(.system(size: 13, weight: .bold))

            Text("AISCEND.CO.UK")
                .font(.system(size: 13, weight: .black, design: .default))
                .tracking(5)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .foregroundStyle(AIscendTheme.Colors.textPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.accentPrimary,
                            Color(hex: "A827FF"),
                            Color(hex: "E23BE8")
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.36), radius: 24, x: 0, y: 10)
    }
}

private struct ResultsOverviewScoreGrid: View {
    let items: [ResultsOverviewScoreItem]

    private let columns = [
        GridItem(.flexible(), spacing: AIscendTheme.Spacing.small),
        GridItem(.flexible(), spacing: AIscendTheme.Spacing.small)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: AIscendTheme.Spacing.small) {
            ForEach(items) { item in
                ResultsOverviewScoreTile(item: item)
            }
        }
    }
}

private struct ResultsOverviewScoreItem: Identifiable {
    let id = UUID()
    let title: String
    let value: Double

    var clampedValue: Double {
        min(max(value.isFinite ? value : 0, 0), 100)
    }

    var displayValue: String {
        ScanJSONValue.formatted(number: clampedValue.rounded())
    }
}

private struct ResultsOverviewScoreTile: View {
    let item: ResultsOverviewScoreItem

    var body: some View {
        VStack(spacing: AIscendTheme.Spacing.small) {
            Text(item.title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.76)

            ResultsScoreRing(
                value: item.clampedValue,
                text: item.displayValue
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color(hex: "211033").opacity(0.72),
                            Color.white.opacity(0.035)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 10)
    }
}

private struct ResultsScoreRing: View {
    let value: Double
    let text: String

    private var progress: Double {
        min(max(value / 100, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 12)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: "7CF35A"),
                            AIscendTheme.Colors.success,
                            AIscendTheme.Colors.accentMint
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: AIscendTheme.Colors.success.opacity(0.40), radius: 10, x: 0, y: 0)

            VStack(spacing: 2) {
                Text(text)
                    .font(.system(size: 26, weight: .black, design: .default))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)

                Text("/100")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                    .monospacedDigit()
            }
        }
        .frame(width: 94, height: 94)
    }
}

private struct ResultsMicroProgress: View {
    let step: Int
    let total: Int

    private var progress: Double {
        guard total > 0 else {
            return 0
        }

        return min(max(Double(step) / Double(total), 0), 1)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.14))

                Capsule(style: .continuous)
                    .fill(AIscendTheme.Colors.accentGlow)
                    .frame(width: max(geometry.size.width * progress, 10))
                    .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.45), radius: 10, x: 0, y: 0)
            }
        }
        .frame(height: 7)
    }
}
