//
//  DrinkDatabaseModels.swift
//  AIscend
//
//  Created by Codex on 5/10/26.
//

import Foundation

enum DrinkCategory: String, CaseIterable, Codable, Identifiable, Hashable, Sendable {
    case water
    case sparklingWater
    case electrolyteDrink
    case sportsDrink
    case coffee
    case tea
    case milk
    case juice
    case smoothie
    case softDrink
    case energyDrink
    case proteinShake
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .water:
            return "Water"
        case .sparklingWater:
            return "Sparkling Water"
        case .electrolyteDrink:
            return "Electrolyte Drink"
        case .sportsDrink:
            return "Sports Drink"
        case .coffee:
            return "Coffee"
        case .tea:
            return "Tea"
        case .milk:
            return "Milk"
        case .juice:
            return "Juice"
        case .smoothie:
            return "Smoothie"
        case .softDrink:
            return "Soft Drink"
        case .energyDrink:
            return "Energy Drink"
        case .proteinShake:
            return "Protein Shake"
        case .custom:
            return "Custom"
        }
    }
}

struct DrinkServingSize: Codable, Equatable, Hashable, Identifiable, Sendable {
    var id: String
    var name: String
    var amountMl: Int

    init(
        id: String = UUID().uuidString,
        name: String,
        amountMl: Int
    ) {
        self.id = id
        self.name = name
        self.amountMl = amountMl
    }
}

struct DrinkNutritionProfile: Codable, Equatable, Hashable, Sendable {
    var caffeineMg: Int
    var sugarG: Double
    var calories: Int

    static let zero = DrinkNutritionProfile(caffeineMg: 0, sugarG: 0, calories: 0)

    init(
        caffeineMg: Int = 0,
        sugarG: Double = 0,
        calories: Int = 0
    ) {
        self.caffeineMg = caffeineMg
        self.sugarG = sugarG
        self.calories = calories
    }

    func scaled(from servingSizeMl: Int, to amountMl: Int) -> DrinkNutritionProfile {
        guard servingSizeMl > 0 else { return self }

        let scale = Double(amountMl) / Double(servingSizeMl)
        return DrinkNutritionProfile(
            caffeineMg: Int((Double(caffeineMg) * scale).rounded()),
            sugarG: sugarG * scale,
            calories: Int((Double(calories) * scale).rounded())
        )
    }
}

struct DrinkElectrolyteProfile: Codable, Equatable, Hashable, Sendable {
    var sodiumMg: Int
    var potassiumMg: Int
    var magnesiumMg: Int

    static let zero = DrinkElectrolyteProfile(sodiumMg: 0, potassiumMg: 0, magnesiumMg: 0)

    init(
        sodiumMg: Int = 0,
        potassiumMg: Int = 0,
        magnesiumMg: Int = 0
    ) {
        self.sodiumMg = sodiumMg
        self.potassiumMg = potassiumMg
        self.magnesiumMg = magnesiumMg
    }

    var totalElectrolytesMg: Int {
        sodiumMg + potassiumMg + magnesiumMg
    }

    func scaled(from servingSizeMl: Int, to amountMl: Int) -> DrinkElectrolyteProfile {
        guard servingSizeMl > 0 else { return self }

        let scale = Double(amountMl) / Double(servingSizeMl)
        return DrinkElectrolyteProfile(
            sodiumMg: Int((Double(sodiumMg) * scale).rounded()),
            potassiumMg: Int((Double(potassiumMg) * scale).rounded()),
            magnesiumMg: Int((Double(magnesiumMg) * scale).rounded())
        )
    }
}

struct DrinkHydrationProfile: Codable, Equatable, Hashable, Sendable {
    var effectivenessMultiplier: Double

    init(effectivenessMultiplier: Double = 1) {
        self.effectivenessMultiplier = effectivenessMultiplier
    }

    func hydrationCreditMl(for amountMl: Int) -> Int {
        Int((Double(amountMl) * effectivenessMultiplier).rounded())
    }
}

