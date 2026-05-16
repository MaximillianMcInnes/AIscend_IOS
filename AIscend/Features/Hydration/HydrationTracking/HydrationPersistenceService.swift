//
//  HydrationPersistenceService.swift
//  AIscend
//
//  Created by Codex on 5/10/26.
//

import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

struct HydrationPersistenceService {
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func loadDrinkLogs(userID: String?) -> [String: [DrinkLogEntry]] {
        do {
            let url = try drinkLogsURL(userID: userID)
            guard fileManager.fileExists(atPath: url.path) else {
                return [:]
            }

            let data = try Data(contentsOf: url)
            return try decoder.decode([String: [DrinkLogEntry]].self, from: data)
        } catch {
            return [:]
        }
    }

    func saveDrinkLogs(_ logsByDay: [String: [DrinkLogEntry]], userID: String?) {
        do {
            let url = try drinkLogsURL(userID: userID)
            try fileManager.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try encoder.encode(logsByDay)
            try data.write(to: url, options: [.atomic])
        } catch {
            return
        }
    }

    func syncDrinkLogToFirestore(_ entry: DrinkLogEntry, userID: String?) async {
        guard let userID = normalizedUserID(userID) else {
            return
        }

        #if canImport(FirebaseFirestore)
        #if canImport(FirebaseCore)
        guard FirebaseApp.app() != nil else {
            return
        }
        #endif

        let reference = Firestore.firestore()
            .collection("Users")
            .document(userID)
            .collection("hydrationLogs")
            .document(entry.hydrationFirestorePathComponent)

        do {
            try await setData(entry.firebasePayload(), on: reference, merge: true)
        } catch {
            return
        }
        #else
        return
        #endif
    }

    func deleteDrinkLogFromFirestore(_ entry: DrinkLogEntry, userID: String?) async {
        guard let userID = normalizedUserID(userID) else {
            return
        }

        #if canImport(FirebaseFirestore)
        #if canImport(FirebaseCore)
        guard FirebaseApp.app() != nil else {
            return
        }
        #endif

        let reference = Firestore.firestore()
            .collection("Users")
            .document(userID)
            .collection("hydrationLogs")
            .document(entry.hydrationFirestorePathComponent)

        do {
            try await deleteDocument(reference)
        } catch {
            return
        }
        #else
        return
        #endif
    }

    func groupedByDay(_ logs: [DrinkLogEntry]) -> [String: [DrinkLogEntry]] {
        Dictionary(grouping: logs) { HydrationGoalEngine.dayKey(for: $0.loggedAt) }
            .mapValues { $0.sorted { $0.loggedAt > $1.loggedAt } }
    }

    func flatLogs(from logsByDay: [String: [DrinkLogEntry]]) -> [DrinkLogEntry] {
        logsByDay.values.flatMap { $0 }.sorted { $0.loggedAt > $1.loggedAt }
    }

    private func drinkLogsURL(userID: String?) throws -> URL {
        let baseURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let namespace = Self.namespace(for: userID)
        return baseURL
            .appendingPathComponent("AIscend", isDirectory: true)
            .appendingPathComponent("Hydration", isDirectory: true)
            .appendingPathComponent("drink-logs-\(namespace).json", isDirectory: false)
    }

