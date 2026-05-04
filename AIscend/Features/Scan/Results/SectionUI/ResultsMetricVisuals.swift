//
//  ResultsMetricVisuals.swift
//  AIscend
//

import Foundation
import SwiftUI

struct BellCurveMini: View {
    let percentile: Double
    var typicalRange: ClosedRange<Double> = 35...65
    var label: String? = nil

    private var clampedPercentile: Double {
        min(max(percentile.isFinite ? percentile : 50, 0), 100)
    }

    private var clampedTypicalRange: ClosedRange<Double> {
        let lower = min(max(typicalRange.lowerBound, 0), 100)
        let upper = min(max(typicalRange.upperBound, lower), 100)
        return lower...upper
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
            GeometryReader { geometry in
                let size = geometry.size
                let markerX = size.width * CGFloat(clampedPercentile / 100)
                let range = clampedTypicalRange
                let rangeStart = size.width * CGFloat(range.lowerBound / 100)
                let rangeWidth = size.width * CGFloat((range.upperBound - range.lowerBound) / 100)

                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.035))

                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(AIscendTheme.Colors.accentCyan.opacity(0.12))
                        .frame(width: max(rangeWidth, 4), height: size.height * 0.52)
                        .offset(x: rangeStart, y: -size.height * 0.08)

                    bellFill(in: size)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.accentGlow.opacity(0.16),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    bellLine(in: size)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.accentGlow,
                                    AIscendTheme.Colors.accentPrimary,
                                    Color(hex: "E858FF")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.42), radius: 8, x: 0, y: 0)

                    Rectangle()
                        .fill(AIscendTheme.Colors.textPrimary)
                        .frame(width: 2, height: size.height * 0.72)
                        .offset(x: markerX, y: -size.height * 0.08)
                        .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.65), radius: 8, x: 0, y: 0)
                }
            }
            .frame(height: 92)

            HStack {
                Text(label ?? "Percentile \(Int(clampedPercentile.rounded()))")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)

                Spacer()

                Text("Typical \(Int(clampedTypicalRange.lowerBound))-\(Int(clampedTypicalRange.upperBound))")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }
        }
    }

    private func bellLine(in size: CGSize) -> Path {
        Path { path in
            for index in 0...96 {
                let t = CGFloat(index) / 96
                let x = t * size.width
                let normalized = Double((t - 0.5) * 6)
                let gaussian = CGFloat(exp(-0.5 * normalized * normalized))
                let y = size.height * (0.86 - 0.66 * gaussian)

                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
    }

    private func bellFill(in size: CGSize) -> Path {
        var path = bellLine(in: size)
        path.addLine(to: CGPoint(x: size.width, y: size.height * 0.92))
        path.addLine(to: CGPoint(x: 0, y: size.height * 0.92))
        path.closeSubpath()
        return path
    }
}

struct RangeZoneBar: View {
    let value: Double
    let domain: ClosedRange<Double>
    let idealRange: ClosedRange<Double>
    var warningRanges: [ClosedRange<Double>] = []
    var valueLabel: String? = nil
    var targetLabel: String? = nil

    private var safeDomain: ClosedRange<Double> {
        if domain.upperBound > domain.lowerBound {
            return domain
        }

        return 0...1
    }

    private var clampedValue: Double {
        min(max(value.isFinite ? value : safeDomain.lowerBound, safeDomain.lowerBound), safeDomain.upperBound)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let pointerX = xOffset(for: clampedValue, width: width)

                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color(hex: "7A1F3A").opacity(0.66))

                    ForEach(warningRanges.indices, id: \.self) { index in
                        zone(range: warningRanges[index], width: width, color: AIscendTheme.Colors.warning.opacity(0.72))
                    }

                    zone(range: idealRange, width: width, color: AIscendTheme.Colors.success.opacity(0.78))

                    VStack(spacing: 3) {
                        Triangle()
                            .fill(AIscendTheme.Colors.textPrimary)
                            .frame(width: 10, height: 7)

                        RoundedRectangle(cornerRadius: 999, style: .continuous)
                            .fill(AIscendTheme.Colors.textPrimary)
                            .frame(width: 2, height: 22)
                    }
                    .offset(x: min(max(pointerX - 5, 0), max(width - 10, 0)), y: -17)
                    .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.55), radius: 8, x: 0, y: 0)
                }
                .clipShape(Capsule(style: .continuous))
            }
            .frame(height: 18)
            .padding(.top, 16)

            HStack(alignment: .firstTextBaseline) {
                Text(valueLabel ?? "You: \(formatted(clampedValue))")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)

                Spacer()

                Text(targetLabel ?? "Target \(formatted(idealRange.lowerBound))-\(formatted(idealRange.upperBound))")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }
        }
    }

    private func zone(range: ClosedRange<Double>, width: CGFloat, color: Color) -> some View {
        let lower = min(max(range.lowerBound, safeDomain.lowerBound), safeDomain.upperBound)
        let upper = min(max(range.upperBound, lower), safeDomain.upperBound)
        let start = xOffset(for: lower, width: width)
        let end = xOffset(for: upper, width: width)

        return Capsule(style: .continuous)
            .fill(color)
            .frame(width: max(end - start, 4))
            .offset(x: start)
    }

    private func xOffset(for rawValue: Double, width: CGFloat) -> CGFloat {
        let domain = safeDomain
        let clamped = min(max(rawValue, domain.lowerBound), domain.upperBound)
        let ratio = (clamped - domain.lowerBound) / (domain.upperBound - domain.lowerBound)
        return width * CGFloat(ratio)
    }

    private func formatted(_ value: Double) -> String {
        if abs(value.rounded() - value) < 0.05 {
            return "\(Int(value.rounded()))"
        }

        return String(format: "%.1f", value)
    }
}

struct RatioPlacementCard: View {
    let title: String
    let value: String
    let detail: String
    var percentile: Double? = nil
    var targetRange: ClosedRange<Double>? = nil

    var body: some View {
        ResultsAuroraPanel(intensity: .quiet, cornerRadius: 26) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                        Text(value)
                            .aiscendTextStyle(.metricCompact, color: AIscendTheme.Colors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.74)
                    }

                    Spacer(minLength: AIscendTheme.Spacing.small)

                    if let percentile {
                        Text("P\(Int(min(max(percentile, 0), 100).rounded()))")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                            .padding(.horizontal, AIscendTheme.Spacing.small)
                            .padding(.vertical, 7)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(AIscendTheme.Colors.accentGlow.opacity(0.14))
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(AIscendTheme.Colors.accentGlow.opacity(0.26), lineWidth: 1)
                            )
                    }
                }

                Text(detail)
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let percentile {
                    BellCurveMini(
                        percentile: percentile,
                        typicalRange: targetRange ?? 35...65,
                        label: "Placement \(Int(min(max(percentile, 0), 100).rounded()))"
                    )
                }
            }
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}
