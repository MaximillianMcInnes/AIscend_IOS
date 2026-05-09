//
//  FacialImpactCard.swift
//  AIscend
//

import SwiftUI

struct FacialImpactCard: View {
    let scores: AestheticNutritionScores

    var body: some View {
        DashboardGlassCard(tone: .hero) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                        AIscendBadge(title: "Facial Impact", symbol: "face.smiling.inverse", style: .accent)

                        Text("Aesthetic Nutrition Score")
                            .aiscendTextStyle(.sectionTitle)
                    }

                    Spacer()

                    Text("\(scores.faceImpactScore)")
                        .font(.system(size: 48, weight: .bold, design: .default))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .monospacedDigit()
                }

                Text(faceForecast)
                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
                    scoreTile(title: "Nutrition", value: scores.nutritionQuality, symbol: "fork.knife")
                    scoreTile(title: "Hydration", value: scores.hydrationQuality, symbol: "drop.fill")
                    scoreTile(title: "Skin", value: scores.skinSupport, symbol: "sparkles")
                    scoreTile(title: "Inflammation", value: 100 - scores.inflammationRisk, symbol: "flame.fill")
                }
            }
        }
    }

    private var faceForecast: String {
        if scores.inflammationRisk > 64 {
            return "Tomorrow's read may be softer from inflammation and water retention. Tighten sodium, sugar, and hydration before sleep."
        }

        if scores.faceImpactScore >= 82 {
            return "Nutrition is aligned with sharper contours, cleaner skin support, and stronger recovery signalling."
        }

        return "Good base. Protein, hydration, and fiber can push the next facial read into a cleaner zone."
    }

    private func scoreTile(title: String, value: Int, symbol: String) -> some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.accentGlow)
                .frame(width: 32, height: 32)
                .background(Circle().fill(AIscendTheme.Colors.accentPrimary.opacity(0.16)))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)")
                    .aiscendTextStyle(.metricCompact)
                    .monospacedDigit()

                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }

            Spacer(minLength: 0)
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
}

