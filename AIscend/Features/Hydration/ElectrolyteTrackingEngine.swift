//
//  ElectrolyteTrackingEngine.swift
//  AIscend
//
//  Created by Codex on 4/19/26.
//

import Foundation
import SwiftUI

enum ElectrolyteChatIntent: Sendable {
    case estimateToday
    case explainBalance
    case presetInfo(ElectrolytePreset)
}

struct ElectrolyteTrackingConfig: Equatable, Sendable {
    struct Thresholds: Equatable, Sendable {
        var lowSignalTotalMg: Int = 120
        var lowSodiumThresholdMg: Int = 450
        var highWaterThresholdMl: Int = 2_600
        var highSodiumThresholdMg: Int = 1_400
        var lowPotassiumThresholdMg: Int = 350
        var balancedSodiumThresholdMg: Int = 850
        var balancedPotassiumThresholdMg: Int = 450
    }

    var presets: [ElectrolytePreset]
    var thresholds: Thresholds

    static let live = ElectrolyteTrackingConfig(
        presets: [
            ElectrolytePreset(
                id: "electrolyte-drink",
                title: "Electrolyte drink",
                subtitle: "Fast support with a balanced mix",
                sodiumMg: 500,
                potassiumMg: 200,
                magnesiumMg: 50,
                iconName: "sparkles"
            ),
            ElectrolytePreset(
                id: "sports-drink",
                title: "Sports drink",
                subtitle: "Light sodium support",
                sodiumMg: 300,
                potassiumMg: 100,
                magnesiumMg: 0,
                iconName: "bolt.fill"
            ),
            ElectrolytePreset(
                id: "salt-added-to-water",
                title: "Salt added to water",
                subtitle: "Quick sodium top-up",
                sodiumMg: 400,
                potassiumMg: 0,
                magnesiumMg: 0,
                iconName: "drop.fill"
            ),
            ElectrolytePreset(
                id: "salty-meal",
                title: "Salty meal",
                subtitle: "Food-led replenishment",
                sodiumMg: 700,
                potassiumMg: 150,
                magnesiumMg: 20,
                iconName: "fork.knife"
            ),
            ElectrolytePreset(
                id: "banana-potassium-snack",
                title: "Banana / potassium snack",
                subtitle: "Potassium-forward support",
                sodiumMg: 5,
                potassiumMg: 400,
                magnesiumMg: 30,
                iconName: "leaf.fill"
            ),
            ElectrolytePreset(
                id: "magnesium-supplement",
                title: "Magnesium supplement",
                subtitle: "Magnesium-focused support",
                sodiumMg: 0,
                potassiumMg: 0,
                magnesiumMg: 200,
                iconName: "capsule.fill"
            )
        ],
        thresholds: Thresholds()
    )
}

struct ElectrolyteTrackingEngine {
    let config: ElectrolyteTrackingConfig

    init(config: ElectrolyteTrackingConfig = .live) {
        self.config = config
    }

    var presetLibrary: [ElectrolytePreset] {
        config.presets
    }

    func preset(id: String) -> ElectrolytePreset? {
        config.presets.first { $0.id == id }
    }

    func preset(title: String) -> ElectrolytePreset? {
        config.presets.first { $0.title == title }
    }

    func entry(from preset: ElectrolytePreset, date: Date = .now) -> ElectrolyteEntry {
        ElectrolyteEntry(
            date: date,
            sourceName: preset.title,
            sodiumMg: preset.sodiumMg,
            potassiumMg: preset.potassiumMg,
            magnesiumMg: preset.magnesiumMg
        )
    }

    func manualEntry(
        sodiumMg: Int?,
        potassiumMg: Int?,
        magnesiumMg: Int?,
        note: String,
        date: Date = .now
    ) -> ElectrolyteEntry? {
        let sodium = max(0, sodiumMg ?? 0)
        let potassium = max(0, potassiumMg ?? 0)
        let magnesium = max(0, magnesiumMg ?? 0)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        guard sodium > 0 || potassium > 0 || magnesium > 0 || !trimmedNote.isEmpty else {
            return nil
        }

        return ElectrolyteEntry(
            date: date,
            sourceName: "Manual entry",
            sodiumMg: sodium,
            potassiumMg: potassium,
            magnesiumMg: magnesium,
            isManualEntry: true,
            note: trimmedNote
        )
    }

