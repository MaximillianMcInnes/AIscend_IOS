//
//  HydrationTrackingEngine.swift
//  AIscend
//
//  Created by Codex on 4/19/26.
//

import Foundation
import SwiftUI

enum HydrationAIIntent: Sendable {
    case askAI
    case estimate
    case explain
}

struct HydrationTrackingConfig: Equatable, Sendable {
    struct Thresholds: Equatable, Sendable {
        var lowProgress: Double = 0.18
        var behindProgress: Double = 0.72
        var onTrackProgress: Double = 0.98
        var optimalProgressUpperBound: Double = 1.18
        var highWaterThresholdMl: Int = 3_000
    }

    var quickAddAmountsMl: [Int]
    var defaultTargetMl: Int
    var thresholds: Thresholds

    static let live = HydrationTrackingConfig(
        quickAddAmountsMl: [250, 500, 750, 1_000],
        defaultTargetMl: 2_800,
        thresholds: Thresholds()
    )
}

struct HydrationGoalEngine {
    let config: HydrationTrackingConfig
    private let electrolyteEngine: ElectrolyteTrackingEngine

    init(
        config: HydrationTrackingConfig = .live,
        electrolyteEngine: ElectrolyteTrackingEngine = ElectrolyteTrackingEngine()
    ) {
        self.config = config
        self.electrolyteEngine = electrolyteEngine
    }

    func daySummary(
        for date: Date,
        logs: [DrinkLogEntry],
        targetHydrationMl: Int
    ) -> HydrationDaySummary {
        let dayLogs = logs.sorted { $0.loggedAt > $1.loggedAt }
        let safeTarget = max(500, targetHydrationMl)
        let totalFluidMl = dayLogs.reduce(0) { $0 + max(0, $1.amountMl) }
        let hydrationCreditMl = dayLogs.reduce(0) { $0 + max(0, $1.hydrationCreditMl) }
        let waterOnlyMl = dayLogs.reduce(0) { partial, log in
            isWaterLog(log) ? partial + max(0, log.amountMl) : partial
        }
        let sodiumMg = dayLogs.reduce(0) { $0 + max(0, $1.sodiumMg) }
        let potassiumMg = dayLogs.reduce(0) { $0 + max(0, $1.potassiumMg) }
        let magnesiumMg = dayLogs.reduce(0) { $0 + max(0, $1.magnesiumMg) }
        let caffeineMg = dayLogs.reduce(0) { $0 + max(0, $1.caffeineMg) }
        let calories = dayLogs.reduce(0) { $0 + max(0, $1.calories) }
        let sugarG = dayLogs.reduce(0) { $0 + max(0, $1.sugarG) }
        let progress = progress(hydrationCreditMl: hydrationCreditMl, targetHydrationMl: safeTarget)
        let balanceStatus = electrolyteBalanceStatus(
            sodiumMg: sodiumMg,
            potassiumMg: potassiumMg,
            magnesiumMg: magnesiumMg,
            waterIntakeMl: hydrationCreditMl
        )

        return HydrationDaySummary(
            id: Self.dayKey(for: date),
            date: date,
            targetHydrationMl: safeTarget,
            totalFluidMl: totalFluidMl,
            hydrationCreditMl: hydrationCreditMl,
            waterOnlyMl: waterOnlyMl,
            sodiumMg: sodiumMg,
            potassiumMg: potassiumMg,
            magnesiumMg: magnesiumMg,
            caffeineMg: caffeineMg,
            calories: calories,
            sugarG: sugarG,
            dailyGoalProgress: progress,
            electrolyteBalanceStatus: balanceStatus,
            recentDrinks: Array(dayLogs.prefix(5)),
            logs: dayLogs,
            smartSuggestionText: smartSuggestionText(
                hydrationCreditMl: hydrationCreditMl,
                targetHydrationMl: safeTarget,
                totalFluidMl: totalFluidMl,
                waterOnlyMl: waterOnlyMl,
                sodiumMg: sodiumMg,
                potassiumMg: potassiumMg,
                magnesiumMg: magnesiumMg,
                caffeineMg: caffeineMg,
                sugarG: sugarG,
                balanceStatus: balanceStatus
            )
        )
    }

