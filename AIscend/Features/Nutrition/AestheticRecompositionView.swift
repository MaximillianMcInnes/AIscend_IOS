//
//  AestheticRecompositionView.swift
//  AIscend
//

import SwiftUI
import UIKit

struct AestheticRecompositionView: View {
    @ObservedObject var store: NutritionStore
    let onDismiss: () -> Void

    @State private var currentWeightKg: Double
    @State private var targetWeightKg: Double
    @State private var currentBodyFat: Double
    @State private var targetBodyFat: Double
    @State private var timelineWeeks: Double = 16
    @State private var hydrationConsistency: Double = 78
    @State private var sleepQuality: Double = 76
    @State private var inflammationControl: Double = 72
    @State private var reveal = false

    private let engine = AestheticRecompositionEngine()

    init(store: NutritionStore, onDismiss: @escaping () -> Void) {
        self.store = store
        self.onDismiss = onDismiss

        let latest = store.bodyCompositionEntries.sorted { $0.date > $1.date }.first
        let weight = latest?.weightKg ?? 79.0
        let bodyFat = latest?.estimatedBodyFat ?? 16.5

        _currentWeightKg = State(initialValue: weight)
        _targetWeightKg = State(initialValue: max(52, weight - 4.0))
        _currentBodyFat = State(initialValue: bodyFat)
        _targetBodyFat = State(initialValue: max(7, bodyFat - 3.2))
    }

    private var input: AestheticRecompositionInput {
        AestheticRecompositionInput(
            currentWeightKg: currentWeightKg,
            targetWeightKg: targetWeightKg,
            currentBodyFat: currentBodyFat,
            targetBodyFat: targetBodyFat,
            timelineWeeks: Int(timelineWeeks.rounded()),
            hydrationConsistency: hydrationConsistency,
            sleepQuality: sleepQuality,
            inflammationControl: inflammationControl
        )
    }