struct DrinkItem: Codable, Equatable, Hashable, Identifiable, Sendable {
    var id: String
    var name: String
    var brand: String?
    var category: DrinkCategory
    var servingSize: DrinkServingSize
    var hydrationProfile: DrinkHydrationProfile
    var nutritionProfile: DrinkNutritionProfile
    var electrolyteProfile: DrinkElectrolyteProfile
    var notes: String
    var isCustom: Bool
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        brand: String? = nil,
        category: DrinkCategory,
        servingSize: DrinkServingSize,
        hydrationProfile: DrinkHydrationProfile = DrinkHydrationProfile(),
        nutritionProfile: DrinkNutritionProfile = .zero,
        electrolyteProfile: DrinkElectrolyteProfile = .zero,
        notes: String = "",
        isCustom: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.category = category
        self.servingSize = servingSize
        self.hydrationProfile = hydrationProfile
        self.nutritionProfile = nutritionProfile
        self.electrolyteProfile = electrolyteProfile
        self.notes = notes
        self.isCustom = isCustom
        self.createdAt = createdAt
    }

    var servingSizeMl: Int {
        servingSize.amountMl
    }

    var hydrationEffectivenessMultiplier: Double {
        hydrationProfile.effectivenessMultiplier
    }

    var caffeineMg: Int {
        nutritionProfile.caffeineMg
    }

    var sugarG: Double {
        nutritionProfile.sugarG
    }

    var calories: Int {
        nutritionProfile.calories
    }

    var sodiumMg: Int {
        electrolyteProfile.sodiumMg
    }

    var potassiumMg: Int {
        electrolyteProfile.potassiumMg
    }

    var magnesiumMg: Int {
        electrolyteProfile.magnesiumMg
    }

    var hydrationCreditMl: Int {
        hydrationCreditMl(for: servingSizeMl)
    }

    var totalElectrolytesMg: Int {
        electrolyteProfile.totalElectrolytesMg
    }

    func hydrationCreditMl(for amountMl: Int) -> Int {
        hydrationProfile.hydrationCreditMl(for: amountMl)
    }

    func nutritionTotals(for amountMl: Int) -> DrinkNutritionProfile {
        nutritionProfile.scaled(from: servingSizeMl, to: amountMl)
    }

    func electrolyteTotals(for amountMl: Int) -> DrinkElectrolyteProfile {
        electrolyteProfile.scaled(from: servingSizeMl, to: amountMl)
    }

    func logEntry(amountMl: Int, loggedAt: Date = .now) -> DrinkLogEntry {
        let nutrition = nutritionTotals(for: amountMl)
        let electrolytes = electrolyteTotals(for: amountMl)

        return DrinkLogEntry(
            drinkId: id,
            drinkName: name,
            amountMl: amountMl,
            loggedAt: loggedAt,
            hydrationCreditMl: hydrationCreditMl(for: amountMl),
            sodiumMg: electrolytes.sodiumMg,
            potassiumMg: electrolytes.potassiumMg,
            magnesiumMg: electrolytes.magnesiumMg,
            caffeineMg: nutrition.caffeineMg,
            calories: nutrition.calories,
            sugarG: nutrition.sugarG,
            drinkCategory: category
        )
    }
}

struct DrinkLogEntry: Codable, Equatable, Hashable, Identifiable, Sendable {
    var id: String
    var drinkId: String
    var drinkName: String
    var amountMl: Int
    var loggedAt: Date
    var hydrationCreditMl: Int
    var sodiumMg: Int
    var potassiumMg: Int
    var magnesiumMg: Int
    var caffeineMg: Int
    var calories: Int
    var sugarG: Double
    var drinkCategory: DrinkCategory?
    var createdAt: Date?
    var updatedAt: Date?

