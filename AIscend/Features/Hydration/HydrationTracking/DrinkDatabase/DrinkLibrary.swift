//
//  DrinkLibrary.swift
//  AIscend
//
//  Created by Codex on 5/10/26.
//

import Foundation

protocol DrinkLibraryProviding {
    var drinks: [DrinkItem] { get }

    func search(query: String) -> [DrinkItem]
    func drinks(in category: DrinkCategory) -> [DrinkItem]
    func popularDrinks() -> [DrinkItem]
    func recentCompatibleDrinks(from logs: [DrinkLogEntry]) -> [DrinkItem]
    func drink(id: String) -> DrinkItem?
    func createCustomDrink(
        name: String,
        brand: String?,
        category: DrinkCategory,
        defaultServingMl: Int,
        hydrationMultiplier: Double,
        sodiumMg: Int,
        potassiumMg: Int,
        magnesiumMg: Int,
        caffeineMg: Int,
        calories: Int,
        sugarG: Double,
        notes: String
    ) -> DrinkItem
}

struct DrinkLibrary: DrinkLibraryProviding {
    static let shared = DrinkLibrary()

    let drinks: [DrinkItem]

    private let popularDrinkIDs: [String]

    init(
        drinks: [DrinkItem] = DrinkLibrary.seededDrinks,
        popularDrinkIDs: [String] = DrinkLibrary.defaultPopularDrinkIDs
    ) {
        self.drinks = drinks
        self.popularDrinkIDs = popularDrinkIDs
    }

