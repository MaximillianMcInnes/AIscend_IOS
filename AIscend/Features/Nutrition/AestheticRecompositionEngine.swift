//
//  AestheticRecompositionEngine.swift
//  AIscend
//

import Foundation

struct AestheticRecompositionInput: Equatable {
    var currentWeightKg: Double
    var targetWeightKg: Double
    var currentBodyFat: Double
    var targetBodyFat: Double
    var timelineWeeks: Int
    var hydrationConsistency: Double
    var sleepQuality: Double
    var inflammationControl: Double
}

struct AestheticRecompositionForecast {
    var currentSharpness: Int
    var predictedSharpness: Int
    var jawlineVisibility: Int
    var cheekboneProminence: Int
    var eyeAreaImprovement: Int
    var transformationProbability: Int
    var aestheticImpact: Int
    var timeline: [AestheticTimelinePoint]
    var heatmap: [AestheticHeatmapCell]
    var optimisationPlan: [AestheticOptimisationPlanItem]
    var explanations: [AestheticExplanation]
}

struct AestheticTimelinePoint: Identifiable, Equatable {
    var id = UUID()
    var week: Int
    var bodyFat: Double
    var weightKg: Double
    var facialSharpness: Int
    var jawlineVisibility: Int
    var cheekboneProminence: Int
    var eyeAreaScore: Int
}

struct AestheticHeatmapCell: Identifiable, Equatable {
    var id = UUID()
    var week: Int
    var metric: AestheticHeatmapMetric
    var intensity: Double
}

enum AestheticHeatmapMetric: String, CaseIterable {
    case sharpness = "Sharp"
    case jawline = "Jaw"
    case cheekbones = "Cheek"
    case eyes = "Eyes"
    case retention = "Water"
}

struct AestheticOptimisationPlanItem: Identifiable, Equatable {
    var id = UUID()
    var title: String
    var detail: String
    var priority: Int
    var symbol: String
}

struct AestheticExplanation: Identifiable, Equatable {
    var id = UUID()
    var title: String
    var detail: String
    var symbol: String
}

protocol FutureFaceEstimationProviding {
    func estimateFutureFace(input: AestheticRecompositionInput) async throws -> AestheticRecompositionForecast?
}

protocol AestheticBodyCompositionProvider {
    func latestBodyComposition() async throws -> NutritionBodyCompositionEntry?
}

struct AestheticRecompositionEngine {
    var futureFaceProvider: FutureFaceEstimationProviding?
    var bodyCompositionProvider: AestheticBodyCompositionProvider?

    func forecast(input: AestheticRecompositionInput) -> AestheticRecompositionForecast {
        let weeks = max(4, min(52, input.timelineWeeks))
        let fatDelta = max(-14, min(8, input.currentBodyFat - input.targetBodyFat))
        let weightDelta = input.currentWeightKg - input.targetWeightKg
        let sustainablePace = abs(weightDelta) / Double(weeks)
        let adherenceScore = adherenceScore(input: input, weeklyWeightChange: sustainablePace)
        let currentSharpness = facialSharpness(bodyFat: input.currentBodyFat, hydration: input.hydrationConsistency, sleep: input.sleepQuality, inflammation: input.inflammationControl)
        let predictedSharpness = facialSharpness(bodyFat: input.targetBodyFat, hydration: input.hydrationConsistency, sleep: input.sleepQuality, inflammation: input.inflammationControl)
        let timeline = makeTimeline(input: input, weeks: weeks)
        let final = timeline.last ?? AestheticTimelinePoint(week: weeks, bodyFat: input.targetBodyFat, weightKg: input.targetWeightKg, facialSharpness: predictedSharpness, jawlineVisibility: predictedSharpness, cheekboneProminence: predictedSharpness, eyeAreaScore: predictedSharpness)

        let probability = clampInt(
            46
            + fatDelta * 5.2
            + adherenceScore * 0.34
            - max(0, sustainablePace - 0.72) * 22
            + input.sleepQuality * 0.12
            + input.hydrationConsistency * 0.10
            + input.inflammationControl * 0.10
        )

        return AestheticRecompositionForecast(
            currentSharpness: currentSharpness,
            predictedSharpness: final.facialSharpness,
            jawlineVisibility: final.jawlineVisibility,
            cheekboneProminence: final.cheekboneProminence,
            eyeAreaImprovement: final.eyeAreaScore,
            transformationProbability: probability,
            aestheticImpact: clampInt(Double(final.facialSharpness - currentSharpness) * 1.6 + Double(probability) * 0.72),
            timeline: timeline,
            heatmap: makeHeatmap(from: timeline, input: input),
            optimisationPlan: optimisationPlan(input: input, weeklyWeightChange: sustainablePace),
            explanations: explanations()
        )
    }

    private func makeTimeline(input: AestheticRecompositionInput, weeks: Int) -> [AestheticTimelinePoint] {
        (0...weeks).map { week in
            let progress = Double(week) / Double(max(weeks, 1))
            let eased = 1 - pow(1 - progress, 1.45)
            let bodyFat = input.currentBodyFat + (input.targetBodyFat - input.currentBodyFat) * eased
            let weight = input.currentWeightKg + (input.targetWeightKg - input.currentWeightKg) * eased
            let sharpness = facialSharpness(bodyFat: bodyFat, hydration: input.hydrationConsistency, sleep: input.sleepQuality, inflammation: input.inflammationControl)
            let jawline = clampInt(Double(sharpness) + max(0, input.currentBodyFat - bodyFat) * 1.15 - max(0, 14 - bodyFat) * 0.35)
            let cheekbone = clampInt(Double(sharpness) + max(0, 18 - bodyFat) * 0.88 + input.sleepQuality * 0.04)
            let eyes = clampInt(Double(sharpness) - max(0, 78 - input.sleepQuality) * 0.20 + input.hydrationConsistency * 0.08 + input.inflammationControl * 0.06)

            return AestheticTimelinePoint(
                week: week,
                bodyFat: bodyFat,
                weightKg: weight,
                facialSharpness: sharpness,
                jawlineVisibility: jawline,
                cheekboneProminence: cheekbone,
                eyeAreaScore: eyes
            )
        }
    }