    private var forecast: AestheticRecompositionForecast {
        engine.forecast(input: input)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AIscendBackdrop()
                DashboardAmbientLayer()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                        topBar(topInset: geometry.safeAreaInsets.top)
                        heroCard
                        inputConsole
                        projectionDashboard
                        timelineSimulation
                        correlationGraph
                        progressHeatmap
                        optimisationPlan
                        explanationDeck
                    }
                    .frame(maxWidth: 640)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                    .padding(.top, AIscendTheme.Spacing.small)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 56)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.86)) {
                reveal = true
            }
        }
    }

    private func topBar(topInset: CGFloat) -> some View {
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

            AIscendBadge(title: "Predictive AI", symbol: "sparkles", style: .accent)
        }
        .padding(.top, topInset + AIscendTheme.Spacing.small)
    }

    private var heroCard: some View {
        DashboardGlassCard(tone: .hero) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        AIscendBadge(title: "Aesthetic Recomposition Engine", symbol: "chart.xyaxis.line", style: .accent)
                        Text("Predict the face, not just the scale.")
                            .font(.system(size: 36, weight: .bold, design: .default))
                            .foregroundStyle(AIscendTheme.Colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Body composition, hydration, sleep, and inflammation are modeled into jawline, cheekbone, sharpness, and eye-area projections.")
                            .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: AIscendTheme.Spacing.medium)

                    forecastOrb
                }

                HStack(spacing: AIscendTheme.Spacing.small) {
                    metricPill(title: "Impact", value: "\(forecast.aestheticImpact)", symbol: "sparkles")
                    metricPill(title: "Probability", value: "\(forecast.transformationProbability)%", symbol: "checkmark.seal.fill")
                }
            }
        }
    }

    private var forecastOrb: some View {
        ZStack {
            Circle()
                .stroke(AIscendTheme.Colors.surfaceHighlight, lineWidth: 8)
            Circle()
                .trim(from: 0, to: reveal ? Double(forecast.predictedSharpness) / 100 : 0)
                .stroke(
                    LinearGradient(
                        colors: [AIscendTheme.Colors.accentGlow, AIscendTheme.Colors.accentCyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("\(forecast.predictedSharpness)")
                    .aiscendTextStyle(.metricCompact)
                    .monospacedDigit()
                Text("FACE")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
            }
        }
        .frame(width: 108, height: 108)
        .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.22), radius: 22, x: 0, y: 0)
    }

    private var inputConsole: some View {
        DashboardGlassCard(tone: .premium) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "Inputs",
                    title: "Transformation controls",
                    subtitle: "Set the goal, timeline, and lifestyle signal. The forecast updates live."
                )

                recompositionSlider(title: "Current weight", value: $currentWeightKg, range: 45...140, unit: "kg", symbol: "scalemass.fill")
                recompositionSlider(title: "Goal weight", value: $targetWeightKg, range: 45...140, unit: "kg", symbol: "target")
                recompositionSlider(title: "Current body fat", value: $currentBodyFat, range: 6...35, unit: "%", symbol: "figure")
                recompositionSlider(title: "Goal body fat", value: $targetBodyFat, range: 6...35, unit: "%", symbol: "scope")
                recompositionSlider(title: "Timeline", value: $timelineWeeks, range: 4...52, unit: "wk", symbol: "calendar")

                Divider()
                    .overlay(AIscendTheme.Colors.divider)

                recompositionSlider(title: "Hydration consistency", value: $hydrationConsistency, range: 35...100, unit: "%", symbol: "drop.fill")
                recompositionSlider(title: "Sleep quality", value: $sleepQuality, range: 35...100, unit: "%", symbol: "moon.stars.fill")
                recompositionSlider(title: "Inflammation control", value: $inflammationControl, range: 35...100, unit: "%", symbol: "flame.fill")

                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    store.addBodyComposition(weightKg: currentWeightKg, bodyFat: currentBodyFat)
                } label: {
                    AIscendButtonLabel(title: "Save Current Check-In", leadingSymbol: "checkmark.circle.fill")
                }
                .buttonStyle(AIscendButtonStyle(variant: .secondary))
            }
        }
    }

    private var projectionDashboard: some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "Projection",
                    title: "Facial improvement estimates",
                    subtitle: "Predictions are directional and include hydration, sleep, and inflammation because those can mask true recomposition."
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
                    projectionTile(title: "Sharpness", value: forecast.predictedSharpness, delta: forecast.predictedSharpness - forecast.currentSharpness, symbol: "face.smiling.inverse", accent: .sky)
                    projectionTile(title: "Jawline", value: forecast.jawlineVisibility, delta: forecast.jawlineVisibility - forecast.currentSharpness, symbol: "line.diagonal", accent: .mint)
                    projectionTile(title: "Cheekbones", value: forecast.cheekboneProminence, delta: forecast.cheekboneProminence - forecast.currentSharpness, symbol: "diamond.fill", accent: .dawn)
                    projectionTile(title: "Eye Area", value: forecast.eyeAreaImprovement, delta: forecast.eyeAreaImprovement - forecast.currentSharpness, symbol: "eye.fill", accent: .mint)
                }

                futureFaceHooks
            }
        }
    }

    private var futureFaceHooks: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            HStack(spacing: AIscendTheme.Spacing.small) {
                Image(systemName: "camera.filters")
                    .foregroundStyle(AIscendTheme.Colors.accentGlow)
                Text("Future face estimation hooks")
                    .aiscendTextStyle(.buttonLabel)
                Spacer()
            }

            Text("The engine exposes provider hooks for future face simulation, scan history, Core ML body estimates, and generated recommendation systems.")
                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.48))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private var timelineSimulation: some View {
        DashboardGlassCard(tone: .premium) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "Timeline Simulation",
                    title: "\(Int(timelineWeeks.rounded())) week aesthetic arc",
                    subtitle: expectedTimelineCopy
                )

                AestheticTimelineGraph(points: forecast.timeline, reveal: reveal)
                    .frame(height: 210)

                HStack(spacing: AIscendTheme.Spacing.small) {
                    metricPill(title: "Start BF", value: String(format: "%.1f%%", currentBodyFat), symbol: "figure")
                    metricPill(title: "Goal BF", value: String(format: "%.1f%%", targetBodyFat), symbol: "scope")
                }
            }
        }
    }

    private var expectedTimelineCopy: String {
        let fatDrop = currentBodyFat - targetBodyFat
        if fatDrop >= 5 {
            return "Expect the first visible facial shift after consistency stabilizes, then a stronger jawline read deeper into the timeline."
        }

        if timelineWeeks < 10 {
            return "Short timelines can show sharper daily reads, but true structural-looking change needs consistency beyond the first few weeks."
        }

        return "The projection is realistic: subtle early changes, cleaner contour reads, then stronger facial contrast as body fat trends down."
    }

    private var correlationGraph: some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "Correlation",
                    title: "Weight-to-face signal",
                    subtitle: "Scale change is interpreted through body fat, water retention, and aesthetic sharpness rather than weight alone."
                )

                WeightFaceCorrelationGraph(points: forecast.timeline, reveal: reveal)
                    .frame(height: 190)
            }
        }
    }

    private var progressHeatmap: some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "Progress Heatmap",
                    title: "Where the transformation shows",
                    subtitle: "A compact map of projected visibility across facial sharpness, jawline, cheekbones, eye area, and retention control."
                )

                AestheticProgressHeatmap(cells: forecast.heatmap)
            }
        }
    }

    private var optimisationPlan: some View {
        DashboardGlassCard(tone: .premium) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "AI Plan",
                    title: "Optimisation strategy",
                    subtitle: "A realistic plan focused on visible facial outcomes, not gym-bro noise."
                )

                ForEach(forecast.optimisationPlan) { item in
                    HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                        AIscendIconOrb(symbol: item.symbol, accent: item.priority <= 2 ? .sky : .mint, size: 42)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .aiscendTextStyle(.buttonLabel)
                            Text(item.detail)
                                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(AIscendTheme.Spacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                            .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.50))
                    )
                }
            }
        }
    }

    private var explanationDeck: some View {
        DashboardGlassCard(tone: .subtle) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "Reality Model",
                    title: "Why the face changes",
                    subtitle: "AIScend keeps the forecast motivating without pretending every kilogram maps cleanly to the face."
                )

                ForEach(forecast.explanations) { item in
                    HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AIscendTheme.Colors.accentGlow)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(AIscendTheme.Colors.accentPrimary.opacity(0.16)))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title)
                                .aiscendTextStyle(.buttonLabel)
                            Text(item.detail)
                                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private func recompositionSlider(title: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
            HStack(spacing: AIscendTheme.Spacing.small) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AIscendTheme.Colors.accentGlow)
                    .frame(width: 24)
                Text(title)
                    .aiscendTextStyle(.buttonLabel)
                Spacer()
                Text(formatted(value.wrappedValue, unit: unit))
                    .aiscendTextStyle(.buttonLabel, color: AIscendTheme.Colors.accentGlow)
                    .monospacedDigit()
            }

            Slider(value: value, in: range)
                .tint(AIscendTheme.Colors.accentGlow)
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.46))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private func projectionTile(title: String, value: Int, delta: Int, symbol: String, accent: RoutineAccent) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            HStack {
                AIscendIconOrb(symbol: symbol, accent: accent, size: 38)
                Spacer()
                AIscendBadge(title: delta >= 0 ? "+\(delta)" : "\(delta)", symbol: delta >= 0 ? "arrow.up" : "arrow.down", style: delta >= 0 ? .accent : .subtle)
            }

            Text("\(value)")
                .aiscendTextStyle(.metricCompact)
                .monospacedDigit()
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.58))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private func metricPill(title: String, value: String, symbol: String) -> some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Image(systemName: symbol)
                .foregroundStyle(AIscendTheme.Colors.accentGlow)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .aiscendTextStyle(.buttonLabel)
                    .monospacedDigit()
                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }
            Spacer(minLength: 0)
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.52))
        )
    }

    private func formatted(_ value: Double, unit: String) -> String {
        if unit == "wk" {
            return "\(Int(value.rounded()))\(unit)"
        }
        return String(format: "%.1f%@", value, unit)
    }
}

