//
//  MacroModels.swift
//  AIscend
//

import Foundation

enum NutritionGoalMode: String, CaseIterable, Codable, Identifiable {
    case cut
    case leanBulk
    case maintenance
    case recomposition
    case glowUpChallenge
    case jawlineEnhancement
    case skinRecovery

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cut:
            return "Cut"
        case .leanBulk:
            return "Lean Bulk"
        case .maintenance:
            return "Maintenance"
        case .recomposition:
            return "Recomp"
        case .glowUpChallenge:
            return "Glow-Up"
        case .jawlineEnhancement:
            return "Jawline"
        case .skinRecovery:
            return "Skin Recovery"
        }
    }

    var detail: String {
        switch self {
        case .cut:
            return "Deficit with tissue retention."
        case .leanBulk:
            return "Controlled surplus, low inflammation."
        case .maintenance:
            return "Stable energy and recovery."
        case .recomposition:
            return "Protein-led body recomposition."
        case .glowUpChallenge:
            return "Aggressive aesthetic consistency."
        case .jawlineEnhancement:
            return "Low-puffiness facial definition."
        case .skinRecovery:
            return "Hydration, micronutrients, sleep support."
        }
    }
}

enum NutritionMealType: String, CaseIterable, Codable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case snack
    case supplement
    case hydration

    var id: String { rawValue }

    var title: String {
        switch self {
        case .breakfast:
            return "Breakfast"
        case .lunch:
            return "Lunch"
        case .dinner:
            return "Dinner"
        case .snack:
            return "Snack"
        case .supplement:
            return "Supplement"
        case .hydration:
            return "Hydration"
        }
    }

    var symbol: String {
        switch self {
        case .breakfast:
            return "sunrise.fill"
        case .lunch:
            return "fork.knife"
        case .dinner:
            return "moon.stars.fill"
        case .snack:
            return "sparkles"
        case .supplement:
            return "cross.case.fill"
        case .hydration:
            return "drop.fill"
        }
    }
}

enum NutritionLogSource: String, Codable {
    case manual
    case quickAdd
    case barcode
    case aiVision
    case template
    case duplicate

    var title: String {
        switch self {
        case .manual:
            return "Manual"
        case .quickAdd:
            return "Quick Add"
        case .barcode:
            return "Barcode"
        case .aiVision:
            return "AI Vision"
        case .template:
            return "Template"
        case .duplicate:
            return "Duplicated"
        }
    }
}

struct NutritionMacros: Codable, Equatable, Hashable {
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
    var sodium: Double
    var water: Double
    var sugar: Double
    var potassium: Double

    static let zero = NutritionMacros(
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
        sodium: 0,
        water: 0,
        sugar: 0,
        potassium: 0
    )

    static func + (lhs: NutritionMacros, rhs: NutritionMacros) -> NutritionMacros {
        NutritionMacros(
            calories: lhs.calories + rhs.calories,
            protein: lhs.protein + rhs.protein,
            carbs: lhs.carbs + rhs.carbs,
            fat: lhs.fat + rhs.fat,
            fiber: lhs.fiber + rhs.fiber,
            sodium: lhs.sodium + rhs.sodium,
            water: lhs.water + rhs.water,
            sugar: lhs.sugar + rhs.sugar,
            potassium: lhs.potassium + rhs.potassium
        )
    }
}

struct NutritionMacroTargets: Codable, Equatable {
    var calories: Int
    var burned: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
    var sodiumLimit: Double
    var water: Double
    var potassium: Double

    static let premiumDefault = NutritionMacroTargets(
        calories: 2300,
        burned: 450,
        protein: 165,
        carbs: 235,
        fat: 72,
        fiber: 34,
        sodiumLimit: 2300,
        water: 3.2,
        potassium: 3400
    )
}

struct NutritionMealEntry: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var date: Date
    var mealType: NutritionMealType
    var name: String
    var detail: String
    var macros: NutritionMacros
    var satietyScore: Int
    var glycemicImpact: Int
    var aestheticRating: Int
    var facialImpactEstimate: String
    var source: NutritionLogSource
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        date: Date = .now,
        mealType: NutritionMealType,
        name: String,
        detail: String,
        macros: NutritionMacros,
        satietyScore: Int,
        glycemicImpact: Int,
        aestheticRating: Int,
        facialImpactEstimate: String,
        source: NutritionLogSource = .manual,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.date = date
        self.mealType = mealType
        self.name = name
        self.detail = detail
        self.macros = macros
        self.satietyScore = satietyScore
        self.glycemicImpact = glycemicImpact
        self.aestheticRating = aestheticRating
        self.facialImpactEstimate = facialImpactEstimate
        self.source = source
        self.isFavorite = isFavorite
    }
}

struct NutritionBodyCompositionEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var date: Date
    var weightKg: Double
    var estimatedBodyFat: Double
    var leanMassKg: Double
    var waterRetention: Double
    var facialSharpnessForecast: Int

    init(
        id: UUID = UUID(),
        date: Date = .now,
        weightKg: Double,
        estimatedBodyFat: Double,
        leanMassKg: Double,
        waterRetention: Double,
        facialSharpnessForecast: Int
    ) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.estimatedBodyFat = estimatedBodyFat
        self.leanMassKg = leanMassKg
        self.waterRetention = waterRetention
        self.facialSharpnessForecast = facialSharpnessForecast
    }
}

struct AestheticNutritionScores: Codable, Equatable {
    var nutritionQuality: Int
    var inflammationRisk: Int
    var hydrationQuality: Int
    var skinSupport: Int
    var aestheticOptimisation: Int

    var faceImpactScore: Int {
        max(0, min(100, aestheticOptimisation))
    }
}

enum NutritionInsightSeverity: String, Codable {
    case advantage
    case watch
    case risk

    var badge: String {
        switch self {
        case .advantage:
            return "Advantage"
        case .watch:
            return "Watch"
        case .risk:
            return "Risk"
        }
    }
}

struct NutritionInsight: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var detail: String
    var symbol: String
    var severity: NutritionInsightSeverity

    init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        symbol: String,
        severity: NutritionInsightSeverity
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.symbol = symbol
        self.severity = severity
    }
}

struct NutritionRecommendation: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var detail: String
    var symbol: String
    var priority: Int

    init(id: UUID = UUID(), title: String, detail: String, symbol: String, priority: Int) {
        self.id = id
        self.title = title
        self.detail = detail
        self.symbol = symbol
        self.priority = priority
    }
}

struct NutritionTrendPoint: Identifiable, Codable, Equatable {
    var id: UUID
    var label: String
    var score: Double

    init(id: UUID = UUID(), label: String, score: Double) {
        self.id = id
        self.label = label
        self.score = score
    }
}

struct NutritionDailySummary: Equatable {
    let date: Date
    let macros: NutritionMacros
    let targets: NutritionMacroTargets
    let scores: AestheticNutritionScores
    let insights: [NutritionInsight]
    let recommendations: [NutritionRecommendation]
    let trend: [NutritionTrendPoint]

    var calorieDelta: Int {
        macros.calories - targets.calories
    }

    var netCalories: Int {
        macros.calories - targets.burned
    }
}

extension Calendar {
    func isDateInCurrentWeek(_ date: Date, now: Date = .now) -> Bool {
        isDate(date, equalTo: now, toGranularity: .weekOfYear)
    }
}
