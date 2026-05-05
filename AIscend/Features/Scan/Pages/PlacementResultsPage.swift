//
//  PlacementResultsPage.swift
//  AIscend
//

import Foundation
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
        ResultsFullscreenShell(
            title: "Your placement",
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
                PlacementClassPanel(
                    tierTitle: result?.tierTitle ?? "Prime",
                    percentile: percentile,
                    accessLevel: result?.accessLevel ?? .free
                )

                PlacementBellCurveHero(percentile: percentile)

                PlacementBestFeatureCard(feature: bestFeature)

                ResultsAuroraPanel(intensity: .quiet, cornerRadius: 26) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        Text("What this means")
                            .aiscendTextStyle(.cardTitle)

                        Text(result?.placementNarrative ?? "AIScend places this scan into a stronger-than-average band.")
                            .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                ResultsNextButton(
                    title: "Continue to Harmony",
                    action: onContinue
                )
            }
        }
    }

    private var percentile: Int {
        min(max(result?.percentile ?? 18, 1), 100)
    }

    private var bestFeature: PlacementFeature {
        let fallback = result?.overallScore ?? 72
        let candidates = [
            PlacementFeature(title: "Overall", value: result?.overallScore ?? fallback, note: "The total read is your headline signal."),
            PlacementFeature(title: "Potential", value: result?.potentialScore ?? min(fallback + 6, 99), note: "There is visible upside left in the scan."),
            PlacementFeature(title: "Eyes", value: result?.payload.scores.eyes ?? max(fallback - 3, 0), note: "Keep this strong and avoid over-correcting."),
            PlacementFeature(title: "Skin", value: result?.payload.scores.skin ?? max(fallback - 4, 0), note: "Surface quality supports the overall read."),
            PlacementFeature(title: "Jaw", value: result?.payload.scores.jaw ?? max(fallback - 1, 0), note: "Lower-third structure is carrying visual weight."),
            PlacementFeature(title: "Side", value: result?.payload.scores.side ?? max(fallback - 2, 0), note: "Profile balance shapes the total impression.")
        ]

        return candidates.max(by: { $0.value < $1.value }) ?? candidates[0]
    }
}

private struct PlacementClassPanel: View {
    let tierTitle: String
    let percentile: Int
    let accessLevel: ScanResultsAccess

    var body: some View {
        ResultsAuroraPanel(intensity: .standard, cornerRadius: 28) {
            HStack(alignment: .center, spacing: AIscendTheme.Spacing.medium) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                    Text("YOU ARE:")
                        .aiscendTextStyle(.eyebrow, color: AIscendTheme.Colors.textMuted)

                    HStack(alignment: .firstTextBaseline, spacing: AIscendTheme.Spacing.xSmall) {
                        Text(tierTitle)
                            .font(.system(size: 36, weight: .black, design: .default))
                            .foregroundStyle(AIscendTheme.Colors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.66)

                        Text("class")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: AIscendTheme.Spacing.small)

                VStack(alignment: .trailing, spacing: 5) {
                    Text("PLACEMENT")
                        .aiscendTextStyle(.eyebrow, color: AIscendTheme.Colors.textMuted)

                    Text("Top \(percentile)%")
                        .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
                        .monospacedDigit()

                    Text(accessLevel == .premium ? "Full read" : "Preview")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                }
                .padding(.horizontal, AIscendTheme.Spacing.medium)
                .padding(.vertical, AIscendTheme.Spacing.small)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.black.opacity(0.24))
                        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            }
        }
    }
}

private struct PlacementBellCurveHero: View {
    let percentile: Int

