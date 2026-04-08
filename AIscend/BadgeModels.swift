//
//  BadgeModels.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import Foundation

enum AIScendBadgeCategory: String, CaseIterable, Codable, Identifiable, Hashable, Sendable {
    case results
    case consistency
    case routine
    case advisor
    case premium

    var id: String { rawValue }

    var title: String {
        switch self {
        case .results:
            "Results"
        case .consistency:
            "Consistency"
        case .routine:
            "Routine"
        case .advisor:
            "Advisor"
        case .premium:
            "Premium"
        }
    }
}

enum AIScendBadgeID: String, CaseIterable, Codable, Identifiable, Sendable {
    case firstScan
    case firstDailyCheckIn
    case threeDayStreak
    case sevenDayStreak
    case fourteenDayStreak
    case thirtyDayStreak
    case consistencyBuilder
    case routineLockedIn
    case aiExplorer
    case premiumUnlocked
    case glowUpCommitted
    case weeklyPerfectRun

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstScan:
            "First Scan"
        case .firstDailyCheckIn:
            "First Daily Check-In"
        case .threeDayStreak:
            "3 Day Streak"
        case .sevenDayStreak:
            "7 Day Streak"
        case .fourteenDayStreak:
            "14 Day Streak"
        case .thirtyDayStreak:
            "30 Day Streak"
        case .consistencyBuilder:
            "Consistency Builder"
        case .routineLockedIn:
            "Routine Locked In"
        case .aiExplorer:
            "AI Explorer"
        case .premiumUnlocked:
            "Premium Unlocked"
        case .glowUpCommitted:
            "Glow-Up Committed"
        case .weeklyPerfectRun:
            "Weekly Perfect Run"
        }
    }

    var detail: String {
        switch self {
        case .firstScan:
            "The first reveal is logged. AIScend is now tracking the climb."
        case .firstDailyCheckIn:
            "The daily accountability loop is active."
        case .threeDayStreak:
            "Three straight days of discipline. The chain is real now."
        case .sevenDayStreak:
            "A full week preserved. Consistency is becoming identity."
        case .fourteenDayStreak:
            "Two clean weeks of follow-through. Momentum is now obvious."
        case .thirtyDayStreak:
            "A month protected. This is no longer motivation, it is system."
        case .consistencyBuilder:
            "You are stacking enough clean days for the product to feel sticky on purpose."
        case .routineLockedIn:
            "The routine is moving from good intention to repeatable execution."
        case .aiExplorer:
            "You used the advisor to sharpen the plan instead of staying passive."
        case .premiumUnlocked:
            "The deeper AIScend layer is open."
        case .glowUpCommitted:
            "You turned the scan into an actual next move."
        case .weeklyPerfectRun:
            "Seven consecutive days checked in with the routine handled cleanly."
        }
    }

    var unlockHint: String {
        switch self {
        case .firstScan:
            "View your first scan result."
        case .firstDailyCheckIn:
            "Complete today's first check-in."
        case .threeDayStreak:
            "Protect the chain for 3 days."
        case .sevenDayStreak:
            "Protect the chain for a full week."
        case .fourteenDayStreak:
            "Protect the chain for 14 days."
        case .thirtyDayStreak:
            "Protect the chain for 30 days."
        case .consistencyBuilder:
            "Hold the cadence long enough for the system to notice."
        case .routineLockedIn:
            "Check in after handling the routine properly."
        case .aiExplorer:
            "Use the AI advisor to unpack your plan."
        case .premiumUnlocked:
            "Unlock the premium layer."
        case .glowUpCommitted:
            "Open the glow-up path from results or routine."
        case .weeklyPerfectRun:
            "Check in for 7 straight days with the routine completed."
        }
    }

    var symbol: String {
        switch self {
        case .firstScan:
            "viewfinder.circle.fill"
        case .firstDailyCheckIn:
            "calendar.badge.checkmark"
        case .threeDayStreak:
            "flame.fill"
        case .sevenDayStreak:
            "sparkles.rectangle.stack.fill"
        case .fourteenDayStreak:
            "scope"
        case .thirtyDayStreak:
            "bolt.shield.fill"
        case .consistencyBuilder:
            "figure.strengthtraining.traditional"
        case .routineLockedIn:
            "checkmark.seal.fill"
        case .aiExplorer:
            "message.fill"
        case .premiumUnlocked:
            "crown.fill"
        case .glowUpCommitted:
            "star.square.on.square.fill"
        case .weeklyPerfectRun:
            "calendar.circle.fill"
        }
    }

    var accent: RoutineAccent {
        switch self {
        case .firstScan, .firstDailyCheckIn:
            .dawn
        case .premiumUnlocked, .glowUpCommitted, .thirtyDayStreak:
            .sky
        case .threeDayStreak, .sevenDayStreak, .fourteenDayStreak, .consistencyBuilder, .routineLockedIn, .aiExplorer, .weeklyPerfectRun:
            .mint
        }
    }

    var category: AIScendBadgeCategory {
        switch self {
        case .firstScan:
            .results
        case .firstDailyCheckIn, .threeDayStreak, .sevenDayStreak, .fourteenDayStreak, .thirtyDayStreak, .consistencyBuilder, .weeklyPerfectRun:
            .consistency
        case .routineLockedIn, .glowUpCommitted:
            .routine
        case .aiExplorer:
            .advisor
        case .premiumUnlocked:
            .premium
        }
    }

    static func migrated(from rawValue: String) -> AIScendBadgeID? {
        if let badgeID = AIScendBadgeID(rawValue: rawValue) {
            return badgeID
        }

        switch rawValue {
        case "dailyCheckInStarter":
            return .firstDailyCheckIn
        case "askedTheAI":
            return .aiExplorer
        case "completedFirstRoutine":
            return .routineLockedIn
        case "glowUpLockedIn":
            return .glowUpCommitted
        default:
            return nil
        }
    }
}

struct BadgeUnlockRecord: Codable, Hashable, Sendable {
    let id: AIScendBadgeID
    let unlockedAt: Date
}

struct AIScendBadge: Identifiable, Hashable, Sendable {
    let id: AIScendBadgeID
    let title: String
    let detail: String
    let symbol: String
    let accent: RoutineAccent
    let category: AIScendBadgeCategory
    let unlockHint: String
    let unlockedAt: Date

    init(
        _ id: AIScendBadgeID,
        unlockedAt: Date = .now
    ) {
        self.id = id
        self.title = id.title
        self.detail = id.detail
        self.symbol = id.symbol
        self.accent = id.accent
        self.category = id.category
        self.unlockHint = id.unlockHint
        self.unlockedAt = unlockedAt
    }

    init(record: BadgeUnlockRecord) {
        self.init(record.id, unlockedAt: record.unlockedAt)
    }
}
