//
//  AppModel.swift
//  AIscend
//
//  Created by Codex on 4/7/26.
//

import Foundation
import Observation

enum AnalysisGoal: String, CaseIterable, Codable, Identifiable, Hashable {
    case jawline
    case skin
    case eyes
    case hair
    case symmetry
    case overallAttractiveness

    var id: String { rawValue }

    var title: String {
        switch self {
        case .jawline:
            "Jawline"
        case .skin:
            "Skin"
        case .eyes:
            "Eyes"
        case .hair:
            "Hair"
        case .symmetry:
            "Symmetry"
        case .overallAttractiveness:
            "Overall attractiveness"
        }
    }

    var shortTitle: String {
        switch self {
        case .jawline:
            "Jawline"
        case .skin:
            "Skin"
        case .eyes:
            "Eyes"
        case .hair:
            "Hair"
        case .symmetry:
            "Symmetry"
        case .overallAttractiveness:
            "Attractiveness"
        }
    }

    var subtitle: String {
        switch self {
        case .jawline:
            "Define lower-face structure and profile strength."
        case .skin:
            "Improve texture, clarity, and overall finish."
        case .eyes:
            "Sharpen presence and reduce a tired read."
        case .hair:
            "Upgrade framing, density perception, and shape."
        case .symmetry:
            "Balance the overall facial read."
        case .overallAttractiveness:
            "Lift first impression across the full face."
        }
    }

    var symbol: String {
        switch self {
        case .jawline:
            "triangle.bottomhalf.filled"
        case .skin:
            "sparkles"
        case .eyes:
            "eye.fill"
        case .hair:
            "scissors"
        case .symmetry:
            "square.split.diagonal.2x2"
        case .overallAttractiveness:
            "crown.fill"
        }
    }

    static let defaultSelection: [AnalysisGoal] = []
}

enum FocusTrack: String, CaseIterable, Codable, Identifiable {
    case momentum
    case mastery
    case balance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .momentum:
            "Momentum"
        case .mastery:
            "Mastery"
        case .balance:
            "Balance"
        }
    }

    var subtitle: String {
        switch self {
        case .momentum:
            "Bias toward visible wins and steady forward motion."
        case .mastery:
            "Protect long focus blocks so quality compounds."
        case .balance:
            "Lower noise, keep calm, and make the day feel lighter."
        }
    }

    var symbol: String {
        switch self {
        case .momentum:
            "bolt.fill"
        case .mastery:
            "scope"
        case .balance:
            "wind"
        }
    }

    var routinePrompt: String {
        switch self {
        case .momentum:
            "Turn early energy into a visible shipping streak."
        case .mastery:
            "Give your hardest problem the quiet room it deserves."
        case .balance:
            "Choose the one move that makes the rest of the day easier."
        }
    }

    var blockTitle: String {
        switch self {
        case .momentum:
            "Ship the next visible win"
        case .mastery:
            "Protect a ninety-minute craft block"
        case .balance:
            "Reduce friction before you add more effort"
        }
    }

    var blockDetail: String {
        switch self {
        case .momentum:
            "Prioritize progress you can point to by lunch."
        case .mastery:
            "Silence distractions and stay with one meaningful challenge."
        case .balance:
            "Handle the task that will quiet the most background stress."
        }
    }
}

enum HabitAnchor: String, CaseIterable, Codable, Identifiable {
    case movement
    case planning
    case learning
    case reflection

    var id: String { rawValue }

    var title: String {
        switch self {
        case .movement:
            "Movement"
        case .planning:
            "Planning"
        case .learning:
            "Learning"
        case .reflection:
            "Reflection"
        }
    }

    var symbol: String {
        switch self {
        case .movement:
            "figure.walk"
        case .planning:
            "list.bullet.clipboard"
        case .learning:
            "book.fill"
        case .reflection:
            "sparkles.rectangle.stack"
        }
    }

    var detail: String {
        switch self {
        case .movement:
            "Use a quick stretch or walk to wake up your attention."
        case .planning:
            "Name your top outcome before the day fills itself for you."
        case .learning:
            "Keep one pocket of curiosity in the routine, even on busy days."
        case .reflection:
            "Close the loop with a two-minute note on what worked."
        }
    }
}

