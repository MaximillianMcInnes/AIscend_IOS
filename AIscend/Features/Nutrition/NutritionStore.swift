//
//  NutritionStore.swift
//  AIscend
//

import Combine
import Foundation

@MainActor
final class NutritionStore: ObservableObject {
    @Published var selectedGoal: NutritionGoalMode = .jawlineEnhancement {
        didSet { recalculateTargetsAndPersist() }
    }
    @Published private(set) var targets: NutritionMacroTargets = .premiumDefault
    @Published private(set) var mealEntries: [NutritionMealEntry] = []
    @Published private(set) var bodyCompositionEntries: [NutritionBodyCompositionEntry] = []
    @Published private(set) var nutritionStreak = 6
    @Published private(set) var hydrationStreak = 4
    @Published private(set) var proteinStreak = 5
    @Published private(set) var facialOptimisationStreak = 3

    private let calorieEngine = CalorieEngine()
    private let scoreEngine = AestheticNutritionScoreEngine()
    private let aiEngine = NutritionAIEngine()
    private var userNamespace = "local"

    private var storageKey: String {
        "aiscend.nutrition.state.\(userNamespace)"
    }

    init() {
        restoreOrSeed()
    }

    func applyAuthenticatedUserID(_ userID: String?) {
        let nextNamespace = userID?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? userID! : "local"
        guard nextNamespace != userNamespace else {
            return
        }

        userNamespace = nextNamespace
        restoreOrSeed()
    }

