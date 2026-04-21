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
final class HydrationTrackingStore: ObservableObject {
    private enum Keys {
        static let entries = "hydration.entries"
        static let targets = "hydration.targets"
        static let legacyImport = "hydration.legacyImport"
    }

    @Published private(set) var entriesByDay: [String: [WaterEntry]] = [:]
    @Published private(set) var targetByDay: [String: Int] = [:]

    let engine: HydrationTrackingEngine

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var storageNamespace: String

    init(
        defaults: UserDefaults = .standard,
        userID: String? = nil,
        engine: HydrationTrackingEngine = HydrationTrackingEngine()
    ) {
        self.defaults = defaults
        self.engine = engine
        self.storageNamespace = Self.namespace(for: userID)

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
        restorePersistedState()
    }

    func todaySummary(
        electrolyteSummary: ElectrolyteDailySummary? = nil,
        now: Date = .now
    ) -> WaterDailySummary {
        summary(for: now, electrolyteSummary: electrolyteSummary)
    }

    func summary(
        for date: Date,
        electrolyteSummary: ElectrolyteDailySummary? = nil
    ) -> WaterDailySummary {
        let dayKey = Self.dayKey(for: date)
        let entries = entriesByDay[dayKey] ?? []
        let target = targetByDay[dayKey] ?? engine.config.defaultTargetMl
        return engine.dailySummary(
            entries: entries,
            targetWaterMl: target,
            electrolyteSummary: electrolyteSummary
        )
    }

    func recentEntries(limit: Int = 5, on date: Date = .now) -> [WaterEntry] {
        let dayKey = Self.dayKey(for: date)
        return (entriesByDay[dayKey] ?? [])
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { $0 }
    }

    func addWater(
        amountMl: Int,
        sourceName: String? = nil,
        date: Date = .now
    ) {
        guard let entry = engine.makeEntry(amountMl: amountMl, sourceName: sourceName, date: date) else {
            return
        }

        let dayKey = Self.dayKey(for: date)
        var entries = entriesByDay[dayKey] ?? []
        entries.append(entry)
        entriesByDay[dayKey] = entries.sorted { $0.date > $1.date }
        persist()
    }

    func removeLastEntry(now: Date = .now) {
        let dayKey = Self.dayKey(for: now)
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

    private func persist() {
        guard let encodedEntries = try? encoder.encode(entriesByDay),
              let encodedTargets = try? encoder.encode(targetByDay) else {
            return
        }

        defaults.set(encodedEntries, forKey: namespacedKey(Keys.entries))
        defaults.set(encodedTargets, forKey: namespacedKey(Keys.targets))
    }

    private func restorePersistedState() {
        if let data = defaults.data(forKey: namespacedKey(Keys.entries)),
           let decoded = try? decoder.decode([String: [WaterEntry]].self, from: data) {
            entriesByDay = decoded
        } else {
            entriesByDay = [:]
        }

        if let data = defaults.data(forKey: namespacedKey(Keys.targets)),
           let decoded = try? decoder.decode([String: Int].self, from: data) {
            targetByDay = decoded
        } else {
            targetByDay = [:]
        }
    }

    private func namespacedKey(_ key: String) -> String {
        "\(key).\(storageNamespace)"
    }

    private static func namespace(for userID: String?) -> String {
        let trimmed = userID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "guest" : trimmed
    }

    private static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
