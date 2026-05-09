//
//  AestheticNutritionScoreEngine.swift
//  AIscend
//

import Foundation

struct AestheticNutritionScoreEngine {
    func scores(macros: NutritionMacros, targets: NutritionMacroTargets, goal: NutritionGoalMode) -> AestheticNutritionScores {
        let calorieAlignment = scoreCloseness(value: Double(macros.calories), target: Double(targets.calories), tolerance: 0.18)
        let protein = scoreProgress(value: macros.protein, target: targets.protein)
        let fiber = scoreProgress(value: macros.fiber, target: targets.fiber)
        let water = scoreProgress(value: macros.water, target: targets.water)
        let sodiumRisk = riskScore(value: macros.sodium, limit: targets.sodiumLimit)
        let potassium = scoreProgress(value: macros.potassium, target: targets.potassium)
        let sugarRisk = min(100, Int((macros.sugar / 85) * 100))

        let nutritionQuality = weightedScore([
            (calorieAlignment, 0.24),
            (protein, 0.26),
            (fiber, 0.18),
            (100 - sodiumRisk, 0.16),
            (potassium, 0.16)
        ])

        let inflammationRisk = min(100, weightedScore([
            (sodiumRisk, 0.45),
            (sugarRisk, 0.32),
            (max(0, 100 - fiber), 0.23)
        ]))

        let hydrationQuality = weightedScore([
            (water, 0.52),
            (potassium, 0.26),
            (100 - sodiumRisk, 0.22)
        ])

        let skinSupport = weightedScore([
            (protein, 0.28),
            (fiber, 0.24),
            (hydrationQuality, 0.28),
            (100 - sugarRisk, 0.20)
        ])

        var aesthetic = weightedScore([
            (nutritionQuality, 0.34),
            (hydrationQuality, 0.24),
            (skinSupport, 0.24),
            (100 - inflammationRisk, 0.18)
        ])

        if goal == .jawlineEnhancement {
            aesthetic = Int(Double(aesthetic) * 0.82 + Double(100 - sodiumRisk) * 0.18)
        }

        return AestheticNutritionScores(
            nutritionQuality: nutritionQuality,
            inflammationRisk: inflammationRisk,
            hydrationQuality: hydrationQuality,
            skinSupport: skinSupport,
            aestheticOptimisation: min(max(aesthetic, 0), 100)
        )
    }

    private func scoreProgress(value: Double, target: Double) -> Int {
        guard target > 0 else {
            return 0
        }

        let ratio = value / target
        if ratio <= 1 {
            return Int((ratio * 100).rounded())
        }

        return max(72, 100 - Int(((ratio - 1) * 42).rounded()))
    }

    private func scoreCloseness(value: Double, target: Double, tolerance: Double) -> Int {
        guard target > 0 else {
            return 0
        }

        let delta = abs(value - target) / target
        if delta <= tolerance {
            return 100 - Int((delta / tolerance * 16).rounded())
        }

        return max(35, 84 - Int(((delta - tolerance) * 180).rounded()))
    }

    private func riskScore(value: Double, limit: Double) -> Int {
        guard limit > 0 else {
            return 0
        }

        let ratio = value / limit
        return min(100, max(0, Int((ratio * 76).rounded())))
    }

    private func weightedScore(_ items: [(Int, Double)]) -> Int {
        let total = items.reduce(0.0) { $0 + Double($1.0) * $1.1 }
        return Int(total.rounded())
    }
}

