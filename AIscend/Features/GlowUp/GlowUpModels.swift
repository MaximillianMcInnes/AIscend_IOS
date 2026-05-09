//
//  GlowUpModels.swift
//  AIscend
//

import Foundation

enum GlowUpComparisonRange: String, CaseIterable, Codable, Identifiable {
    case latestPrevious
    case thirtyDays
    case ninetyDays
    case allTime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .latestPrevious:
            "Latest"
        case .thirtyDays:
            "30D"
        case .ninetyDays:
            "90D"
        case .allTime:
            "All"
        }
    }

    var detail: String {
        switch self {
        case .latestPrevious:
            "Latest vs previous"
        case .thirtyDays:
            "Last 30 days"
        case .ninetyDays:
            "Last 90 days"
        case .allTime:
            "All time"
        }
    }

    var lookbackDays: Int? {
        switch self {
        case .latestPrevious:
            nil
        case .thirtyDays:
            30
        case .ninetyDays:
            90
        case .allTime:
            nil
        }
    }
}

enum GlowUpMetricView: String, CaseIterable, Codable, Identifiable {
    case whatChanged
    case scoreDeltas

    var id: String { rawValue }

    var title: String {
        switch self {
        case .whatChanged:
            "Changed"
        case .scoreDeltas:
            "Deltas"
        }
    }
}

enum GlowUpMetricID: String, CaseIterable, Codable, Identifiable {
    case skinClarity
    case jawVisibility
    case eyeArea
    case facialHarmony
    case symmetry
    case postureSideProfile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .skinClarity:
            "Skin clarity"
        case .jawVisibility:
            "Jaw visibility"
        case .eyeArea:
            "Eye area tiredness"
        case .facialHarmony:
            "Facial harmony"
        case .symmetry:
            "Symmetry"
        case .postureSideProfile:
            "Posture / side profile"
        }
    }

    var symbol: String {
        switch self {
        case .skinClarity:
            "sparkles"
        case .jawVisibility:
            "viewfinder"
        case .eyeArea:
            "eye.fill"
        case .facialHarmony:
            "circle.hexagongrid.fill"
        case .symmetry:
            "arrow.left.and.right"
        case .postureSideProfile:
            "figure.stand"
        }
    }
}

enum GlowUpDeltaState: String, Codable {
    case improved
    case stable
    case declined
    case insufficientData

    var label: String {
        switch self {
        case .improved:
            "Appears improved"
        case .stable:
            "Stable"
        case .declined:
            "Needs attention"
        case .insufficientData:
            "Limited signal"
        }
    }
}

struct GlowUpTimelineScan: Identifiable, Hashable {
    let id: String
    let date: Date
    let score: Double?
    let tier: String
    let frontImageRawValue: String?
    let sideImageRawValue: String?
    let record: PersistedScanRecord
}

struct GlowUpMetricSnapshot: Hashable {
    let id: GlowUpMetricID
    let title: String
    let value: Double?
    let qualitativeValue: String?
}

struct GlowUpMetricDelta: Identifiable, Hashable {
    var id: GlowUpMetricID { metricID }

    let metricID: GlowUpMetricID
    let title: String
    let symbol: String
    let previousValue: Double?
    let latestValue: Double?
    let delta: Double?
    let state: GlowUpDeltaState
    let narrative: String
}

struct GlowUpProgressSummary: Hashable {
    let overallTrend: String
    let bestImprovedArea: String
    let areaNeedingAttention: String
    let consistencyNote: String
}

struct GlowUpComparison: Hashable {
    let latest: GlowUpTimelineScan
    let baseline: GlowUpTimelineScan
    let metricDeltas: [GlowUpMetricDelta]
    let overallDelta: Double?
    let summary: GlowUpProgressSummary
}

struct GlowUpTrackerPreferences: Codable, Equatable {
    var selectedRange: GlowUpComparisonRange = .latestPrevious
    var isPrivacyModeEnabled = true
    var preferredMetricView: GlowUpMetricView = .whatChanged
}

