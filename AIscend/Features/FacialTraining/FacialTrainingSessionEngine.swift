//
//  FacialTrainingSessionEngine.swift
//  AIscend
//
//  Created by Codex on 5/10/26.
//

import Foundation

struct FacialTrainingSessionEngine {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func generatePlan(
        profile: UserTrainingGoals,
        startDate: Date = .now,
        feedbackHistory: [SessionFeedback] = [],
        progress: [ProgressSnapshot] = []
    ) -> FacialTrainingPlan {
        let tier = difficultyTier(for: profile)
        let loadProfile = makeLoadProfile(
            profile: profile,
            feedbackHistory: feedbackHistory,
            progress: progress
        )
        let adaptationState = adaptationState(for: loadProfile, profile: profile)
        let multiplier = baseMultiplier(for: profile, tier: tier, loadProfile: loadProfile)
        let recoverySchedule = recoverySchedule(for: profile, tier: tier, loadProfile: loadProfile)
        let weeks = (1...6).map { weekIndex in
            buildWeek(
                weekIndex: weekIndex,
                profile: profile,
                tier: tier,
                multiplier: multiplier,
                loadProfile: loadProfile
            )
        }

        return FacialTrainingPlan(
            createdAt: startDate,
            profile: profile,
            difficultyTier: tier,
            recoverySchedule: recoverySchedule,
            weeks: weeks,
            adaptationMultiplier: multiplier,
            adaptationState: adaptationState
        )
    }

    func routineForToday(plan: FacialTrainingPlan, progress: [ProgressSnapshot], date: Date = .now) -> FacialRoutine {
        let daysSinceStart = max(calendar.dateComponents([.day], from: calendar.startOfDay(for: plan.createdAt), to: calendar.startOfDay(for: date)).day ?? 0, 0)
        let weekIndex = min(daysSinceStart / 7, 5)
        let dayIndex = daysSinceStart % 7

        guard plan.weeks.indices.contains(weekIndex) else {
            return fallbackRoutine(plan: plan)
        }

        let week = plan.weeks[weekIndex]
        if let routine = week.routines.first(where: { $0.dayIndex == dayIndex }) {
            return routine
        }

        return week.routines.first ?? fallbackRoutine(plan: plan)
    }

    func adaptedPlan(
        plan: FacialTrainingPlan,
        latestFeedback: SessionFeedback,
        feedbackHistory: [SessionFeedback],
        progress: [ProgressSnapshot]
    ) -> FacialTrainingPlan {
        var updated = plan
        let combinedFeedback = ([latestFeedback] + feedbackHistory)
            .uniquedBy(\.id)
            .sorted { $0.date > $1.date }
        let loadProfile = makeLoadProfile(
            profile: plan.profile,
            feedbackHistory: combinedFeedback,
            progress: progress
        )
        let state = adaptationState(for: loadProfile, profile: plan.profile)
        let targetMultiplier = baseMultiplier(
            for: plan.profile,
            tier: plan.difficultyTier,
            loadProfile: loadProfile
        )
        let smoothedMultiplier = ((plan.adaptationMultiplier * 0.68) + (targetMultiplier * 0.32))
            .clamped(to: 0.66...1.24)

        updated.adaptationMultiplier = smoothedMultiplier
        updated.adaptationState = state
        updated.recoverySchedule = recoverySchedule(
            for: plan.profile,
            tier: plan.difficultyTier,
            loadProfile: loadProfile
        )
        updated.lastUpdatedAt = .now
        updated.weeks = rebuildFutureSchedule(
            from: updated,
            after: latestFeedback.routineID,
            loadProfile: loadProfile
        )
        return updated
    }

    func completionSnapshot(
        for routine: FacialRoutine,
        feedback: SessionFeedback?,
        recentProgress: [ProgressSnapshot] = []
    ) -> ProgressSnapshot {
        let readiness = feedback?.readinessScore ?? 0.76
        let consistency = consistencyScore(from: recentProgress, endingAt: .now)

        return ProgressSnapshot(
            completedRoutineID: routine.id,
            weekIndex: routine.weekIndex,
            durationSeconds: routine.estimatedDurationSeconds,
            completedExerciseIDs: routine.prescriptions.map(\.exercise.id),
            readinessScore: readiness,
            trainingLoadScore: routine.intensityScore,
            consistencyScore: consistency
        )
    }

    func hasCompletedToday(_ progress: [ProgressSnapshot], date: Date = .now) -> Bool {
        progress.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func currentStreak(from progress: [ProgressSnapshot], date: Date = .now) -> Int {
        let completedDays = Set(progress.map { calendar.startOfDay(for: $0.date) })
        guard !completedDays.isEmpty else {
            return 0
        }

        var day = calendar.startOfDay(for: date)
        if !completedDays.contains(day),
           let yesterday = calendar.date(byAdding: .day, value: -1, to: day),
           completedDays.contains(yesterday)
        {
            day = yesterday
        }

        var streak = 0
        while completedDays.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else {
                break
            }
            day = previous
        }

        return streak
    }

