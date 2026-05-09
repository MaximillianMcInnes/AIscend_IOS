//
//  RoadmapStore.swift
//  AIscend
//

import Foundation

@MainActor
final class RoadmapStore: ObservableObject {
    @Published private(set) var roadmap: AIScendRoadmap?
    @Published private(set) var scanSignal: RoadmapScanSignal = .unavailable
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var completedActionIDsToday: Set<String> = []

    private let repository: ScanResultsRepositoryProtocol
    private let defaults: UserDefaults
    private let calendar: Calendar
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Keys {
        static let roadmap = "aiscend.roadmap.selected"
        static let progress = "aiscend.roadmap.progress"
    }

    private struct ProgressState: Codable, Equatable {
        var completionsByDay: [String: Set<String>] = [:]
    }

    private var progressState = ProgressState()

    init(
        repository: ScanResultsRepositoryProtocol = ScanResultsRepository(),
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.defaults = defaults
        self.calendar = calendar
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        loadPersistedState()
    }

    func load() async {
        guard !isLoading else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        let archive = await repository.loadPersistedArchive()
        let latestRecord = archive.first(where: \.isDisplayable)
        scanSignal = RoadmapScanAdapter.signal(from: latestRecord)

        if roadmap == nil, scanSignal.hasScan {
            roadmap = Self.buildRoadmap(
                profile: RoadmapBuilderProfile(goal: .scanImprovement),
                scanSignal: scanSignal
            )
            persistRoadmap()
        }

        refreshTodayCompletion()
    }

    func buildRoadmap(profile: RoadmapBuilderProfile) {
        roadmap = Self.buildRoadmap(profile: profile, scanSignal: scanSignal)
        progressState = ProgressState()
        persistRoadmap()
        persistProgress()
        refreshTodayCompletion()
    }

    func toggleAction(_ actionID: String) {
        let key = dayKey(for: .now)
        var daySet = progressState.completionsByDay[key, default: []]

        if daySet.contains(actionID) {
            daySet.remove(actionID)
        } else {
            daySet.insert(actionID)
        }

        progressState.completionsByDay[key] = daySet
        persistProgress()
        refreshTodayCompletion()
    }

    func isActionCompleteToday(_ actionID: String) -> Bool {
        completedActionIDsToday.contains(actionID)
    }

    func progressSnapshot(now: Date = .now) -> RoadmapProgressSnapshot {
        let currentDay = dayNumber(now: now)
        let phaseID = RoadmapPhaseID.allCases.first(where: { $0.dayRange.contains(currentDay) }) ?? .optimisation
        let dailyCount = max(roadmap?.dailyActions.count ?? 0, 1)
        let todayCompletion = Double(completedActionIDsToday.count) / Double(dailyCount)
        let weeklyCompletion = weeklyCompletionRatio(now: now)
        let score = Int((weeklyCompletion * 100).rounded())

        return RoadmapProgressSnapshot(
            currentPhaseID: phaseID,
            currentDay: currentDay,
            todayCompletion: min(max(todayCompletion, 0), 1),
            weeklyCompletion: weeklyCompletion,
            consistencyScore: min(max(score, 0), 100),
            streakDays: streakDays(now: now)
        )
    }

    func phaseProgress(for phase: RoadmapPhase, now: Date = .now) -> Double {
        let currentDay = dayNumber(now: now)
        if currentDay > phase.id.dayRange.upperBound {
            return 1
        }
        if currentDay < phase.id.dayRange.lowerBound {
            return 0
        }

        let elapsed = currentDay - phase.id.dayRange.lowerBound + 1
        let total = phase.id.dayRange.upperBound - phase.id.dayRange.lowerBound + 1
        let timeProgress = Double(elapsed) / Double(total)
        let actionProgress = progressSnapshot(now: now).weeklyCompletion
        return min(max((timeProgress * 0.55) + (actionProgress * 0.45), 0), 1)
    }

