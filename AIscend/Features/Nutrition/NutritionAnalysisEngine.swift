//
//  NutritionAnalysisEngine.swift
//  AIscend
//

import Foundation
import UIKit

struct MealAnalysisResult: Identifiable {
    var id: UUID
    var createdAt: Date
    var image: UIImage?
    var detectedItems: [DetectedFoodItem]
    var recognitionSource: FoodRecognitionSource
    var confidence: Double
    var macros: NutritionMacros
    var glycemicLoad: Int
    var facialImpact: FacialNutritionImpactReport

    var primaryName: String {
        let names = detectedItems.prefix(2).map(\.name)
        return names.isEmpty ? "AI scanned meal" : names.joined(separator: " + ")
    }

    var mealEntry: NutritionMealEntry {
        NutritionMealEntry(
            date: createdAt,
            mealType: suggestedMealType(for: createdAt),
            name: primaryName,
            detail: detectedItems.map { "\($0.name) \(Int($0.confidence * 100))%" }.joined(separator: " · "),
            macros: macros,
            satietyScore: min(100, max(0, Int((macros.protein * 1.3 + macros.fiber * 2.2 + 28).rounded()))),
            glycemicImpact: glycemicLoad,
            aestheticRating: min(100, max(0, 100 - facialImpact.inflammationRisk + Int(macros.protein / 8))),
            facialImpactEstimate: facialImpact.insights.first ?? "AI nutrition scan complete.",
            source: .aiVision
        )
    }

    private func suggestedMealType(for date: Date) -> NutritionMealType {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<11:
            return .breakfast
        case 11..<16:
            return .lunch
        case 16..<22:
            return .dinner
        default:
            return .snack
        }
    }
}

struct NutritionAnalysisEngine {
    var recognitionPipeline = FoodRecognitionPipeline()
    var facialImpactEngine = FacialNutritionImpactEngine()

    func analyzeMealImage(_ image: UIImage?) async throws -> MealAnalysisResult {
        async let recognition = recognitionPipeline.recognizeFood(in: image)
        try await Task.sleep(nanoseconds: 850_000_000)

        let output = try await recognition
        let macros = estimateNutrition(from: output.items)
        let glycemicLoad = estimateGlycemicLoad(macros: macros, items: output.items)
        let impact = facialImpactEngine.analyze(
            macros: macros,
            glycemicLoad: glycemicLoad,
            recognitionConfidence: output.confidence
        )

        return MealAnalysisResult(
            id: UUID(),
            createdAt: .now,
            image: image,
            detectedItems: output.items,
            recognitionSource: output.source,
            confidence: output.confidence,
            macros: macros,
            glycemicLoad: glycemicLoad,
            facialImpact: impact
        )
    }

    private func estimateNutrition(from items: [DetectedFoodItem]) -> NutritionMacros {
        let weighted = items.reduce(NutritionMacros.zero) { partial, item in
            partial + scaled(profile(for: item), by: item.estimatedPortion)
        }

        if weighted.calories > 0 {
            return weighted
        }

        return NutritionMacros(
            calories: 520,
            protein: 36,
            carbs: 48,
            fat: 18,
            fiber: 7,
            sodium: 740,
            water: 0.46,
            sugar: 9,
            potassium: 780
        )
    }

    private func estimateGlycemicLoad(macros: NutritionMacros, items: [DetectedFoodItem]) -> Int {
        let denseMealPenalty = items.contains { $0.category == "dense meal" } ? 10 : 0
        let condimentPenalty = items.contains { $0.category == "condiment" } ? 6 : 0
        let fiberBuffer = Int(min(18, macros.fiber * 1.4))
        let load = Double(macros.carbs) * 0.72 + Double(macros.sugar) * 0.56 + Double(denseMealPenalty + condimentPenalty - fiberBuffer)
        return min(100, max(0, Int(load.rounded())))
    }

    private func profile(for item: DetectedFoodItem) -> NutritionMacros {
        switch item.name.lowercased() {
        case let name where name.contains("burger"):
            return NutritionMacros(calories: 610, protein: 31, carbs: 46, fat: 34, fiber: 3, sodium: 1120, water: 0.18, sugar: 8, potassium: 520)
        case let name where name.contains("fries"):
            return NutritionMacros(calories: 390, protein: 5, carbs: 52, fat: 18, fiber: 5, sodium: 470, water: 0.12, sugar: 1, potassium: 720)
        case let name where name.contains("sushi"):
            return NutritionMacros(calories: 430, protein: 24, carbs: 62, fat: 9, fiber: 4, sodium: 680, water: 0.34, sugar: 8, potassium: 520)
        case let name where name.contains("soy"):
            return NutritionMacros(calories: 20, protein: 2, carbs: 2, fat: 0, fiber: 0, sodium: 920, water: 0.04, sugar: 1, potassium: 70)
        case let name where name.contains("yogurt"):
            return NutritionMacros(calories: 310, protein: 28, carbs: 34, fat: 8, fiber: 5, sodium: 120, water: 0.42, sugar: 18, potassium: 620)
        case let name where name.contains("fruit"):
            return NutritionMacros(calories: 110, protein: 1, carbs: 28, fat: 0, fiber: 5, sodium: 4, water: 0.26, sugar: 19, potassium: 310)
        case let name where name.contains("salmon"):
            return NutritionMacros(calories: 560, protein: 42, carbs: 42, fat: 24, fiber: 8, sodium: 520, water: 0.42, sugar: 5, potassium: 1050)
        case let name where name.contains("avocado"):
            return NutritionMacros(calories: 160, protein: 2, carbs: 9, fat: 15, fiber: 7, sodium: 8, water: 0.10, sugar: 1, potassium: 485)
        case let name where name.contains("green") || name.contains("vegetable"):
            return NutritionMacros(calories: 86, protein: 4, carbs: 14, fat: 2, fiber: 6, sodium: 80, water: 0.34, sugar: 5, potassium: 620)
        case let name where name.contains("chicken"):
            return NutritionMacros(calories: 590, protein: 46, carbs: 56, fat: 16, fiber: 6, sodium: 720, water: 0.38, sugar: 7, potassium: 820)
        case let name where name.contains("sauce"):
            return NutritionMacros(calories: 90, protein: 1, carbs: 10, fat: 5, fiber: 0, sodium: 420, water: 0.06, sugar: 6, potassium: 60)
        default:
            return NutritionMacros(calories: 360, protein: 24, carbs: 34, fat: 14, fiber: 5, sodium: 520, water: 0.30, sugar: 6, potassium: 520)
        }
    }

    private func scaled(_ macros: NutritionMacros, by portion: Double) -> NutritionMacros {
        NutritionMacros(
            calories: Int((Double(macros.calories) * portion).rounded()),
            protein: macros.protein * portion,
            carbs: macros.carbs * portion,
            fat: macros.fat * portion,
            fiber: macros.fiber * portion,
            sodium: macros.sodium * portion,
            water: macros.water * portion,
            sugar: macros.sugar * portion,
            potassium: macros.potassium * portion
        )
    }
}