    static func namespace(for userID: String?) -> String {
        let trimmed = userID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let rawNamespace = trimmed.isEmpty ? "guest" : trimmed
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let sanitizedScalars = rawNamespace.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(scalar) : "-"
        }
        return String(sanitizedScalars)
    }

    private func normalizedUserID(_ userID: String?) -> String? {
        let trimmed = userID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    #if canImport(FirebaseFirestore)
    private func setData(_ data: [String: Any], on reference: DocumentReference, merge: Bool) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reference.setData(data, merge: merge) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func deleteDocument(_ reference: DocumentReference) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reference.delete { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    #endif
}

final class HydrationDrinkLogStore {
    private var userID: String?
    private let persistence: HydrationPersistenceService

    init(
        userID: String? = nil,
        persistence: HydrationPersistenceService = HydrationPersistenceService()
    ) {
        self.userID = userID
        self.persistence = persistence
    }

    func applyAuthenticatedUserID(_ userID: String?) {
        self.userID = userID
    }

    func loadLogsByDay() -> [String: [DrinkLogEntry]] {
        persistence.loadDrinkLogs(userID: userID)
    }

    func saveLogsByDay(_ logsByDay: [String: [DrinkLogEntry]]) {
        persistence.saveDrinkLogs(logsByDay, userID: userID)
    }

    func logsByAdding(_ entry: DrinkLogEntry, to logsByDay: [String: [DrinkLogEntry]]) -> [String: [DrinkLogEntry]] {
        var nextLogs = logsByDay
        let dayKey = HydrationGoalEngine.dayKey(for: entry.loggedAt)
        var dayLogs = nextLogs[dayKey] ?? []
        dayLogs.append(entry)
        nextLogs[dayKey] = dayLogs.sorted { $0.loggedAt > $1.loggedAt }
        return nextLogs
    }

    func logsByUpdating(_ entry: DrinkLogEntry, in logsByDay: [String: [DrinkLogEntry]]) -> [String: [DrinkLogEntry]] {
        var nextLogs = logsByDay
        let dayKey = HydrationGoalEngine.dayKey(for: entry.loggedAt)
        guard var dayLogs = nextLogs[dayKey],
              let index = dayLogs.firstIndex(where: { $0.id == entry.id }) else {
            return logsByDay
        }

        dayLogs[index] = entry
        nextLogs[dayKey] = dayLogs.sorted { $0.loggedAt > $1.loggedAt }
        return nextLogs
    }

    func logsByDeleting(_ entry: DrinkLogEntry, from logsByDay: [String: [DrinkLogEntry]]) -> [String: [DrinkLogEntry]] {
        var nextLogs = logsByDay
        let dayKey = HydrationGoalEngine.dayKey(for: entry.loggedAt)
        guard var dayLogs = nextLogs[dayKey] else {
            return logsByDay
        }

        dayLogs.removeAll { $0.id == entry.id }
        nextLogs[dayKey] = dayLogs
        return nextLogs
    }

    func syncToFirebaseIfAvailable(_ entry: DrinkLogEntry) {
        Task {
            await persistence.syncDrinkLogToFirestore(entry, userID: userID)
        }
    }

    func deleteFromFirebaseIfAvailable(_ entry: DrinkLogEntry) {
        Task {
            await persistence.deleteDrinkLogFromFirestore(entry, userID: userID)
        }
    }
}

extension DrinkLogEntry {
    var hydrationFirestorePathComponent: String {
        id
    }

    func firebasePayload(now: Date = .now) -> [String: Any] {
        var payload: [String: Any] = [
            "drinkId": drinkId,
            "drinkName": drinkName,
            "amountMl": amountMl,
            "hydrationCreditMl": hydrationCreditMl,
            "electrolytes": [
                "sodiumMg": sodiumMg,
                "potassiumMg": potassiumMg,
                "magnesiumMg": magnesiumMg
            ],
            "caffeineMg": caffeineMg,
            "calories": calories,
            "sugarG": sugarG
        ]

        if let drinkCategory {
            payload["category"] = drinkCategory.rawValue
        }

        #if canImport(FirebaseFirestore)
        payload["loggedAt"] = Timestamp(date: loggedAt)
        payload["createdAt"] = Timestamp(date: createdAt ?? loggedAt)
        payload["updatedAt"] = Timestamp(date: updatedAt ?? now)
        #else
        payload["loggedAt"] = loggedAt
        payload["createdAt"] = createdAt ?? loggedAt
        payload["updatedAt"] = updatedAt ?? now
        #endif

        return payload
    }
}