    private func loadPersistedState() {
        if let data = defaults.data(forKey: Keys.roadmap),
           let decoded = try? decoder.decode(AIScendRoadmap.self, from: data)
        {
            roadmap = decoded
        }

        if let data = defaults.data(forKey: Keys.progress),
           let decoded = try? decoder.decode(ProgressState.self, from: data)
        {
            progressState = decoded
        }

        refreshTodayCompletion()
    }

    private func persistRoadmap() {
        guard let roadmap,
              let encoded = try? encoder.encode(roadmap)
        else {
            defaults.removeObject(forKey: Keys.roadmap)
            return
        }

        defaults.set(encoded, forKey: Keys.roadmap)
    }

    private func persistProgress() {
        guard let encoded = try? encoder.encode(progressState) else {
            return
        }

        defaults.set(encoded, forKey: Keys.progress)
    }

    private func refreshTodayCompletion() {
        completedActionIDsToday = progressState.completionsByDay[dayKey(for: .now)] ?? []
    }

    private func dayNumber(now: Date) -> Int {
        guard let createdAt = roadmap?.createdAt else {
            return 1
        }

        let start = calendar.startOfDay(for: createdAt)
        let today = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return min(max(days + 1, 1), 90)
    }

    private func weeklyCompletionRatio(now: Date) -> Double {
        guard let roadmap else {
            return 0
        }

        let dailyCount = max(roadmap.dailyActions.count, 1)
        let ratios = (0..<7).compactMap { offset -> Double? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: now) else {
                return nil
            }

            let completed = progressState.completionsByDay[dayKey(for: date)] ?? []
            return min(Double(completed.count) / Double(dailyCount), 1)
        }

        guard !ratios.isEmpty else {
            return 0
        }

        return min(max(ratios.reduce(0, +) / Double(ratios.count), 0), 1)
    }

    private func streakDays(now: Date) -> Int {
        guard let roadmap else {
            return 0
        }

        let dailyCount = max(roadmap.dailyActions.count, 1)
        var count = 0

        for offset in 0..<90 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: now) else {
                break
            }

            let completed = progressState.completionsByDay[dayKey(for: date)] ?? []
            let ratio = Double(completed.count) / Double(dailyCount)
            if ratio >= 0.6 {
                count += 1
            } else if offset == 0, completed.isEmpty {
                continue
            } else {
                break
            }
        }

        return count
    }

    private func dayKey(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}

extension RoadmapStore {
    static func buildRoadmap(
        profile: RoadmapBuilderProfile,
        scanSignal: RoadmapScanSignal
    ) -> AIScendRoadmap {
        let categories = selectedCategories(profile: profile, scanSignal: scanSignal)
        let priorities = categories.prefix(5).map { category in
            priority(for: category, profile: profile, scanSignal: scanSignal)
        }
        let actions = dailyActions(for: priorities.map(\.category), profile: profile)
        let weekly = weeklyActions(for: priorities.map(\.category))
        let focus = overallFocus(profile: profile, scanSignal: scanSignal, categories: categories)

        return AIScendRoadmap(
            id: UUID(),
            createdAt: .now,
            overallFocus: focus,
            sourceSummary: scanSignal.hasScan
                ? scanSignal.sourceSummary
                : "Built from your selected goal and concern. Add a scan later to sharpen the weak-point targeting.",
            priorities: priorities,
            phases: phases(for: priorities.map(\.category), profile: profile),
            dailyActions: actions,
            weeklyActions: weekly,
            builderProfile: profile
        )
    }

