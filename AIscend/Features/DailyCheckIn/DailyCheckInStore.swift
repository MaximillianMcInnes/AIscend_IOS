//
//  DailyCheckInStore.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import Foundation
import SwiftUI

enum DailyCheckInMood: String, CaseIterable, Codable, Identifiable, Sendable {
    case lockedIn
    case steady
    case resetting

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lockedIn:
            "Locked In"
        case .steady:
            "Steady"
        case .resetting:
            "Resetting"
        }
    }

    var subtitle: String {
        switch self {
        case .lockedIn:
            "Momentum is clean and execution is controlled."
        case .steady:
            "The day is under control and the chain stays intact."
        case .resetting:
            "Today is about recovering discipline, not forcing perfection."
        }
    }
}

struct DailyCheckInRecord: Codable, Hashable, Identifiable, Sendable {
    let ymd: String
    let mood: DailyCheckInMood
    let note: String
    let routineCompleted: Bool
    let selfCareCompleted: Bool
    let createdAt: Date

    var id: String { ymd }

    init(
        ymd: String,
        mood: DailyCheckInMood,
        note: String,
        routineCompleted: Bool,
        selfCareCompleted: Bool,
        createdAt: Date
    ) {
        self.ymd = ymd
        self.mood = mood
        self.note = note
        self.routineCompleted = routineCompleted
        self.selfCareCompleted = selfCareCompleted
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case ymd
        case mood
        case note
        case routineCompleted
        case selfCareCompleted
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ymd = try container.decode(String.self, forKey: .ymd)
        mood = try container.decode(DailyCheckInMood.self, forKey: .mood)
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        routineCompleted = try container.decodeIfPresent(Bool.self, forKey: .routineCompleted) ?? false
        selfCareCompleted = try container.decodeIfPresent(Bool.self, forKey: .selfCareCompleted) ?? false
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}

struct DailyCheckInOutcome: Sendable {
    let record: DailyCheckInRecord
    let snapshot: StreakSnapshot
    let wasNewCheckIn: Bool
}

@MainActor
final class DailyCheckInStore: ObservableObject {
    private enum Keys {
        static let records = "aiscend.dailyCheckIn.records"
        static let streakState = "aiscend.dailyCheckIn.streakState"
    }

    @Published private(set) var recordsByDay: [String: DailyCheckInRecord] = [:]
    @Published private(set) var snapshot: StreakSnapshot
    @Published private(set) var streakState: StreakState

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let streakManager: StreakManager
    private var usedFreezeRecently = false

    init(
        defaults: UserDefaults = .standard,
        streakManager: StreakManager = StreakManager()
    ) {
        self.defaults = defaults
        self.streakManager = streakManager

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let loadedRecords: [String: DailyCheckInRecord]
        if let data = defaults.data(forKey: Keys.records),
           let decoded = try? decoder.decode([String: DailyCheckInRecord].self, from: data) {
            loadedRecords = decoded
        } else {
            loadedRecords = [:]
        }

        let loadedState: StreakState
        if let data = defaults.data(forKey: Keys.streakState),
           let decoded = try? decoder.decode(StreakState.self, from: data) {
            loadedState = decoded
        } else {
            loadedState = streakManager.bootstrapState(from: loadedRecords)
        }

        let reconciliation = streakManager.reconcile(state: loadedState)

        self.recordsByDay = loadedRecords
        self.streakState = reconciliation.state
        self.usedFreezeRecently = reconciliation.usedFreezeRecently
        self.snapshot = streakManager.makeSnapshot(
            from: loadedRecords,
            state: reconciliation.state,
            usedFreezeRecently: reconciliation.usedFreezeRecently
        )

        persist()
    }

    var hasCheckedInToday: Bool {
        recordsByDay[Self.ymd(for: .now)] != nil
    }

    func record(for date: Date) -> DailyCheckInRecord? {
        recordsByDay[Self.ymd(for: date)]
    }

    func checkInToday(
        mood: DailyCheckInMood,
        note: String,
        routineCompleted: Bool,
        selfCareCompleted: Bool
    ) -> DailyCheckInOutcome {
        refreshForCurrentDate()

        let key = Self.ymd(for: .now)
        let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let wasNewCheckIn = recordsByDay[key] == nil

        let record = DailyCheckInRecord(
            ymd: key,
            mood: mood,
            note: cleanNote,
            routineCompleted: routineCompleted,
            selfCareCompleted: selfCareCompleted,
            createdAt: .now
        )

        recordsByDay[key] = record
        streakState = streakManager.recordCheckIn(state: streakState)
        usedFreezeRecently = false
        persist()

        let updatedSnapshot = streakManager.makeSnapshot(
            from: recordsByDay,
            state: streakState,
            usedFreezeRecently: usedFreezeRecently
        )
        snapshot = updatedSnapshot

        return DailyCheckInOutcome(
            record: record,
            snapshot: updatedSnapshot,
            wasNewCheckIn: wasNewCheckIn
        )
    }

    func recentRecords(limit: Int = 7) -> [DailyCheckInRecord] {
        recordsByDay.values
            .sorted(by: { $0.ymd > $1.ymd })
            .prefix(limit)
            .map { $0 }
    }

    func completionCount(days: Int, now: Date = .now) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        return (0..<days).reduce(into: 0) { partialResult, offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
                return
            }

            let key = Self.ymd(for: date)
            if recordsByDay[key] != nil {
                partialResult += 1
            }
        }
    }

    func routineCompletionCount(days: Int, now: Date = .now) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        return (0..<days).reduce(into: 0) { partialResult, offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
                return
            }

            let key = Self.ymd(for: date)
            if recordsByDay[key]?.routineCompleted == true {
                partialResult += 1
            }
        }
    }

    func refreshForCurrentDate(now: Date = .now) {
        let reconciliation = streakManager.reconcile(state: streakState, now: now)
        streakState = reconciliation.state
        usedFreezeRecently = reconciliation.usedFreezeRecently
        snapshot = streakManager.makeSnapshot(
            from: recordsByDay,
            state: streakState,
            usedFreezeRecently: usedFreezeRecently,
            now: now
        )
        persist()
    }

    private func persist() {
        guard let encodedRecords = try? encoder.encode(recordsByDay),
              let encodedState = try? encoder.encode(streakState) else {
            return
        }

        defaults.set(encodedRecords, forKey: Keys.records)
        defaults.set(encodedState, forKey: Keys.streakState)
    }

    nonisolated static func ymd(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    nonisolated static func date(from ymd: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: ymd)
    }
}
