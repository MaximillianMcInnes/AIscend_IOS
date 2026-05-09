//
//  NutritionAnalyticsView.swift
//  AIscend
//

import SwiftUI

struct NutritionAnalyticsView: View {
    let summary: NutritionDailySummary
    let bodyEntries: [NutritionBodyCompositionEntry]
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    topBar

                    AIscendSectionHeader(
                        eyebrow: "Analytics",
                        title: "Metabolic aesthetics",
                        subtitle: "Rolling nutrition and body composition intelligence for facial sharpness forecasting.",
                        prominence: .hero
                    )

                    DashboardGlassCard(tone: .premium) {
                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                            AIscendSectionHeader(
                                eyebrow: "7 Day Signal",
                                title: "Aesthetic optimisation trend"
                            )

                            NutritionTrendLine(points: summary.trend)
                                .frame(height: 180)
                        }
                    }

                    DashboardGlassCard {
                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                            AIscendSectionHeader(
                                eyebrow: "Body Composition",
                                title: "Sharpness forecast",
                                subtitle: "Weight, lean mass, estimated body fat, and water retention are interpreted together."
                            )

                            ForEach(bodyEntries.sorted { $0.date > $1.date }.prefix(5)) { entry in
                                bodyRow(entry)
                            }
                        }
                    }

                    DashboardGlassCard {
                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                            AIscendSectionHeader(
                                eyebrow: "Reports",
                                title: "Transformation cadence",
                                subtitle: "Weekly and monthly reports are ready for deeper retention loops."
                            )

                            reportRow(title: "Weekly report", detail: "Protein streak, hydration quality, sodium drift, and face optimisation trend.", symbol: "calendar.badge.clock")
                            reportRow(title: "Monthly transformation", detail: "Body composition, water retention, and facial sharpness projection.", symbol: "chart.xyaxis.line")
                        }
                    }
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, AIscendTheme.Spacing.xxLarge)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(AIscendTheme.Colors.surfaceGlass))
                    .overlay(Circle().stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    private func bodyRow(_ entry: NutritionBodyCompositionEntry) -> some View {
        HStack(spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: "figure", accent: .mint, size: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "%.1fkg / %.1f%% BF", entry.weightKg, entry.estimatedBodyFat))
                    .aiscendTextStyle(.buttonLabel)

                Text(String(format: "Lean %.1fkg / retention %d", entry.leanMassKg, Int(entry.waterRetention)))
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }

            Spacer()

            Text("\(entry.facialSharpnessForecast)")
                .aiscendTextStyle(.metricCompact)
                .monospacedDigit()
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.62))
        )
    }

    private func reportRow(title: String, detail: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: symbol, accent: .sky, size: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .aiscendTextStyle(.cardTitle)

                Text(detail)
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct NutritionTrendLine: View {
    let points: [NutritionTrendPoint]
    @State private var reveal = false

    var body: some View {
        GeometryReader { geometry in
            let values = points.map(\.score)
            let minValue = values.min() ?? 0
            let maxValue = values.max() ?? 100
            let range = max(maxValue - minValue, 1)

            ZStack(alignment: .bottomLeading) {
                VStack {
                    ForEach(0..<4, id: \.self) { _ in
                        Rectangle()
                            .fill(AIscendTheme.Colors.divider)
                            .frame(height: 1)
                        Spacer()
                    }
                }

                Path { path in
                    for index in points.indices {
                        let x = geometry.size.width * CGFloat(index) / CGFloat(max(points.count - 1, 1))
                        let normalized = (points[index].score - minValue) / range
                        let y = geometry.size.height - (geometry.size.height * CGFloat(normalized))

                        if index == points.startIndex {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .trim(from: 0, to: reveal ? 1 : 0)
                .stroke(
                    LinearGradient(
                        colors: [AIscendTheme.Colors.accentGlow, AIscendTheme.Colors.accentCyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                )
                .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.26), radius: 14, x: 0, y: 0)

                HStack {
                    ForEach(points) { point in
                        VStack(spacing: 4) {
                            Spacer()
                            Text(point.label)
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9)) {
                reveal = true
            }
        }
    }
}