    private static func selectedCategories(
        profile: RoadmapBuilderProfile,
        scanSignal: RoadmapScanSignal
    ) -> [RoadmapPriorityCategory] {
        var categories: [RoadmapPriorityCategory] = []

        categories.append(contentsOf: scanSignal.weakCategories)

        switch profile.goal {
        case .sharperPresentation:
            categories.append(contentsOf: [.facialPosture, .styleGrooming, .sleepRecovery])
        case .skinConsistency:
            categories.append(contentsOf: [.skin, .hydration, .sleepRecovery])
        case .groomingUpgrade:
            categories.append(contentsOf: [.hair, .eyebrows, .styleGrooming])
        case .recoveryAndEnergy:
            categories.append(contentsOf: [.sleepRecovery, .hydration, .skin])
        case .scanImprovement:
            categories.append(contentsOf: [.scanSpecificWeakPoint, .skin, .facialPosture])
        }

        switch profile.concern {
        case .tiredLook:
            categories.append(contentsOf: [.sleepRecovery, .hydration, .skin])
        case .skinTexture:
            categories.append(contentsOf: [.skin, .hydration])
        case .hairAndGrooming:
            categories.append(contentsOf: [.hair, .eyebrows, .styleGrooming])
        case .postureProfile:
            categories.append(contentsOf: [.facialPosture, .scanSpecificWeakPoint])
        case .consistency:
            categories.append(contentsOf: [.sleepRecovery, .hydration, .styleGrooming])
        }

        categories.append(contentsOf: [
            .skin,
            .sleepRecovery,
            .hydration,
            .facialPosture,
            .styleGrooming,
            .hair,
            .eyebrows,
            .scanSpecificWeakPoint
        ])

        return deduplicated(categories)
    }

    private static func deduplicated(_ categories: [RoadmapPriorityCategory]) -> [RoadmapPriorityCategory] {
        var seen: Set<RoadmapPriorityCategory> = []
        return categories.filter { category in
            if seen.contains(category) {
                return false
            }
            seen.insert(category)
            return true
        }
    }

    private static func priority(
        for category: RoadmapPriorityCategory,
        profile: RoadmapBuilderProfile,
        scanSignal: RoadmapScanSignal
    ) -> RoadmapPriority {
        let weakPointBoost = scanSignal.weakCategories.contains(category) ? 2 : 0
        let impact = min(10, baseImpact(for: category, profile: profile) + weakPointBoost)
        let difficulty = difficulty(for: category, profile: profile)

        return RoadmapPriority(
            id: category.rawValue,
            category: category,
            title: priorityTitle(for: category, scanSignal: scanSignal),
            reason: priorityReason(for: category, scanSignal: scanSignal),
            impactScore: impact,
            difficultyScore: difficulty,
            timeToVisibleChange: visibleChangeEstimate(for: category),
            dailyActions: dailyCopy(for: category),
            weeklyActions: weeklyCopy(for: category)
        )
    }

    private static func baseImpact(for category: RoadmapPriorityCategory, profile: RoadmapBuilderProfile) -> Int {
        switch (category, profile.goal) {
        case (.skin, .skinConsistency), (.hair, .groomingUpgrade), (.eyebrows, .groomingUpgrade), (.sleepRecovery, .recoveryAndEnergy), (.scanSpecificWeakPoint, .scanImprovement):
            9
        case (.facialPosture, .sharperPresentation), (.styleGrooming, .sharperPresentation):
            8
        default:
            7
        }
    }

    private static func difficulty(for category: RoadmapPriorityCategory, profile: RoadmapBuilderProfile) -> Int {
        let base: Int
        switch category {
        case .hydration, .styleGrooming:
            base = 3
        case .skin, .eyebrows, .sleepRecovery:
            base = 4
        case .hair, .facialPosture:
            base = 5
        case .scanSpecificWeakPoint:
            base = 6
        }

        let modeOffset: Int
        switch profile.consistencyMode {
        case .lowEffort:
            modeOffset = -1
        case .balanced:
            modeOffset = 0
        case .aggressiveConsistency:
            modeOffset = 1
        }

        return min(max(base + modeOffset, 1), 10)
    }

