//
//  ChartSection.swift
//  AIscend
//

import Charts
import SwiftUI

struct ChartSection: View {
    let snapshot: DashboardSnapshot

    private var highlightedTrendPoint: DashboardTrendPoint {
        let midpoint = snapshot.trendPoints.count / 2
        return snapshot.trendPoints.indices.contains(midpoint)
            ? snapshot.trendPoints[midpoint]
            : (snapshot.trendPoints.last ?? DashboardTrendPoint(label: "Now", score: Double(snapshot.score)))
    }

    private var minTrendValue: Double {
        let values = snapshot.trendPoints.map(\.score)
        return max((values.min() ?? Double(snapshot.score)) - 4, 0)
    }

    private var maxTrendValue: Double {
        snapshot.trendPoints.map(\.score).max() ?? Double(snapshot.score)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                    Text("Score / cycle")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                    Text(snapshot.heroStatement)
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: AIscendTheme.Spacing.small)

                Text("\(Int(highlightedTrendPoint.score))")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .padding(.horizontal, AIscendTheme.Spacing.small)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AIscendTheme.Colors.accentPrimary)
                    )
            }

            Chart {
                ForEach(snapshot.trendPoints) { point in
                    AreaMark(
                        x: .value("Period", point.label),
                        yStart: .value("Baseline", minTrendValue),
                        yEnd: .value("Score", point.score)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                AIscendTheme.Colors.accentPrimary.opacity(0.22),
                                AIscendTheme.Colors.accentGlow.opacity(0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Period", point.label),
                        y: .value("Score", point.score)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(AIscendTheme.Colors.accentGlow)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                }

                RuleMark(x: .value("Selected", highlightedTrendPoint.label))
                    .foregroundStyle(AIscendTheme.Colors.textMuted.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

                PointMark(
                    x: .value("Selected", highlightedTrendPoint.label),
                    y: .value("Score", highlightedTrendPoint.score)
                )
                .symbolSize(260)
                .foregroundStyle(AIscendTheme.Colors.accentGlow)

                PointMark(
                    x: .value("Selected", highlightedTrendPoint.label),
                    y: .value("Score", highlightedTrendPoint.score)
                )
                .symbolSize(90)
                .foregroundStyle(Color.white)
            }
            .chartLegend(.hidden)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: snapshot.trendPoints.map(\.label)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0))
                    AxisTick(stroke: StrokeStyle(lineWidth: 0))
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(AIscendTheme.Colors.textMuted)
                        }
                    }
                }
            }
            .chartYScale(domain: minTrendValue...(maxTrendValue + 4))
            .frame(maxWidth: .infinity)
            .frame(height: 220)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "151515").opacity(0.98),
                            AIscendTheme.Colors.surfaceMuted.opacity(0.96)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.34), radius: 24, x: 0, y: 16)
    }
}