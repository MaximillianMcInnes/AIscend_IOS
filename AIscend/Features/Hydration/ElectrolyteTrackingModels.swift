//
//  ElectrolyteTrackingModels.swift
//  AIscend
//
//  Created by Codex on 4/19/26.
//

import Foundation

enum ElectrolyteBalanceState: String, CaseIterable, Codable, Identifiable, Sendable {
    case low
    case moderate
    case balanced
    case highSodiumLowPotassium
    case lowSodiumHighWater
    case unknown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low:
            "Low"
        case .moderate:
            "Moderate"
        case .balanced:
            "Balanced"
        case .highSodiumLowPotassium:
            "Sodium Heavy"
        case .lowSodiumHighWater:
            "Low Sodium"
        case .unknown:
            "Unknown"
        }
    }
}

struct ElectrolyteEntry: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: UUID
    let date: Date
    let sourceName: String
    let sodiumMg: Int
    let potassiumMg: Int
    let magnesiumMg: Int
    let isManualEntry: Bool
    let note: String

    init(
        id: UUID = UUID(),
        date: Date = .now,
        sourceName: String,
        sodiumMg: Int,
        potassiumMg: Int,
        magnesiumMg: Int,
        isManualEntry: Bool = false,
        note: String = ""
    ) {
        self.id = id
        self.date = date
        self.sourceName = sourceName
        self.sodiumMg = sodiumMg
        self.potassiumMg = potassiumMg
        self.magnesiumMg = magnesiumMg
        self.isManualEntry = isManualEntry
        self.note = note
    }
}

struct ElectrolytePreset: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let sodiumMg: Int
    let potassiumMg: Int
    let magnesiumMg: Int
    let iconName: String
}

struct ElectrolyteDailySummary: Equatable, Sendable {
    let totalSodiumMg: Int
    let totalPotassiumMg: Int
    let totalMagnesiumMg: Int
    let entries: [ElectrolyteEntry]
    let balanceState: ElectrolyteBalanceState
    let shortInsight: String
}