    private func facialSharpness(bodyFat: Double, hydration: Double, sleep: Double, inflammation: Double) -> Int {
        let fatScore = 104 - bodyFat * 2.22
        let hydrationScore = (hydration - 50) * 0.18
        let sleepScore = (sleep - 50) * 0.16
        let inflammationScore = (inflammation - 50) * 0.20
        return clampInt(fatScore + hydrationScore + sleepScore + inflammationScore)
    }

    private func adherenceScore(input: AestheticRecompositionInput, weeklyWeightChange: Double) -> Double {
        let pace = max(0, 100 - max(0, weeklyWeightChange - 0.65) * 60)
        let targetRealism = max(42, 100 - max(0, input.currentBodyFat - input.targetBodyFat - 7) * 8)
        return (pace * 0.34) + (targetRealism * 0.24) + (input.sleepQuality * 0.16) + (input.hydrationConsistency * 0.13) + (input.inflammationControl * 0.13)
    }

    private func makeHeatmap(from timeline: [AestheticTimelinePoint], input: AestheticRecompositionInput) -> [AestheticHeatmapCell] {
        let sampled = timeline.enumerated().filter { index, _ in index % max(1, timeline.count / 9) == 0 || index == timeline.count - 1 }.map(\.element)

        return sampled.flatMap { point in
            [
                AestheticHeatmapCell(week: point.week, metric: .sharpness, intensity: Double(point.facialSharpness) / 100),
                AestheticHeatmapCell(week: point.week, metric: .jawline, intensity: Double(point.jawlineVisibility) / 100),
                AestheticHeatmapCell(week: point.week, metric: .cheekbones, intensity: Double(point.cheekboneProminence) / 100),
                AestheticHeatmapCell(week: point.week, metric: .eyes, intensity: Double(point.eyeAreaScore) / 100),
                AestheticHeatmapCell(week: point.week, metric: .retention, intensity: (input.hydrationConsistency * 0.48 + input.sleepQuality * 0.22 + input.inflammationControl * 0.30) / 100)
            ]
        }
    }

    private func optimisationPlan(input: AestheticRecompositionInput, weeklyWeightChange: Double) -> [AestheticOptimisationPlanItem] {
        var plan: [AestheticOptimisationPlanItem] = []

        if weeklyWeightChange > 0.75 {
            plan.append(AestheticOptimisationPlanItem(title: "Slow the weekly drop", detail: "The target pace is aggressive. A smaller deficit protects lean tissue and keeps the face from reading flat.", priority: 1, symbol: "speedometer"))
        } else {
            plan.append(AestheticOptimisationPlanItem(title: "Hold a controlled deficit", detail: "The timeline is realistic enough to reduce facial softness without forcing a depleted look.", priority: 1, symbol: "scope"))
        }

        plan.append(AestheticOptimisationPlanItem(title: "Protein anchors", detail: "Keep protein high across 3 to 4 meals so recomposition improves jawline visibility without losing facial fullness.", priority: 2, symbol: "shield.fill"))
        plan.append(AestheticOptimisationPlanItem(title: "Hydration rhythm", detail: "Consistent water and potassium reduce noisy day-to-day puffiness, especially during lower-body-fat phases.", priority: 3, symbol: "drop.fill"))

        if input.sleepQuality < 74 {
            plan.append(AestheticOptimisationPlanItem(title: "Sleep as contour control", detail: "Improving sleep regularity will help the eye area and reduce inflammation-driven softness.", priority: 4, symbol: "moon.stars.fill"))
        }

        if input.inflammationControl < 72 {
            plan.append(AestheticOptimisationPlanItem(title: "Lower inflammation load", detail: "Reduce late sodium spikes, alcohol, and high-sugar meals before scan days for cleaner facial reads.", priority: 5, symbol: "flame.fill"))
        }

        return plan
    }

    private func explanations() -> [AestheticExplanation] {
        [
            AestheticExplanation(title: "Body fat changes facial contrast", detail: "Lower body fat usually reduces subcutaneous facial softness, making the jawline, cheekbones, and lower-face transitions easier to read.", symbol: "face.smiling.inverse"),
            AestheticExplanation(title: "Timelines are nonlinear", detail: "Early weeks can look subtle while water and inflammation fluctuate. Visible facial definition often accelerates once consistency compounds.", symbol: "calendar.badge.clock"),
            AestheticExplanation(title: "Hydration changes the daily read", detail: "Water balance, potassium, sodium, and carbohydrate timing can temporarily soften or sharpen the face independent of true fat loss.", symbol: "drop.fill"),
            AestheticExplanation(title: "Sleep protects the eye area", detail: "Poor sleep increases retention and dullness around the eyes, so sleep quality is part of the face forecast rather than a separate wellness metric.", symbol: "moon.stars.fill"),
            AestheticExplanation(title: "Inflammation can mask progress", detail: "High sodium, high sugar, alcohol, and stress can blur cheekbone and jawline improvements even when the body composition trend is moving correctly.", symbol: "flame.fill")
        ]
    }

    private func clampInt(_ value: Double, min lowerBound: Int = 0, max upperBound: Int = 100) -> Int {
        min(upperBound, max(lowerBound, Int(value.rounded())))
    }
}