    private var markerProgress: Double {
        min(max(1 - (Double(percentile) / 100.0), 0.04), 0.98)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            GeometryReader { geometry in
                let size = geometry.size
                let markerX = size.width * CGFloat(markerProgress)

                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "2A0757"),
                                    Color(hex: "180029"),
                                    Color(hex: "09030F")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RadialGradient(
                        colors: [
                            AIscendTheme.Colors.accentPrimary.opacity(0.46),
                            Color(hex: "E858FF").opacity(0.16),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 230
                    )

                    PlacementBellFill()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.accentPrimary.opacity(0.38),
                                    Color(hex: "D64EFF").opacity(0.18),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .padding(.horizontal, AIscendTheme.Spacing.small)
                        .padding(.bottom, 58)
                        .padding(.top, 52)

                    PlacementBellLine()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.accentPrimary,
                                    AIscendTheme.Colors.accentGlow,
                                    Color(hex: "D64EFF")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                        )
                        .padding(.horizontal, AIscendTheme.Spacing.small)
                        .padding(.bottom, 58)
                        .padding(.top, 52)
                        .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.42), radius: 18, x: 0, y: 0)

                    ForEach([0.40, 0.50, 0.60], id: \.self) { xRatio in
                        Rectangle()
                            .stroke(style: StrokeStyle(lineWidth: 1.4, dash: [7, 7]))
                            .foregroundStyle(Color.white.opacity(xRatio == 0.50 ? 0.34 : 0.16))
                            .frame(width: 1, height: size.height * 0.52)
                            .offset(x: size.width * xRatio, y: -size.height * 0.18)
                    }

                    Rectangle()
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 7]))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary.opacity(0.70))
                        .frame(width: 1, height: size.height * 0.60)
                        .offset(x: markerX, y: -size.height * 0.18)

                    Rectangle()
                        .fill(Color.white.opacity(0.10))
                        .frame(height: 2)
                        .offset(y: -58)
                }
                .overlay(alignment: .topTrailing) {
                    Text("Top \(percentile)%")
                        .aiscendTextStyle(.buttonLabel, color: AIscendTheme.Colors.textPrimary)
                        .monospacedDigit()
                        .padding(.horizontal, AIscendTheme.Spacing.medium)
                        .padding(.vertical, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.black.opacity(0.44))
                                .background(.ultraThinMaterial, in: Capsule(style: .continuous))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )
                        .padding(AIscendTheme.Spacing.medium)
                }
            }
        }
        .frame(height: 330)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.16),
                            AIscendTheme.Colors.accentGlow.opacity(0.22),
                            Color(hex: "E858FF").opacity(0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.16), radius: 28, x: 0, y: 18)
    }
}

private struct PlacementBellLine: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            for index in 0...120 {
                let t = CGFloat(index) / 120
                let x = rect.minX + t * rect.width
                let normalized = Double((t - 0.5) * 4.8)
                let gaussian = CGFloat(exp(-0.5 * normalized * normalized))
                let y = rect.maxY - rect.height * (0.06 + 0.78 * gaussian)

                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
    }
}

private struct PlacementBellFill: Shape {
    func path(in rect: CGRect) -> Path {
        var path = PlacementBellLine().path(in: rect)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct PlacementFeature: Identifiable {
    let id = UUID()
    let title: String
    let value: Double
    let note: String

    var clampedValue: Double {
        min(max(value.isFinite ? value : 0, 0), 100)
    }
}

private struct PlacementBestFeatureCard: View {
    let feature: PlacementFeature

    var body: some View {
        ResultsAuroraPanel(intensity: .quiet, cornerRadius: 26) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                        Text("BEST SCORING FEATURE")
                            .aiscendTextStyle(.eyebrow, color: AIscendTheme.Colors.textMuted)

                        Text(feature.title)
                            .aiscendTextStyle(.cardTitle)
                    }

                    Spacer()

                    Text("\(Int(feature.clampedValue.rounded()))/100")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                        .monospacedDigit()
                        .padding(.horizontal, AIscendTheme.Spacing.small)
                        .padding(.vertical, 6)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.black.opacity(0.28))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.12))

                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AIscendTheme.Colors.accentGlow,
                                        AIscendTheme.Colors.accentPrimary,
                                        Color(hex: "E858FF")
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(geometry.size.width * CGFloat(feature.clampedValue / 100), 10))
                            .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.32), radius: 10, x: 0, y: 0)
                    }
                }
                .frame(height: 11)

                Text(feature.note)
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
            }
        }
    }
}
