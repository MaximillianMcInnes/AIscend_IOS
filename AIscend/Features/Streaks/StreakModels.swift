//
//  StreakModels.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import Foundation

enum StreakDayStatus: String, Codable, Hashable, Sendable {
    case completed
    case missed
    case pending
    case future
}

struct StreakState: Codable, Hashable, Sendable {
    var streak: Int
    var lastDate: String?
    var longest: Int
    var freezes: Int

    static let `default` = StreakState(
        streak: 0,
        lastDate: nil,
        longest: 0,
        freezes: 2
    )
}

struct StreakDayModel: Identifiable, Hashable, Sendable {
    let id: String
    let date: Date
    let weekdayLabel: String
    let dayNumber: String
    let status: StreakDayStatus
}

enum StreakMilestone: Int, CaseIterable, Identifiable, Hashable, Sendable {
    case three = 3
    case seven = 7
    case fourteen = 14
    case thirty = 30
    case sixty = 60

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .three:
            "3 day lock"
        case .seven:
            "7 day lock"
        case .fourteen:
            "14 day run"
        case .thirty:
            "30 day system"
        case .sixty:
            "60 day command"
        }
    }
}

struct StreakSnapshot: Hashable, Sendable {
    let currentStreak: Int
    let bestStreak: Int
    let totalCheckIns: Int
    let checkedInToday: Bool
    let freezesRemaining: Int
    let usedFreezeRecently: Bool
    let nextMilestone: Int
    let progressToNextMilestone: Double
    let recentDays: [StreakDayModel]
    let lastCheckInDate: Date?
    let perfectWeeks: Int
    let recentCompletionRate: Double

    var motivationalLine: String {
        if checkedInToday {
            return "Today's check-in is locked. Protect the chain tomorrow."
        }

        if usedFreezeRecently {
            return "A streak freeze protected the run. Lock today in so the chain keeps moving cleanly."
        }

        if currentStreak >= 14 {
            return "This is a serious run now. Keep the chain disciplined tonight."
        }

        if currentStreak > 0 {
            return "Protect your \(currentStreak)-day run before the day closes."
        }

        return "Start today's chain and put the system back in motion."
    }

    var statusTitle: String {
        if checkedInToday {
            return "Protected today"
        }

        if usedFreezeRecently {
            return "Freeze just used"
        }

        if currentStreak >= 7 {
            return "Momentum is live"
        }

        if currentStreak > 0 {
            return "Chain is exposed"
        }

        return "Chain is waiting"
    }

    var milestoneLabel: String {
        "\(nextMilestone)-day target"
    }
}