    func weeklySummary(
        endingOn date: Date = .now,
        logsByDay: [String: [DrinkLogEntry]],
        targetByDay: [String: Int],
        defaultTargetMl: Int
    ) -> [HydrationDaySummary] {
        let calendar = Calendar.current

        let summaries: [HydrationDaySummary] = (0..<7).compactMap { dayOffset -> HydrationDaySummary? in
            guard let summaryDate = calendar.date(byAdding: .day, value: -dayOffset, to: date) else {
                return nil
            }

            let dayKey = Self.dayKey(for: summaryDate)
            return daySummary(
                for: summaryDate,
                logs: logsByDay[dayKey] ?? [],
                targetHydrationMl: targetByDay[dayKey] ?? defaultTargetMl
            )
        }

        return Array(summaries.reversed())
    }

    func progress(hydrationCreditMl: Int, targetHydrationMl: Int) -> Double {
        guard targetHydrationMl > 0 else {
            return 0
        }

        return Double(max(0, hydrationCreditMl)) / Double(targetHydrationMl)
    }

    func electrolyteBalanceStatus(
        sodiumMg: Int,
        potassiumMg: Int,
        magnesiumMg: Int,
        waterIntakeMl: Int?
    ) -> ElectrolyteBalanceState {
        electrolyteEngine.evaluateBalanceState(
            sodiumMg: sodiumMg,
            potassiumMg: potassiumMg,
            magnesiumMg: magnesiumMg,
            waterIntakeMl: waterIntakeMl
        )
    }

    func combinedElectrolyteSummary(
        base: ElectrolyteDailySummary,
        drinkSummary: HydrationDaySummary,
        waterIntakeMl: Int?
    ) -> ElectrolyteDailySummary {
        let sodium = base.totalSodiumMg + drinkSummary.sodiumMg
        let potassium = base.totalPotassiumMg + drinkSummary.potassiumMg
        let magnesium = base.totalMagnesiumMg + drinkSummary.magnesiumMg
        let balanceState = electrolyteBalanceStatus(
            sodiumMg: sodium,
            potassiumMg: potassium,
            magnesiumMg: magnesium,
            waterIntakeMl: waterIntakeMl
        )

        return ElectrolyteDailySummary(
            totalSodiumMg: sodium,
            totalPotassiumMg: potassium,
            totalMagnesiumMg: magnesium,
            entries: base.entries,
            balanceState: balanceState,
            shortInsight: electrolyteEngine.shortInsight(
                for: balanceState,
                sodiumMg: sodium,
                potassiumMg: potassium,
                magnesiumMg: magnesium
            )
        )
    }

    func isWaterLog(_ log: DrinkLogEntry) -> Bool {
        if log.drinkCategory == .water {
            return true
        }

        let normalizedID = log.drinkId.lowercased()
        let normalizedName = log.drinkName.lowercased()
        return normalizedID == "water" || normalizedID.contains("plain-water") || normalizedName == "water" || normalizedName == "still water"
    }

    func smartSuggestionText(
        hydrationCreditMl: Int,
        targetHydrationMl: Int,
        totalFluidMl: Int,
        waterOnlyMl: Int,
        sodiumMg: Int,
        potassiumMg: Int,
        magnesiumMg: Int,
        caffeineMg: Int,
        sugarG: Double,
        balanceStatus: ElectrolyteBalanceState
    ) -> String {
        let progress = progress(hydrationCreditMl: hydrationCreditMl, targetHydrationMl: targetHydrationMl)

        if totalFluidMl == 0 {
            return "No drinks logged yet today."
        }

        if sugarG >= 25 {
            return "Sugary drinks are counted as fluid, with sugar shown separately for context."
        }

        if caffeineMg >= 120 {
            return "Caffeinated drinks are counted with their hydration credit shown separately."
        }

        if sodiumMg + potassiumMg + magnesiumMg > 0,
           balanceStatus == .balanced || balanceStatus == .moderate {
            return "Hydration credit and electrolyte totals are building from your drink logs."
        }

        if progress < config.thresholds.behindProgress {
            return "Hydration credit is behind your daily target."
        }

        if waterOnlyMl < hydrationCreditMl / 2 {
            return "Most hydration credit is coming from non-water drinks today."
        }

        if progress >= config.thresholds.onTrackProgress {
            return "Hydration credit is on track for today."
        }

        return "Drink totals are approximate and update as you log more."
    }