    func search(query: String) -> [DrinkItem] {
        let normalizedQuery = normalized(query)

        guard !normalizedQuery.isEmpty else {
            return popularDrinks()
        }

        return drinks
            .compactMap { drink -> RankedDrink? in
                let score = searchScore(for: drink, query: normalizedQuery)
                guard score > 0 else { return nil }
                return RankedDrink(drink: drink, score: score)
            }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score {
                    return lhs.score > rhs.score
                }

                return lhs.drink.name.localizedCaseInsensitiveCompare(rhs.drink.name) == .orderedAscending
            }
            .map(\.drink)
    }

    func drinks(in category: DrinkCategory) -> [DrinkItem] {
        drinks
            .filter { $0.category == category }
            .sorted { lhs, rhs in
                if isPopular(lhs) != isPopular(rhs) {
                    return isPopular(lhs)
                }

                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    func popularDrinks() -> [DrinkItem] {
        popularDrinkIDs.compactMap { drink(id: $0) }
    }

    func recentCompatibleDrinks(from logs: [DrinkLogEntry]) -> [DrinkItem] {
        let sortedLogs = logs.sorted { lhs, rhs in
            lhs.loggedAt > rhs.loggedAt
        }

        var seenIDs = Set<String>()
        var recentDrinks: [DrinkItem] = []

        for log in sortedLogs {
            guard seenIDs.insert(log.drinkId).inserted else {
                continue
            }

            if let drink = drink(id: log.drinkId) {
                recentDrinks.append(drink)
            } else {
                recentDrinks.append(createCustomDrink(from: log))
            }
        }

        return recentDrinks
    }

    func drink(id: String) -> DrinkItem? {
        drinks.first { $0.id == id }
    }

    func createCustomDrink(
        name: String,
        brand: String? = nil,
        category: DrinkCategory = .custom,
        defaultServingMl: Int,
        hydrationMultiplier: Double,
        sodiumMg: Int = 0,
        potassiumMg: Int = 0,
        magnesiumMg: Int = 0,
        caffeineMg: Int = 0,
        calories: Int = 0,
        sugarG: Double = 0,
        notes: String = ""
    ) -> DrinkItem {
        let resolvedNotes = notes.isEmpty
            ? "User-entered values are approximate."
            : "\(notes) Values are approximate."

        return DrinkItem(
            name: name,
            brand: brand,
            category: category,
            servingSize: DrinkServingSize(name: "Default Serving", amountMl: max(defaultServingMl, 1)),
            hydrationProfile: DrinkHydrationProfile(effectivenessMultiplier: max(hydrationMultiplier, 0)),
            nutritionProfile: DrinkNutritionProfile(
                caffeineMg: max(caffeineMg, 0),
                sugarG: max(sugarG, 0),
                calories: max(calories, 0)
            ),
            electrolyteProfile: DrinkElectrolyteProfile(
                sodiumMg: max(sodiumMg, 0),
                potassiumMg: max(potassiumMg, 0),
                magnesiumMg: max(magnesiumMg, 0)
            ),
            notes: resolvedNotes,
            isCustom: true
        )
    }
}

private extension DrinkLibrary {
    struct RankedDrink {
        let drink: DrinkItem
        let score: Int
    }

    static let defaultPopularDrinkIDs: [String] = [
        "water",
        "sparkling-water",
        "electrolyte-tablet-drink",
        "black-coffee",
        "green-tea",
        "lucozade-sport",
        "gatorade",
        "protein-shake"
    ]

    static let seededDrinks: [DrinkItem] = [
        seed(
            id: "water",
            name: "Water",
            category: .water,
            servingMl: 500,
            hydrationMultiplier: 1,
            notes: "Plain still water. Values are approximate."
        ),
        seed(
            id: "sparkling-water",
            name: "Sparkling Water",
            category: .sparklingWater,
            servingMl: 330,
            hydrationMultiplier: 1,
            notes: "Unsweetened sparkling water. Values are approximate."
        ),
        seed(
            id: "coconut-water",
            name: "Coconut Water",
            category: .juice,
            servingMl: 330,
            hydrationMultiplier: 0.9,
            sodiumMg: 80,
            potassiumMg: 600,
            magnesiumMg: 25,
            calories: 60,
            sugarG: 14,
            notes: "Plain coconut water. Values are approximate."
        ),
        seed(
            id: "electrolyte-tablet-drink",
            name: "Electrolyte Tablet Drink",
            category: .electrolyteDrink,
            servingMl: 500,
            hydrationMultiplier: 1,
            sodiumMg: 300,
            potassiumMg: 75,
            magnesiumMg: 25,
            calories: 10,
            sugarG: 1,
            notes: "Low-sugar tablet mixed with water. Values are approximate."
        ),
        seed(
            id: "lucozade-sport",
            name: "Lucozade Sport",
            brand: "Lucozade",
            category: .sportsDrink,
            servingMl: 500,
            hydrationMultiplier: 0.9,
            sodiumMg: 250,
            potassiumMg: 60,
            calories: 140,
            sugarG: 18,
            notes: "Bottled sports drink. Values are approximate."
        ),
        seed(
            id: "powerade",
            name: "Powerade",
            brand: "Powerade",
            category: .sportsDrink,
            servingMl: 500,
            hydrationMultiplier: 0.9,
            sodiumMg: 250,
            potassiumMg: 60,
            calories: 95,
            sugarG: 20,
            notes: "Bottled sports drink. Values are approximate."
        ),
        seed(
            id: "gatorade",
            name: "Gatorade",
            brand: "Gatorade",
            category: .sportsDrink,
            servingMl: 591,
            hydrationMultiplier: 0.9,
            sodiumMg: 270,
            potassiumMg: 75,
            calories: 140,
            sugarG: 34,
            notes: "Bottled sports drink. Values are approximate."
        ),
        seed(
            id: "black-coffee",
            name: "Black Coffee",
            category: .coffee,
            servingMl: 240,
            hydrationMultiplier: 0.85,
            caffeineMg: 95,
            calories: 2,
            notes: "Brewed coffee without milk or sugar. Values are approximate."
        ),
        seed(
            id: "latte",
            name: "Latte",
            category: .coffee,
            servingMl: 350,
            hydrationMultiplier: 0.8,
            sodiumMg: 150,
            potassiumMg: 380,
            magnesiumMg: 35,
            caffeineMg: 90,
            calories: 180,
            sugarG: 15,
            notes: "Coffee with milk. Values are approximate."
        ),
        seed(
            id: "green-tea",
            name: "Green Tea",
            category: .tea,
            servingMl: 240,
            hydrationMultiplier: 0.9,
            caffeineMg: 30,
            calories: 2,
            notes: "Plain brewed green tea. Values are approximate."
        ),
        seed(
            id: "english-breakfast-tea",
            name: "English Breakfast Tea",
            category: .tea,
            servingMl: 240,
            hydrationMultiplier: 0.9,
            caffeineMg: 45,
            calories: 2,
            notes: "Plain brewed black tea. Values are approximate."
        ),
        seed(
            id: "orange-juice",
            name: "Orange Juice",
            category: .juice,
            servingMl: 250,
            hydrationMultiplier: 0.8,
            sodiumMg: 2,
            potassiumMg: 450,
            magnesiumMg: 27,
            calories: 110,
            sugarG: 21,
            notes: "Ready-to-drink orange juice. Values are approximate."
        ),
        seed(
            id: "apple-juice",
            name: "Apple Juice",
            category: .juice,
            servingMl: 250,
            hydrationMultiplier: 0.8,
            sodiumMg: 10,
            potassiumMg: 250,
            magnesiumMg: 12,
            calories: 115,
            sugarG: 24,
            notes: "Ready-to-drink apple juice. Values are approximate."
        ),
        seed(
            id: "coke",
            name: "Coke",
            brand: "Coca-Cola",
            category: .softDrink,
            servingMl: 330,
            hydrationMultiplier: 0.7,
            sodiumMg: 35,
            caffeineMg: 32,
            calories: 139,
            sugarG: 35,
            notes: "Regular cola. Values are approximate."
        ),
        seed(
            id: "diet-coke",
            name: "Diet Coke",
            brand: "Coca-Cola",
            category: .softDrink,
            servingMl: 330,
            hydrationMultiplier: 0.75,
            sodiumMg: 40,
            caffeineMg: 42,
            calories: 1,
            notes: "Diet cola. Values are approximate."
        ),
        seed(
            id: "red-bull",
            name: "Red Bull",
            brand: "Red Bull",
            category: .energyDrink,
            servingMl: 250,
            hydrationMultiplier: 0.65,
            sodiumMg: 100,
            caffeineMg: 80,
            calories: 110,
            sugarG: 27,
            notes: "Regular energy drink. Values are approximate."
        ),
        seed(
            id: "monster-energy",
            name: "Monster Energy",
            brand: "Monster",
            category: .energyDrink,
            servingMl: 500,
            hydrationMultiplier: 0.65,
            sodiumMg: 370,
            caffeineMg: 160,
            calories: 210,
            sugarG: 54,
            notes: "Regular energy drink. Values are approximate."
        ),
        seed(
            id: "protein-shake",
            name: "Protein Shake",
            category: .proteinShake,
            servingMl: 330,
            hydrationMultiplier: 0.8,
            sodiumMg: 180,
            potassiumMg: 300,
            magnesiumMg: 40,
            calories: 180,
            sugarG: 5,
            notes: "Ready-to-drink protein shake. Values are approximate."
        ),
        seed(
            id: "milk",
            name: "Milk",
            category: .milk,
            servingMl: 250,
            hydrationMultiplier: 0.9,
            sodiumMg: 105,
            potassiumMg: 322,
            magnesiumMg: 24,
            calories: 150,
            sugarG: 12,
            notes: "Plain whole milk. Values are approximate."
        ),
        seed(
            id: "smoothie",
            name: "Smoothie",
            category: .smoothie,
            servingMl: 350,
            hydrationMultiplier: 0.75,
            sodiumMg: 45,
            potassiumMg: 520,
            magnesiumMg: 42,
            calories: 220,
            sugarG: 32,
            notes: "Fruit smoothie with yogurt. Values are approximate."
        )
    ]

    static func seed(
        id: String,
        name: String,
        brand: String? = nil,
        category: DrinkCategory,
        servingMl: Int,
        hydrationMultiplier: Double,
        sodiumMg: Int = 0,
        potassiumMg: Int = 0,
        magnesiumMg: Int = 0,
        caffeineMg: Int = 0,
        calories: Int = 0,
        sugarG: Double = 0,
        notes: String
    ) -> DrinkItem {
        DrinkItem(
            id: id,
            name: name,
            brand: brand,
            category: category,
            servingSize: DrinkServingSize(id: "\(id)-serving", name: "Default Serving", amountMl: servingMl),
            hydrationProfile: DrinkHydrationProfile(effectivenessMultiplier: hydrationMultiplier),
            nutritionProfile: DrinkNutritionProfile(caffeineMg: caffeineMg, sugarG: sugarG, calories: calories),
            electrolyteProfile: DrinkElectrolyteProfile(
                sodiumMg: sodiumMg,
                potassiumMg: potassiumMg,
                magnesiumMg: magnesiumMg
            ),
            notes: notes
        )
    }

    func createCustomDrink(from log: DrinkLogEntry) -> DrinkItem {
        DrinkItem(
            id: log.drinkId,
            name: log.drinkName,
            category: log.drinkCategory ?? .custom,
            servingSize: DrinkServingSize(name: "Logged Serving", amountMl: max(log.amountMl, 1)),
            hydrationProfile: DrinkHydrationProfile(effectivenessMultiplier: log.hydrationCreditRatio),
            nutritionProfile: DrinkNutritionProfile(
                caffeineMg: log.caffeineMg,
                sugarG: log.sugarG,
                calories: log.calories
            ),
            electrolyteProfile: DrinkElectrolyteProfile(
                sodiumMg: log.sodiumMg,
                potassiumMg: log.potassiumMg,
                magnesiumMg: log.magnesiumMg
            ),
            notes: "Recreated from a previous drink log. Values are approximate.",
            isCustom: true
        )
    }

    func searchScore(for drink: DrinkItem, query: String) -> Int {
        let fields = searchableFields(for: drink)
        var score = 0

        if normalized(drink.name) == query {
            score += 120
        }

        if normalized(drink.brand ?? "") == query {
            score += 90
        }

        if normalized(drink.category.rawValue) == query || normalized(drink.category.title) == query {
            score += 70
        }

        if fields.contains(where: { $0.hasPrefix(query) }) {
            score += 45
        }

        if fields.contains(where: { $0.contains(query) }) {
            score += 25
        }

        if isPopular(drink) {
            score += 15
        }

        return score
    }

    func searchableFields(for drink: DrinkItem) -> [String] {
        [
            drink.name,
            drink.brand ?? "",
            drink.category.rawValue,
            drink.category.title
        ].map(normalized)
    }

    func isPopular(_ drink: DrinkItem) -> Bool {
        popularDrinkIDs.contains(drink.id)
    }

    func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }
}