    private static func priorityTitle(
        for category: RoadmapPriorityCategory,
        scanSignal: RoadmapScanSignal
    ) -> String {
        switch category {
        case .skin:
            "Stabilise skin baseline"
        case .hair:
            "Sharper hair control"
        case .eyebrows:
            "Clean brow frame"
        case .facialPosture:
            "Posture and profile discipline"
        case .sleepRecovery:
            "Recovery signal"
        case .hydration:
            "Hydration consistency"
        case .styleGrooming:
            "Presentation polish"
        case .scanSpecificWeakPoint:
            scanSignal.lowestMetricLabel.map { "Target \($0.lowercased()) signal" } ?? "Target scan weak point"
        }
    }

    private static func priorityReason(
        for category: RoadmapPriorityCategory,
        scanSignal: RoadmapScanSignal
    ) -> String {
        switch category {
        case .skin:
            return "A consistent AM/PM baseline can make the face read calmer and more deliberate over time."
        case .hair:
            return "Hair shape and edge control are high-visibility presentation details with low daily friction."
        case .eyebrows:
            return "Small brow grooming changes can improve eye-area framing without changing the face itself."
        case .facialPosture:
            return "Neck position, jaw relaxation, and camera-aware posture can influence how profile and lower-face definition reads."
        case .sleepRecovery:
            return "Sleep and recovery consistency can reduce tired-looking signals and support a fresher scan baseline."
        case .hydration:
            return "Hydration supports skin and recovery routines, especially when paired with sleep and grooming consistency."
        case .styleGrooming:
            return "Clothing fit, neckline, facial hair, and grooming checks can raise the whole presentation read."
        case .scanSpecificWeakPoint:
            if scanSignal.hasScan {
                return "This is based on the lowest available scan signals, handled as directional feedback rather than a fixed verdict."
            }
            return "Once a scan is available, AIScend can sharpen this priority around the weakest measured areas."
        }
    }

    private static func visibleChangeEstimate(for category: RoadmapPriorityCategory) -> String {
        switch category {
        case .hydration, .styleGrooming, .hair:
            "3-14 days"
        case .skin, .eyebrows, .facialPosture:
            "2-6 weeks"
        case .sleepRecovery:
            "1-4 weeks"
        case .scanSpecificWeakPoint:
            "30-90 days"
        }
    }

    private static func dailyCopy(for category: RoadmapPriorityCategory) -> [String] {
        switch category {
        case .skin:
            ["AM cleanse, moisturise, SPF", "PM cleanse and moisturise"]
        case .hair:
            ["2-minute hair shape check"]
        case .eyebrows:
            ["Brush brows into a clean frame"]
        case .facialPosture:
            ["2-minute neck posture reset; stop if pain appears"]
        case .sleepRecovery:
            ["Set a wind-down time and reduce late screen glare"]
        case .hydration:
            ["Front-load water earlier in the day"]
        case .styleGrooming:
            ["Fit, neckline, scent, and grooming check"]
        case .scanSpecificWeakPoint:
            ["Log one weak-point rep after the daily routine"]
        }
    }

    private static func weeklyCopy(for category: RoadmapPriorityCategory) -> [String] {
        switch category {
        case .skin:
            ["Review irritation triggers and simplify if skin feels stressed"]
        case .hair:
            ["Plan trim, neckline, or product adjustment"]
        case .eyebrows:
            ["Tidy obvious strays only; avoid over-shaping"]
        case .facialPosture:
            ["Review side-profile posture in consistent lighting"]
        case .sleepRecovery:
            ["Audit sleep debt and recovery bottlenecks"]
        case .hydration:
            ["Check average water rhythm across the week"]
        case .styleGrooming:
            ["Upgrade one fit or grooming detail"]
        case .scanSpecificWeakPoint:
            ["Compare weekly notes against scan weak points"]
        }
    }