    static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct HydrationTrackingEngine {
    let config: HydrationTrackingConfig

    init(config: HydrationTrackingConfig = .live) {
        self.config = config
    }

    func makeEntry(
        amountMl: Int,
        sourceName: String? = nil,
        date: Date = .now
    ) -> WaterEntry? {
        guard amountMl > 0 else {
            return nil
        }

        return WaterEntry(
            date: date,
            amountMl: amountMl,
            sourceName: sourceName
        )
    }

    func dailySummary(
        entries: [WaterEntry],
        targetWaterMl: Int,
        electrolyteSummary: ElectrolyteDailySummary? = nil
    ) -> WaterDailySummary {
        let sortedEntries = entries.sorted { $0.date > $1.date }
        let totalWaterMl = sortedEntries.reduce(0) { $0 + max(0, $1.amountMl) }
        let safeTarget = max(500, targetWaterMl)
        let progress = Double(totalWaterMl) / Double(safeTarget)
        let hydrationState = evaluateState(totalWaterMl: totalWaterMl, targetWaterMl: safeTarget)
        let insight = makeInsight(
            for: hydrationState,
            totalWaterMl: totalWaterMl,
            targetWaterMl: safeTarget,
            electrolyteSummary: electrolyteSummary
        )

        return WaterDailySummary(
            totalWaterMl: totalWaterMl,
            targetWaterMl: safeTarget,
            progress: progress,
            entries: sortedEntries,
            hydrationState: hydrationState,
            insight: insight
        )
    }

    func evaluateState(totalWaterMl: Int, targetWaterMl: Int) -> HydrationState {
        guard targetWaterMl > 0 else {
            return .low
        }

        let progress = Double(totalWaterMl) / Double(targetWaterMl)

        if progress < config.thresholds.lowProgress {
            return .low
        }

        if progress < config.thresholds.behindProgress {
            return .behind
        }

        if progress < config.thresholds.onTrackProgress {
            return .onTrack
        }

        if progress <= config.thresholds.optimalProgressUpperBound {
            return .optimal
        }

        return .high
    }

    func combinedDashboardInsight(
        waterSummary: WaterDailySummary,
        electrolyteSummary: ElectrolyteDailySummary
    ) -> String {
        if waterSummary.hydrationState == .high,
           electrolyteSummary.balanceState == .lowSodiumHighWater {
            return "High water, low sodium support."
        }

        if waterSummary.hydrationState == .behind || waterSummary.hydrationState == .low {
            return "Water behind target."
        }

        if waterSummary.hydrationState == .optimal,
           electrolyteSummary.balanceState == .balanced {
            return "Water strong. Balance looks good."
        }

        if waterSummary.hydrationState == .onTrack || waterSummary.hydrationState == .optimal {
            switch electrolyteSummary.balanceState {
            case .low, .moderate, .unknown:
                return "Hydration on track. Electrolytes low."
            case .highSodiumLowPotassium:
                return "Hydration on track. Sodium is ahead."
            case .lowSodiumHighWater:
                return "High water, low sodium support."
            case .balanced:
                return "Water strong. Balance looks good."
            }
        }

        return waterSummary.shortInsight
    }

    func buildChatPrompt(
        intent: HydrationAIIntent,
        waterSummary: WaterDailySummary,
        electrolyteSummary: ElectrolyteDailySummary,
        lastSelectedPreset: ElectrolytePreset?
    ) -> String {
        let opener: String
        let closer: String

        switch intent {
        case .askAI:
            opener = "Please review my hydration and electrolyte picture for today."
            closer = "Keep the explanation short, practical, and premium in tone."
        case .estimate:
            opener = "Please estimate whether my hydration and electrolyte intake look reasonable today."
            closer = "Explain simply and suggest what I may be missing."
        case .explain:
            opener = "Please explain my hydration and electrolyte picture simply."
            closer = "Tell me why it matters without turning this into a medical lecture."
        }

        var prompt = """
        \(opener) Current totals: water \(waterSummary.totalWaterMl)ml of \(waterSummary.targetWaterMl)ml target, sodium \(electrolyteSummary.totalSodiumMg)mg, potassium \(electrolyteSummary.totalPotassiumMg)mg, magnesium \(electrolyteSummary.totalMagnesiumMg)mg.
        Current hydration insight: "\(waterSummary.shortInsight)"
        Current electrolyte insight: "\(electrolyteSummary.shortInsight)"
        """

        if let lastSelectedPreset {
            prompt += "\nThe last electrolyte preset I logged was \(lastSelectedPreset.title.lowercased())."
        }

        prompt += "\n\(closer)"
        return prompt
    }

    func makeInsight(
        for state: HydrationState,
        totalWaterMl: Int,
        targetWaterMl: Int,
        electrolyteSummary: ElectrolyteDailySummary?
    ) -> HydrationInsight {
        if totalWaterMl >= config.thresholds.highWaterThresholdMl,
           let electrolyteSummary,
           electrolyteSummary.balanceState == .lowSodiumHighWater || electrolyteSummary.balanceState == .low {
            return HydrationInsight(
                title: "Electrolytes lagging",
                shortText: "Water is high, but electrolyte support may be low."
            )
        }

        switch state {
        case .low, .behind:
            return HydrationInsight(
                title: "Behind target",
                shortText: "You're behind your hydration target today."
            )
        case .onTrack:
            return HydrationInsight(
                title: "On track",
                shortText: "Water intake is on track so far."
            )
        case .optimal:
            return HydrationInsight(
                title: "Strong",
                shortText: "Hydration looks strong today."
            )
        case .high:
            return HydrationInsight(
                title: "Above target",
                shortText: "You've moved past target. Ease off if you already feel topped up."
            )
        }
    }

    static func formatWater(_ amountMl: Int, prefersCompact: Bool = false) -> String {
        if prefersCompact || amountMl >= 1_000 {
            let liters = Double(amountMl) / 1_000
            return String(format: liters >= 10 ? "%.0fL" : "%.1fL", liters)
        }

        return "\(amountMl)ml"
    }
}

@MainActor
final class HydrationTrackingViewModel: ObservableObject {
    private enum Keys {
        static let entries = "hydration.entries"
        static let drinkLogs = "hydration.drinkLogs"
        static let targets = "hydration.targets"
        static let legacyImport = "hydration.legacyImport"
    }

