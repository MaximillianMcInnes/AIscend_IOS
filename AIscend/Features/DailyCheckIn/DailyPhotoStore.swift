//
//  DailyPhotoStore.swift
//  AIscend
//
//  Created by Codex on 4/9/26.
//

import Foundation
import SwiftUI

enum DailyPhotoPromptTrigger {
    case firstOpen
    case engagement
}

struct DailyPhotoEntry: Codable, Hashable, Identifiable, Sendable {
    let ymd: String
    let relativePath: String
    let createdAt: Date

    var id: String { ymd }
}

struct DailyPhotoPromptRecord: Codable, Hashable, Sendable {
    let ymd: String
    var initialPromptShown: Bool
    var randomPromptOffsets: [Int]
    var deliveredPromptOffsets: [Int]
    var lastPromptAt: Date?

    static func make(for date: Date) -> DailyPhotoPromptRecord {
        let today = DailyPhotoStore.ymd(for: date)
        var offsets = Set<Int>()

        while offsets.count < 3 {
            offsets.insert(Int.random(in: 10 * 60..<(22 * 60)))
        }

        return DailyPhotoPromptRecord(
            ymd: today,
            initialPromptShown: false,
            randomPromptOffsets: offsets.sorted(),
            deliveredPromptOffsets: [],
            lastPromptAt: nil
        )
    }
}

@MainActor
final class DailyPhotoStore: ObservableObject {
    private enum Keys {
        static let entries = "dailyPhoto.entries"
        static let promptRecord = "dailyPhoto.promptRecord"
    }

    @Published private(set) var entriesByDay: [String: DailyPhotoEntry] = [:]
    @Published private(set) var promptRecord: DailyPhotoPromptRecord

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var storageNamespace: String

    init(
        defaults: UserDefaults = .standard,
        userID: String? = nil
    ) {
        self.defaults = defaults
        self.storageNamespace = Self.namespace(for: userID)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        self.promptRecord = DailyPhotoPromptRecord.make(for: .now)
        restorePersistedState()
    }

    var hasPhotoToday: Bool {
        entry(for: .now) != nil
    }

    var todayEntry: DailyPhotoEntry? {
        entry(for: .now)
    }

    var captureCount: Int {
        entriesByDay.count
    }

    var randomPromptsRemainingToday: Int {
        max(0, 3 - promptRecord.deliveredPromptOffsets.count)
    }

    func applyAuthenticatedUserID(_ userID: String?) {
        let newNamespace = Self.namespace(for: userID)
        guard newNamespace != storageNamespace else {
            return
        }

        storageNamespace = newNamespace
        restorePersistedState()
    }

    func entry(for date: Date) -> DailyPhotoEntry? {
        entriesByDay[Self.ymd(for: date)]
    }

    func recentEntries(limit: Int = 3) -> [DailyPhotoEntry] {
        entriesByDay.values
            .sorted(by: { $0.ymd > $1.ymd })
            .prefix(limit)
            .map { $0 }
    }

    func currentStreakDays(now: Date = .now) -> Int {
        let calendar = Calendar.current
        var count = 0
        var cursor = calendar.startOfDay(for: now)

        while let entry = entriesByDay[Self.ymd(for: cursor)], !entry.relativePath.isEmpty {
            count += 1

            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }

            cursor = previous
        }