    private func rebuildFutureSchedule(
        from plan: FacialTrainingPlan,
        after routineID: UUID,
        loadProfile: FacialPlanningLoadProfile
    ) -> [TrainingWeek] {
        let completedWeekIndex = plan.weeks.firstIndex { week in
            week.routines.contains { $0.id == routineID }
        } ?? 0
        let completedDayIndex = plan.weeks[safe: completedWeekIndex]?.routines.first(where: { $0.id == routineID })?.dayIndex ?? -1

        return plan.weeks.map { week in
            guard week.weekIndex - 1 >= completedWeekIndex else {
                return week
            }

            let rebuilt = buildWeek(
                weekIndex: week.weekIndex,
                profile: plan.profile,
                tier: plan.difficultyTier,
                multiplier: plan.adaptationMultiplier,
                loadProfile: loadProfile
            )

            guard week.weekIndex - 1 == completedWeekIndex else {
                return rebuilt
            }

            let routines = rebuilt.routines.map { newRoutine in
                guard newRoutine.dayIndex <= completedDayIndex,
                      let oldRoutine = week.routines.first(where: { $0.dayIndex == newRoutine.dayIndex })
                else {
                    return newRoutine
                }
                return oldRoutine
            }

            return TrainingWeek(
                weekIndex: week.weekIndex,
                title: rebuilt.title,
                phase: rebuilt.phase,
                improvementGoal: rebuilt.improvementGoal,
                routines: routines,
                targetSessions: rebuilt.targetSessions,
                deloadDays: rebuilt.deloadDays
            )
        }
    }

    private func buildWeek(
        weekIndex: Int,
        profile: UserTrainingGoals,
        tier: FacialDifficultyTier,
        multiplier: Double,
        loadProfile: FacialPlanningLoadProfile
    ) -> TrainingWeek {
        var exposure = FacialWeeklyExposure()
        var previousCategories: [FacialExerciseCategory] = []
        let deloadDays = deloadDays(for: weekIndex, tier: tier, loadProfile: loadProfile)

        let routines = (0..<7).map { dayIndex in
            let dayType = dayType(
                weekIndex: weekIndex,
                dayIndex: dayIndex,
                deloadDays: deloadDays,
                loadProfile: loadProfile
            )
            let routine = buildRoutine(
                weekIndex: weekIndex,
                dayIndex: dayIndex,
                dayType: dayType,
                previousCategories: previousCategories,
                profile: profile,
                tier: tier,
                multiplier: multiplier,
                loadProfile: loadProfile,
                exposure: exposure
            )
            exposure.record(routine)
            previousCategories = routine.prescriptions.map(\.exercise.category)
            return routine
        }

        return TrainingWeek(
            weekIndex: weekIndex,
            title: "Week \(weekIndex)",
            phase: phaseTitle(for: weekIndex, loadProfile: loadProfile),
            improvementGoal: improvementGoal(for: weekIndex, profile: profile, loadProfile: loadProfile),
            routines: routines,
            targetSessions: loadProfile.recoveryPressure > 0.66 ? 4 : 5,
            deloadDays: deloadDays
        )
    }

    private func buildRoutine(
        weekIndex: Int,
        dayIndex: Int,
        dayType: FacialTrainingDayType,
        previousCategories: [FacialExerciseCategory],
        profile: UserTrainingGoals,
        tier: FacialDifficultyTier,
        multiplier: Double,
        loadProfile: FacialPlanningLoadProfile,
        exposure: FacialWeeklyExposure
    ) -> FacialRoutine {
        let focus = focusFor(
            dayIndex: dayIndex,
            dayType: dayType,
            goals: profile.goals,
            previousCategories: previousCategories,
            exposure: exposure
        )
        let targetMinutes = targetMinutes(for: profile, dayType: dayType, loadProfile: loadProfile)
        let available = FacialTrainingExerciseLibrary.available(for: profile, week: weekIndex)
        let selected = selectExercises(
            from: available,
            focus: focus,
            dayType: dayType,
            profile: profile,
            loadProfile: loadProfile,
            exposure: exposure
        )
        let prescriptions = selected.map { exercise in
            prescription(
                for: exercise,
                weekIndex: weekIndex,
                dayType: dayType,
                profile: profile,
                tier: tier,
                multiplier: multiplier,
                loadProfile: loadProfile
            )
        }
        let fitted = fitWithinTimeWindow(prescriptions, targetMinutes: targetMinutes)
        let estimatedSeconds = estimatedSeconds(for: fitted)
        let loads = categoryLoads(for: fitted)
        let recoveryEmphasis = dayType == .recovery || dayType == .deload

        return FacialRoutine(
            title: title(for: focus, dayType: dayType),
            focus: focus.subtitle,
            weekIndex: weekIndex,
            dayIndex: dayIndex,
            dayType: dayType,
            prescriptions: fitted,
            estimatedDurationSeconds: estimatedSeconds,
            intensityScore: intensityScore(for: fitted, recovery: recoveryEmphasis),
            recoveryEmphasis: recoveryEmphasis,
            progressionSummary: progressionSummary(weekIndex: weekIndex, dayType: dayType, loadProfile: loadProfile),
            neckLoadScore: loads.neck,
            jawLoadScore: loads.jaw,
            postureLoadScore: loads.posture
        )
    }

