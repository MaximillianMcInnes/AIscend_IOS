//
//  NutritionAIEngine.swift
//  AIscend
//

import Foundation

struct NutritionAIEngine {
    func insights(
        macros: NutritionMacros,
        targets: NutritionMacroTargets,
        scores: AestheticNutritionScores,
        goal: NutritionGoalMode
    ) -> [NutritionInsight] {
        var insights: [NutritionInsight] = []

        if macros.sodium > targets.sodiumLimit {
            insights.append(
                NutritionInsight(
                    title: "Puffiness risk elevated",
                    detail: "High sodium intake may increase facial water retention tomorrow, especially around the jaw and eye area.",
                    symbol: "drop.triangle.fill",
                    severity: .risk
                )
            )
        }

        if macros.protein >= targets.protein * 0.92 {
            insights.append(
                NutritionInsight(
                    title: "Tissue retention protected",
                    detail: "Protein intake is supporting lean facial tissue while your body composition target stays active.",
                    symbol: "shield.lefthalf.filled",
                    severity: .advantage
                )
            )
        } else {
            insights.append(
                NutritionInsight(
                    title: "Protein timing weak",
                    detail: "Protein is under target. This can reduce recovery quality and make aggressive fat loss read flatter in the face.",
                    symbol: "waveform.path.ecg",
                    severity: .watch
                )
            )
        }

        if scores.hydrationQuality >= 82 {
            insights.append(
                NutritionInsight(
                    title: "Hydration quality improved",
                    detail: "Water and potassium balance are trending toward a sharper, less inflamed facial read.",
                    symbol: "drop.fill",
                    severity: .advantage
                )
            )
        }

        if macros.sugar > 70 {
            insights.append(
                NutritionInsight(
                    title: "Eye-area volatility",
                    detail: "Excess sugar paired with poor sleep can make the under-eye area look softer the next morning.",
                    symbol: "eye.trianglebadge.exclamationmark.fill",
                    severity: .watch
                )
            )
        }

        if goal == .jawlineEnhancement && macros.potassium < targets.potassium * 0.72 {
            insights.append(
                NutritionInsight(
                    title: "Potassium gap detected",
                    detail: "Add potassium-rich foods to offset sodium and support a cleaner jawline forecast.",
                    symbol: "bolt.heart.fill",
                    severity: .watch
                )
            )
        }

        if insights.isEmpty {
            insights.append(
                NutritionInsight(
                    title: "Aesthetic nutrition stable",
                    detail: "Today's intake is aligned with a low-noise facial optimisation profile.",
                    symbol: "sparkles",
                    severity: .advantage
                )
            )
        }

        return Array(insights.prefix(4))
    }

    func recommendations(
        macros: NutritionMacros,
        targets: NutritionMacroTargets,
        scores: AestheticNutritionScores,
        goal: NutritionGoalMode
    ) -> [NutritionRecommendation] {
        var recommendations: [NutritionRecommendation] = []

        if macros.sodium > targets.sodiumLimit * 0.85 {
            recommendations.append(
                NutritionRecommendation(
                    title: "Reduce sodium drift",
                    detail: "Keep the next meal lower sodium and add potassium to control facial water retention.",
                    symbol: "dial.low.fill",
                    priority: 1
                )
            )
        }

        if macros.protein < targets.protein {
            recommendations.append(
                NutritionRecommendation(
                    title: "Close the protein gap",
                    detail: "Add a lean protein serving before your final meal to protect recovery and tissue density.",
                    symbol: "plus.forwardslash.minus",
                    priority: 2
                )
            )
        }

        if macros.water < targets.water {
            recommendations.append(
                NutritionRecommendation(
                    title: "Hydration pulse",
                    detail: "Add 600ml water with electrolytes across the next two hours for sharper tomorrow-read stability.",
                    symbol: "drop.degreesign.fill",
                    priority: 3
                )
            )
        }

        if macros.fiber < targets.fiber * 0.72 {
            recommendations.append(
                NutritionRecommendation(
                    title: "Improve skin-supporting fiber",
                    detail: "Add fruit, oats, legumes, or greens to support digestion and lower inflammation load.",
                    symbol: "leaf.fill",
                    priority: 4
                )
            )
        }

        if goal == .skinRecovery {
            recommendations.append(
                NutritionRecommendation(
                    title: "Skin recovery stack",
                    detail: "Prioritise omega-3s, vitamin C foods, collagen support, and consistent water before sleep.",
                    symbol: "sparkle.magnifyingglass",
                    priority: 5
                )
            )
        }

        return recommendations.sorted { $0.priority < $1.priority }.prefix(5).map { $0 }
    }
}
