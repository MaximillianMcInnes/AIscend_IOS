//
//  FacialTrainingStore.swift
//  AIscend
//
//  Created by Codex on 5/10/26.
//

import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

@MainActor
final class FacialTrainingStore: ObservableObject {
    private enum Keys {
        static let plan = "aiscend.facialTraining.plan"
        static let progress = "aiscend.facialTraining.progress"
        static let feedback = "aiscend.facialTraining.feedback"
    }

    @Published private(set) var plan: FacialTrainingPlan?
    @Published private(set) var progress: [ProgressSnapshot]
    @Published private(set) var feedbackHistory: [SessionFeedback]
    @Published private(set) var syncState: FacialTrainingSyncState = .local

    private let defaults: UserDefaults
    private let engine: FacialTrainingSessionEngine
    private var authenticatedUserID: String?

    init(
        defaults: UserDefaults = .standard,
        engine: FacialTrainingSessionEngine = FacialTrainingSessionEngine()
    ) {
        self.defaults = defaults
        self.engine = engine
        self.plan = Self.load(FacialTrainingPlan.self, key: Keys.plan, defaults: defaults)
        self.progress = Self.load([ProgressSnapshot].self, key: Keys.progress, defaults: defaults) ?? []
        self.feedbackHistory = Self.load([SessionFeedback].self, key: Keys.feedback, defaults: defaults) ?? []
    }

    var hasGeneratedPlan: Bool {
        plan != nil
    }

    var todayRoutine: FacialRoutine? {
        guard let plan else {
            return nil
        }
        return engine.routineForToday(plan: plan, progress: progress)
    }

    var currentWeek: TrainingWeek? {
        guard let routine = todayRoutine, let plan else {
            return plan?.weeks.first
        }
        return plan.weeks.first(where: { $0.weekIndex == routine.weekIndex })
    }

    var completionProgress: Double {
        guard let plan else {
            return 0
        }
        let totalTarget = plan.weeks.reduce(0) { $0 + $1.targetSessions }
        guard totalTarget > 0 else {
            return 0
        }
        return min(Double(progress.count) / Double(totalTarget), 1)
    }

    var hasCompletedToday: Bool {
        engine.hasCompletedToday(progress)
    }

    var currentStreak: Int {
        engine.currentStreak(from: progress)
    }

    var latestReadinessScore: Double {
        progress.sorted { $0.date > $1.date }.first?.readinessScore ?? 0.78
    }

    func nextRoutine(after routine: FacialRoutine) -> FacialRoutine? {
        guard let plan else {
            return nil
        }

        let flattened = plan.weeks.flatMap(\.routines)
        guard let index = flattened.firstIndex(where: { $0.id == routine.id }) else {
            return todayRoutine
        }

        let nextIndex = flattened.index(after: index)
        guard flattened.indices.contains(nextIndex) else {
            return flattened.first
        }

        return flattened[nextIndex]
    }

    func applyAuthenticatedUserID(_ userID: String?) async {
        authenticatedUserID = userID
        guard let userID, !userID.isEmpty else {
            syncState = .local
            return
        }

        syncState = .syncing
        do {
            if let remote = try await FacialTrainingFirebaseSync.load(userID: userID) {
                mergeRemote(remote)
                syncState = .synced
            } else {
                try await syncToFirebase()
                syncState = .synced
            }
        } catch {
            syncState = .failed(error.localizedDescription)
        }
    }

    func generateInitialPlan(profile: UserTrainingGoals) {
        plan = engine.generatePlan(profile: sanitized(profile))
        progress = []
        feedbackHistory = []
        persistAll()
        Task { await syncAfterMutation() }
    }

    func regeneratePlan(using profile: UserTrainingGoals? = nil) {
        let source = profile ?? plan?.profile ?? .empty
        plan = engine.generatePlan(profile: sanitized(source))
        persistPlan()
        Task { await syncAfterMutation() }
    }

    func recordCompletion(routine: FacialRoutine, feedback: SessionFeedback) {
        feedbackHistory.removeAll { $0.routineID == routine.id }
        feedbackHistory.insert(feedback, at: 0)
        feedbackHistory = Array(feedbackHistory.prefix(90))

        if let currentPlan = plan {
            plan = engine.adaptedPlan(
                plan: currentPlan,
                latestFeedback: feedback,
                feedbackHistory: feedbackHistory,
                progress: progress
            )
        }

        progress.removeAll { Calendar.current.isDate($0.date, inSameDayAs: .now) }
        progress.insert(engine.completionSnapshot(for: routine, feedback: feedback, recentProgress: progress), at: 0)
        progress = Array(progress.prefix(180))

        persistAll()
        Task { await syncAfterMutation() }
    }

    func resetPlan() {
        plan = nil
        progress = []
        feedbackHistory = []
        defaults.removeObject(forKey: Keys.plan)
        defaults.removeObject(forKey: Keys.progress)
        defaults.removeObject(forKey: Keys.feedback)
        Task { await syncAfterMutation() }
    }