    @Published private(set) var entriesByDay: [String: [WaterEntry]] = [:]
    @Published private(set) var drinkLogsByDay: [String: [DrinkLogEntry]] = [:]
    @Published private(set) var targetByDay: [String: Int] = [:]

    let engine: HydrationTrackingEngine
    let goalEngine: HydrationGoalEngine

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let drinkLogStore: HydrationDrinkLogStore
    private var storageNamespace: String
    private var authenticatedUserID: String?

    init(
        defaults: UserDefaults = .standard,
        userID: String? = nil,
        engine: HydrationTrackingEngine = HydrationTrackingEngine(),
        goalEngine: HydrationGoalEngine = HydrationGoalEngine(),
        drinkLogStore: HydrationDrinkLogStore = HydrationDrinkLogStore()
    ) {
        self.defaults = defaults
        self.engine = engine
        self.goalEngine = goalEngine
        self.drinkLogStore = drinkLogStore
        self.authenticatedUserID = userID
        self.storageNamespace = Self.namespace(for: userID)
        self.drinkLogStore.applyAuthenticatedUserID(userID)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        restorePersistedState()
    }

    var quickAddAmountsMl: [Int] {
        engine.config.quickAddAmountsMl
    }

    func applyAuthenticatedUserID(_ userID: String?) {
        let newNamespace = Self.namespace(for: userID)
        guard newNamespace != storageNamespace else {
            return
        }

        storageNamespace = newNamespace
        authenticatedUserID = userID
        drinkLogStore.applyAuthenticatedUserID(userID)
        restorePersistedState()
    }

