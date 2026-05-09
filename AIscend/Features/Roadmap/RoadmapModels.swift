//
//  RoadmapModels.swift
//  AIscend
//

import Foundation

enum RoadmapGoal: String, CaseIterable, Codable, Identifiable {
    case sharperPresentation
    case skinConsistency
    case groomingUpgrade
    case recoveryAndEnergy
    case scanImprovement

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sharperPresentation:
            "Sharper presentation"
        case .skinConsistency:
            "Skin consistency"
        case .groomingUpgrade:
            "Grooming upgrade"
        case .recoveryAndEnergy:
            "Recovery and energy"
        case .scanImprovement:
            "Improve scan signals"
        }
    }

    var detail: String {
        switch self {
        case .sharperPresentation:
            "Posture, styling, facial freshness, and polish."
        case .skinConsistency:
            "A calmer, more reliable skin baseline."
        case .groomingUpgrade:
            "Hair, brows, neckline, and detail control."
        case .recoveryAndEnergy:
            "Sleep, hydration, and lower fatigue signals."
        case .scanImprovement:
            "Target the lowest available scan categories."
        }
    }
}

enum RoadmapConcern: String, CaseIterable, Codable, Identifiable {
    case tiredLook
    case skinTexture
    case hairAndGrooming
    case postureProfile
    case consistency

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tiredLook:
            "Tired look"
        case .skinTexture:
            "Skin texture"
        case .hairAndGrooming:
            "Hair and grooming"
        case .postureProfile:
            "Posture/profile"
        case .consistency:
            "Consistency"
        }
    }
}

enum RoadmapDailyTime: String, CaseIterable, Codable, Identifiable {
    case five
    case ten
    case twenty

    var id: String { rawValue }

    var title: String {
        switch self {
        case .five:
            "5 min"
        case .ten:
            "10 min"
        case .twenty:
            "20 min"
        }
    }

    var minutes: Int {
        switch self {
        case .five:
            5
        case .ten:
            10
        case .twenty:
            20
        }
    }
}

enum RoadmapConsistencyMode: String, CaseIterable, Codable, Identifiable {
    case lowEffort
    case balanced
    case aggressiveConsistency

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lowEffort:
            "Low effort"
        case .balanced:
            "Balanced"
        case .aggressiveConsistency:
            "Aggressive consistency"
        }
    }

    var detail: String {
        switch self {
        case .lowEffort:
            "Minimal daily friction."
        case .balanced:
            "Focused, realistic cadence."
        case .aggressiveConsistency:
            "More reps, still recovery-aware."
        }
    }
}

enum RoadmapPriorityCategory: String, CaseIterable, Codable, Identifiable {
    case skin
    case hair
    case eyebrows
    case facialPosture
    case sleepRecovery
    case hydration
    case styleGrooming
    case scanSpecificWeakPoint

    var id: String { rawValue }

    var title: String {
        switch self {
        case .skin:
            "Skin"
        case .hair:
            "Hair"
        case .eyebrows:
            "Eyebrows"
        case .facialPosture:
            "Facial posture"
        case .sleepRecovery:
            "Sleep/recovery"
        case .hydration:
            "Hydration"
        case .styleGrooming:
            "Style/grooming"
        case .scanSpecificWeakPoint:
            "Scan-specific weak point"
        }
    }
}

struct RoadmapBuilderProfile: Codable, Hashable {
    var goal: RoadmapGoal = .sharperPresentation
    var concern: RoadmapConcern = .tiredLook
    var dailyTime: RoadmapDailyTime = .ten
    var consistencyMode: RoadmapConsistencyMode = .balanced
}

struct RoadmapAction: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let reason: String
    let estimatedMinutes: Int
    let category: RoadmapPriorityCategory
}

struct RoadmapPriority: Identifiable, Codable, Hashable {
    let id: String
    let category: RoadmapPriorityCategory
    let title: String
    let reason: String
    let impactScore: Int
    let difficultyScore: Int
    let timeToVisibleChange: String
    let dailyActions: [String]
    let weeklyActions: [String]
}

enum RoadmapPhaseID: String, CaseIterable, Codable, Identifiable {
    case foundation
    case refinement
    case optimisation

    var id: String { rawValue }

    var number: Int {
        switch self {
        case .foundation:
            1
        case .refinement:
            2
        case .optimisation:
            3
        }
    }

    var title: String {
        switch self {
        case .foundation:
            "Foundation"
        case .refinement:
            "Refinement"
        case .optimisation:
            "Optimisation"
        }
    }

    var dayRange: ClosedRange<Int> {
        switch self {
        case .foundation:
            1...30
        case .refinement:
            31...60
        case .optimisation:
            61...90
        }
    }

    var dayLabel: String {
        "Days \(dayRange.lowerBound)-\(dayRange.upperBound)"
    }
}

struct RoadmapPhase: Identifiable, Codable, Hashable {
    var id: RoadmapPhaseID
    let focusArea: String
    let keyActions: [String]
    let expectedOutcome: String
}

struct AIScendRoadmap: Identifiable, Codable, Hashable {
    var id: UUID
    var createdAt: Date
    var overallFocus: String
    var sourceSummary: String
    var priorities: [RoadmapPriority]
    var phases: [RoadmapPhase]
    var dailyActions: [RoadmapAction]
    var weeklyActions: [RoadmapAction]
    var builderProfile: RoadmapBuilderProfile
}

struct RoadmapProgressSnapshot: Hashable {
    let currentPhaseID: RoadmapPhaseID
    let currentDay: Int
    let todayCompletion: Double
    let weeklyCompletion: Double
    let consistencyScore: Int
    let streakDays: Int
}

struct RoadmapScanSignal: Hashable {
    let hasScan: Bool
    let sourceSummary: String
    let weakCategories: [RoadmapPriorityCategory]
    let lowestMetricLabel: String?
    let scores: [RoadmapPriorityCategory: Double]

    static let unavailable = RoadmapScanSignal(
        hasScan: false,
        sourceSummary: "No scan data available yet.",
        weakCategories: [],
        lowestMetricLabel: nil,
        scores: [:]
    )
}

