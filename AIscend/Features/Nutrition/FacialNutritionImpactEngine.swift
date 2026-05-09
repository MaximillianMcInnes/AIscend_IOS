//
//  FacialNutritionImpactEngine.swift
//  AIscend
//

import Foundation

struct FacialNutritionImpactReport {
    var hydrationImpact: Int
    var inflammationRisk: Int
    var puffinessRisk: Int
    var skinClaritySupport: Int
    var leanFacialRetention: Int
    var confidence: Double
    var insights: [String]
}

struct FacialNutritionImpactEngine {
    func analyze(macros: NutritionMacros, glycemicLoad: Int, recognitionConfidence: Double) -> FacialNutritionImpactReport {
        let sodiumPressure = min(1, macros.sodium / 1800)
        let sugarPressure = min(1, macros.sugar / 45)
        let fiberBuffer = min(1, macros.fiber / 12)
        let potassiumBuffer = min(1, macros.potassium / 1200)
        let proteinSupport = min(1, macros.protein / 45)
        let hydrationBase = min(1, macros.water / 0.8)

        let hydrationImpact = clampInt((hydrationBase * 54) + (potassiumBuffer * 26) - (sodiumPressure * 18) - (sugarPressure * 8) + 34)
        let inflammationRisk = clampInt((sodiumPressure * 34) + (sugarPressure * 30) + (Double(glycemicLoad) * 0.34) - (fiberBuffer * 18) + 12)
        let puffinessRisk = clampInt((sodiumPressure * 58) + (sugarPressure * 16) - (potassiumBuffer * 20) + 10)
        let skinClaritySupport = clampInt(88 - (sugarPressure * 32) - (Double(glycemicLoad) * 0.22) + (fiberBuffer * 12) + (hydrationBase * 8))
        let leanFacialRetention = clampInt((proteinSupport * 62) + (fiberBuffer * 12) + 26)

        var insights: [String] = []

        if macros.sodium >= 900 {
            insights.append("This meal may increase facial puffiness due to sodium levels.")
        } else {
            insights.append("Sodium looks controlled, which supports a sharper next-day facial read.")
        }

        if macros.protein >= 32 {
            insights.append("High protein content supports lean facial retention.")
        } else {
            insights.append("Adding protein would improve satiety and lean facial retention.")
        }

        if macros.sugar >= 24 || glycemicLoad >= 68 {
            insights.append("High glycemic load may negatively affect skin clarity.")
        } else {
            insights.append("Glycemic load appears steady enough for clearer skin support.")
        }

        if macros.potassium >= 700 || macros.water >= 0.5 {
            insights.append("Potassium and water content may help offset visible water retention.")
        }

        return FacialNutritionImpactReport(
            hydrationImpact: hydrationImpact,
            inflammationRisk: inflammationRisk,
            puffinessRisk: puffinessRisk,
            skinClaritySupport: skinClaritySupport,
            leanFacialRetention: leanFacialRetention,
            confidence: min(0.96, max(0.58, recognitionConfidence - 0.02)),
            insights: Array(insights.prefix(4))
        )
    }

    private func clampInt(_ value: Double, min lowerBound: Int = 0, max upperBound: Int = 100) -> Int {
        min(upperBound, max(lowerBound, Int(value.rounded())))
    }
}