    func entries(on date: Date = .now) -> [NutritionMealEntry] {
        mealEntries
            .filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date < $1.date }
    }

    func recentMeals(limit: Int = 6) -> [NutritionMealEntry] {
        Array(mealEntries.sorted { $0.date > $1.date }.prefix(limit))
    }

    func favoriteMeals() -> [NutritionMealEntry] {
        mealEntries
            .filter(\.isFavorite)
            .sorted { $0.name < $1.name }
    }

    func templates() -> [NutritionMealEntry] {
        [
            NutritionMealEntry(
                mealType: .breakfast,
                name: "Greek yoghurt protocol",
                detail: "Yoghurt, berries, honey, collagen",
                macros: NutritionMacros(calories: 430, protein: 42, carbs: 44, fat: 9, fiber: 8, sodium: 160, water: 0.2, sugar: 26, potassium: 520),
                satietyScore: 78,
                glycemicImpact: 38,
                aestheticRating: 88,
                facialImpactEstimate: "High protein and collagen support; low sodium facial load.",
                source: .template,
                isFavorite: true
            ),
            NutritionMealEntry(
                mealType: .dinner,
                name: "Lean salmon plate",
                detail: "Salmon, potato, greens, olive oil",
                macros: NutritionMacros(calories: 690, protein: 54, carbs: 58, fat: 26, fiber: 11, sodium: 520, water: 0.3, sugar: 7, potassium: 1180),
                satietyScore: 88,
                glycemicImpact: 42,
                aestheticRating: 91,
                facialImpactEstimate: "Recovery-positive fats and potassium support sharpness.",
                source: .template,
                isFavorite: true
            )
        ]
    }

    func addMeal(_ meal: NutritionMealEntry) {
        mealEntries.append(meal)
        updateStreaks()
        persist()
    }

    func duplicate(_ meal: NutritionMealEntry, as type: NutritionMealType? = nil) {
        var duplicate = meal
        duplicate.id = UUID()
        duplicate.date = .now
        duplicate.mealType = type ?? meal.mealType
        duplicate.source = .duplicate
        mealEntries.append(duplicate)
        updateStreaks()
        persist()
    }

    func toggleFavorite(_ meal: NutritionMealEntry) {
        guard let index = mealEntries.firstIndex(where: { $0.id == meal.id }) else {
            return
        }

        mealEntries[index].isFavorite.toggle()
        persist()
    }

    func logHydration(liters: Double) {
        addMeal(
            NutritionMealEntry(
                mealType: .hydration,
                name: "\(String(format: "%.1f", liters))L hydration",
                detail: "Water intake logged",
                macros: NutritionMacros(calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, sodium: 0, water: liters, sugar: 0, potassium: 0),
                satietyScore: 0,
                glycemicImpact: 0,
                aestheticRating: 84,
                facialImpactEstimate: "Hydration improves next-day facial sharpness stability.",
                source: .quickAdd
            )
        )
    }

    func addBodyComposition(weightKg: Double, bodyFat: Double) {
        let leanMass = weightKg * (1 - bodyFat / 100)
        let todayMacros = totalMacros()
        let scores = scoreEngine.scores(macros: todayMacros, targets: targets, goal: selectedGoal)
        bodyCompositionEntries.append(
            NutritionBodyCompositionEntry(
                weightKg: weightKg,
                estimatedBodyFat: bodyFat,
                leanMassKg: leanMass,
                waterRetention: max(0, min(100, Double(scores.inflammationRisk) * 0.72 + Double(max(0, Int(todayMacros.sodium - targets.sodiumLimit))) / 55)),
                facialSharpnessForecast: max(0, min(100, scores.aestheticOptimisation - scores.inflammationRisk / 5))
            )
        )
        recalculateTargetsAndPersist()
    }

    func totalMacros(on date: Date = .now) -> NutritionMacros {
        entries(on: date).reduce(.zero) { partialResult, entry in
            partialResult + entry.macros
        }
    }

    func summary(on date: Date = .now) -> NutritionDailySummary {
        let macros = totalMacros(on: date)
        let scores = scoreEngine.scores(macros: macros, targets: targets, goal: selectedGoal)
        return NutritionDailySummary(
            date: date,
            macros: macros,
            targets: targets,
            scores: scores,
            insights: aiEngine.insights(macros: macros, targets: targets, scores: scores, goal: selectedGoal),
            recommendations: aiEngine.recommendations(macros: macros, targets: targets, scores: scores, goal: selectedGoal),
            trend: weeklyTrend()
        )
    }

    func weeklyTrend(now: Date = .now) -> [NutritionTrendPoint] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "E"

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset - 6, to: now) else {
                return nil
            }

            let macros = totalMacros(on: date)
            let scores = scoreEngine.scores(macros: macros, targets: targets, goal: selectedGoal)
            let fallback = 68 + (offset * 3 % 19)
            return NutritionTrendPoint(
                label: formatter.string(from: date),
                score: macros.calories == 0 ? Double(fallback) : Double(scores.aestheticOptimisation)
            )
        }
    }

    private func recalculateTargetsAndPersist() {
        let latestBody = bodyCompositionEntries.sorted { $0.date > $1.date }.first
        targets = calorieEngine.targets(
            for: selectedGoal,
            bodyWeightKg: latestBody?.weightKg,
            leanMassKg: latestBody?.leanMassKg,
            currentTargets: targets
        )
        persist()
    }

    private func updateStreaks() {
        let summary = summary()
        nutritionStreak = summary.scores.nutritionQuality >= 72 ? nutritionStreak + 1 : max(0, nutritionStreak - 1)
        hydrationStreak = summary.scores.hydrationQuality >= 74 ? hydrationStreak + 1 : max(0, hydrationStreak - 1)
        proteinStreak = summary.macros.protein >= targets.protein * 0.9 ? proteinStreak + 1 : max(0, proteinStreak - 1)
        facialOptimisationStreak = summary.scores.aestheticOptimisation >= 76 ? facialOptimisationStreak + 1 : max(0, facialOptimisationStreak - 1)
    }

    private func restoreOrSeed() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let state = try? JSONDecoder().decode(PersistedNutritionState.self, from: data)
        else {
            seed()
            return
        }

        selectedGoal = state.selectedGoal
        targets = state.targets
        mealEntries = state.mealEntries
        bodyCompositionEntries = state.bodyCompositionEntries
        nutritionStreak = state.nutritionStreak
        hydrationStreak = state.hydrationStreak
        proteinStreak = state.proteinStreak
        facialOptimisationStreak = state.facialOptimisationStreak
    }

    private func seed() {
        let calendar = Calendar.current
        func todayAt(_ hour: Int, _ minute: Int) -> Date {
            calendar.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
        }

        selectedGoal = .jawlineEnhancement
        bodyCompositionEntries = [
            NutritionBodyCompositionEntry(date: calendar.date(byAdding: .day, value: -21, to: .now) ?? .now, weightKg: 80.8, estimatedBodyFat: 17.4, leanMassKg: 66.7, waterRetention: 42, facialSharpnessForecast: 72),
            NutritionBodyCompositionEntry(date: calendar.date(byAdding: .day, value: -10, to: .now) ?? .now, weightKg: 79.9, estimatedBodyFat: 16.8, leanMassKg: 66.5, waterRetention: 37, facialSharpnessForecast: 76),
            NutritionBodyCompositionEntry(date: .now, weightKg: 79.3, estimatedBodyFat: 16.2, leanMassKg: 66.5, waterRetention: 31, facialSharpnessForecast: 82)
        ]
        targets = calorieEngine.targets(for: selectedGoal, bodyWeightKg: 79.3, leanMassKg: 66.5)
        mealEntries = [
            NutritionMealEntry(
                date: todayAt(8, 20),
                mealType: .breakfast,
                name: "Protein oats",
                detail: "Oats, whey, blueberries, chia",
                macros: NutritionMacros(calories: 520, protein: 43, carbs: 61, fat: 12, fiber: 12, sodium: 230, water: 0.2, sugar: 16, potassium: 640),
                satietyScore: 84,
                glycemicImpact: 46,
                aestheticRating: 88,
                facialImpactEstimate: "Stable energy with low puffiness load.",
                source: .manual,
                isFavorite: true
            ),
            NutritionMealEntry(
                date: todayAt(12, 50),
                mealType: .lunch,
                name: "Chicken rice bowl",
                detail: "Chicken, jasmine rice, avocado, greens",
                macros: NutritionMacros(calories: 760, protein: 58, carbs: 82, fat: 21, fiber: 10, sodium: 790, water: 0.2, sugar: 8, potassium: 1040),
                satietyScore: 86,
                glycemicImpact: 58,
                aestheticRating: 82,
                facialImpactEstimate: "Protein-forward; sodium moderate.",
                source: .manual
            ),
            NutritionMealEntry(
                date: todayAt(15, 25),
                mealType: .hydration,
                name: "Mineral water",
                detail: "Electrolyte-enhanced water",
                macros: NutritionMacros(calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, sodium: 120, water: 1.1, sugar: 0, potassium: 280),
                satietyScore: 0,
                glycemicImpact: 0,
                aestheticRating: 87,
                facialImpactEstimate: "Hydration improved sharpness forecast.",
                source: .quickAdd
            )
        ]
        persist()
    }

    private func persist() {
        let state = PersistedNutritionState(
            selectedGoal: selectedGoal,
            targets: targets,
            mealEntries: mealEntries,
            bodyCompositionEntries: bodyCompositionEntries,
            nutritionStreak: nutritionStreak,
            hydrationStreak: hydrationStreak,
            proteinStreak: proteinStreak,
            facialOptimisationStreak: facialOptimisationStreak
        )

        guard let data = try? JSONEncoder().encode(state) else {
            return
        }

        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

private struct PersistedNutritionState: Codable {
    let selectedGoal: NutritionGoalMode
    let targets: NutritionMacroTargets
    let mealEntries: [NutritionMealEntry]
    let bodyCompositionEntries: [NutritionBodyCompositionEntry]
    let nutritionStreak: Int
    let hydrationStreak: Int
    let proteinStreak: Int
    let facialOptimisationStreak: Int
}