    private func prescription(
        for exercise: FacialExercise,
        weekIndex: Int,
        dayType: FacialTrainingDayType,
        profile: UserTrainingGoals,
        tier: FacialDifficultyTier,
        multiplier: Double,
        loadProfile: FacialPlanningLoadProfile
    ) -> FacialExercisePrescription {
        let progression = progressionFactor(
            weekIndex: weekIndex,
            dayType: dayType,
            exercise: exercise,
            profile: profile,
            tier: tier,
            loadProfile: loadProfile
        )
        let loadManagedMultiplier = multiplier * progression * categoryCapacityBias(for: exercise.category, profile: profile)
        let duration = Int(Double(exercise.baseDurationSeconds) * loadManagedMultiplier)
            .clamped(to: exercise.category == .recovery ? 45...110 : 35...120)
        let rest = restSeconds(
            for: exercise,
            tier: tier,
            dayType: dayType,
            loadProfile: loadProfile
        )

        return FacialExercisePrescription(
            exercise: exercise,
            durationSeconds: duration,
            restSeconds: rest,
            reps: progressedReps(for: exercise, weekIndex: weekIndex, dayType: dayType, loadProfile: loadProfile),
            intensityMultiplier: loadManagedMultiplier,
            coachingCue: coachingCue(for: exercise, weekIndex: weekIndex, dayType: dayType, loadProfile: loadProfile),
            progressionCue: progressionCue(for: exercise, weekIndex: weekIndex, dayType: dayType, profile: profile),
            loadScore: loadScore(for: exercise, durationSeconds: duration, multiplier: loadManagedMultiplier),
            complexityLevel: complexityLevel(weekIndex: weekIndex, dayType: dayType, exercise: exercise)
        )
    }

    private func selectExercises(
        from exercises: [FacialExercise],
        focus: RoutineFocus,
        dayType: FacialTrainingDayType,
        profile: UserTrainingGoals,
        loadProfile: FacialPlanningLoadProfile,
        exposure: FacialWeeklyExposure
    ) -> [FacialExercise] {
        if dayType == .recovery || dayType == .deload {
            var recovery = [
                FacialTrainingExerciseLibrary.breathingReset,
                FacialTrainingExerciseLibrary.facialRelaxation,
                FacialTrainingExerciseLibrary.lymphaticMassage,
                FacialTrainingExerciseLibrary.wallPostureHold
            ].filter { exercises.contains($0) }

            if profile.goals.contains(.betterPosture), exercises.contains(FacialTrainingExerciseLibrary.thoracicExtension) {
                recovery.insert(FacialTrainingExerciseLibrary.thoracicExtension, at: min(2, recovery.count))
            }

            return Array(recovery.prefix(dayType == .deload ? 5 : 4))
        }

        var selected: [FacialExercise] = []
        for category in focus.categories {
            let candidates = exercises
                .filter { $0.category == category }
                .filter { exerciseAllowed($0, dayType: dayType, loadProfile: loadProfile, exposure: exposure) }
                .sorted { lhs, rhs in
                    score(lhs, for: profile, dayType: dayType, loadProfile: loadProfile) > score(rhs, for: profile, dayType: dayType, loadProfile: loadProfile)
                }

            if let exercise = candidates.first {
                selected.append(exercise)
            }
        }

        if shouldAddNeckOverload(profile: profile, dayType: dayType, exposure: exposure, loadProfile: loadProfile),
           let neckExercise = preferredNeckOverload(from: exercises, profile: profile, exposure: exposure)
        {
            selected.append(neckExercise)
        }

        if shouldAddJawOverload(profile: profile, dayType: dayType, exposure: exposure, loadProfile: loadProfile),
           exercises.contains(FacialTrainingExerciseLibrary.jawResistance)
        {
            selected.append(FacialTrainingExerciseLibrary.jawResistance)
        }

        if profile.equipment.contains(.chewingGum),
           profile.goals.contains(.sharperJawline),
           dayType == .density,
           exposure.chewingExposures < 2,
           loadProfile.recoveryPressure < 0.58,
           exercises.contains(FacialTrainingExerciseLibrary.chewingProtocol)
        {
            selected.append(FacialTrainingExerciseLibrary.chewingProtocol)
        }

        if selected.contains(where: { $0.category == .posture }) == false {
            selected.append(profile.postureLevel == .low ? FacialTrainingExerciseLibrary.wallPostureHold : FacialTrainingExerciseLibrary.scapularRetraction)
        }

        selected.append(FacialTrainingExerciseLibrary.breathingReset)
        return Array(selected.uniquedBy(\.id).prefix(loadProfile.recoveryPressure > 0.58 ? 5 : 6))
    }

    private func fitWithinTimeWindow(_ prescriptions: [FacialExercisePrescription], targetMinutes: Int) -> [FacialExercisePrescription] {
        let minSeconds = 10 * 60
        let maxSeconds = 15 * 60
        let targetSeconds = targetMinutes.clamped(to: 10...15) * 60
        var result = prescriptions
        var total = estimatedSeconds(for: result)

        while total > min(targetSeconds, maxSeconds), result.count > 4 {
            if let removableIndex = result.lastIndex(where: { $0.exercise.category != .recovery }) {
                result.remove(at: removableIndex)
            } else {
                result.removeLast()
            }
            total = estimatedSeconds(for: result)
        }

        while total < minSeconds {
            let filler = FacialExercisePrescription(
                exercise: FacialTrainingExerciseLibrary.breathingReset,
                durationSeconds: min(90, minSeconds - total + 15),
                restSeconds: 15,
                reps: nil,
                intensityMultiplier: 1,
                coachingCue: "Downshift the nervous system before you leave.",
                progressionCue: "Recovery volume keeps the plan inside the minimum effective window.",
                loadScore: 0.12,
                complexityLevel: 1
            )
            result.append(filler)
            total = estimatedSeconds(for: result)
            if result.count > 8 {
                break
            }
        }

        return result
    }