    func dailySummary(
        entries: [ElectrolyteEntry],
        waterIntakeMl: Int? = nil
    ) -> ElectrolyteDailySummary {
        let sortedEntries = entries.sorted { $0.date > $1.date }
        let totalSodiumMg = sortedEntries.reduce(0) { $0 + max(0, $1.sodiumMg) }
        let totalPotassiumMg = sortedEntries.reduce(0) { $0 + max(0, $1.potassiumMg) }
        let totalMagnesiumMg = sortedEntries.reduce(0) { $0 + max(0, $1.magnesiumMg) }
        let balanceState = evaluateBalanceState(
            sodiumMg: totalSodiumMg,
            potassiumMg: totalPotassiumMg,
            magnesiumMg: totalMagnesiumMg,
            waterIntakeMl: waterIntakeMl
        )

        return ElectrolyteDailySummary(
            totalSodiumMg: totalSodiumMg,
            totalPotassiumMg: totalPotassiumMg,
            totalMagnesiumMg: totalMagnesiumMg,
            entries: sortedEntries,
            balanceState: balanceState,
            shortInsight: shortInsight(
                for: balanceState,
                sodiumMg: totalSodiumMg,
                potassiumMg: totalPotassiumMg,
                magnesiumMg: totalMagnesiumMg
            )
        )
    }

    func evaluateBalanceState(
        sodiumMg: Int,
        potassiumMg: Int,
        magnesiumMg: Int,
        waterIntakeMl: Int?
    ) -> ElectrolyteBalanceState {
        let total = sodiumMg + potassiumMg + magnesiumMg

        if total < config.thresholds.lowSignalTotalMg {
            return .unknown
        }

        if sodiumMg < config.thresholds.lowSodiumThresholdMg,
           (waterIntakeMl ?? 0) >= config.thresholds.highWaterThresholdMl {
            return .lowSodiumHighWater
        }

        if sodiumMg >= config.thresholds.highSodiumThresholdMg,
           potassiumMg < config.thresholds.lowPotassiumThresholdMg {
            return .highSodiumLowPotassium
        }

        if sodiumMg >= config.thresholds.balancedSodiumThresholdMg,
           potassiumMg >= config.thresholds.balancedPotassiumThresholdMg {
            return .balanced
        }

        if sodiumMg > 0 || potassiumMg > 0 || magnesiumMg > 0 {
            if total >= 500 {
                return .moderate
            }

            return .low
        }

        return .unknown
    }

    func shortInsight(
        for state: ElectrolyteBalanceState,
        sodiumMg: Int,
        potassiumMg: Int,
        magnesiumMg: Int
    ) -> String {
        switch state {
        case .low:
            return "Electrolyte support looks low today."
        case .moderate:
            return "Electrolyte support is building, but still light."
        case .balanced:
            return "Balance looks solid so far."
        case .highSodiumLowPotassium:
            return "Sodium is ahead of potassium today."
        case .lowSodiumHighWater:
            return "You may need more electrolyte support if water intake is high."
        case .unknown:
            return "No meaningful electrolyte logs yet."
        }
    }

    func buildChatPrompt(
        intent: ElectrolyteChatIntent,
        summary: ElectrolyteDailySummary,
        lastSelectedPreset: ElectrolytePreset?,
        waterIntakeMl: Int?
    ) -> String {
        switch intent {
        case .estimateToday:
            var prompt = """
            Please estimate whether my electrolyte intake is reasonable today. Current logged totals: sodium \(summary.totalSodiumMg)mg, potassium \(summary.totalPotassiumMg)mg, magnesium \(summary.totalMagnesiumMg)mg
            """

            if let waterIntakeMl {
                prompt += ", water \(waterIntakeMl)ml"
            }

            prompt += ". My current app insight says: \"\(summary.shortInsight)\"."

            if let lastSelectedPreset {
                prompt += " The last preset I logged was \(lastSelectedPreset.title.lowercased())."
            }

            prompt += " Explain simply and suggest what I may be missing."
            return prompt

        case .explainBalance:
            return """
            I logged sodium \(summary.totalSodiumMg)mg, potassium \(summary.totalPotassiumMg)mg, and magnesium \(summary.totalMagnesiumMg)mg today\(waterIntakeMl.map { " with \($0)ml of water" } ?? "").
            My current electrolyte insight is: "\(summary.shortInsight)"
            Explain what that means simply and what I might want to think about next.
            """

        case .presetInfo(let preset):
            return """
            How much sodium, potassium, and magnesium is usually in \(preset.title.lowercased())?
            I currently have sodium \(summary.totalSodiumMg)mg, potassium \(summary.totalPotassiumMg)mg, and magnesium \(summary.totalMagnesiumMg)mg logged today.
            Keep it practical and brief.
            """
        }
    }
}