    func todaySummary(
        electrolyteSummary: ElectrolyteDailySummary? = nil,
        now: Date = .now
    ) -> WaterDailySummary {
        summary(for: now, electrolyteSummary: electrolyteSummary)
    }

    func todaySummary(now: Date) -> HydrationDaySummary {
        hydrationSummary(for: now)
    }

    var todayHydrationSummary: HydrationDaySummary {
        hydrationSummary(for: .now)
    }

    func summary(
        for date: Date,
        electrolyteSummary: ElectrolyteDailySummary? = nil
    ) -> WaterDailySummary {
        let hydrationSummary = hydrationSummary(for: date)
        let hydrationState = engine.evaluateState(
            totalWaterMl: hydrationSummary.hydrationCreditMl,
            targetWaterMl: hydrationSummary.targetHydrationMl
        )
        let insight = engine.makeInsight(
            for: hydrationState,
            totalWaterMl: hydrationSummary.hydrationCreditMl,
            targetWaterMl: hydrationSummary.targetHydrationMl,
            electrolyteSummary: electrolyteSummary
        )

        return WaterDailySummary(
            totalWaterMl: hydrationSummary.hydrationCreditMl,
            targetWaterMl: hydrationSummary.targetHydrationMl,
            progress: hydrationSummary.dailyGoalProgress,
            entries: recentEntries(limit: 20, on: date),
            hydrationState: hydrationState,
            insight: insight
        )
    }

    func hydrationSummary(for date: Date = .now) -> HydrationDaySummary {
        let dayKey = Self.dayKey(for: date)
        return goalEngine.daySummary(
            for: date,
            logs: drinkLogsByDay[dayKey] ?? [],
            targetHydrationMl: targetByDay[dayKey] ?? engine.config.defaultTargetMl
        )
    }

    func weeklySummary(endingOn date: Date = .now) -> [HydrationDaySummary] {
        goalEngine.weeklySummary(
            endingOn: date,
            logsByDay: drinkLogsByDay,
            targetByDay: targetByDay,
            defaultTargetMl: engine.config.defaultTargetMl
        )
    }

    func recentEntries(limit: Int = 5, on date: Date = .now) -> [WaterEntry] {
        let dayKey = Self.dayKey(for: date)
        return (entriesByDay[dayKey] ?? [])
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { $0 }
    }

    func todayDrinkLogs(now: Date = .now) -> [DrinkLogEntry] {
        drinkLogs(on: now)
    }

    func drinkLogs(on date: Date = .now) -> [DrinkLogEntry] {
        let dayKey = Self.dayKey(for: date)
        return (drinkLogsByDay[dayKey] ?? []).sorted { $0.loggedAt > $1.loggedAt }
    }

    func recentDrinkLogs(limit: Int = 8) -> [DrinkLogEntry] {
        drinkLogsByDay
            .values
            .flatMap { $0 }
            .sorted { $0.loggedAt > $1.loggedAt }
            .prefix(limit)
            .map { $0 }
    }