    private func estimatedSeconds(for prescriptions: [FacialExercisePrescription]) -> Int {
        prescriptions.enumerated().reduce(0) { partial, pair in
            let isLast = pair.offset == prescriptions.count - 1
            return partial + pair.element.durationSeconds + (isLast ? 0 : pair.element.restSeconds)
        }
    }

    private func makeLoadProfile(
        profile: UserTrainingGoals,
        feedbackHistory: [SessionFeedback],
        progress: [ProgressSnapshot]
    ) -> FacialPlanningLoadProfile {
        let recentFeedback = Array(feedbackHistory.sorted { $0.date > $1.date }.prefix(7))
        let soreness = average(recentFeedback.map(\.soreness), fallback: 2)
        let fatigue = average(recentFeedback.map(\.fatigue), fallback: 2)
        let tension = average(recentFeedback.map(\.tensionLevel), fallback: 2)
        let energy = average(recentFeedback.map(\.energy), fallback: 3)
        let adherence = average(recentFeedback.map(\.adherence), fallback: recentFeedback.isEmpty ? 5 : 3)
        let difficulty = average(recentFeedback.map(\.difficulty), fallback: 3)
        let consistency = consistencyScore(from: progress, endingAt: .now)
        let latestProgressReadiness = progress.sorted { $0.date > $1.date }.first?.readinessScore
        let readiness = recentFeedback.first?.readinessScore ?? latestProgressReadiness ?? 0.76
        let sorenessPressure = max(0, (soreness - 2.2) / 2.8)
        let fatiguePressure = max(0, (fatigue - 2.2) / 2.8)
        let tensionPressure = max(0, (tension - 2.4) / 2.6)
        let energyPressure = max(0, (3.0 - energy) / 2.0)
        let lowAdherencePressure = max(0, (3.0 - adherence) / 2.0) * 0.45
        let recoveryPressure = (sorenessPressure * 0.31 + fatiguePressure * 0.28 + tensionPressure * 0.20 + energyPressure * 0.14 + lowAdherencePressure)
            .clamped(to: 0...1)

        return FacialPlanningLoadProfile(
            readiness: readiness,
            consistency: consistency,
            soreness: soreness,
            fatigue: fatigue,
            tension: tension,
            energy: energy,
            adherence: adherence,
            difficulty: difficulty,
            recoveryPressure: recoveryPressure,
            neckCapacity: profile.neckStrengthLevel.trainingBias,
            postureCapacity: profile.postureLevel.trainingBias
        )
    }

    private func adaptationState(
        for loadProfile: FacialPlanningLoadProfile,
        profile: UserTrainingGoals
    ) -> FacialTrainingAdaptationState {
        FacialTrainingAdaptationState(
            readinessScore: loadProfile.readiness,
            consistencyScore: loadProfile.consistency,
            sorenessTrend: loadProfile.soreness,
            fatigueTrend: loadProfile.fatigue,
            energyTrend: loadProfile.energy,
            adherenceTrend: loadProfile.adherence,
            recommendedIntensityMultiplier: baseMultiplier(
                for: profile,
                tier: difficultyTier(for: profile),
                loadProfile: loadProfile
            ),
            recoveryPressure: loadProfile.recoveryPressure,
            coachingSummary: coachingSummary(for: loadProfile)
        )
    }

    private func baseMultiplier(
        for profile: UserTrainingGoals,
        tier: FacialDifficultyTier,
        loadProfile: FacialPlanningLoadProfile
    ) -> Double {
        let readinessBias = 0.88 + (loadProfile.readiness * 0.24)
        let consistencyBias = loadProfile.consistency < 0.35 ? 0.93 : loadProfile.consistency > 0.72 ? 1.04 : 1.0
        let recoveryBias = 1.0 - (loadProfile.recoveryPressure * 0.30)
        let experienceBias = profile.experience.intensitySeed
        let tierBias = tier == .advanced ? 1.04 : tier == .performance ? 1.0 : 0.96
        return (readinessBias * consistencyBias * recoveryBias * experienceBias * tierBias)
            .clamped(to: 0.68...1.22)
    }