    init(
        id: String = UUID().uuidString,
        drinkId: String,
        drinkName: String,
        amountMl: Int,
        loggedAt: Date = .now,
        hydrationCreditMl: Int,
        sodiumMg: Int = 0,
        potassiumMg: Int = 0,
        magnesiumMg: Int = 0,
        caffeineMg: Int = 0,
        calories: Int = 0,
        sugarG: Double = 0,
        drinkCategory: DrinkCategory? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.drinkId = drinkId
        self.drinkName = drinkName
        self.amountMl = amountMl
        self.loggedAt = loggedAt
        self.hydrationCreditMl = hydrationCreditMl
        self.sodiumMg = sodiumMg
        self.potassiumMg = potassiumMg
        self.magnesiumMg = magnesiumMg
        self.caffeineMg = caffeineMg
        self.calories = calories
        self.sugarG = sugarG
        self.drinkCategory = drinkCategory
        self.createdAt = createdAt ?? loggedAt
        self.updatedAt = updatedAt ?? loggedAt
    }

    var totalElectrolytesMg: Int {
        sodiumMg + potassiumMg + magnesiumMg
    }

    var hydrationCreditRatio: Double {
        guard amountMl > 0 else { return 0 }
        return Double(hydrationCreditMl) / Double(amountMl)
    }
}