enum RoutineAccent: String, Codable, Hashable, Sendable {
    case dawn
    case sky
    case mint
}

struct RoutineProfile: Codable, Equatable {
    var name: String = ""
    var intention: String = "Move with clarity and make today's climb count."
    var wakeUpHour: Int = 7
    var wakeUpMinute: Int = 0
    var focusTrack: FocusTrack = .momentum
    var anchors: [HabitAnchor] = [.movement, .reflection]
    var avatarRelativePath: String?

    private static let wakeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Climber" : trimmed
    }

    var wakeDate: Date {
        Calendar.current.date(
            from: DateComponents(
                calendar: .current,
                hour: wakeUpHour,
                minute: wakeUpMinute
            )
        ) ?? .now
    }

    var wakeLabel: String {
        RoutineProfile.wakeFormatter.string(from: wakeDate)
    }

    var anchorSummary: String {
        guard !anchors.isEmpty else {
            return "Choose at least one steady habit anchor."
        }

        return anchors.map(\.title).joined(separator: " + ")
    }
}

struct RoutineTrackerState: Codable, Equatable {
    var waterIntake: Int = 0
    var waterGoal: Int = 8
    var electrolyteIntake: Int = 0
    var electrolyteGoal: Int = 1
    var caloriesLogged: Int = 0
    var calorieGoal: Int = 2200
    var exerciseMinutes: Int = 0
    var exerciseGoalMinutes: Int = 45

    private enum CodingKeys: String, CodingKey {
        case waterIntake
        case waterGoal
        case electrolyteIntake
        case electrolyteGoal
        case caloriesLogged
        case calorieGoal
        case exerciseMinutes
        case exerciseGoalMinutes
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        waterIntake = try container.decodeIfPresent(Int.self, forKey: .waterIntake) ?? 0
        waterGoal = try container.decodeIfPresent(Int.self, forKey: .waterGoal) ?? 8
        electrolyteIntake = try container.decodeIfPresent(Int.self, forKey: .electrolyteIntake) ?? 0
        electrolyteGoal = try container.decodeIfPresent(Int.self, forKey: .electrolyteGoal) ?? 1
        caloriesLogged = try container.decodeIfPresent(Int.self, forKey: .caloriesLogged) ?? 0
        calorieGoal = try container.decodeIfPresent(Int.self, forKey: .calorieGoal) ?? 2200
        exerciseMinutes = try container.decodeIfPresent(Int.self, forKey: .exerciseMinutes) ?? 0
        exerciseGoalMinutes = try container.decodeIfPresent(Int.self, forKey: .exerciseGoalMinutes) ?? 45
    }
}

struct HabitStreakSummary: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let accent: RoutineAccent
    let currentStreak: Int
    let isCompletedToday: Bool
    let progressLabel: String?
}

struct RoutineStep: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let accent: RoutineAccent
    let isComplete: Bool
}

struct RoutineSection: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let accent: RoutineAccent
    let steps: [RoutineStep]
}

