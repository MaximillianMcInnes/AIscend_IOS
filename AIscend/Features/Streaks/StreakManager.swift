//
//  StreakManager.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import Foundation

struct StreakManager: Sendable {
    private let calendar = Calendar.current

    @MainActor
    func makeSnapshot(
        from records: [String: DailyCheckInRecord],
        state: StreakState,
        usedFreezeRecently: Bool = false,
        now: Date = .now,
        windowSize: Int = 28
    ) -> StreakSnapshot {
        let todayKey = DailyCheckInStore.ymd(for: now)
        let checkedInToday = records[todayKey] != nil
        let current = max(state.streak, 0)
        let next = nextMilestone(for: current)

        return StreakSnapshot(
            currentStreak: current,
            bestStreak: max(state.longest, bestStreak(from: records.keys.sorted())),
            totalCheckIns: records.count,
            checkedInToday: checkedInToday,
            freezesRemaining: max(state.freezes, 0),
            usedFreezeRecently: usedFreezeRecently,
            nextMilestone: next,
            progressToNextMilestone: progressToNextMilestone(current: current, next: next),
            recentDays: recentDays(from: records, now: now, windowSize: windowSize),
            lastCheckInDate: lastCheckInDate(from: records),
            perfectWeeks: perfectWeeks(from: records, now: now),
            recentCompletionRate: recentCompletionRate(from: records, now: now)
        )
    }

    @MainActor
    func bootstrapState(from records: [String: DailyCheckInRecord], now: Date = .now) -> StreakState {
        let sortedKeys = records.keys.sorted()
        let best = bestStreak(from: sortedKeys)
        let streak = currentStreakFromRecords(records, now: now)

        return StreakState(
            streak: streak,
            lastDate: sortedKeys.last,
            longest: max(best, streak),
            freezes: StreakState.default.freezes
        )
    }

    func reconcile(
        state: StreakState,
        now: Date = .now
    ) -> (state: StreakState, usedFreezeRecently: Bool) {
        var updated = state
        var usedFreezeRecently = false
        let todayKey = DailyCheckInStore.ymd(for: now)

        guard let lastDate = updated.lastDate else {
            return (updated, false)
        }

        guard lastDate != todayKey else {
            return (updated, false)
        }

        guard let gap = uncoveredGapDays(since: lastDate, now: now), gap > 0 else {
            return (updated, false)
        }

        var remainingGap = gap
        while remainingGap > 0, updated.freezes > 0 {
            updated.freezes -= 1
            usedFreezeRecently = true

            if let coveredDate = coveredDate(from: lastDate, offset: gap - remainingGap + 1) {
                updated.lastDate = coveredDate
            }

            remainingGap -= 1
        }

        if remainingGap > 0 {
            updated.streak = 0
            updated.lastDate = nil
        }

        updated.longest = max(updated.longest, updated.streak)
        return (updated, usedFreezeRecently)
    }

    func recordCheckIn(
        state: StreakState,
        now: Date = .now
    ) -> StreakState {
        var updated = state
        let todayKey = DailyCheckInStore.ymd(for: now)

        if updated.lastDate == todayKey {
            return updated
        }

        if let lastDate = updated.lastDate,
           let gap = dayGap(from: lastDate, to: todayKey),
           gap == 1 {
            updated.streak += 1
        } else {
            updated.streak = max(updated.streak, 0) + 1
        }

        updated.lastDate = todayKey
        updated.longest = max(updated.longest, updated.streak)
        return updated
    }

    @MainActor
    private func bestStreak(from sortedKeys: [String]) -> Int {
        guard !sortedKeys.isEmpty else {
            return 0
        }

        var best = 0
        var current = 0
        var previousDate: Date?

        for key in sortedKeys {
            guard let date = DailyCheckInStore.date(from: key) else {
                continue
            }

            if let previousDate,
               let expected = calendar.date(byAdding: .day, value: 1, to: previousDate),
               calendar.isDate(expected, inSameDayAs: date) {
                current += 1
            } else {
                current = 1
            }

            best = max(best, current)
            previousDate = date
        }

        return best
    }

