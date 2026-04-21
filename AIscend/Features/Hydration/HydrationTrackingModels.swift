//
//  HydrationTrackingModels.swift
//  AIscend
//
//  Created by Codex on 4/19/26.
//

import Foundation

enum HydrationState: String, CaseIterable, Codable, Identifiable, Sendable {
    case low
    case behind
    case onTrack
    case optimal
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low:
            "Low"
        case .behind:
            "Behind"
        case .onTrack:
            "On Track"
        case .optimal:
            "Optimal"
        case .high:
            "Over Target"
        }
    }
}

struct HydrationInsight: Codable, Equatable, Hashable, Sendable {
    let title: String
    let shortText: String
}

struct WaterEntry: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: UUID
    let date: Date
    let amountMl: Int
    let sourceName: String?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        amountMl: Int,
        sourceName: String? = nil
    ) {
        self.id = id
        self.date = date
        self.amountMl = amountMl
        self.sourceName = sourceName
    }
}

struct WaterDailySummary: Equatable, Sendable {
    let totalWaterMl: Int
    let targetWaterMl: Int
    let progress: Double
    let entries: [WaterEntry]
    let hydrationState: HydrationState
    let insight: HydrationInsight

    var shortInsight: String {
        insight.shortText
    }
}