    private func consistencyScore(from progress: [ProgressSnapshot], endingAt date: Date) -> Double {
        guard progress.isEmpty == false else {
            return 0.5
        }

        let recentDays = (0..<14).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: calendar.startOfDay(for: date))
        }
        let completedDays = Set(progress.map { calendar.startOfDay(for: $0.date) })
        let completions = recentDays.filter { completedDays.contains($0) }.count
        return (Double(completions) / 10.0).clamped(to: 0...1)
    }

    private func targetMinutes(
        for profile: UserTrainingGoals,
        dayType: FacialTrainingDayType,
        loadProfile: FacialPlanningLoadProfile
    ) -> Int {
        let userCap = profile.availableDailyMinutes.clamped(to: 10...15)
        let recoveryAdjustment = loadProfile.recoveryPressure > 0.66 ? -2 : loadProfile.recoveryPressure > 0.48 ? -1 : 0
        let dayBias: Int

        switch dayType {
        case .overload, .density:
            dayBias = 1
        case .recovery, .deload:
            dayBias = -1
        case .neuralPrimer, .integration:
            dayBias = 0
        }

        return (userCap + recoveryAdjustment + dayBias).clamped(to: 10...15)
    }

    private func dayType(
        weekIndex: Int,
        dayIndex: Int,
        deloadDays: [Int],
        loadProfile: FacialPlanningLoadProfile
    ) -> FacialTrainingDayType {
        if deloadDays.contains(dayIndex) {
            return loadProfile.recoveryPressure > 0.58 ? .deload : .recovery
        }

        if loadProfile.recoveryPressure > 0.72, dayIndex == 1 {
            return .deload
        }

        switch (weekIndex, dayIndex % 5) {
        case (1, 0):
            return .neuralPrimer
        case (_, 1):
            return .overload
        case (_, 2):
            return .integration
        case (5...6, 4):
            return .density
        case (_, 4):
            return .overload
        default:
            return .neuralPrimer
        }
    }

    private func deloadDays(
        for weekIndex: Int,
        tier: FacialDifficultyTier,
        loadProfile: FacialPlanningLoadProfile
    ) -> [Int] {
        if loadProfile.recoveryPressure > 0.62 {
            return [2, 5, 6]
        }

        if weekIndex == 6 {
            return [3, 6]
        }

        return tier == .advanced ? [3, 6] : [2, 6]
    }

    private func progressionFactor(
        weekIndex: Int,
        dayType: FacialTrainingDayType,
        exercise: FacialExercise,
        profile: UserTrainingGoals,
        tier: FacialDifficultyTier,
        loadProfile: FacialPlanningLoadProfile
    ) -> Double {
        let weeklyRamp = 1.0 + (Double(weekIndex - 1) * tier.weeklyRamp)
        let bodyBias = profile.bodyFatEstimate.planBias
        let readinessBias = 0.92 + (loadProfile.readiness * 0.16)
        let recoveryBias = 1.0 - (loadProfile.recoveryPressure * (exercise.category == .recovery ? 0.05 : 0.28))
        let dayBias: Double

        switch dayType {
        case .overload:
            dayBias = 1.06
        case .density:
            dayBias = 1.10
        case .integration:
            dayBias = 1.0
        case .neuralPrimer:
            dayBias = 0.95
        case .recovery:
            dayBias = exercise.category == .recovery ? 1.06 : 0.72
        case .deload:
            dayBias = exercise.category == .recovery ? 1.08 : 0.62
        }

        return (weeklyRamp * bodyBias * readinessBias * recoveryBias * dayBias)
            .clamped(to: 0.62...1.42)
    }

    private func restSeconds(
        for exercise: FacialExercise,
        tier: FacialDifficultyTier,
        dayType: FacialTrainingDayType,
        loadProfile: FacialPlanningLoadProfile
    ) -> Int {
        let overloadReduction = (dayType == .density && loadProfile.recoveryPressure < 0.35) ? -5 : 0
        let recoveryBonus = Int((loadProfile.recoveryPressure * 18).rounded())
        let neckBonus = exercise.category == .neck ? 8 : 0
        let tierAdjustment = tier == .advanced && loadProfile.recoveryPressure < 0.4 ? -3 : 0
        let deloadBonus = dayType == .deload ? 10 : 0
        return (exercise.baseRestSeconds + overloadReduction + recoveryBonus + neckBonus + tierAdjustment + deloadBonus)
            .clamped(to: 15...55)
    }

    private func progressedReps(
        for exercise: FacialExercise,
        weekIndex: Int,
        dayType: FacialTrainingDayType,
        loadProfile: FacialPlanningLoadProfile
    ) -> String? {
        guard let reps = exercise.reps else {
            return nil
        }

        if dayType == .deload || dayType == .recovery || loadProfile.recoveryPressure > 0.68 {
            return reps.replacingOccurrences(of: "controlled", with: "easy controlled")
        }

        if weekIndex >= 5, exercise.category != .recovery {
            return "\(reps) / final rep 3s hold"
        }

        if weekIndex >= 3, exercise.category == .neck {
            return "\(reps) / +1 quality rep if crisp"
        }

        return reps
    }

    private func categoryCapacityBias(for category: FacialExerciseCategory, profile: UserTrainingGoals) -> Double {
        switch category {
        case .neck:
            return profile.neckStrengthLevel.trainingBias
        case .posture:
            return profile.postureLevel.trainingBias
        case .jawHyoid:
            return profile.experience == .beginner ? 0.94 : 1.0
        case .recovery:
            return 1.0
        }
    }

    private func loadScore(for exercise: FacialExercise, durationSeconds: Int, multiplier: Double) -> Double {
        let durationBias = Double(durationSeconds) / Double(max(exercise.baseDurationSeconds, 1))
        return ((Double(exercise.intensity) / 5.0) * durationBias * multiplier)
            .clamped(to: 0.05...1.0)
    }

    private func categoryLoads(for prescriptions: [FacialExercisePrescription]) -> (neck: Double, jaw: Double, posture: Double) {
        let neck = prescriptions.filter { $0.exercise.category == .neck }.reduce(0.0) { $0 + $1.loadScore }
        let jaw = prescriptions.filter { $0.exercise.category == .jawHyoid }.reduce(0.0) { $0 + $1.loadScore }
        let posture = prescriptions.filter { $0.exercise.category == .posture }.reduce(0.0) { $0 + $1.loadScore }
        return (neck.clamped(to: 0...1), jaw.clamped(to: 0...1), posture.clamped(to: 0...1))
    }

    private func intensityScore(for prescriptions: [FacialExercisePrescription], recovery: Bool) -> Double {
        guard !prescriptions.isEmpty else {
            return 0
        }

        let total = prescriptions.reduce(0.0) { $0 + $1.loadScore }
        let average = total / Double(prescriptions.count)
        return recovery ? min(average, 0.45) : average.clamped(to: 0.2...1)
    }

    private func exerciseAllowed(
        _ exercise: FacialExercise,
        dayType: FacialTrainingDayType,
        loadProfile: FacialPlanningLoadProfile,
        exposure: FacialWeeklyExposure
    ) -> Bool {
        if dayType == .deload, exercise.intensity >= 4 {
            return false
        }

        if exercise.category == .neck, exposure.neckExposures >= 3, exercise.intensity >= 3 {
            return false
        }

        if exercise.id == FacialTrainingExerciseLibrary.chewingProtocol.id, exposure.chewingExposures >= 2 {
            return false
        }

        if loadProfile.recoveryPressure > 0.62, exercise.intensity >= 4 {
            return false
        }

        return true
    }

    private func score(
        _ exercise: FacialExercise,
        for profile: UserTrainingGoals,
        dayType: FacialTrainingDayType,
        loadProfile: FacialPlanningLoadProfile
    ) -> Double {
        var score = 10.0 - Double(exercise.intensity) * 0.35

        if profile.goals.contains(.neckSize), exercise.category == .neck {
            score += 2.4
        }
        if profile.goals.contains(.betterPosture) || profile.goals.contains(.betterSideProfile), exercise.category == .posture {
            score += 2.0
        }
        if profile.goals.contains(.sharperJawline) || profile.goals.contains(.strongerLowerThird), exercise.category == .jawHyoid {
            score += 1.8
        }
        if profile.goals.contains(.eyeAreaFreshness), exercise.category == .recovery {
            score += 1.2
        }
        if dayType == .overload, exercise.intensity >= 3 {
            score += 1.1
        }
        if dayType == .density, exercise.baseRestSeconds <= 30 {
            score += 0.8
        }
        if loadProfile.recoveryPressure > 0.5, exercise.category == .recovery {
            score += 2.6
        }
        return score
    }

    private func shouldAddNeckOverload(
        profile: UserTrainingGoals,
        dayType: FacialTrainingDayType,
        exposure: FacialWeeklyExposure,
        loadProfile: FacialPlanningLoadProfile
    ) -> Bool {
        guard profile.goals.contains(.neckSize) || profile.goals.contains(.betterSideProfile) else {
            return false
        }
        return (dayType == .overload || dayType == .density)
            && exposure.neckExposures < 3
            && loadProfile.recoveryPressure < 0.62
    }

    private func preferredNeckOverload(
        from exercises: [FacialExercise],
        profile: UserTrainingGoals,
        exposure: FacialWeeklyExposure
    ) -> FacialExercise? {
        if profile.equipment.contains(.dumbbells) || profile.equipment.contains(.neckHarness),
           exercises.contains(FacialTrainingExerciseLibrary.weightedNeckCurl),
           exposure.weightedNeckExposures < 2
        {
            return FacialTrainingExerciseLibrary.weightedNeckCurl
        }

        if exercises.contains(FacialTrainingExerciseLibrary.sideNeckRaise) {
            return FacialTrainingExerciseLibrary.sideNeckRaise
        }

        return exercises.contains(FacialTrainingExerciseLibrary.deepNeckFlexorHold) ? FacialTrainingExerciseLibrary.deepNeckFlexorHold : nil
    }

    private func shouldAddJawOverload(
        profile: UserTrainingGoals,
        dayType: FacialTrainingDayType,
        exposure: FacialWeeklyExposure,
        loadProfile: FacialPlanningLoadProfile
    ) -> Bool {
        guard profile.goals.contains(.strongerLowerThird) || profile.goals.contains(.sharperJawline) else {
            return false
        }
        return dayType != .recovery
            && dayType != .deload
            && exposure.jawExposures < 4
            && loadProfile.tension < 3.6
            && loadProfile.recoveryPressure < 0.6
    }

    private func difficultyTier(for profile: UserTrainingGoals) -> FacialDifficultyTier {
        if profile.experience == .advanced, profile.neckStrengthLevel != .low {
            return .advanced
        }

        if profile.experience == .trained || profile.availableDailyMinutes >= 12 {
            return .performance
        }

        return .foundation
    }

    private func recoverySchedule(
        for profile: UserTrainingGoals,
        tier: FacialDifficultyTier,
        loadProfile: FacialPlanningLoadProfile
    ) -> String {
        if loadProfile.recoveryPressure > 0.62 {
            return "High recovery pressure detected. Three lower-load days this week, no aggressive chewing, and loaded neck work capped until soreness normalizes."
        }

        let base = "Two lower-load recovery days weekly, with breathing and relaxation after every session."
        if profile.goals.contains(.neckSize) || tier == .advanced {
            return "\(base) Neck loading is capped at three exposures per week with at least one day between heavy exposures."
        }
        return "\(base) Jaw and hyoid work rotate with posture to avoid local overuse."
    }

    private func coachingCue(
        for exercise: FacialExercise,
        weekIndex: Int,
        dayType: FacialTrainingDayType,
        loadProfile: FacialPlanningLoadProfile
    ) -> String {
        if dayType == .deload || loadProfile.recoveryPressure > 0.68 {
            return "Reduce effort. Precision, breath, and release are the work."
        }

        if dayType == .recovery {
            return "Leave the session fresher than you entered."
        }

        if weekIndex >= 5 {
            return "Own the tempo. No visible strain."
        }

        switch exercise.category {
        case .neck:
            return "Ribs down, jaw quiet, neck line precise."
        case .jawHyoid:
            return "Light contact beats hard effort."
        case .posture:
            return "Make the profile taller without forcing it."
        case .recovery:
            return "Slow the system down."
        }
    }

    private func progressionCue(
        for exercise: FacialExercise,
        weekIndex: Int,
        dayType: FacialTrainingDayType,
        profile: UserTrainingGoals
    ) -> String {
        if dayType == .deload || dayType == .recovery {
            return "Deload volume. Preserve range and tissue quality."
        }

        switch exercise.category {
        case .neck:
            if weekIndex >= 4, profile.equipment.contains(.dumbbells) || profile.equipment.contains(.neckHarness) {
                return "Add resistance only if yesterday's neck soreness was 2/5 or lower."
            }
            return "Progress by adding hold quality before load."
        case .jawHyoid:
            return weekIndex >= 3 ? "Add one rep or a short final hold only if jaw tension stays quiet." : "Keep effort submaximal and symmetrical."
        case .posture:
            return "Increase time under posture, not force."
        case .recovery:
            return "Recovery volume supports readiness for the next overload block."
        }
    }

    private func complexityLevel(
        weekIndex: Int,
        dayType: FacialTrainingDayType,
        exercise: FacialExercise
    ) -> Int {
        guard dayType != .recovery, dayType != .deload else {
            return 1
        }

        let base = weekIndex >= 5 ? 3 : weekIndex >= 3 ? 2 : 1
        return exercise.intensity >= 4 ? min(base + 1, 4) : base
    }

    private func progressionSummary(
        weekIndex: Int,
        dayType: FacialTrainingDayType,
        loadProfile: FacialPlanningLoadProfile
    ) -> String {
        if dayType == .deload || loadProfile.recoveryPressure > 0.66 {
            return "Load reduced from feedback: longer rests, lower intensity, more recovery exposure."
        }

        switch weekIndex {
        case 1:
            return "Baseline movement quality. Establish clean range and low tension."
        case 2:
            return "Add modest hold time and slightly more neck/posture exposure."
        case 3:
            return "Introduce measured overload through reps, hold density, or light resistance."
        case 4:
            return "Integrate posture under facial and neck fatigue."
        case 5:
            return "Increase density by trimming rest only when readiness stays high."
        default:
            return "Consolidate gains and deload based on soreness and adherence."
        }
    }

    private func phaseTitle(for weekIndex: Int, loadProfile: FacialPlanningLoadProfile) -> String {
        if loadProfile.recoveryPressure > 0.68 {
            return "Recovery recalibration"
        }

        switch weekIndex {
        case 1:
            return "Calibration"
        case 2:
            return "Tissue tolerance"
        case 3:
            return "Controlled overload"
        case 4:
            return "Posture integration"
        case 5:
            return "Performance density"
        default:
            return "Consolidation"
        }
    }

    private func improvementGoal(
        for weekIndex: Int,
        profile: UserTrainingGoals,
        loadProfile: FacialPlanningLoadProfile
    ) -> String {
        if loadProfile.recoveryPressure > 0.68 {
            return "Normalize soreness and fatigue while preserving the daily training rhythm."
        }

        let primary = profile.goals.first?.shortTitle ?? "Control"
        switch weekIndex {
        case 1:
            return "Build clean movement patterns and establish \(primary.lowercased()) baselines."
        case 2:
            return "Increase hold quality while keeping soreness low."
        case 3:
            return "Introduce measured overload and better side-to-side symmetry."
        case 4:
            return "Make posture and tongue position easier to hold under fatigue."
        case 5:
            return "Raise density without adding visible strain."
        default:
            return "Lock in the repeatable routine and deload where feedback demands it."
        }
    }

    private func coachingSummary(for loadProfile: FacialPlanningLoadProfile) -> String {
        if loadProfile.recoveryPressure > 0.66 {
            return "Recovery pressure is elevated. Future sessions bias breathing, posture, longer rest, and lower neck/jaw load."
        }

        if loadProfile.consistency < 0.35 {
            return "Consistency is the limiter. The plan holds intensity steady and protects the daily habit."
        }

        if loadProfile.readiness > 0.78, loadProfile.adherence >= 4 {
            return "Readiness is strong. Progression can move through density, hold time, and measured resistance."
        }

        return "Balanced progression. Rotate neck, jaw, posture, and recovery without stacking the same tissue on consecutive days."
    }

    private func title(for focus: RoutineFocus, dayType: FacialTrainingDayType) -> String {
        switch dayType {
        case .deload:
            return "Controlled Deload"
        case .recovery:
            return "Recovery Reset"
        case .density:
            return "Density Session"
        default:
            return focus.title
        }
    }

    private func fallbackRoutine(plan: FacialTrainingPlan) -> FacialRoutine {
        buildRoutine(
            weekIndex: 1,
            dayIndex: 0,
            dayType: .neuralPrimer,
            previousCategories: [],
            profile: plan.profile,
            tier: plan.difficultyTier,
            multiplier: plan.adaptationMultiplier,
            loadProfile: .baseline(profile: plan.profile),
            exposure: FacialWeeklyExposure()
        )
    }

    private func average(_ values: [Int], fallback: Double) -> Double {
        guard !values.isEmpty else {
            return fallback
        }

        return Double(values.reduce(0, +)) / Double(values.count)
    }
}