        return count
    }

    func imageURL(for entry: DailyPhotoEntry) -> URL? {
        let url = photoStorageDirectory.appendingPathComponent(entry.relativePath, isDirectory: false)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func saveTodayPhoto(data: Data, fileExtension: String = "jpg", now: Date = .now) throws -> DailyPhotoEntry {
        normalizePromptRecordIfNeeded(for: now)

        let today = Self.ymd(for: now)
        let fileManager = FileManager.default
        try fileManager.createDirectory(
            at: photoStorageDirectory,
            withIntermediateDirectories: true
        )

        let sanitizedNamespace = storageNamespace.replacingOccurrences(of: "[^A-Za-z0-9._-]", with: "-", options: .regularExpression)
        let filename = "daily-photo-\(sanitizedNamespace)-\(today).\(fileExtension)"
        let destinationURL = photoStorageDirectory.appendingPathComponent(filename, isDirectory: false)

        if let existingEntry = entriesByDay[today],
           existingEntry.relativePath != filename
        {
            let existingURL = photoStorageDirectory.appendingPathComponent(existingEntry.relativePath, isDirectory: false)
            try? fileManager.removeItem(at: existingURL)
        }

        try data.write(to: destinationURL, options: .atomic)

        let entry = DailyPhotoEntry(
            ymd: today,
            relativePath: filename,
            createdAt: now
        )

        entriesByDay[today] = entry
        persistEntries()
        return entry
    }

    func shouldPresentPrompt(for trigger: DailyPhotoPromptTrigger, now: Date = .now) -> Bool {
        normalizePromptRecordIfNeeded(for: now)

        if hasPhotoToday {
            return false
        }

        switch trigger {
        case .firstOpen:
            guard !promptRecord.initialPromptShown else {
                return false
            }

            promptRecord.initialPromptShown = true
            promptRecord.lastPromptAt = now
            persistPromptRecord()
            return true

        case .engagement:
            guard promptRecord.initialPromptShown else {
                return false
            }

            guard now.timeIntervalSince(promptRecord.lastPromptAt ?? .distantPast) >= 20 * 60 else {
                return false
            }

            let minutesSinceStartOfDay = Self.minutesSinceStartOfDay(for: now)
            guard let nextOffset = promptRecord.randomPromptOffsets.first(where: {
                $0 <= minutesSinceStartOfDay && !promptRecord.deliveredPromptOffsets.contains($0)
            }) else {
                return false
            }

            promptRecord.deliveredPromptOffsets.append(nextOffset)
            promptRecord.lastPromptAt = now
            persistPromptRecord()
            return true
        }
    }

    private func restorePersistedState() {
        if let data = defaults.data(forKey: namespacedKey(Keys.entries)),
           let decoded = try? decoder.decode([String: DailyPhotoEntry].self, from: data)
        {
            entriesByDay = decoded
        } else {
            entriesByDay = [:]
        }

        if let data = defaults.data(forKey: namespacedKey(Keys.promptRecord)),
           let decoded = try? decoder.decode(DailyPhotoPromptRecord.self, from: data)
        {
            promptRecord = decoded
        } else {
            promptRecord = DailyPhotoPromptRecord.make(for: .now)
        }

        normalizePromptRecordIfNeeded(for: .now)
    }

    private func normalizePromptRecordIfNeeded(for date: Date) {
        let today = Self.ymd(for: date)
        guard promptRecord.ymd != today else {
            return
        }

        promptRecord = DailyPhotoPromptRecord.make(for: date)
        persistPromptRecord()
    }

    private func persistEntries() {
        guard let data = try? encoder.encode(entriesByDay) else {
            return
        }

        defaults.set(data, forKey: namespacedKey(Keys.entries))
    }

    private func persistPromptRecord() {
        guard let data = try? encoder.encode(promptRecord) else {
            return
        }

        defaults.set(data, forKey: namespacedKey(Keys.promptRecord))
    }

    private func namespacedKey(_ key: String) -> String {
        "\(storageNamespace).\(key)"
    }

    private static func namespace(for userID: String?) -> String {
        guard let userID, !userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "guest"
        }

        return "user.\(userID)"
    }

    private var photoStorageDirectory: URL {
        defaultsDirectory
            .appendingPathComponent("AIscendDailyPhotos", isDirectory: true)
            .appendingPathComponent(storageNamespace, isDirectory: true)
    }

    private var defaultsDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
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

    nonisolated static func minutesSinceStartOfDay(for date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}