private struct AestheticTimelineGraph: View {
    let points: [AestheticTimelinePoint]
    let reveal: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                graphGrid

                linePath(in: geometry.size, values: points.map(\.facialSharpness))
                    .trim(from: 0, to: reveal ? 1 : 0)
                    .stroke(AIscendTheme.Colors.accentGlow, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.28), radius: 14, x: 0, y: 0)

                linePath(in: geometry.size, values: points.map(\.jawlineVisibility))
                    .trim(from: 0, to: reveal ? 1 : 0)
                    .stroke(AIscendTheme.Colors.accentCyan.opacity(0.82), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                VStack {
                    Spacer()
                    HStack {
                        ForEach(sampleLabels, id: \.week) { point in
                            Text("W\(point.week)")
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }

    private var graphGrid: some View {
        VStack {
            ForEach(0..<5, id: \.self) { _ in
                Rectangle()
                    .fill(AIscendTheme.Colors.divider)
                    .frame(height: 1)
                Spacer(minLength: 0)
            }
        }
    }

    private var sampleLabels: [AestheticTimelinePoint] {
        guard points.count > 4 else { return points }
        let step = max(1, points.count / 4)
        return points.enumerated().filter { $0.offset % step == 0 || $0.offset == points.count - 1 }.map(\.element)
    }

    private func linePath(in size: CGSize, values: [Int]) -> Path {
        let minValue = values.min() ?? 40
        let maxValue = values.max() ?? 100
        let range = max(maxValue - minValue, 1)

        return Path { path in
            for index in values.indices {
                let x = size.width * CGFloat(index) / CGFloat(max(values.count - 1, 1))
                let normalized = Double(values[index] - minValue) / Double(range)
                let y = size.height - (size.height * CGFloat(normalized) * 0.78) - 18
                if index == values.startIndex {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
    }
}

private struct WeightFaceCorrelationGraph: View {
    let points: [AestheticTimelinePoint]
    let reveal: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<4, id: \.self) { index in
                    Rectangle()
                        .fill(AIscendTheme.Colors.divider)
                        .frame(height: 1)
                        .position(x: geometry.size.width / 2, y: geometry.size.height * CGFloat(index + 1) / 5)
                }

                ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                    let x = geometry.size.width * CGFloat(index) / CGFloat(max(points.count - 1, 1))
                    let y = yPosition(point: point, height: geometry.size.height)
                    Circle()
                        .fill(AIscendTheme.Colors.accentGlow.opacity(reveal ? 0.92 : 0))
                        .frame(width: 7, height: 7)
                        .position(x: x, y: y)
                        .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.30), radius: 8, x: 0, y: 0)
                }
            }
        }
    }

    private func yPosition(point: AestheticTimelinePoint, height: CGFloat) -> CGFloat {
        let score = min(100, max(35, point.facialSharpness))
        return height - (height * CGFloat(Double(score - 35) / 65.0) * 0.86) - 8
    }
}

private struct AestheticProgressHeatmap: View {
    let cells: [AestheticHeatmapCell]

    private var weeks: [Int] {
        Array(Set(cells.map(\.week))).sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            HStack(spacing: 6) {
                Text("")
                    .frame(width: 48)
                ForEach(weeks, id: \.self) { week in
                    Text("\(week)")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }

            ForEach(AestheticHeatmapMetric.allCases, id: \.self) { metric in
                HStack(spacing: 6) {
                    Text(metric.rawValue)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                        .frame(width: 48, alignment: .leading)

                    ForEach(weeks, id: \.self) { week in
                        let intensity = cells.first { $0.week == week && $0.metric == metric }?.intensity ?? 0
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(cellColor(intensity))
                            .frame(height: 22)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    private func cellColor(_ intensity: Double) -> Color {
        let opacity = min(0.96, max(0.18, intensity))
        if intensity > 0.82 {
            return AIscendTheme.Colors.accentMint.opacity(opacity)
        }
        if intensity > 0.68 {
            return AIscendTheme.Colors.accentGlow.opacity(opacity)
        }
        return AIscendTheme.Colors.accentPrimary.opacity(opacity)
    }
}