private struct FacialPlanningLoadProfile {
    let readiness: Double
    let consistency: Double
    let soreness: Double
    let fatigue: Double
    let tension: Double
    let energy: Double
    let adherence: Double
    let difficulty: Double
    let recoveryPressure: Double
    let neckCapacity: Double
    let postureCapacity: Double

    static func baseline(profile: UserTrainingGoals) -> FacialPlanningLoadProfile {
        FacialPlanningLoadProfile(
            readiness: 0.76,
            consistency: 0.5,
            soreness: 2,
            fatigue: 2,
            tension: 2,
            energy: 3,
            adherence: 5,
            difficulty: 3,
            recoveryPressure: 0.22,
            neckCapacity: profile.neckStrengthLevel.trainingBias,
            postureCapacity: profile.postureLevel.trainingBias
        )
    }
}

private struct FacialWeeklyExposure {
    var neckExposures = 0
    var weightedNeckExposures = 0
    var jawExposures = 0
    var chewingExposures = 0
    var postureExposures = 0

    mutating func record(_ routine: FacialRoutine) {
        let ids = routine.prescriptions.map(\.exercise.id)
        if routine.neckLoadScore > 0.22 {
            neckExposures += 1
        }
        if ids.contains(FacialTrainingExerciseLibrary.weightedNeckCurl.id) {
            weightedNeckExposures += 1
        }
        if routine.jawLoadScore > 0.22 {
            jawExposures += 1
        }
        if ids.contains(FacialTrainingExerciseLibrary.chewingProtocol.id) {
            chewingExposures += 1
        }
        if routine.postureLoadScore > 0.18 {
            postureExposures += 1
        }
    }
}

