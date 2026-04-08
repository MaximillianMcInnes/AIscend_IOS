//
//  NotificationManager.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import Foundation
import SwiftUI
import UserNotifications

enum AIScendReminderKind: String, CaseIterable, Identifiable, Codable, Sendable {
    case dailyCheckIn
    case streakProtection
    case routine

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dailyCheckIn:
            "Daily check-in"
        case .streakProtection:
            "Streak protection"
        case .routine:
            "Routine reminder"
        }
    }

    var subtitle: String {
        switch self {
        case .dailyCheckIn:
            "A clean nightly nudge to close the day."
        case .streakProtection:
            "A stronger reminder before the chain is exposed."
        case .routine:
            "A lighter prompt to move the plan forward early."
        }
    }

    fileprivate var identifier: String {
        switch self {
        case .dailyCheckIn:
            "aiscend.notifications.dailyCheckIn"
        case .streakProtection:
            "aiscend.notifications.streakProtection"
        case .routine:
            "aiscend.notifications.routine"
        }
    }

    fileprivate var defaultTime: DateComponents {
        switch self {
        case .dailyCheckIn:
            DateComponents(hour: 20, minute: 30)
        case .streakProtection:
            DateComponents(hour: 18, minute: 45)
        case .routine:
            DateComponents(hour: 9, minute: 15)
        }
    }

    fileprivate var content: (title: String, body: String) {
        switch self {
        case .dailyCheckIn:
            (
                "Keep the chain clean",
                "Today's AIScend check-in is still open. Lock it in before the day closes."
            )
        case .streakProtection:
            (
                "Don't break the streak",
                "Your current run is still alive. Protect it with a fast nightly check-in."
            )
        case .routine:
            (
                "Move the plan forward",
                "A clean routine day compounds faster than another day of drift."
            )
        }
    }
}

struct AIScendNotificationPreferences: Codable, Hashable, Sendable {
    var dailyCheckInEnabled: Bool = true
    var streakProtectionEnabled: Bool = true
    var routineEnabled: Bool = true
    var lastSyncedAt: Date?

    func isEnabled(_ kind: AIScendReminderKind) -> Bool {
        switch kind {
        case .dailyCheckIn:
            dailyCheckInEnabled
        case .streakProtection:
            streakProtectionEnabled
        case .routine:
            routineEnabled
        }
    }

    mutating func setEnabled(_ enabled: Bool, for kind: AIScendReminderKind) {
        switch kind {
        case .dailyCheckIn:
            dailyCheckInEnabled = enabled
        case .streakProtection:
            streakProtectionEnabled = enabled
        case .routine:
            routineEnabled = enabled
        }
    }

    var enabledCount: Int {
        [
            dailyCheckInEnabled,
            streakProtectionEnabled,
            routineEnabled
        ]
        .filter { $0 }
        .count
    }

    var anyEnabled: Bool {
        enabledCount > 0
    }
}

@MainActor
final class NotificationManager: ObservableObject {
    enum AuthorizationState: Equatable {
        case unknown
        case enabled
        case denied
        case unavailable

        var badgeTitle: String {
            switch self {
            case .unknown:
                "Not Set"
            case .enabled:
                "Enabled"
            case .denied:
                "Denied"
            case .unavailable:
                "Unavailable"
            }
        }

        var detail: String {
            switch self {
            case .unknown:
                "AIScend can protect your streak with daily reminders when you allow notifications."
            case .enabled:
                "Daily check-in and streak reminders are active."
            case .denied:
                "Notifications are currently off. You can re-enable them in Settings."
            case .unavailable:
                "Notifications are unavailable in this build."
            }
        }
    }

    @Published private(set) var authorizationState: AuthorizationState = .unknown
    @Published private(set) var preferences: AIScendNotificationPreferences

    private enum Keys {
        static let preferences = "aiscend.notifications.preferences"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601

        if let data = defaults.data(forKey: Keys.preferences),
           let decoded = try? decoder.decode(AIScendNotificationPreferences.self, from: data) {
            self.preferences = decoded
        } else {
            self.preferences = AIScendNotificationPreferences()
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await currentSettings()
        authorizationState = map(settings.authorizationStatus)
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await currentSettings()
        let mapped = map(settings.authorizationStatus)

        switch mapped {
        case .enabled:
            authorizationState = .enabled
            return true
        case .denied:
            authorizationState = .denied
            return false
        case .unavailable:
            authorizationState = .unavailable
            return false
        case .unknown:
            let granted = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }

            authorizationState = granted ? .enabled : .denied
            return granted
        }
    }

    func scheduleDefaultAIScendReminders() async {
        await syncScheduledReminders(requestAuthorizationIfNeeded: true)
    }

    func removeAIScendReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: AIScendReminderKind.allCases.map(\.identifier))
    }

    func isEnabled(_ kind: AIScendReminderKind) -> Bool {
        preferences.isEnabled(kind)
    }

    func setReminderEnabled(_ enabled: Bool, for kind: AIScendReminderKind) async {
        if enabled {
            let granted = await requestAuthorizationIfNeeded()

            guard granted else {
                preferences.setEnabled(false, for: kind)
                persist()
                return
            }
        }

        preferences.setEnabled(enabled, for: kind)
        persist()

        await syncScheduledReminders(requestAuthorizationIfNeeded: false)
    }

    func enableAllReminders() async {
        preferences.dailyCheckInEnabled = true
        preferences.streakProtectionEnabled = true
        preferences.routineEnabled = true
        persist()

        await syncScheduledReminders(requestAuthorizationIfNeeded: true)
    }

    func syncScheduledReminders(requestAuthorizationIfNeeded shouldRequestAuthorizationIfNeeded: Bool = true) async {
        if shouldRequestAuthorizationIfNeeded {
            guard await requestAuthorizationIfNeeded() else {
                return
            }
        } else {
            let settings = await currentSettings()
            authorizationState = map(settings.authorizationStatus)

            guard authorizationState == .enabled else {
                return
            }
        }

        for kind in AIScendReminderKind.allCases {
            if preferences.isEnabled(kind) {
                scheduleCalendarReminder(kind: kind)
            } else {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [kind.identifier])
            }
        }

        preferences.lastSyncedAt = .now
        persist()
    }

    private func scheduleCalendarReminder(kind: AIScendReminderKind) {
        let content = UNMutableNotificationContent()
        content.title = kind.content.title
        content.body = kind.content.body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: kind.identifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: kind.defaultTime, repeats: true)
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func currentSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { (continuation: CheckedContinuation<UNNotificationSettings, Never>) in
            UNUserNotificationCenter.current().getNotificationSettings { continuation.resume(returning: $0) }
        }
    }

    private func map(_ status: UNAuthorizationStatus) -> AuthorizationState {
        switch status {
        case .authorized, .provisional, .ephemeral:
            .enabled
        case .denied:
            .denied
        case .notDetermined:
            .unknown
        @unknown default:
            .unavailable
        }
    }

    private func persist() {
        guard let data = try? encoder.encode(preferences) else {
            return
        }

        defaults.set(data, forKey: Keys.preferences)
    }
}