    private func sanitized(_ profile: UserTrainingGoals) -> UserTrainingGoals {
        var sanitized = profile
        sanitized.age = profile.age.clamped(to: 13...85)
        sanitized.availableDailyMinutes = profile.availableDailyMinutes.clamped(to: 10...15)
        if sanitized.goals.isEmpty {
            sanitized.goals = [.sharperJawline, .betterPosture]
        }
        if sanitized.equipment.isEmpty {
            sanitized.equipment = [.none]
        }
        return sanitized
    }

    private func mergeRemote(_ remote: FacialTrainingRemoteSnapshot) {
        let remoteProgressIsNewer = (remote.progress.first?.date ?? .distantPast) > (progress.first?.date ?? .distantPast)
        let remotePlanIsNewer = (remote.plan?.lastUpdatedAt ?? .distantPast) > (plan?.lastUpdatedAt ?? .distantPast)

        if remotePlanIsNewer || plan == nil {
            plan = remote.plan
        }

        if remoteProgressIsNewer || progress.isEmpty {
            progress = remote.progress
        }

        if feedbackHistory.isEmpty || (remote.feedback.first?.date ?? .distantPast) > (feedbackHistory.first?.date ?? .distantPast) {
            feedbackHistory = remote.feedback
        }

        persistAll()
    }

    private func syncAfterMutation() async {
        guard authenticatedUserID != nil else {
            syncState = .local
            return
        }

        syncState = .syncing
        do {
            try await syncToFirebase()
            syncState = .synced
        } catch {
            syncState = .failed(error.localizedDescription)
        }
    }

    private func syncToFirebase() async throws {
        guard let authenticatedUserID else {
            return
        }

        try await FacialTrainingFirebaseSync.save(
            FacialTrainingRemoteSnapshot(
                plan: plan,
                progress: progress,
                feedback: feedbackHistory
            ),
            userID: authenticatedUserID
        )
    }

    private func persistAll() {
        persistPlan()
        persistProgress()
        persistFeedback()
    }

    private func persistPlan() {
        Self.save(plan, key: Keys.plan, defaults: defaults)
    }

    private func persistProgress() {
        Self.save(progress, key: Keys.progress, defaults: defaults)
    }

    private func persistFeedback() {
        Self.save(feedbackHistory, key: Keys.feedback, defaults: defaults)
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String, defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }

        return try? JSONDecoder().decode(type, from: data)
    }

    private static func save<T: Encodable>(_ value: T?, key: String, defaults: UserDefaults) {
        guard let value else {
            defaults.removeObject(forKey: key)
            return
        }

        guard let data = try? JSONEncoder().encode(value) else {
            return
        }

        defaults.set(data, forKey: key)
    }
}

enum FacialTrainingSyncState: Equatable {
    case local
    case syncing
    case synced
    case failed(String)

    var title: String {
        switch self {
        case .local:
            "Offline ready"
        case .syncing:
            "Syncing"
        case .synced:
            "Synced"
        case .failed:
            "Local saved"
        }
    }
}

struct FacialTrainingRemoteSnapshot: Codable {
    let plan: FacialTrainingPlan?
    let progress: [ProgressSnapshot]
    let feedback: [SessionFeedback]
}

enum FacialTrainingFirebaseSync {
    static func save(_ snapshot: FacialTrainingRemoteSnapshot, userID: String) async throws {
        #if canImport(FirebaseFirestore)
        let reference = Firestore.firestore()
            .collection("Users")
            .document(userID)
            .collection("FacialTraining")
            .document("current")

        var payload = try dictionary(from: snapshot)
        payload["updatedAt"] = Date().timeIntervalSince1970
        try await setData(payload, on: reference)
        #else
        let _ = snapshot
        let _ = userID
        #endif
    }

    static func load(userID: String) async throws -> FacialTrainingRemoteSnapshot? {
        #if canImport(FirebaseFirestore)
        let reference = Firestore.firestore()
            .collection("Users")
            .document(userID)
            .collection("FacialTraining")
            .document("current")

        let data = try await getData(from: reference)
        guard data.isEmpty == false else {
            return nil
        }
        return try decode(FacialTrainingRemoteSnapshot.self, from: data)
        #else
        let _ = userID
        return nil
        #endif
    }

    private static func dictionary<T: Encodable>(from value: T) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        let object = try JSONSerialization.jsonObject(with: data)
        return object as? [String: Any] ?? [:]
    }

    private static func decode<T: Decodable>(_ type: T.Type, from dictionary: [String: Any]) throws -> T {
        var scrubbed = dictionary
        scrubbed.removeValue(forKey: "updatedAt")
        let data = try JSONSerialization.data(withJSONObject: scrubbed)
        return try JSONDecoder().decode(type, from: data)
    }

    #if canImport(FirebaseFirestore)
    private static func setData(_ data: [String: Any], on reference: DocumentReference) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reference.setData(data, merge: true) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private static func getData(from reference: DocumentReference) async throws -> [String: Any] {
        try await withCheckedThrowingContinuation { continuation in
            reference.getDocument { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: snapshot?.data() ?? [:])
            }
        }
    }
    #endif
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