    func addWater(
        amountMl: Int,
        sourceName: String? = nil,
        date: Date = .now
    ) {
        let safeAmount = max(0, amountMl)
        guard safeAmount > 0 else {
            return
        }

        let water = DrinkItem(
            id: "water",
            name: sourceName ?? "Water",
            category: .water,
            servingSize: DrinkServingSize(id: "water-\(safeAmount)ml", name: "Water", amountMl: safeAmount),
            hydrationProfile: DrinkHydrationProfile(effectivenessMultiplier: 1),
            notes: "Plain water. Values are approximate."
        )
        _ = logDrink(water, amountMl: safeAmount, loggedAt: date)
    }

    @discardableResult
    func logDrink(
        _ drink: DrinkItem,
        amountMl: Int,
        loggedAt: Date = .now
    ) -> DrinkLogEntry? {
        let safeAmount = max(0, amountMl)
        guard safeAmount > 0 else {
            return nil
        }

        let entry = drink.logEntry(amountMl: safeAmount, loggedAt: loggedAt)
        logDrink(entry)
        return entry
    }

    func logDrink(_ entry: DrinkLogEntry) {
        let dayKey = Self.dayKey(for: entry.loggedAt)

        drinkLogsByDay = drinkLogStore.logsByAdding(entry, to: drinkLogsByDay)

        if goalEngine.isWaterLog(entry),
           let waterEntry = engine.makeEntry(
            amountMl: entry.amountMl,
            sourceName: entry.drinkName,
            date: entry.loggedAt
        ) {
            var entries = entriesByDay[dayKey] ?? []
            entries.append(waterEntry)
            entriesByDay[dayKey] = entries.sorted { $0.date > $1.date }
        }

        persist()
        drinkLogStore.syncToFirebaseIfAvailable(entry)
    }

    func deleteLog(_ entry: DrinkLogEntry) {
        let dayKey = Self.dayKey(for: entry.loggedAt)
        guard drinkLogsByDay[dayKey] != nil else {
            return
        }

        drinkLogsByDay = drinkLogStore.logsByDeleting(entry, from: drinkLogsByDay)

        if goalEngine.isWaterLog(entry) {
            removeMatchingWaterEntry(for: entry, on: dayKey)
        }

        persist()
        drinkLogStore.deleteFromFirebaseIfAvailable(entry)
    }

    func deleteLog(entry: DrinkLogEntry) {
        deleteLog(entry)
    }

    func updateLog(_ entry: DrinkLogEntry, amountMl: Int) {
        let safeAmount = max(1, amountMl)
        let dayKey = Self.dayKey(for: entry.loggedAt)
        guard drinkLogsByDay[dayKey]?.contains(where: { $0.id == entry.id }) == true else {
            return
        }

        let updatedEntry = scaledEntry(entry, amountMl: safeAmount)
        drinkLogsByDay = drinkLogStore.logsByUpdating(updatedEntry, in: drinkLogsByDay)

        if goalEngine.isWaterLog(entry) {
            removeMatchingWaterEntry(for: entry, on: dayKey)

            if let waterEntry = engine.makeEntry(
                amountMl: updatedEntry.amountMl,
                sourceName: updatedEntry.drinkName,
                date: updatedEntry.loggedAt
            ) {
                var entries = entriesByDay[dayKey] ?? []
                entries.append(waterEntry)
                entriesByDay[dayKey] = entries.sorted { $0.date > $1.date }
            }
        }

        persist()
        drinkLogStore.syncToFirebaseIfAvailable(updatedEntry)
    }

    func removeLastEntry(now: Date = .now) {
        let dayKey = Self.dayKey(for: now)
        if var logs = drinkLogsByDay[dayKey],
           let lastWaterLog = logs
            .sorted(by: { $0.loggedAt > $1.loggedAt })
            .first(where: goalEngine.isWaterLog) {
            logs.removeAll { $0.id == lastWaterLog.id }
            drinkLogsByDay[dayKey] = logs
            removeMatchingWaterEntry(for: lastWaterLog, on: dayKey)
            persist()
            drinkLogStore.deleteFromFirebaseIfAvailable(lastWaterLog)
            return
        }

        guard var entries = entriesByDay[dayKey], !entries.isEmpty else {
            return
        }

        entries.sort { $0.date > $1.date }
        entries.removeFirst()
        entriesByDay[dayKey] = entries
        persist()
    }