    private static func dailyActions(
        for categories: [RoadmapPriorityCategory],
        profile: RoadmapBuilderProfile
    ) -> [RoadmapAction] {
        let maxCount: Int
        switch profile.dailyTime {
        case .five:
            maxCount = 3
        case .ten:
            maxCount = 5
        case .twenty:
            maxCount = 7
        }

        let actions = categories.flatMap { category -> [RoadmapAction] in
            dailyCopy(for: category).enumerated().map { index, title in
                RoadmapAction(
                    id: "daily-\(category.rawValue)-\(index)",
                    title: title,
                    reason: actionReason(for: category),
                    estimatedMinutes: minutes(for: category, profile: profile),
                    category: category
                )
            }
        }

        return Array(actions.prefix(maxCount))
    }

    private static func weeklyActions(for categories: [RoadmapPriorityCategory]) -> [RoadmapAction] {
        categories.prefix(5).map { category in
            RoadmapAction(
                id: "weekly-\(category.rawValue)",
                title: weeklyCopy(for: category).first ?? "Weekly optimisation review",
                reason: "Keeps the 30/60/90 plan adaptive without overreacting to one day.",
                estimatedMinutes: 10,
                category: category
            )
        }
    }

    private static func actionReason(for category: RoadmapPriorityCategory) -> String {
        switch category {
        case .facialPosture:
            "Keep this gentle. Stop if there is pain, pressure, or discomfort."
        case .skin:
            "General skincare consistency only; adjust if irritation appears."
        default:
            "Small execution detail that supports presentation consistency."
        }
    }

    private static func minutes(for category: RoadmapPriorityCategory, profile: RoadmapBuilderProfile) -> Int {
        switch (category, profile.dailyTime) {
        case (.sleepRecovery, .twenty), (.scanSpecificWeakPoint, .twenty):
            5
        case (.styleGrooming, .five), (.hydration, .five):
            1
        default:
            2
        }
    }

    private static func phases(
        for categories: [RoadmapPriorityCategory],
        profile: RoadmapBuilderProfile
    ) -> [RoadmapPhase] {
        [
            RoadmapPhase(
                id: .foundation,
                focusArea: "Baseline control and friction removal",
                keyActions: [
                    "Lock the smallest daily version of the plan",
                    "Standardise sleep, water, AM/PM grooming, and scan conditions",
                    "Remove any routine step that creates irritation or pain"
                ],
                expectedOutcome: "You may see a cleaner daily baseline and better consistency, especially in skin, recovery, and presentation polish."
            ),
            RoadmapPhase(
                id: .refinement,
                focusArea: "Visible detail refinement",
                keyActions: [
                    "Tune the top two priorities from the first 30 days",
                    "Add weekly grooming and style reviews",
                    "Use posture and photo feedback as directional signal only"
                ],
                expectedOutcome: "The presentation may read more deliberate as grooming, posture, and recovery inputs become more consistent."
            ),
            RoadmapPhase(
                id: .optimisation,
                focusArea: profile.consistencyMode == .aggressiveConsistency ? "High-consistency optimisation" : "Sustainable optimisation",
                keyActions: [
                    "Retake scans under similar conditions",
                    "Compare trend signals instead of reacting to one result",
                    "Keep the best-performing actions and cut low-value friction"
                ],
                expectedOutcome: "AIScend should have clearer comparison data, helping you decide which habits correlate with better scan reads."
            )
        ]
    }

    private static func overallFocus(
        profile: RoadmapBuilderProfile,
        scanSignal: RoadmapScanSignal,
        categories: [RoadmapPriorityCategory]
    ) -> String {
        let first = categories.first?.title.lowercased() ?? "presentation consistency"
        if scanSignal.hasScan {
            return "Prioritise \(first) while tightening grooming, recovery, hydration, and posture inputs across 90 days."
        }

        return "\(profile.goal.title): build a consistent 90-day execution base, then sharpen with scan data when available."
    }
}
