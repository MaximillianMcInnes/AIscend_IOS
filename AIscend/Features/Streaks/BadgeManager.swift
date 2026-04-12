//
//  BadgeManager.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import Foundation
import SwiftUI
import UIKit

@MainActor
final class BadgeManager: ObservableObject {
    private enum Keys {
        static let records = "aiscend.badges.records"
        static let legacyEarned = "aiscend.badges.earned"
    }

    @Published private(set) var earnedBadges: [AIScendBadge] = []
    @Published var latestUnlockedBadge: AIScendBadge?

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.decoder.dateDecodingStrategy = .iso8601
        self.encoder.dateEncodingStrategy = .iso8601
        self.earnedBadges = loadBadges()
    }

    var earnedCount: Int {
        earnedBadges.count
    }

    var nextLockedBadges: [AIScendBadge] {
        AIScendBadgeID.allCases
            .filter { candidate in
                !earnedBadges.contains(where: { $0.id == candidate })
            }
            .prefix(3)
            .map { AIScendBadge($0) }
    }

    func recordResultsViewed(accessLevel: ScanResultsAccess) {
        award(.firstScan)

        if accessLevel == .premium {
            award(.premiumUnlocked)
        }
    }

    func recordPremiumUnlocked() {
        award(.premiumUnlocked)
    }

    func recordAdvisorOpened() {
        award(.aiExplorer)
    }

    func recordGlowUpOpened() {
        award(.glowUpCommitted)
    }

    func recordRoutineProgress(progress: Double, streak: Int) {
        if progress >= 1 {
            award(.routineLockedIn)
        }

        if progress >= 1, streak >= 30 {
            award(.thirtyDayStreak)
        }
    }

    func recordDailyCheckIn(
        outcome: DailyCheckInOutcome,
        allRecords: [String: DailyCheckInRecord]
    ) {
        award(.firstDailyCheckIn)
        evaluateMilestones(for: outcome.snapshot.currentStreak)

        if outcome.snapshot.currentStreak >= 5 {
            award(.consistencyBuilder)
        }

        if outcome.record.routineCompleted, outcome.snapshot.currentStreak >= 3 {
            award(.routineLockedIn)
        }

        if hasPerfectWeek(in: allRecords) {
            award(.weeklyPerfectRun)
        }
    }

    private func evaluateMilestones(for streak: Int) {
        if streak >= 3 {
            award(.threeDayStreak)
        }

        if streak >= 7 {
            award(.sevenDayStreak)
        }

        if streak >= 14 {
            award(.fourteenDayStreak)
        }

        if streak >= 30 {
            award(.thirtyDayStreak)
        }
    }

    private func hasPerfectWeek(in records: [String: DailyCheckInRecord], now: Date = .now) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
                return false
            }

            let key = DailyCheckInStore.ymd(for: date)
            guard let record = records[key], record.routineCompleted else {
                return false
            }
        }

        return true
    }

    private func award(_ badgeID: AIScendBadgeID) {
        if earnedBadges.contains(where: { $0.id == badgeID }) {
            return
        }

        let badge = AIScendBadge(badgeID)
        earnedBadges.append(badge)
        earnedBadges.sort { $0.unlockedAt > $1.unlockedAt }
        persist()
        latestUnlockedBadge = badge

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            if latestUnlockedBadge?.id == badgeID {
                latestUnlockedBadge = nil
            }
        }
    }

    private func loadBadges() -> [AIScendBadge] {
        if let data = defaults.data(forKey: Keys.records),
           let decoded = try? decoder.decode([BadgeUnlockRecord].self, from: data) {
            return decoded
                .map(AIScendBadge.init(record:))
                .sorted(by: { $0.unlockedAt > $1.unlockedAt })
        }

        let legacyIDs = (defaults.array(forKey: Keys.legacyEarned) as? [String] ?? [])
            .compactMap(AIScendBadgeID.migrated(from:))

        let migrated = legacyIDs.enumerated().map { index, id in
            AIScendBadge(
                id,
                unlockedAt: Date(timeIntervalSince1970: TimeInterval(index + 1))
            )
        }

        if !migrated.isEmpty {
            persist(badges: migrated)
        }

        return migrated.sorted(by: { $0.unlockedAt > $1.unlockedAt })
    }

    private func persist() {
        persist(badges: earnedBadges)
    }

    private func persist(badges: [AIScendBadge]) {
        let records = badges.map {
            BadgeUnlockRecord(id: $0.id, unlockedAt: $0.unlockedAt)
        }

        guard let data = try? encoder.encode(records) else {
            return
        }

        defaults.set(data, forKey: Keys.records)
    }
}
