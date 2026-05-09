//
//  JawTrainingStore.swift
//  AIscend
//
//  Created by Codex on 5/7/26.
//

import Foundation

@MainActor
final class JawTrainingStore: ObservableObject {
    private enum Keys {
        static let selectedPlan = "aiscend.jawTraining.selectedPlan"
        static let completions = "aiscend.jawTraining.completions"
    }

    @Published private(set) var selectedPlan: JawTrainingPlan
    @Published private(set) var completions: [JawTrainingCompletion]

    private let defaults: UserDefaults
    private let calendar: Calendar

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar

        if
            let data = defaults.data(forKey: Keys.selectedPlan),
            let plan = try? JSONDecoder().decode(JawTrainingPlan.self, from: data)
        {
            selectedPlan = plan
        } else {
            selectedPlan = JawTrainingPlanLibrary.beginner
        }

        if
            let data = defaults.data(forKey: Keys.completions),
            let savedCompletions = try? JSONDecoder().decode([JawTrainingCompletion].self, from: data)
        {
            completions = savedCompletions.sorted { $0.date > $1.date }
        } else {
            completions = []
        }
    }

    var hasCompletedToday: Bool {
        completions.contains { calendar.isDateInToday($0.date) }
    }

    var currentStreak: Int {
        let completedDays = Set(completions.map { calendar.startOfDay(for: $0.date) })
        guard !completedDays.isEmpty else {
            return 0
        }

        var streak = 0
        var day = calendar.startOfDay(for: .now)

        if !completedDays.contains(day),
           let yesterday = calendar.date(byAdding: .day, value: -1, to: day),
           completedDays.contains(yesterday)
        {
            day = yesterday
        }

        while completedDays.contains(day) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else {
                break
            }
            day = previousDay
        }

        return streak
    }

    var weeklyCompletionCount: Int {
        weeklyProgress.filter(\.isCompleted).count
    }

    var weeklyProgress: [JawWeeklyProgressDay] {
        let today = calendar.startOfDay(for: .now)
        let completedDays = Set(completions.map { calendar.startOfDay(for: $0.date) })
        let formatter = DateFormatter()
        formatter.dateFormat = "E"

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset - 6, to: today) else {
                return nil
            }

            let day = calendar.startOfDay(for: date)
            return JawWeeklyProgressDay(
                id: Self.dayKey(for: day),
                date: day,
                weekday: formatter.string(from: day),
                isCompleted: completedDays.contains(day)
            )
        }
    }

    func selectPlan(_ plan: JawTrainingPlan) {
        selectedPlan = plan
        persistSelectedPlan()
    }

    func saveBuiltPlan(_ plan: JawTrainingPlan) {
        selectedPlan = plan
        persistSelectedPlan()
    }

    func markCompleted(plan: JawTrainingPlan, date: Date = .now) {
        let day = calendar.startOfDay(for: date)
        completions.removeAll { calendar.isDate($0.date, inSameDayAs: day) }
        completions.insert(
            JawTrainingCompletion(
                date: date,
                planID: plan.id,
                planName: plan.name,
                durationMinutes: plan.durationMinutes
            ),
            at: 0
        )
        completions = Array(completions.prefix(180))
        persistCompletions()
    }

    func completionsForCurrentWeek() -> [JawTrainingCompletion] {
        guard
            let interval = calendar.dateInterval(of: .weekOfYear, for: .now)
        else {
            return completions
        }

        return completions.filter { interval.contains($0.date) }
    }

    private func persistSelectedPlan() {
        guard let data = try? JSONEncoder().encode(selectedPlan) else {
            return
        }

        defaults.set(data, forKey: Keys.selectedPlan)
    }

    private func persistCompletions() {
        guard let data = try? JSONEncoder().encode(completions) else {
            return
        }

        defaults.set(data, forKey: Keys.completions)
    }

    private static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