private struct RoutineFocus {
    let title: String
    let subtitle: String
    let categories: [FacialExerciseCategory]
}

private func focusFor(
    dayIndex: Int,
    dayType: FacialTrainingDayType,
    goals: [FacialTrainingGoal],
    previousCategories: [FacialExerciseCategory],
    exposure: FacialWeeklyExposure
) -> RoutineFocus {
    if dayType == .recovery || dayType == .deload {
        return RoutineFocus(
            title: dayType == .deload ? "Controlled Deload" : "Recovery Reset",
            subtitle: "Breathing, relaxation, posture, and tissue quality.",
            categories: [.recovery, .posture]
        )
    }

    let postureHeavy = goals.contains(.betterPosture) || goals.contains(.betterSideProfile)
    let needsNeck = (goals.contains(.neckSize) || postureHeavy) && exposure.neckExposures < 3
    let needsPosture = postureHeavy && exposure.postureExposures < 5
    let priorWasJaw = previousCategories.contains(.jawHyoid)

    switch dayType {
    case .overload:
        return RoutineFocus(
            title: needsNeck ? "Neck Performance" : "Lower Third Strength",
            subtitle: needsNeck ? "Deep flexors, SCM control, and cervical load tolerance." : "Jawline control without clenching.",
            categories: needsNeck ? [.neck, .posture, .jawHyoid] : [.jawHyoid, .posture, .recovery]
        )
    case .integration:
        return RoutineFocus(
            title: postureHeavy ? "Side Profile Stack" : "Hyoid Control",
            subtitle: postureHeavy ? "Thoracic extension, wall posture, and hyoid precision." : "Submental control without throat tension.",
            categories: needsPosture ? [.posture, .jawHyoid, .neck] : [.jawHyoid, .posture, .recovery]
        )
    case .density:
        return RoutineFocus(
            title: "Performance Density",
            subtitle: "Controlled work capacity across neck, posture, and lower-third mechanics.",
            categories: priorWasJaw ? [.neck, .posture, .recovery] : [.jawHyoid, .neck, .posture]
        )
    case .neuralPrimer:
        return RoutineFocus(
            title: "Lower Third Primer",
            subtitle: "Jawline control, tongue posture, and clean cervical position.",
            categories: [.jawHyoid, .posture, needsNeck ? .neck : .recovery]
        )
    default:
        return RoutineFocus(
            title: "Lower Third Primer",
            subtitle: "Jawline control, tongue posture, and clean cervical position.",
            categories: [.jawHyoid, .posture, needsNeck ? .neck : .recovery]
        )
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

    func uniquedBy<ID: Hashable>(_ keyPath: KeyPath<Element, ID>) -> [Element] {
        var seen = Set<ID>()
        return filter { element in
            let id = element[keyPath: keyPath]
            guard seen.contains(id) == false else {
                return false
            }
            seen.insert(id)
            return true
        }
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