    func delete(_ entry: WaterEntry, on date: Date = .now) {
        let dayKey = Self.dayKey(for: date)
        guard var entries = entriesByDay[dayKey] else {
            return
        }

        if let deletedEntry = entries.first(where: { $0.id == entry.id }) {
            removeMatchingDrinkLog(for: deletedEntry, on: dayKey)
        }

        entries.removeAll { $0.id == entry.id }
        entriesByDay[dayKey] = entries
        persist()
    }

    func setTarget(_ targetMl: Int, for date: Date = .now) {
        let dayKey = Self.dayKey(for: date)
        targetByDay[dayKey] = max(500, targetMl)
        persist()
    }

    func target(for date: Date = .now) -> Int {
        targetByDay[Self.dayKey(for: date)] ?? engine.config.defaultTargetMl
    }

    func combinedInsight(
        electrolyteSummary: ElectrolyteDailySummary,
        now: Date = .now
    ) -> String {
        let waterSummary = summary(for: now, electrolyteSummary: electrolyteSummary)
        return engine.combinedDashboardInsight(
            waterSummary: waterSummary,
            electrolyteSummary: electrolyteSummary
        )
    }

    func combinedPrompt(
        intent: HydrationAIIntent,
        electrolyteSummary: ElectrolyteDailySummary,
        lastSelectedPreset: ElectrolytePreset?,
        now: Date = .now
    ) -> String {
        let waterSummary = summary(for: now, electrolyteSummary: electrolyteSummary)
        return engine.buildChatPrompt(
            intent: intent,
            waterSummary: waterSummary,
            electrolyteSummary: electrolyteSummary,
            lastSelectedPreset: lastSelectedPreset
        )
    }

    func importLegacyIfNeeded(
        waterCups: Int,
        waterGoalCups: Int,
        now: Date = .now
    ) {
        guard !defaults.bool(forKey: namespacedKey(Keys.legacyImport)) else {
            return
        }

        defer {
            defaults.set(true, forKey: namespacedKey(Keys.legacyImport))
        }

        let safeWaterCups = max(0, waterCups)
        let safeGoalCups = max(0, waterGoalCups)
        let todayKey = Self.dayKey(for: now)

        if safeWaterCups > 0, (entriesByDay[todayKey] ?? []).isEmpty {
            addWater(
                amountMl: safeWaterCups * 250,
                sourceName: "Imported water",
                date: now
            )
        }

        if safeGoalCups > 0 {
            setTarget(safeGoalCups * 250, for: now)
        }
    }

    private func scaledEntry(_ entry: DrinkLogEntry, amountMl: Int) -> DrinkLogEntry {
        let previousAmount = max(entry.amountMl, 1)
        let scale = Double(amountMl) / Double(previousAmount)

        return DrinkLogEntry(
            id: entry.id,
            drinkId: entry.drinkId,
            drinkName: entry.drinkName,
            amountMl: amountMl,
            loggedAt: entry.loggedAt,
            hydrationCreditMl: Int((Double(entry.hydrationCreditMl) * scale).rounded()),
            sodiumMg: Int((Double(entry.sodiumMg) * scale).rounded()),
            potassiumMg: Int((Double(entry.potassiumMg) * scale).rounded()),
            magnesiumMg: Int((Double(entry.magnesiumMg) * scale).rounded()),
            caffeineMg: Int((Double(entry.caffeineMg) * scale).rounded()),
            calories: Int((Double(entry.calories) * scale).rounded()),
            sugarG: entry.sugarG * scale,
            drinkCategory: entry.drinkCategory,
            createdAt: entry.createdAt ?? entry.loggedAt,
            updatedAt: .now
        )
    }

