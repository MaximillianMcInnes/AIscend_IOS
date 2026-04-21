//
//  DailyCheckInNotifications.swift
//  AIscend
//
//  Created by Codex on 4/19/26.
//

import Foundation

struct AIScendReminderSchedule: Sendable {
    let time: DateComponents
    let title: String
    let body: String
}

enum DailyCheckInNotifications {
    static let dailyCheckIn = AIScendReminderSchedule(
        time: DateComponents(hour: 20, minute: 30),
        title: "Keep your streak alive",
        body: "Open the routine, finish today's check-in, and lock in the streak before the day closes."
    )

    static let streakProtection = AIScendReminderSchedule(
        time: DateComponents(hour: 18, minute: 45),
        title: "Protect today's run",
        body: "Your streak is still live. Jump back into the routine and protect it with a fast check-in."
    )

    static let routine = AIScendReminderSchedule(
        time: DateComponents(hour: 9, minute: 15),
        title: "Keep the routine moving",
        body: "Open your routine early, keep the day clean, and make tonight's streak check-in easy."
    )
}

extension AIScendReminderKind {
    var schedule: AIScendReminderSchedule {
        switch self {
        case .dailyCheckIn:
            DailyCheckInNotifications.dailyCheckIn
        case .streakProtection:
            DailyCheckInNotifications.streakProtection
        case .routine:
            DailyCheckInNotifications.routine
        }
    }
}
