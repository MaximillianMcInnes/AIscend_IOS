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
                let chartRect = CGRect(
                    x: 12,
                    y: 8,
                    width: max(size.width - 24, 1),
                    height: max(size.height - 16, 1)
                )
                let markerX = xPosition(for: clampedPercentile, in: chartRect)
                let range = clampedTypicalRange
                let rangeStart = xPosition(for: range.lowerBound, in: chartRect)
                let rangeEnd = xPosition(for: range.upperBound, in: chartRect)

                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.035))

                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(AIscendTheme.Colors.accentCyan.opacity(0.12))
                        .frame(width: max(rangeEnd - rangeStart, 4), height: chartRect.height * 0.54)
                        .position(x: rangeStart + max(rangeEnd - rangeStart, 4) / 2, y: chartRect.midY + chartRect.height * 0.08)

                    bellFill(in: chartRect)
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

                    bellLine(in: chartRect)
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
                        .frame(width: 2, height: chartRect.height * 0.74)
                        .position(x: markerX, y: chartRect.midY + chartRect.height * 0.04)
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

    private func xPosition(for percentile: Double, in rect: CGRect) -> CGFloat {
        rect.minX + rect.width * CGFloat(min(max(percentile, 0), 100) / 100)
    }

    private func bellLine(in rect: CGRect) -> Path {
        Path { path in
            for index in 0...96 {
                let t = CGFloat(index) / 96
                let x = rect.minX + t * rect.width
                let normalized = Double((t - 0.5) * 6)
                let gaussian = CGFloat(exp(-0.5 * normalized * normalized))
                let y = rect.minY + rect.height * (0.88 - 0.68 * gaussian)

                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
    }

    private func bellFill(in rect: CGRect) -> Path {
        var path = bellLine(in: rect)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
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
                let markerX = min(max(pointerX, 8), max(width - 8, 8))
                let barHeight: CGFloat = 16

                ZStack(alignment: .topLeading) {
                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(Color(hex: "7A1F3A").opacity(0.66))

                        ForEach(warningRanges.indices, id: \.self) { index in
                            zone(
                                range: warningRanges[index],
                                width: width,
                                height: barHeight,
                                color: AIscendTheme.Colors.warning.opacity(0.72)
                            )
                        }

                        zone(
                            range: idealRange,
                            width: width,
                            height: barHeight,
                            color: AIscendTheme.Colors.success.opacity(0.78)
                        )
                    }
                    .frame(height: barHeight)
                    .clipShape(Capsule(style: .continuous))
                    .position(x: width / 2, y: 24)

                    VStack(spacing: 4) {
                        Circle()
                            .fill(AIscendTheme.Colors.textPrimary)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(AIscendTheme.Colors.accentGlow.opacity(0.72), lineWidth: 2)
                            )

                        RoundedRectangle(cornerRadius: 999, style: .continuous)
                            .fill(AIscendTheme.Colors.textPrimary)
                            .frame(width: 2, height: 24)
                    }
                    .position(x: markerX, y: 15)
                    .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.55), radius: 8, x: 0, y: 0)
                }
            }
            .frame(height: 46)

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

    private func zone(range: ClosedRange<Double>, width: CGFloat, height: CGFloat, color: Color) -> some View {
        let lower = min(max(range.lowerBound, safeDomain.lowerBound), safeDomain.upperBound)
        let upper = min(max(range.upperBound, lower), safeDomain.upperBound)
        let start = xOffset(for: lower, width: width)
        let end = xOffset(for: upper, width: width)

        return Capsule(style: .continuous)
            .fill(color)
            .frame(height: height)
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
    let userValue: Double
    let percentile: Double
    let typicalRange: ClosedRange<Double>
    let domain: ClosedRange<Double>
    let idealRange: ClosedRange<Double>
    var warningRanges: [ClosedRange<Double>] = []
    let mean: Double
    let sd: Double

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            HStack(alignment: .center, spacing: AIscendTheme.Spacing.small) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .aiscendTextStyle(.eyebrow, color: AIscendTheme.Colors.textMuted)

                    HStack(spacing: AIscendTheme.Spacing.xSmall) {
                        statusChip

                        Text("You \(formatted(userValue, decimals: 3))")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                            .monospacedDigit()
                    }
                }

                Spacer(minLength: AIscendTheme.Spacing.small)

                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AIscendTheme.Colors.accentGlow)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(AIscendTheme.Colors.accentGlow.opacity(0.15)))
                    .overlay(Circle().stroke(AIscendTheme.Colors.accentGlow.opacity(0.28), lineWidth: 1))
            }
            .padding(AIscendTheme.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.055))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )

            ResultsAuroraPanel(intensity: .quiet, cornerRadius: 26) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                    RangeZoneBar(
                        value: userValue,
                        domain: domain,
                        idealRange: idealRange,
                        warningRanges: warningRanges,
                        valueLabel: "You: \(formatted(userValue, decimals: 3))",
                        targetLabel: "Ideal \(formatted(idealRange.lowerBound, decimals: 3))-\(formatted(idealRange.upperBound, decimals: 3))"
                    )

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                        HStack {
                            miniMetric(title: "Mean", value: formatted(mean, decimals: 3))
                            miniMetric(title: "SD", value: formatted(sd, decimals: 3))
                        }

                        BellCurveMini(
                            percentile: percentile,
                            typicalRange: typicalRange,
                            label: "Placement P\(Int(clampedPercentile.rounded()))"
                        )
                    }
                }
            }
        }
    }

    private var clampedPercentile: Double {
        min(max(percentile.isFinite ? percentile : 50, 0), 100)
    }

    private var zoneStatus: (title: String, tint: Color) {
        if idealRange.contains(userValue) {
            return ("Ideal", AIscendTheme.Colors.success)
        }

        if warningRanges.contains(where: { $0.contains(userValue) }) {
            return ("Borderline", AIscendTheme.Colors.warning)
        }

        return ("Outside", Color(hex: "FF6B7A"))
    }

    private var statusChip: some View {
        let status = zoneStatus
        return HStack(spacing: 6) {
            Circle()
                .fill(status.tint)
                .frame(width: 6, height: 6)
                .shadow(color: status.tint.opacity(0.64), radius: 8, x: 0, y: 0)

            Text(status.title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
        }
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, 6)
        .background(Capsule(style: .continuous).fill(status.tint.opacity(0.15)))
        .overlay(Capsule(style: .continuous).stroke(status.tint.opacity(0.30), lineWidth: 1))
    }

    private func miniMetric(title: String, value: String) -> some View {
        HStack(spacing: 5) {
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            Text(value)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                .monospacedDigit()
        }
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, 7)
        .background(Capsule(style: .continuous).fill(Color.white.opacity(0.06)))
    }

    private func formatted(_ value: Double, decimals: Int) -> String {
        if abs(value.rounded() - value) < 0.0005 {
            return "\(Int(value.rounded()))"
        }

        return String(format: "%.\(decimals)f", value)
    }
}
