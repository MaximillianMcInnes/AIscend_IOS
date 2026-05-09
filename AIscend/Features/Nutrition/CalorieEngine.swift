//
//  CalorieEngine.swift
//  AIscend
//

import Foundation

struct CalorieEngine {
    func targets(
        for goal: NutritionGoalMode,
        bodyWeightKg: Double?,
        leanMassKg: Double?,
        currentTargets: NutritionMacroTargets = .premiumDefault
    ) -> NutritionMacroTargets {
        let weight = bodyWeightKg ?? 78
        let leanMass = leanMassKg ?? max(52, weight * 0.80)
        let maintenance = Int((weight * 30.5).rounded())
        let calorieGoal: Int

        switch goal {
        case .cut:
            calorieGoal = maintenance - 420
        case .leanBulk:
            calorieGoal = maintenance + 260
        case .maintenance:
            calorieGoal = maintenance
        case .recomposition:
            calorieGoal = maintenance - 120
        case .glowUpChallenge:
            calorieGoal = maintenance - 250
        case .jawlineEnhancement:
            calorieGoal = maintenance - 320
        case .skinRecovery:
            calorieGoal = maintenance - 40
        }

        let proteinMultiplier: Double
        switch goal {
        case .cut, .recomposition, .jawlineEnhancement:
            proteinMultiplier = 2.25
        case .leanBulk:
            proteinMultiplier = 2.0
        case .skinRecovery:
            proteinMultiplier = 1.85
        case .maintenance, .glowUpChallenge:
            proteinMultiplier = 2.05
        }

        let protein = max(130, leanMass * proteinMultiplier)
        let fat = max(58, Double(calorieGoal) * 0.27 / 9)
        let carbs = max(120, (Double(calorieGoal) - (protein * 4) - (fat * 9)) / 4)

        return NutritionMacroTargets(
            calories: max(1650, calorieGoal),
            burned: currentTargets.burned,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: goal == .skinRecovery ? 40 : 34,
            sodiumLimit: goal == .jawlineEnhancement ? 1800 : 2300,
            water: goal == .skinRecovery ? 3.6 : 3.2,
            potassium: goal == .jawlineEnhancement ? 3800 : 3400
        )
    }

    func calorieBalance(macros: NutritionMacros, targets: NutritionMacroTargets) -> Double {
        guard targets.calories > 0 else {
            return 0
        }

        return Double(macros.calories - targets.calories) / Double(targets.calories)
    }

    func macroProgress(value: Double, target: Double) -> Double {
        guard target > 0 else {
            return 0
        }

        return min(max(value / target, 0), 1.24)
    }
}

