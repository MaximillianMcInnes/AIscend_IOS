//
//  MealAnalysisResultView.swift
//  AIscend
//

import SwiftUI

struct MealAnalysisResultView: View {
    let result: MealAnalysisResult
    let onLogMeal: () -> Void
    let onScanAgain: () -> Void

    @State private var reveal = false

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            resultHeader
            macroReveal
            impactGrid
            detectedItems
            aiInsights
            actions
        }
        .onAppear {
            withAnimation(.spring(response: 0.62, dampingFraction: 0.86).delay(0.08)) {
                reveal = true
            }
        }
    }

    private var resultHeader: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                    AIscendBadge(title: "AI Meal Read", symbol: "sparkles", style: .accent)
                    Text(result.primaryName)
                        .aiscendTextStyle(.sectionTitle)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(result.recognitionSource.title) · \(Int(result.confidence * 100))% confidence")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                }

                Spacer(minLength: AIscendTheme.Spacing.medium)

                confidenceOrb
            }
        }
    }

    private var confidenceOrb: some View {
        ZStack {
            Circle()
                .stroke(AIscendTheme.Colors.surfaceHighlight, lineWidth: 7)
            Circle()
                .trim(from: 0, to: reveal ? result.confidence : 0)
                .stroke(
                    LinearGradient(
                        colors: [AIscendTheme.Colors.accentGlow, AIscendTheme.Colors.accentMint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("\(Int(result.confidence * 100))")
                    .aiscendTextStyle(.metricCompact)
                    .monospacedDigit()
                Text("AI")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
            }
        }
        .frame(width: 92, height: 92)
        .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.22), radius: 18, x: 0, y: 0)
    }

    private var macroReveal: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            Text("\(result.macros.calories) kcal")
                .font(.system(size: 42, weight: .bold, design: .default))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                .monospacedDigit()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
                macroBar(title: "Protein", value: result.macros.protein, unit: "g", maxValue: 60, tint: AIscendTheme.Colors.accentGlow)
                macroBar(title: "Carbs", value: result.macros.carbs, unit: "g", maxValue: 90, tint: AIscendTheme.Colors.accentCyan)
                macroBar(title: "Fat", value: result.macros.fat, unit: "g", maxValue: 45, tint: AIscendTheme.Colors.accentAmber)
                macroBar(title: "Sugar", value: result.macros.sugar, unit: "g", maxValue: 45, tint: AIscendTheme.Colors.error)
            }
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.62))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private func macroBar(title: String, value: Double, unit: String, maxValue: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
            HStack {
                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                Spacer()
                Text("\(Int(value.rounded()))\(unit)")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                    .monospacedDigit()
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(AIscendTheme.Colors.surfaceMuted.opacity(0.78))
                    Capsule(style: .continuous)
                        .fill(tint)
                        .frame(width: proxy.size.width * min(1, reveal ? value / maxValue : 0))
                        .shadow(color: tint.opacity(0.26), radius: 12, x: 0, y: 0)
                }
            }
            .frame(height: 8)
        }
        .padding(AIscendTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceGlass.opacity(0.64))
        )
    }

    private var impactGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
            impactTile(title: "Sodium", value: "\(Int(result.macros.sodium))mg", score: sodiumScore, symbol: "saltshaker.fill", tint: AIscendTheme.Colors.accentAmber)
            impactTile(title: "Hydration", value: "\(result.facialImpact.hydrationImpact)%", score: result.facialImpact.hydrationImpact, symbol: "drop.fill", tint: AIscendTheme.Colors.accentCyan)
            impactTile(title: "Inflammation", value: "\(result.facialImpact.inflammationRisk)%", score: 100 - result.facialImpact.inflammationRisk, symbol: "flame.fill", tint: AIscendTheme.Colors.error)
            impactTile(title: "Skin Clarity", value: "\(result.facialImpact.skinClaritySupport)%", score: result.facialImpact.skinClaritySupport, symbol: "sparkles", tint: AIscendTheme.Colors.success)
        }
    }

    private var sodiumScore: Int {
        max(0, min(100, 100 - Int(result.macros.sodium / 18)))
    }

    private func impactTile(title: String, value: String, score: Int, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            HStack {
                Image(systemName: symbol)
                    .foregroundStyle(tint)
                Spacer()
                Text("\(score)")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                    .monospacedDigit()
            }

            Text(value)
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
                .stroke(tint.opacity(0.20), lineWidth: 1)
        )
    }

    private var detectedItems: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            Text("Detected food")
                .aiscendTextStyle(.cardTitle)

            VStack(spacing: AIscendTheme.Spacing.small) {
                ForEach(result.detectedItems) { item in
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        AIscendIconOrb(symbol: "viewfinder", accent: .mint, size: 34)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .aiscendTextStyle(.buttonLabel)
                            Text(item.category.capitalized)
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                        }
                        Spacer()
                        Text("\(Int(item.confidence * 100))%")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                            .monospacedDigit()
                    }
                    .padding(AIscendTheme.Spacing.small)
                    .background(
                        RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                            .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.52))
                    )
                }
            }
        }
    }

    private var aiInsights: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            Text("Facial-aesthetic read")
                .aiscendTextStyle(.cardTitle)

            ForEach(Array(result.facialImpact.insights.enumerated()), id: \.offset) { _, insight in
                HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AIscendTheme.Colors.accentGlow)
                        .padding(.top, 3)
                    Text(insight)
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(AIscendTheme.Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                        .fill(AIscendTheme.Colors.surfaceGlass.opacity(0.58))
                )
            }
        }
    }

    private var actions: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Button(action: onLogMeal) {
                AIscendButtonLabel(title: "Log Meal", leadingSymbol: "checkmark.circle.fill")
            }
            .buttonStyle(AIscendButtonStyle(variant: .primary))

            Button(action: onScanAgain) {
                AIscendButtonLabel(title: "Scan Again", leadingSymbol: "camera.viewfinder")
            }
            .buttonStyle(AIscendButtonStyle(variant: .secondary))
        }
    }
}
