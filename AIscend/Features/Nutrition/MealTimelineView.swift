//
//  MealTimelineView.swift
//  AIscend
//

import SwiftUI

struct MealTimelineView: View {
    let meals: [NutritionMealEntry]
    let onDuplicate: (NutritionMealEntry) -> Void
    let onFavorite: (NutritionMealEntry) -> Void

    var body: some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "Daily Timeline",
                    title: "Nutrition events",
                    subtitle: "Each meal is interpreted through macros, satiety, glycemic load, and facial impact."
                )

                if meals.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(meals.enumerated()), id: \.element.id) { index, meal in
                            NutritionMealTimelineRow(
                                meal: meal,
                                isLast: index == meals.count - 1,
                                onDuplicate: { onDuplicate(meal) },
                                onFavorite: { onFavorite(meal) }
                            )
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AIscendTheme.Spacing.small) {
            AIscendIconOrb(symbol: "fork.knife.circle.fill", accent: .sky, size: 54)

            Text("No intake logged yet")
                .aiscendTextStyle(.cardTitle)

            Text("Start with one meal. AIScend will build the facial-impact timeline around it.")
                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AIscendTheme.Spacing.large)
    }
}

private struct NutritionMealTimelineRow: View {
    let meal: NutritionMealEntry
    let isLast: Bool
    let onDuplicate: () -> Void
    let onFavorite: () -> Void

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var body: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(RoutineAccent.sky.gradient.opacity(0.20))
                    Image(systemName: meal.mealType.symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AIscendTheme.Colors.accentGlow)
                }
                .frame(width: 38, height: 38)

                if !isLast {
                    Rectangle()
                        .fill(AIscendTheme.Colors.borderSubtle)
                        .frame(width: 1, height: 110)
                }
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(meal.name)
                            .aiscendTextStyle(.cardTitle)

                        Text("\(meal.mealType.title) / \(Self.timeFormatter.string(from: meal.date))")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                    }

                    Spacer(minLength: AIscendTheme.Spacing.small)

                    Text("\(meal.macros.calories)")
                        .aiscendTextStyle(.metricCompact)
                        .monospacedDigit()
                }

                Text(meal.detail)
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)

                Text(meal.facialImpactEstimate)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                    .fixedSize(horizontal: false, vertical: true)

                macroChips

                HStack(spacing: AIscendTheme.Spacing.xSmall) {
                    impactMetric(title: "Satiety", value: meal.satietyScore)
                    impactMetric(title: "Glycemic", value: meal.glycemicImpact)
                    impactMetric(title: "Aesthetic", value: meal.aestheticRating)
                }

                HStack(spacing: AIscendTheme.Spacing.xSmall) {
                    Button(action: onDuplicate) {
                        Label("Duplicate", systemImage: "doc.on.doc.fill")
                    }
                    .buttonStyle(NutritionInlineButtonStyle())

                    Button(action: onFavorite) {
                        Label(meal.isFavorite ? "Saved" : "Favorite", systemImage: meal.isFavorite ? "star.fill" : "star")
                    }
                    .buttonStyle(NutritionInlineButtonStyle())
                }
            }
            .padding(.bottom, isLast ? 0 : AIscendTheme.Spacing.mediumLarge)
        }
    }

    private var macroChips: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            chip("P \(Int(meal.macros.protein))g")
            chip("C \(Int(meal.macros.carbs))g")
            chip("F \(Int(meal.macros.fat))g")
            chip("Na \(Int(meal.macros.sodium))")
        }
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(Capsule(style: .continuous).fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.74)))
            .overlay(Capsule(style: .continuous).stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1))
    }

    private func impactMetric(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .aiscendTextStyle(.buttonLabel)
                .monospacedDigit()
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.58))
        )
    }
}

struct NutritionInlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .default))
            .foregroundStyle(AIscendTheme.Colors.textPrimary)
            .padding(.horizontal, AIscendTheme.Spacing.small)
            .frame(height: 34)
            .background(
                Capsule(style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceInteractive.opacity(0.78))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(AIscendTheme.Motion.press, value: configuration.isPressed)
    }
}