    private func removeMatchingWaterEntry(for log: DrinkLogEntry, on dayKey: String) {
        guard var entries = entriesByDay[dayKey],
              let index = entries.firstIndex(where: { entry in
                  entry.amountMl == log.amountMl &&
                  entry.sourceName == log.drinkName &&
                  abs(entry.date.timeIntervalSince(log.loggedAt)) < 2
              }) else {
            return
        }

        entries.remove(at: index)
        entriesByDay[dayKey] = entries
    }

    private func removeMatchingDrinkLog(for entry: WaterEntry, on dayKey: String) {
        guard var logs = drinkLogsByDay[dayKey],
              let index = logs.firstIndex(where: { log in
                  goalEngine.isWaterLog(log) &&
                  log.amountMl == entry.amountMl &&
                  log.drinkName == (entry.sourceName ?? "Water") &&
                  abs(log.loggedAt.timeIntervalSince(entry.date)) < 2
              }) else {
            return
        }

        let deletedLog = logs[index]
        logs.remove(at: index)
        drinkLogsByDay[dayKey] = logs
        drinkLogStore.deleteFromFirebaseIfAvailable(deletedLog)
    }

    private func migrateLegacyWaterEntriesToDrinkLogsIfNeeded() {
        guard drinkLogsByDay.values.allSatisfy(\.isEmpty) else {
            return
        }

        var migratedLogsByDay: [String: [DrinkLogEntry]] = [:]

        for (dayKey, entries) in entriesByDay {
            let logs = entries.map { entry in
                DrinkLogEntry(
                    drinkId: "water",
                    drinkName: entry.sourceName ?? "Water",
                    amountMl: entry.amountMl,
                    loggedAt: entry.date,
                    hydrationCreditMl: entry.amountMl,
                    drinkCategory: .water
                )
            }

            migratedLogsByDay[dayKey] = logs.sorted { $0.loggedAt > $1.loggedAt }
        }

        guard !migratedLogsByDay.isEmpty else {
            return
        }

        drinkLogsByDay = migratedLogsByDay
        persist()
    }

    private func persist() {
        guard let encodedEntries = try? encoder.encode(entriesByDay),
              let encodedTargets = try? encoder.encode(targetByDay) else {
            return
        }

        defaults.set(encodedEntries, forKey: namespacedKey(Keys.entries))
        defaults.set(encodedTargets, forKey: namespacedKey(Keys.targets))
        drinkLogStore.saveLogsByDay(drinkLogsByDay)
    }

    private func restorePersistedState() {
        if let data = defaults.data(forKey: namespacedKey(Keys.entries)),
           let decoded = try? decoder.decode([String: [WaterEntry]].self, from: data) {
            entriesByDay = decoded
        } else {
            entriesByDay = [:]
        }

        drinkLogsByDay = restoredDrinkLogs()

        if let data = defaults.data(forKey: namespacedKey(Keys.targets)),
           let decoded = try? decoder.decode([String: Int].self, from: data) {
            targetByDay = decoded
        } else {
            targetByDay = [:]
        }

        migrateLegacyWaterEntriesToDrinkLogsIfNeeded()
    }

    private func restoredDrinkLogs() -> [String: [DrinkLogEntry]] {
        let fileBackedLogs = drinkLogStore.loadLogsByDay()
        guard fileBackedLogs.values.allSatisfy(\.isEmpty) else {
            return fileBackedLogs
        }

        guard let data = defaults.data(forKey: namespacedKey(Keys.drinkLogs)),
              let decoded = try? decoder.decode([String: [DrinkLogEntry]].self, from: data) else {
            return [:]
        }

        drinkLogStore.saveLogsByDay(decoded)
        return decoded
    }

    private func namespacedKey(_ key: String) -> String {
        "\(key).\(storageNamespace)"
    }

    private static func namespace(for userID: String?) -> String {
        let trimmed = userID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "guest" : trimmed
    }

    private static func dayKey(for date: Date) -> String {
        HydrationGoalEngine.dayKey(for: date)
    }
}

typealias HydrationTrackingStore = HydrationTrackingViewModel
