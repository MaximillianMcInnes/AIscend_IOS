//
//  RoadmapScanAdapter.swift
//  AIscend
//

import Foundation

enum RoadmapScanAdapter {
    static func signal(from record: PersistedScanRecord?) -> RoadmapScanSignal {
        guard let record, record.isDisplayable else {
            return .unavailable
        }

        var scores: [RoadmapPriorityCategory: Double] = [:]
        if let skin = sanitized(record.payload.scores.skin) {
            scores[.skin] = skin
        }
        if let eyes = sanitized(record.payload.scores.eyes) {
            scores[.sleepRecovery] = eyes
        }
        if let jaw = sanitized(record.payload.scores.jaw) {
            scores[.facialPosture] = jaw
        }
        if let side = sanitized(record.payload.scores.side) {
            scores[.facialPosture] = min(scores[.facialPosture] ?? side, side)
        }

        if let harmony = nestedNumber(in: record.payload.frontProfile, keys: ["facial_harmony", "harmony", "facial_balance"]) {
            scores[.scanSpecificWeakPoint] = harmony
        }
        if let brow = nestedNumber(in: record.payload.frontProfile, keys: ["brow_frame", "brows", "eyebrows"]) {
            scores[.eyebrows] = brow
        }
        if let hair = nestedNumber(in: record.payload.frontProfile, keys: ["hair", "hairline", "grooming"]) {
            scores[.hair] = hair
        }

        let weakCategories = scores
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key.title < rhs.key.title
                }
                return lhs.value < rhs.value
            }
            .prefix(3)
            .map(\.key)

        let lowest = scores.min { lhs, rhs in lhs.value < rhs.value }?.key.title
        let scoreText = Int(record.overallScore.rounded())

        return RoadmapScanSignal(
            hasScan: true,
            sourceSummary: "Latest scan score \(scoreText). Roadmap uses available scan signals with graceful fallbacks.",
            weakCategories: Array(weakCategories),
            lowestMetricLabel: lowest,
            scores: scores
        )
    }

    private static func sanitized(_ score: Double?) -> Double? {
        guard let score, score.isFinite else {
            return nil
        }

        return min(max(score, 0), 100)
    }

    private static func nestedNumber(in object: [String: ScanJSONValue], keys: [String]) -> Double? {
        for key in keys {
            if let direct = object[key]?.numberValue {
                return sanitized(direct)
            }

            if let nested = object[key]?.objectValue {
                for nestedKey in ["score", "value", "rating"] {
                    if let value = nested[nestedKey]?.numberValue {
                        return sanitized(value)
                    }
                }
            }
        }

        return nil
    }
}

