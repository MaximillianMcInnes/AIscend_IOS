//
//  GlowUpTimelineView.swift
//  AIscend
//

import SwiftUI

struct GlowUpTimelineView: View {
    let scans: [GlowUpTimelineScan]
    let comparison: GlowUpComparison
    let isPrivacyModeEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            DashboardSectionHeading(
                eyebrow: "Progress timeline",
                title: "Face progression archive",
                subtitle: "A private timeline of saved scans with score movement and comparison anchors."
            )

            DashboardGlassCard(tone: .premium) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    GlowUpScoreTrendChart(scans: scans)
                        .frame(height: 150)

                    LazyVStack(spacing: AIscendTheme.Spacing.medium) {
                        ForEach(scans) { scan in
                            GlowUpTimelineRow(
                                scan: scan,
                                isLatest: scan.id == comparison.latest.id,
                                isBaseline: scan.id == comparison.baseline.id,
                                isPrivacyModeEnabled: isPrivacyModeEnabled
                            )
                        }
                    }
                }
            }
        }
    }
}

private struct GlowUpScoreTrendChart: View {
    let scans: [GlowUpTimelineScan]

    private var points: [GlowUpTimelineScan] {
        scans
            .filter { $0.score != nil }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .fill(Color.white.opacity(0.045))

                chartGrid

                if points.count >= 2 {
                    GlowUpTrendShape(scans: points)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.accentCyan,
                                    AIscendTheme.Colors.accentGlow,
                                    AIscendTheme.Colors.accentPrimary
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.40), radius: 14, x: 0, y: 0)
                        .padding(AIscendTheme.Spacing.medium)

                    pointMarkers(in: geometry)
                } else {
                    Text("Trend builds after multiple scored scans")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }

    private var chartGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { _ in
                Rectangle()
                    .fill(Color.white.opacity(0.055))
                    .frame(height: 1)

                Spacer(minLength: 0)
            }
        }
        .padding(AIscendTheme.Spacing.medium)
    }

    private func pointMarkers(in geometry: GeometryProxy) -> some View {
        let scores = points.compactMap(\.score)
        let minScore = scores.min() ?? 0
        let maxScore = scores.max() ?? 100
        let range = max(maxScore - minScore, 1)
        let width = max(geometry.size.width - (AIscendTheme.Spacing.medium * 2), 1)
        let height = max(geometry.size.height - (AIscendTheme.Spacing.medium * 2), 1)

        return ZStack {
            ForEach(Array(points.enumerated()), id: \.element.id) { index, scan in
                if let score = scan.score {
                    let x = AIscendTheme.Spacing.medium + (CGFloat(index) / CGFloat(max(points.count - 1, 1))) * width
                    let y = AIscendTheme.Spacing.medium + (1 - CGFloat((score - minScore) / range)) * height

                    Circle()
                        .fill(AIscendTheme.Colors.textPrimary)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                        .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.8), radius: 8, x: 0, y: 0)
                }
            }
        }
    }
}

private struct GlowUpTrendShape: Shape {
    let scans: [GlowUpTimelineScan]

    func path(in rect: CGRect) -> Path {
        let scores = scans.compactMap(\.score)
        let minScore = scores.min() ?? 0
        let maxScore = scores.max() ?? 100
        let range = max(maxScore - minScore, 1)

        var path = Path()
        for (index, scan) in scans.enumerated() {
            guard let score = scan.score else {
                continue
            }

            let x = rect.minX + (CGFloat(index) / CGFloat(max(scans.count - 1, 1))) * rect.width
            let y = rect.maxY - CGFloat((score - minScore) / range) * rect.height
            let point = CGPoint(x: x, y: y)

            if path.isEmpty {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        return path
    }
}

private struct GlowUpTimelineRow: View {
    let scan: GlowUpTimelineScan
    let isLatest: Bool
    let isBaseline: Bool
    let isPrivacyModeEnabled: Bool

    private var dateText: String {
        scan.date == .distantPast ? "Saved scan" : scan.date.formatted(date: .abbreviated, time: .omitted)
    }

    private var scoreText: String {
        guard let score = scan.score else {
            return "--"
        }

        return "\(Int(score.rounded()))"
    }

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.medium) {
            timelinePhoto

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                HStack(spacing: AIscendTheme.Spacing.xSmall) {
                    if isLatest {
                        AIscendBadge(title: "Latest", symbol: "clock.fill", style: .accent)
                    }

                    if isBaseline {
                        AIscendBadge(title: "Baseline", symbol: "scope", style: .neutral)
                    }
                }

                Text(dateText)
                    .aiscendTextStyle(.cardTitle)

                Text(scan.tier)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
            }

            Spacer(minLength: AIscendTheme.Spacing.small)

            VStack(alignment: .trailing, spacing: 2) {
                Text(scoreText)
                    .aiscendTextStyle(.metricCompact)
                    .monospacedDigit()

                Text("score")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(Color.white.opacity(isLatest || isBaseline ? 0.075 : 0.045))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(isLatest ? AIscendTheme.Colors.accentGlow.opacity(0.30) : AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private var timelinePhoto: some View {
        let source = ScanPhotoSource(rawValue: scan.frontImageRawValue ?? scan.sideImageRawValue)

        return ZStack {
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.surfaceInteractive,
                            AIscendTheme.Colors.cardGradientEnd
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            #if canImport(UIKit)
            if source.hasImageSource {
                AIscendCachedImage(
                    localURL: source.localURL,
                    remoteURL: source.remoteURL,
                    maxPixelDimension: 220
                ) {
                    Image(systemName: "person.crop.rectangle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(AIscendTheme.Colors.textMuted)
                }
                    .blur(radius: isPrivacyModeEnabled ? 10 : 0)
                    .clipped()
            } else {
                Image(systemName: "person.crop.rectangle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AIscendTheme.Colors.textMuted)
            }
            #else
            Image(systemName: "person.crop.rectangle")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(AIscendTheme.Colors.textMuted)
            #endif

            if isPrivacyModeEnabled {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .padding(7)
                    .background(Circle().fill(Color.black.opacity(0.46)))
            }
        }
        .frame(width: 58, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