@MainActor
final class ElectrolyteTrackingStore: ObservableObject {
    private enum Keys {
        static let entries = "electrolytes.entries"
        static let legacyImport = "electrolytes.legacyImport"
    }

    @Published private(set) var entriesByDay: [String: [ElectrolyteEntry]] = [:]

    let engine: ElectrolyteTrackingEngine

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var storageNamespace: String

    init(
        defaults: UserDefaults = .standard,
        userID: String? = nil,
        engine: ElectrolyteTrackingEngine = ElectrolyteTrackingEngine()
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

    var presets: [ElectrolytePreset] {
        engine.presetLibrary
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
        waterIntakeMl: Int? = nil,
        now: Date = .now
    ) -> ElectrolyteDailySummary {
        summary(for: now, waterIntakeMl: waterIntakeMl)
    }

    func summary(
        for date: Date,
        waterIntakeMl: Int? = nil
    ) -> ElectrolyteDailySummary {
        let dayKey = Self.dayKey(for: date)
        let entries = entriesByDay[dayKey] ?? []
        return engine.dailySummary(entries: entries, waterIntakeMl: waterIntakeMl)
    }

    func recentEntries(limit: Int = 5, on date: Date = .now) -> [ElectrolyteEntry] {
        let dayKey = Self.dayKey(for: date)
        return (entriesByDay[dayKey] ?? [])
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { $0 }
    }

    func addPreset(_ preset: ElectrolytePreset, date: Date = .now) {
        append(engine.entry(from: preset, date: date), on: date)
    }

    func addManualEntry(
        sodiumMg: Int?,
        potassiumMg: Int?,
        magnesiumMg: Int?,
        note: String,
        date: Date = .now
    ) {
        guard let entry = engine.manualEntry(
            sodiumMg: sodiumMg,
            potassiumMg: potassiumMg,
            magnesiumMg: magnesiumMg,
            note: note,
            date: date
        ) else {
            return
        }

        append(entry, on: date)
    }

    func delete(_ entry: ElectrolyteEntry, on date: Date = .now) {
        let dayKey = Self.dayKey(for: date)
        guard var entries = entriesByDay[dayKey] else {
            return
        }

        entries.removeAll { $0.id == entry.id }
        entriesByDay[dayKey] = entries
        persist()
    }

    func lastSelectedPreset(on date: Date = .now) -> ElectrolytePreset? {
        recentEntries(limit: 20, on: date)
            .first(where: { !$0.isManualEntry })
            .flatMap { engine.preset(title: $0.sourceName) }
    }

    func chatPrompt(
        for intent: ElectrolyteChatIntent,
        waterIntakeMl: Int? = nil,
        now: Date = .now
    ) -> String {
        let summary = self.summary(for: now, waterIntakeMl: waterIntakeMl)
        return engine.buildChatPrompt(
            intent: intent,
            summary: summary,
            lastSelectedPreset: lastSelectedPreset(on: now),
            waterIntakeMl: waterIntakeMl
        )
    }

    func importLegacyIfNeeded(servings: Int, now: Date = .now) {
        guard !defaults.bool(forKey: namespacedKey(Keys.legacyImport)) else {
            return
        }

        defer {
            defaults.set(true, forKey: namespacedKey(Keys.legacyImport))
        }

        let safeServings = max(0, servings)
        guard safeServings > 0 else {
            return
        }

        let todayKey = Self.dayKey(for: now)
        guard (entriesByDay[todayKey] ?? []).isEmpty, let preset = presets.first else {
            return
        }

        for offset in 0..<safeServings {
            let entryDate = Calendar.current.date(byAdding: .minute, value: -offset, to: now) ?? now
            addPreset(preset, date: entryDate)
        }
    }

    private func append(_ entry: ElectrolyteEntry, on date: Date) {
        let dayKey = Self.dayKey(for: date)
        var entries = entriesByDay[dayKey] ?? []
        entries.append(entry)
        entriesByDay[dayKey] = entries.sorted { $0.date > $1.date }
        persist()
    }

    private func persist() {
        guard let encodedEntries = try? encoder.encode(entriesByDay) else {
            return
        }

        defaults.set(encodedEntries, forKey: namespacedKey(Keys.entries))
    }

    private func restorePersistedState() {
        if let data = defaults.data(forKey: namespacedKey(Keys.entries)),
           let decoded = try? decoder.decode([String: [ElectrolyteEntry]].self, from: data) {
            entriesByDay = decoded
        } else {
            entriesByDay = [:]
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