extension DrinkItem {
    static let sampleData: [DrinkItem] = [
        DrinkItem(
            id: "plain-water-500ml",
            name: "Still Water",
            category: .water,
            servingSize: DrinkServingSize(id: "bottle-500ml", name: "Bottle", amountMl: 500),
            hydrationProfile: DrinkHydrationProfile(effectivenessMultiplier: 1),
            notes: "Plain still water."
        ),
        DrinkItem(
            id: "sparkling-water-330ml",
            name: "Sparkling Water",
            category: .sparklingWater,
            servingSize: DrinkServingSize(id: "can-330ml", name: "Can", amountMl: 330),
            hydrationProfile: DrinkHydrationProfile(effectivenessMultiplier: 1),
            notes: "Unsweetened sparkling water."
        ),
        DrinkItem(
            id: "electrolyte-tablet-500ml",
            name: "Electrolyte Tablet Drink",
            category: .electrolyteDrink,
            servingSize: DrinkServingSize(id: "mixed-bottle-500ml", name: "Mixed Bottle", amountMl: 500),
            hydrationProfile: DrinkHydrationProfile(effectivenessMultiplier: 1),
            nutritionProfile: DrinkNutritionProfile(calories: 10),
            electrolyteProfile: DrinkElectrolyteProfile(sodiumMg: 300, potassiumMg: 75, magnesiumMg: 25),
            notes: "Typical low-sugar tablet mixed with water."
        ),
        DrinkItem(
            id: "sports-drink-591ml",
            name: "Sports Drink",
            category: .sportsDrink,
            servingSize: DrinkServingSize(id: "bottle-591ml", name: "Bottle", amountMl: 591),
            hydrationProfile: DrinkHydrationProfile(effectivenessMultiplier: 0.95),
            nutritionProfile: DrinkNutritionProfile(sugarG: 34, calories: 130),
            electrolyteProfile: DrinkElectrolyteProfile(sodiumMg: 270, potassiumMg: 75),
            notes: "Standard flavored sports drink."
        ),
        DrinkItem(
            id: "black-coffee-240ml",
            name: "Black Coffee",
            category: .coffee,
            servingSize: DrinkServingSize(id: "mug-240ml", name: "Mug", amountMl: 240),
            hydrationProfile: DrinkHydrationProfile(effectivenessMultiplier: 0.85),
            nutritionProfile: DrinkNutritionProfile(caffeineMg: 95, calories: 2),
            notes: "Brewed coffee without milk or sugar."
        ),
        DrinkItem(
            id: "green-tea-240ml",
            name: "Green Tea",
            category: .tea,
            servingSize: DrinkServingSize(id: "cup-240ml", name: "Cup", amountMl: 240),
            hydrationProfile: DrinkHydrationProfile(effectivenessMultiplier: 0.9),
            nutritionProfile: DrinkNutritionProfile(caffeineMg: 30, calories: 2),
            notes: "Plain brewed green tea."
        ),
        DrinkItem(
            id: "whole-milk-250ml",
            name: "Whole Milk",
            category: .milk,
            servingSize: DrinkServingSize(id: "glass-250ml", name: "Glass", amountMl: 250),
            hydrationProfile: DrinkHydrationProfile(effectivenessMultiplier: 0.9),
            nutritionProfile: DrinkNutritionProfile(sugarG: 12, calories: 150),
            electrolyteProfile: DrinkElectrolyteProfile(sodiumMg: 105, potassiumMg: 322, magnesiumMg: 24),
            notes: "Plain whole milk."
        ),
        DrinkItem(
            id: "orange-juice-250ml",
            name: "Orange Juice",
            category: .juice,
            servingSize: DrinkServingSize(id: "glass-250ml", name: "Glass", amountMl: 250),
            hydrationProfile: DrinkHydrationProfile(effectivenessMultiplier: 0.8),
            nutritionProfile: DrinkNutritionProfile(sugarG: 21, calories: 110),
            electrolyteProfile: DrinkElectrolyteProfile(sodiumMg: 2, potassiumMg: 450, magnesiumMg: 27),
            notes: "Ready-to-drink orange juice."
        ),
        DrinkItem(
            id: "fruit-smoothie-350ml",
            name: "Fruit Smoothie",
            category: .smoothie,
            servingSize: DrinkServingSize(id: "cup-350ml", name: "Cup", amountMl: 350),
            hydrationProfile: DrinkHydrationProfile(effectivenessMultiplier: 0.75),
            nutritionProfile: DrinkNutritionProfile(sugarG: 32, calories: 220),
            electrolyteProfile: DrinkElectrolyteProfile(sodiumMg: 45, potassiumMg: 520, magnesiumMg: 42),
            notes: "Fruit smoothie with yogurt."
        ),
        DrinkItem(
            id: "cola-355ml",
            name: "Cola",
            category: .softDrink,
            servingSize: DrinkServingSize(id: "can-355ml", name: "Can", amountMl: 355),
            hydrationProfile: DrinkHydrationProfile(effectivenessMultiplier: 0.7),
            nutritionProfile: DrinkNutritionProfile(caffeineMg: 34, sugarG: 39, calories: 140),
            electrolyteProfile: DrinkElectrolyteProfile(sodiumMg: 45),
            notes: "Regular caffeinated cola."
        ),
        DrinkItem(
            id: "energy-drink-250ml",
            name: "Energy Drink",
            category: .energyDrink,
            servingSize: DrinkServingSize(id: "can-250ml", name: "Can", amountMl: 250),
            hydrationProfile: DrinkHydrationProfile(effectivenessMultiplier: 0.65),
            nutritionProfile: DrinkNutritionProfile(caffeineMg: 80, sugarG: 27, calories: 110),
            electrolyteProfile: DrinkElectrolyteProfile(sodiumMg: 100),
            notes: "Regular carbonated energy drink."
        ),
        DrinkItem(
            id: "protein-shake-330ml",
            name: "Protein Shake",
            category: .proteinShake,
            servingSize: DrinkServingSize(id: "shake-330ml", name: "Shake", amountMl: 330),
            hydrationProfile: DrinkHydrationProfile(effectivenessMultiplier: 0.8),
            nutritionProfile: DrinkNutritionProfile(sugarG: 5, calories: 180),
            electrolyteProfile: DrinkElectrolyteProfile(sodiumMg: 180, potassiumMg: 300, magnesiumMg: 40),
            notes: "Ready-to-drink vanilla protein shake."
        )
    ]

    static let customTemplate = DrinkItem(
        id: "custom-drink-template",
        name: "Custom Drink",
        category: .custom,
        servingSize: DrinkServingSize(id: "custom-serving", name: "Serving", amountMl: 250),
        notes: "User-defined drink.",
        isCustom: true
    )
}

extension DrinkLogEntry {
    static let sampleData: [DrinkLogEntry] = [
        DrinkItem.sampleData[0].logEntry(amountMl: 500),
        DrinkItem.sampleData[2].logEntry(amountMl: 500),
        DrinkItem.sampleData[4].logEntry(amountMl: 240),
        DrinkItem.sampleData[6].logEntry(amountMl: 250)
    ]
}