@MainActor
@Observable
final class AppModel {
    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let routineProfile = "routineProfile"
        static let completedStepIDs = "completedStepIDs"
        static let routineXP = "routineXP"
        static let trackerState = "trackerState"
        static let habitHistory = "habitHistory"
        static let lastRoutineDay = "lastRoutineDay"
    }

    private enum GlobalKeys {
        static let hasCompletedEntryOnboarding = "hasCompletedEntryOnboarding"
        static let analysisGoals = "analysisGoals"
    }

    private let defaults: UserDefaults
    private var storageNamespace: String
    private var isRestoringPersistedState = false
    private var habitHistoryByDay: [String: [String]] = [:] {
        didSet {
            guard !isRestoringPersistedState else {
                return
            }

            persistHabitHistory()
        }
    }
    private var lastRoutineDay: String = DailyCheckInStore.ymd(for: .now) {
        didSet {
            guard !isRestoringPersistedState else {
                return
            }

            defaults.set(lastRoutineDay, forKey: namespacedKey(Keys.lastRoutineDay))
        }
    }

    var hasCompletedEntryOnboarding: Bool {
        didSet {
            guard !isRestoringPersistedState else {
                return
            }

            defaults.set(hasCompletedEntryOnboarding, forKey: GlobalKeys.hasCompletedEntryOnboarding)
        }
    }

    var analysisGoals: [AnalysisGoal] {
        didSet {
            guard !isRestoringPersistedState else {
                return
            }

            persistAnalysisGoals()
        }
    }

    var hasCompletedOnboarding: Bool {
        didSet {
            guard !isRestoringPersistedState else {
                return
            }

            defaults.set(hasCompletedOnboarding, forKey: namespacedKey(Keys.hasCompletedOnboarding))
        }
    }

    var profile: RoutineProfile {
        didSet {
            guard !isRestoringPersistedState else {
                return
            }

            persistProfile()
        }
    }

    var completedStepIDs: Set<String> = [] {
        didSet {
            guard !isRestoringPersistedState else {
                return
            }

            persistCompletedStepIDs()
        }
    }

    var routineXP: Int = 0 {
        didSet {
            guard !isRestoringPersistedState else {
                return
            }

            defaults.set(routineXP, forKey: namespacedKey(Keys.routineXP))
        }
    }

    var trackerState: RoutineTrackerState {
        didSet {
            guard !isRestoringPersistedState else {
                return
            }

            persistTrackerState()
        }
    }

    var profileAvatarURL: URL? {
        guard let relativePath = profile.avatarRelativePath else {
            return nil
        }

        let url = avatarStorageDirectory.appendingPathComponent(relativePath, isDirectory: false)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    init(
        defaults: UserDefaults = .standard,
        arguments: [String] = ProcessInfo.processInfo.arguments,
        userID: String? = nil
    ) {
        self.defaults = defaults
        let initialNamespace = Self.namespace(for: userID)
        storageNamespace = initialNamespace

        if arguments.contains("--uitest-reset-onboarding") {
            defaults.removeObject(forKey: GlobalKeys.hasCompletedEntryOnboarding)
            defaults.removeObject(forKey: GlobalKeys.analysisGoals)
            defaults.removeObject(forKey: Keys.hasCompletedOnboarding)
            defaults.removeObject(forKey: Keys.routineProfile)
            defaults.removeObject(forKey: Keys.trackerState)
            defaults.removeObject(forKey: Self.namespacedKey(Keys.hasCompletedOnboarding, namespace: initialNamespace))
            defaults.removeObject(forKey: Self.namespacedKey(Keys.routineProfile, namespace: initialNamespace))
            defaults.removeObject(forKey: Self.namespacedKey(Keys.trackerState, namespace: initialNamespace))
        }

        hasCompletedEntryOnboarding = false
        analysisGoals = AnalysisGoal.defaultSelection
        hasCompletedOnboarding = false
        profile = RoutineProfile()
        trackerState = RoutineTrackerState()
        restoreGlobalState()
        restorePersistedState()

        if arguments.contains("--uitest-complete-entry-onboarding") {
            hasCompletedEntryOnboarding = true
        }

        if arguments.contains("--uitest-complete-onboarding") {
            hasCompletedEntryOnboarding = true
            hasCompletedOnboarding = true
        }
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<18:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }

    var progress: Double {
        let totalSteps = routineSections.reduce(0) { $0 + $1.steps.count }
        guard totalSteps > 0 else {
            return 0
        }

        let completedSteps = routineSections.reduce(0) { partialResult, section in
            partialResult + section.steps.filter(\.isComplete).count
        }
        return Double(completedSteps) / Double(totalSteps)
    }

    var progressLabel: String {
        "\(Int(progress * 100))%"
    }

    var completedRoutineCount: Int {
        routineSections.reduce(0) { partialResult, section in
            partialResult + section.steps.filter(\.isComplete).count
        }
    }

    var totalRoutineCount: Int {
        routineSections.reduce(0) { $0 + $1.steps.count }
    }

    var routineLevel: Int {
        max(1, (routineXP / 120) + 1)
    }

    var xpIntoCurrentLevel: Int {
        routineXP % 120
    }

    var xpRequiredForNextLevel: Int {
        120
    }

    var xpProgress: Double {
        Double(xpIntoCurrentLevel) / Double(xpRequiredForNextLevel)
    }

    var currentLevelTitle: String {
        switch routineLevel {
        case 1...2:
            "Foundation"
        case 3...4:
            "Momentum"
        case 5...6:
            "Locked In"
        default:
            "Mastery"
        }
    }

    var trackerCompletionCount: Int {
        [
            trackerState.waterIntake >= trackerState.waterGoal,
            trackerState.electrolyteIntake >= trackerState.electrolyteGoal
        ]
        .filter { $0 }
        .count
    }

    var habitStreakSummaries: [HabitStreakSummary] {
        let routineHabitSummaries = routineSections
            .flatMap(\.steps)
            .map { step in
                HabitStreakSummary(
                    id: step.id,
                    title: step.title,
                    detail: step.isComplete ? "Completed today" : step.detail,
                    symbol: step.symbol,
                    accent: step.accent,
                    currentStreak: habitStreak(for: step.id),
                    isCompletedToday: step.isComplete,
                    progressLabel: nil
                )
            }

        let hydrationSummaries = [
            HabitStreakSummary(
                id: Self.waterHabitID,
                title: "Water",
                detail: trackerState.waterIntake >= trackerState.waterGoal ? "Goal hit today" : "Keep hydration moving",
                symbol: "drop.fill",
                accent: .mint,
                currentStreak: habitStreak(for: Self.waterHabitID),
                isCompletedToday: didCompleteHabitToday(Self.waterHabitID),
                progressLabel: "\(trackerState.waterIntake)/\(trackerState.waterGoal) cups"
            ),
            HabitStreakSummary(
                id: Self.electrolyteHabitID,
                title: "Electrolytes",
                detail: trackerState.electrolyteIntake >= trackerState.electrolyteGoal ? "Goal hit today" : "Add your electrolyte check-in",
                symbol: "bolt.heart.fill",
                accent: .dawn,
                currentStreak: habitStreak(for: Self.electrolyteHabitID),
                isCompletedToday: didCompleteHabitToday(Self.electrolyteHabitID),
                progressLabel: "\(trackerState.electrolyteIntake)/\(trackerState.electrolyteGoal) servings"
            )
        ]

        return routineHabitSummaries + hydrationSummaries
    }

    var dailyRoutineSections: [RoutineSection] {
        routineSections
    }

    var nextOpenStep: RoutineStep? {
        routineSections
            .flatMap(\.steps)
            .first(where: { !$0.isComplete })
    }

    var analysisGoalSummary: String {
        let titles = analysisGoals.map(\.shortTitle)
        guard !titles.isEmpty else {
            return "Clarity"
        }

        if titles.count == 1 {
            return titles[0]
        }

        if titles.count == 2 {
            return "\(titles[0]) + \(titles[1])"
        }

        return "\(titles[0]) + \(titles[1]) + \(titles.count - 2) more"
    }

    var routineSections: [RoutineSection] {
        let primaryAnchor = profile.anchors.first ?? .movement
        let secondaryAnchor = profile.anchors.dropFirst().first ?? .reflection

        return [
            RoutineSection(
                id: "launch",
                title: "Launch window",
                subtitle: "Start with intention before the world starts pulling on you.",
                accent: .dawn,
                steps: [
                    step(
                        id: "mission",
                        title: "Read your climb statement",
                        detail: profile.intention,
                        symbol: "sun.horizon.fill",
                        accent: .dawn
                    ),
                    step(
                        id: "pace",
                        title: "Set your lift-off pace",
                        detail: "Aim to be fully up by \(profile.wakeLabel) and guard the first twenty minutes for yourself.",
                        symbol: "clock.fill",
                        accent: .dawn
                    )
                ]
            ),
            RoutineSection(
                id: "focus",
                title: "Focus block",
                subtitle: profile.focusTrack.routinePrompt,
                accent: .sky,
                steps: [
                    step(
                        id: "deep-work",
                        title: profile.focusTrack.blockTitle,
                        detail: profile.focusTrack.blockDetail,
                        symbol: profile.focusTrack.symbol,
                        accent: .sky
                    ),
                    step(
                        id: "noise-down",
                        title: "Drop the background noise",
                        detail: "Silence one distraction source before you open your main work.",
                        symbol: "bell.slash.fill",
                        accent: .sky
                    )
                ]
            ),
            RoutineSection(
                id: "anchors",
                title: "Reset and close",
                subtitle: "Keep the climb sustainable so tomorrow starts higher.",
                accent: .mint,
                steps: [
                    step(
                        id: "primary-anchor",
                        title: "\(primaryAnchor.title) anchor",
                        detail: primaryAnchor.detail,
                        symbol: primaryAnchor.symbol,
                        accent: .mint
                    ),
                    step(
                        id: "secondary-anchor",
                        title: "\(secondaryAnchor.title) close-out",
                        detail: secondaryAnchor.detail,
                        symbol: secondaryAnchor.symbol,
                        accent: .mint
                    )
                ]
            )
        ]
    }

    func toggleAnchor(_ anchor: HabitAnchor) {
        if let index = profile.anchors.firstIndex(of: anchor) {
            if profile.anchors.count > 1 {
                profile.anchors.remove(at: index)
            }
        } else {
            profile.anchors.append(anchor)
        }
    }

    func toggleAnalysisGoal(_ goal: AnalysisGoal) {
        if let index = analysisGoals.firstIndex(of: goal) {
            analysisGoals.remove(at: index)
        } else {
            analysisGoals.append(goal)
            analysisGoals.sort { lhs, rhs in
                let lhsIndex = AnalysisGoal.allCases.firstIndex(of: lhs) ?? 0
                let rhsIndex = AnalysisGoal.allCases.firstIndex(of: rhs) ?? 0
                return lhsIndex < rhsIndex
            }
        }
    }

    func toggleStep(_ stepID: String) {
        refreshForCurrentDate()

        if completedStepIDs.contains(stepID) {
            completedStepIDs.remove(stepID)
            updateHabitHistory(for: stepID, isCompleted: false)
        } else {
            completedStepIDs.insert(stepID)
            routineXP += xpReward(for: stepID)
            updateHabitHistory(for: stepID, isCompleted: true)
        }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        completedStepIDs.removeAll()
    }

    func completeOnboardingExperience() {
        hasCompletedEntryOnboarding = true
        completeOnboarding()
    }

    func completeEntryOnboarding() {
        hasCompletedEntryOnboarding = true
    }

    func applyAuthenticatedUserID(_ userID: String?) {
        let newNamespace = Self.namespace(for: userID)
        guard newNamespace != storageNamespace else {
            return
        }

        migrateLegacyStateIfNeeded(to: userID)
        storageNamespace = newNamespace
        completedStepIDs.removeAll()
        restorePersistedState()
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        hasCompletedEntryOnboarding = false
        completedStepIDs.removeAll()
    }

    func resetEntryOnboarding() {
        hasCompletedEntryOnboarding = false
    }

    func resetRoutineProgress() {
        completedStepIDs.removeAll()
    }

    func clearLocalAccountData() {
        removeProfileAvatar()

        [
            Keys.hasCompletedOnboarding,
            Keys.routineProfile,
            Keys.completedStepIDs,
            Keys.routineXP,
            Keys.trackerState,
            Keys.habitHistory,
            Keys.lastRoutineDay
        ].forEach { key in
            defaults.removeObject(forKey: namespacedKey(key))
        }

        isRestoringPersistedState = true
        hasCompletedOnboarding = false
        profile = RoutineProfile()
        completedStepIDs = []
        routineXP = 0
        trackerState = RoutineTrackerState()
        habitHistoryByDay = [:]
        lastRoutineDay = DailyCheckInStore.ymd(for: .now)
        isRestoringPersistedState = false
    }

    func adjustWaterIntake(by amount: Int) {
        refreshForCurrentDate()
        trackerState.waterIntake = max(0, trackerState.waterIntake + amount)
        syncTrackerHabitHistory()
    }

    func adjustElectrolyteIntake(by amount: Int) {
        refreshForCurrentDate()
        trackerState.electrolyteIntake = max(0, trackerState.electrolyteIntake + amount)
        syncTrackerHabitHistory()
    }

    func adjustCalories(by amount: Int) {
        refreshForCurrentDate()
        trackerState.caloriesLogged = max(0, trackerState.caloriesLogged + amount)
    }

    func adjustExerciseMinutes(by amount: Int) {
        refreshForCurrentDate()
        trackerState.exerciseMinutes = max(0, trackerState.exerciseMinutes + amount)
    }

    func refreshForCurrentDate(now: Date = .now) {
        let todayKey = DailyCheckInStore.ymd(for: now)
        guard lastRoutineDay != todayKey else {
            return
        }

        completedStepIDs.removeAll()
        trackerState.waterIntake = 0
        trackerState.electrolyteIntake = 0
        trackerState.caloriesLogged = 0
        trackerState.exerciseMinutes = 0
        lastRoutineDay = todayKey
    }

    func habitStreak(for habitID: String, now: Date = .now) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        var streak = 0

        for offset in 0..<366 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
                break
            }

            let key = DailyCheckInStore.ymd(for: date)
            let didComplete = habitHistoryByDay[key]?.contains(habitID) == true

            if didComplete {
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

    func didCompleteHabitToday(_ habitID: String, now: Date = .now) -> Bool {
        let todayKey = DailyCheckInStore.ymd(for: now)
        return habitHistoryByDay[todayKey]?.contains(habitID) == true
    }

    private func step(
        id: String,
        title: String,
        detail: String,
        symbol: String,
        accent: RoutineAccent
    ) -> RoutineStep {
        RoutineStep(
            id: id,
            title: title,
            detail: detail,
            symbol: symbol,
            accent: accent,
            isComplete: completedStepIDs.contains(id)
        )
    }

    private func persistProfile() {
        guard let data = try? JSONEncoder().encode(profile) else {
            return
        }

        defaults.set(data, forKey: namespacedKey(Keys.routineProfile))
    }

    private func persistTrackerState() {
        guard let data = try? JSONEncoder().encode(trackerState) else {
            return
        }

        defaults.set(data, forKey: namespacedKey(Keys.trackerState))
    }

    private func persistHabitHistory() {
        guard let data = try? JSONEncoder().encode(habitHistoryByDay) else {
            return
        }

        defaults.set(data, forKey: namespacedKey(Keys.habitHistory))
    }

    private func persistCompletedStepIDs() {
        guard let data = try? JSONEncoder().encode(Array(completedStepIDs).sorted()) else {
            return
        }

        defaults.set(data, forKey: namespacedKey(Keys.completedStepIDs))
    }

    func saveProfileAvatar(data: Data, fileExtension: String = "jpg") throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(
            at: avatarStorageDirectory,
            withIntermediateDirectories: true
        )

        if let existingRelativePath = profile.avatarRelativePath {
            let existingURL = avatarStorageDirectory.appendingPathComponent(existingRelativePath, isDirectory: false)
            try? fileManager.removeItem(at: existingURL)
        }

        let filename = "avatar-\(storageNamespace).\(fileExtension)"
        let destinationURL = avatarStorageDirectory.appendingPathComponent(filename, isDirectory: false)
        try data.write(to: destinationURL, options: .atomic)
        profile.avatarRelativePath = filename
    }

    func removeProfileAvatar() {
        guard let existingRelativePath = profile.avatarRelativePath else {
            return
        }

        let existingURL = avatarStorageDirectory.appendingPathComponent(existingRelativePath, isDirectory: false)
        try? FileManager.default.removeItem(at: existingURL)
        profile.avatarRelativePath = nil
    }

    private func persistAnalysisGoals() {
        guard let data = try? JSONEncoder().encode(analysisGoals) else {
            return
        }

        defaults.set(data, forKey: GlobalKeys.analysisGoals)
    }

    private func restoreGlobalState() {
        isRestoringPersistedState = true
        defer { isRestoringPersistedState = false }

        if defaults.object(forKey: GlobalKeys.hasCompletedEntryOnboarding) != nil {
            hasCompletedEntryOnboarding = defaults.bool(forKey: GlobalKeys.hasCompletedEntryOnboarding)
        } else {
            hasCompletedEntryOnboarding = false
        }

        if
            let data = defaults.data(forKey: GlobalKeys.analysisGoals),
            let decoded = try? JSONDecoder().decode([AnalysisGoal].self, from: data)
        {
            analysisGoals = decoded
        } else {
            analysisGoals = AnalysisGoal.defaultSelection
        }
    }

    private func restorePersistedState() {
        isRestoringPersistedState = true
        defer { isRestoringPersistedState = false }

        let onboardingKey = namespacedKey(Keys.hasCompletedOnboarding)
        if defaults.object(forKey: onboardingKey) != nil {
            hasCompletedOnboarding = defaults.bool(forKey: onboardingKey)
        } else {
            hasCompletedOnboarding = false
        }

        let routineKey = namespacedKey(Keys.routineProfile)
        if
            let data = defaults.data(forKey: routineKey),
            let decoded = try? JSONDecoder().decode(RoutineProfile.self, from: data)
        {
            profile = decoded
        } else {
            profile = RoutineProfile()
        }

        let completedKey = namespacedKey(Keys.completedStepIDs)
        if
            let data = defaults.data(forKey: completedKey),
            let decoded = try? JSONDecoder().decode([String].self, from: data)
        {
            completedStepIDs = Set(decoded)
        } else {
            completedStepIDs = []
        }

        let xpKey = namespacedKey(Keys.routineXP)
        if defaults.object(forKey: xpKey) != nil {
            routineXP = defaults.integer(forKey: xpKey)
        } else {
            routineXP = 0
        }

        let trackerKey = namespacedKey(Keys.trackerState)
        if
            let data = defaults.data(forKey: trackerKey),
            let decoded = try? JSONDecoder().decode(RoutineTrackerState.self, from: data)
        {
            trackerState = decoded
        } else {
            trackerState = RoutineTrackerState()
        }

        let habitHistoryKey = namespacedKey(Keys.habitHistory)
        if
            let data = defaults.data(forKey: habitHistoryKey),
            let decoded = try? JSONDecoder().decode([String: [String]].self, from: data)
        {
            habitHistoryByDay = decoded
        } else {
            habitHistoryByDay = [:]
        }

        let lastRoutineDayKey = namespacedKey(Keys.lastRoutineDay)
        if let savedDay = defaults.string(forKey: lastRoutineDayKey) {
            lastRoutineDay = savedDay
        } else {
            lastRoutineDay = DailyCheckInStore.ymd(for: .now)
        }

        refreshForCurrentDate()
        syncTrackerHabitHistory()
    }

    private func migrateLegacyStateIfNeeded(to userID: String?) {
        guard let userID else {
            return
        }

        let destinationNamespace = Self.namespace(for: userID)
        let hasDestinationState =
            defaults.object(forKey: namespacedKey(Keys.hasCompletedOnboarding, namespace: destinationNamespace)) != nil ||
            defaults.data(forKey: namespacedKey(Keys.routineProfile, namespace: destinationNamespace)) != nil ||
            defaults.data(forKey: namespacedKey(Keys.completedStepIDs, namespace: destinationNamespace)) != nil ||
            defaults.object(forKey: namespacedKey(Keys.routineXP, namespace: destinationNamespace)) != nil ||
            defaults.data(forKey: namespacedKey(Keys.trackerState, namespace: destinationNamespace)) != nil ||
            defaults.data(forKey: namespacedKey(Keys.habitHistory, namespace: destinationNamespace)) != nil ||
            defaults.string(forKey: namespacedKey(Keys.lastRoutineDay, namespace: destinationNamespace)) != nil

        guard !hasDestinationState else {
            return
        }

        let guestOnboardingKey = Self.namespacedKey(Keys.hasCompletedOnboarding, namespace: "guest")
        let guestProfileKey = Self.namespacedKey(Keys.routineProfile, namespace: "guest")
        let guestCompletedKey = Self.namespacedKey(Keys.completedStepIDs, namespace: "guest")
        let guestXPKey = Self.namespacedKey(Keys.routineXP, namespace: "guest")
        let guestTrackerKey = Self.namespacedKey(Keys.trackerState, namespace: "guest")
        let guestHabitHistoryKey = Self.namespacedKey(Keys.habitHistory, namespace: "guest")
        let guestLastRoutineDayKey = Self.namespacedKey(Keys.lastRoutineDay, namespace: "guest")

        if let guestOnboarding = defaults.object(forKey: guestOnboardingKey) {
            defaults.set(guestOnboarding, forKey: namespacedKey(Keys.hasCompletedOnboarding, namespace: destinationNamespace))
        } else if let legacyOnboarding = defaults.object(forKey: Keys.hasCompletedOnboarding) {
            defaults.set(legacyOnboarding, forKey: namespacedKey(Keys.hasCompletedOnboarding, namespace: destinationNamespace))
        }

        if let guestProfile = defaults.data(forKey: guestProfileKey) {
            defaults.set(guestProfile, forKey: namespacedKey(Keys.routineProfile, namespace: destinationNamespace))
        } else if let legacyProfile = defaults.data(forKey: Keys.routineProfile) {
            defaults.set(legacyProfile, forKey: namespacedKey(Keys.routineProfile, namespace: destinationNamespace))
        }

        if let guestCompleted = defaults.data(forKey: guestCompletedKey) {
            defaults.set(guestCompleted, forKey: namespacedKey(Keys.completedStepIDs, namespace: destinationNamespace))
        }

        if let guestXP = defaults.object(forKey: guestXPKey) {
            defaults.set(guestXP, forKey: namespacedKey(Keys.routineXP, namespace: destinationNamespace))
        }

        if let guestTracker = defaults.data(forKey: guestTrackerKey) {
            defaults.set(guestTracker, forKey: namespacedKey(Keys.trackerState, namespace: destinationNamespace))
        } else if let legacyTracker = defaults.data(forKey: Keys.trackerState) {
            defaults.set(legacyTracker, forKey: namespacedKey(Keys.trackerState, namespace: destinationNamespace))
        }

        if let guestHabitHistory = defaults.data(forKey: guestHabitHistoryKey) {
            defaults.set(guestHabitHistory, forKey: namespacedKey(Keys.habitHistory, namespace: destinationNamespace))
        }

        if let guestLastRoutineDay = defaults.string(forKey: guestLastRoutineDayKey) {
            defaults.set(guestLastRoutineDay, forKey: namespacedKey(Keys.lastRoutineDay, namespace: destinationNamespace))
        }
    }

    private func xpReward(for stepID: String) -> Int {
        switch stepID {
        case "mission", "pace":
            12
        case "deep-work", "noise-down":
            18
        case "primary-anchor", "secondary-anchor":
            14
        default:
            10
        }
    }

    private func namespacedKey(_ key: String, namespace: String? = nil) -> String {
        Self.namespacedKey(key, namespace: namespace ?? storageNamespace)
    }

    private static func namespace(for userID: String?) -> String {
        guard let userID, !userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "guest"
        }

        return "user.\(userID)"
    }

    private static func namespacedKey(_ key: String, namespace: String) -> String {
        "\(namespace).\(key)"
    }

    private var avatarStorageDirectory: URL {
        defaultsDirectory
            .appendingPathComponent("AIscendProfileAvatars", isDirectory: true)
    }

    private var defaultsDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    }

    private func updateHabitHistory(for habitID: String, isCompleted: Bool, now: Date = .now) {
        let dayKey = DailyCheckInStore.ymd(for: now)
        var completedHabits = Set(habitHistoryByDay[dayKey] ?? [])

        if isCompleted {
            completedHabits.insert(habitID)
        } else {
            completedHabits.remove(habitID)
        }

        if completedHabits.isEmpty {
            habitHistoryByDay.removeValue(forKey: dayKey)
        } else {
            habitHistoryByDay[dayKey] = completedHabits.sorted()
        }
    }

    private func syncTrackerHabitHistory(now: Date = .now) {
        updateHabitHistory(
            for: Self.waterHabitID,
            isCompleted: trackerState.waterIntake >= trackerState.waterGoal,
            now: now
        )
        updateHabitHistory(
            for: Self.electrolyteHabitID,
            isCompleted: trackerState.electrolyteIntake >= trackerState.electrolyteGoal,
            now: now
        )
    }

    private static let waterHabitID = "water"
    private static let electrolyteHabitID = "electrolytes"
}