    private func nextMilestone(for streak: Int) -> Int {
        StreakMilestone.allCases
            .map(\.rawValue)
            .first(where: { $0 > streak })
        ?? (max(streak, 30) + 30)
    }

    private func progressToNextMilestone(current: Int, next: Int) -> Double {
        let previous = StreakMilestone.allCases
            .map(\.rawValue)
            .filter { $0 <= current }
            .max() ?? 0

        let span = max(next - previous, 1)
        let progress = Double(current - previous) / Double(span)
        return min(max(progress, 0), 1)
    }

    @MainActor
    private func lastCheckInDate(from records: [String: DailyCheckInRecord]) -> Date? {
        records.keys
            .compactMap(DailyCheckInStore.date(from:))
            .max()
    }

    @MainActor
    private func perfectWeeks(from records: [String: DailyCheckInRecord], now: Date) -> Int {
        let today = calendar.startOfDay(for: now)
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        var count = 0

        for weekOffset in 0..<12 {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: startOfWeek) else {
                continue
            }

            let isPerfect = (0..<7).allSatisfy { dayOffset in
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else {
                    return false
                }

                if date > today {
                    return false
                }

                let key = DailyCheckInStore.ymd(for: date)
                return records[key]?.routineCompleted == true
            }

            if isPerfect {
                count += 1
            }
        }

        return count
    }

    @MainActor
    private func recentCompletionRate(from records: [String: DailyCheckInRecord], now: Date) -> Double {
        let today = calendar.startOfDay(for: now)
        let completed = (0..<7).reduce(into: 0) { partialResult, offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
                return
            }

            let key = DailyCheckInStore.ymd(for: date)
            if records[key] != nil {
                partialResult += 1
            }
        }

        return Double(completed) / 7.0
    }

    @MainActor
    private func recentDays(
        from records: [String: DailyCheckInRecord],
        now: Date,
        windowSize: Int
    ) -> [StreakDayModel] {
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "E"

        return (0..<windowSize).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -(windowSize - 1 - offset), to: now) else {
                return nil
            }

            let key = DailyCheckInStore.ymd(for: date)
            let today = calendar.startOfDay(for: now)
            let startOfDay = calendar.startOfDay(for: date)
            let status: StreakDayStatus

            if records[key] != nil {
                status = .completed
            } else if startOfDay > today {
                status = .future
            } else if calendar.isDate(startOfDay, inSameDayAs: today) {
                status = .pending
            } else {
                status = .missed
            }

            return StreakDayModel(
                id: key,
                date: date,
                weekdayLabel: weekdayFormatter.string(from: date).uppercased(),
                dayNumber: String(calendar.component(.day, from: date)),
                status: status
            )
        }
    }

    @MainActor
    private func currentStreakFromRecords(_ records: [String: DailyCheckInRecord], now: Date) -> Int {
        var streak = 0
        let today = calendar.startOfDay(for: now)

        for offset in 0..<366 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
                break
            }

            let key = DailyCheckInStore.ymd(for: date)
            if records[key] != nil {
                streak += 1
                continue
            }

            if offset == 0 {
                continue
            }

            break
        }

        return streak
    }

    private func uncoveredGapDays(since lastDate: String, now: Date) -> Int? {
        let todayKey = DailyCheckInStore.ymd(for: now)
        guard let gap = dayGap(from: lastDate, to: todayKey) else {
            return nil
        }

        return max(gap - 1, 0)
    }

    private func coveredDate(from lastDate: String, offset: Int) -> String? {
        guard let date = DailyCheckInStore.date(from: lastDate),
              let protectedDate = calendar.date(byAdding: .day, value: offset, to: date) else {
            return nil
        }

        return DailyCheckInStore.ymd(for: protectedDate)
    }

    private func dayGap(from earlier: String, to later: String) -> Int? {
        guard let earlierDate = DailyCheckInStore.date(from: earlier),
              let laterDate = DailyCheckInStore.date(from: later) else {
            return nil
        }

        let earlierDay = calendar.startOfDay(for: earlierDate)
        let laterDay = calendar.startOfDay(for: laterDate)
        return calendar.dateComponents([.day], from: earlierDay, to: laterDay).day
    }
}
