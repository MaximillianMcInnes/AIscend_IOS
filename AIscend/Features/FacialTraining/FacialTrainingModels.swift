//
//  FacialTrainingModels.swift
//  AIscend
//
//  Created by Codex on 5/10/26.
//

import Foundation

enum FacialTrainingGender: String, Codable, CaseIterable, Identifiable, Sendable {
    case male
    case female
    case nonBinary
    case preferNotToSay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .male:
            "Male"
        case .female:
            "Female"
        case .nonBinary:
            "Non-binary"
        case .preferNotToSay:
            "Prefer not to say"
        }
    }
}

enum FacialBodyFatEstimate: String, Codable, CaseIterable, Identifiable, Sendable {
    case lean
    case athletic
    case average
    case higher
    case unsure

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lean:
            "Lean"
        case .athletic:
            "Athletic"
        case .average:
            "Average"
        case .higher:
            "Higher"
        case .unsure:
            "Unsure"
        }
    }

    var planBias: Double {
        switch self {
        case .lean:
            0.96
        case .athletic:
            1.0
        case .average:
            1.04
        case .higher:
            1.08
        case .unsure:
            1.0
        }
    }
}

enum FacialTrainingGoal: String, Codable, CaseIterable, Identifiable, Sendable {
    case sharperJawline
    case betterPosture
    case neckSize
    case reducedSubmentalFullness
    case betterSideProfile
    case strongerLowerThird
    case eyeAreaFreshness

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sharperJawline:
            "Sharper jawline"
        case .betterPosture:
            "Better posture"
        case .neckSize:
            "Neck size"
        case .reducedSubmentalFullness:
            "Reduced submental fullness"
        case .betterSideProfile:
            "Better side profile"
        case .strongerLowerThird:
            "Stronger lower third"
        case .eyeAreaFreshness:
            "Eye area freshness"
        }
    }

    var shortTitle: String {
        switch self {
        case .sharperJawline:
            "Jawline"
        case .betterPosture:
            "Posture"
        case .neckSize:
            "Neck"
        case .reducedSubmentalFullness:
            "Submental"
        case .betterSideProfile:
            "Profile"
        case .strongerLowerThird:
            "Lower third"
        case .eyeAreaFreshness:
            "Freshness"
        }
    }
}

enum FacialTrainingEquipment: String, Codable, CaseIterable, Identifiable, Sendable {
    case none
    case resistanceBands
    case neckHarness
    case dumbbells
    case chewingGum

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none:
            "None"
        case .resistanceBands:
            "Resistance bands"
        case .neckHarness:
            "Neck harness"
        case .dumbbells:
            "Dumbbells"
        case .chewingGum:
            "Chewing gum"
        }
    }
}

enum FacialTrainingExperience: String, Codable, CaseIterable, Identifiable, Sendable {
    case beginner
    case trained
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beginner:
            "Beginner"
        case .trained:
            "Trained"
        case .advanced:
            "Advanced"
        }
    }

    var intensitySeed: Double {
        switch self {
        case .beginner:
            0.82
        case .trained:
            1.0
        case .advanced:
            1.12
        }
    }
}

enum FacialTrainingCapacityLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    case low
    case moderate
    case strong
    case elite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low:
            "Low"
        case .moderate:
            "Moderate"
        case .strong:
            "Strong"
        case .elite:
            "Elite"
        }
    }

    var trainingBias: Double {
        switch self {
        case .low:
            0.86
        case .moderate:
            1.0
        case .strong:
            1.08
        case .elite:
            1.14
        }
    }
}

enum FacialTrainingDayType: String, Codable, CaseIterable, Identifiable, Sendable {
    case neuralPrimer
    case overload
    case integration
    case density
    case recovery
    case deload

    var id: String { rawValue }

    var title: String {
        switch self {
        case .neuralPrimer:
            "Neural primer"
        case .overload:
            "Overload"
        case .integration:
            "Integration"
        case .density:
            "Density"
        case .recovery:
            "Recovery"
        case .deload:
            "Deload"
        }
    }
}

enum FacialDifficultyTier: String, Codable, CaseIterable, Identifiable, Sendable {
    case foundation
    case performance
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .foundation:
            "Foundation"
        case .performance:
            "Performance"
        case .advanced:
            "Advanced"
        }
    }

    var weeklyRamp: Double {
        switch self {
        case .foundation:
            0.07
        case .performance:
            0.10
        case .advanced:
            0.12
        }
    }
}

enum FacialExerciseCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case neck
    case jawHyoid
    case posture
    case recovery

    var id: String { rawValue }

    var title: String {
        switch self {
        case .neck:
            "Neck"
        case .jawHyoid:
            "Jaw/Hyoid"
        case .posture:
            "Posture"
        case .recovery:
            "Recovery"
        }
    }
}

enum FacialMovementPattern: String, Codable, CaseIterable, Sendable {
    case neckCurl
    case neckExtension
    case sideNeckRaise
    case deepNeckFlexor
    case scmBrace
    case chinTuck
    case tonguePosture
    case hyoidEngagement
    case jawResistance
    case chewingProtocol
    case wallPosture
    case scapularRetraction
    case thoracicExtension
    case breathingReset
    case facialRelaxation
    case lymphaticMassage
}

struct ExerciseAnimation: Codable, Hashable, Sendable {
    let pattern: FacialMovementPattern
    let primaryMuscleLabel: String
    let secondaryMuscleLabel: String
    let tempoDescription: String
    let accent: RoutineAccent
}

enum FacialVoiceCueTiming: String, Codable, Hashable, Sendable {
    case intro
    case midpoint
    case finalTen
    case rest
    case transition
}

struct FacialVoiceCue: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let timing: FacialVoiceCueTiming
    let text: String
    let offsetSeconds: Int

    init(
        id: UUID = UUID(),
        timing: FacialVoiceCueTiming,
        text: String,
        offsetSeconds: Int
    ) {
        self.id = id
        self.timing = timing
        self.text = text
        self.offsetSeconds = offsetSeconds
    }
}

struct FacialExercise: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let category: FacialExerciseCategory
    let equipment: [FacialTrainingEquipment]
    let instructions: [String]
    let muscleFocus: String
    let breathingCue: String
    let safetyCue: String
    let baseDurationSeconds: Int
    let baseRestSeconds: Int
    let reps: String?
    let minWeek: Int
    let intensity: Int
    let animation: ExerciseAnimation

    var durationLabel: String {
        if let reps {
            return reps
        }

        let minutes = baseDurationSeconds / 60
        let seconds = baseDurationSeconds % 60
        if minutes > 0 {
            return seconds == 0 ? "\(minutes)m" : "\(minutes)m \(seconds)s"
        }

        return "\(baseDurationSeconds)s"
    }
}

struct FacialExercisePrescription: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let exercise: FacialExercise
    let durationSeconds: Int
    let restSeconds: Int
    let reps: String?
    let intensityMultiplier: Double
    let coachingCue: String
    let progressionCue: String
    let loadScore: Double
    let complexityLevel: Int

    init(
        id: UUID = UUID(),
        exercise: FacialExercise,
        durationSeconds: Int,
        restSeconds: Int,
        reps: String?,
        intensityMultiplier: Double,
        coachingCue: String,
        progressionCue: String = "Quality before load.",
        loadScore: Double = 0.35,
        complexityLevel: Int = 1
    ) {
        self.id = id
        self.exercise = exercise
        self.durationSeconds = durationSeconds
        self.restSeconds = restSeconds
        self.reps = reps
        self.intensityMultiplier = intensityMultiplier
        self.coachingCue = coachingCue
        self.progressionCue = progressionCue
        self.loadScore = loadScore
        self.complexityLevel = complexityLevel
    }

    var doseLabel: String {
        reps ?? FacialTrainingFormat.time(durationSeconds)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case exercise
        case durationSeconds
        case restSeconds
        case reps
        case intensityMultiplier
        case coachingCue
        case progressionCue
        case loadScore
        case complexityLevel
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        exercise = try container.decode(FacialExercise.self, forKey: .exercise)
        durationSeconds = try container.decode(Int.self, forKey: .durationSeconds)
        restSeconds = try container.decode(Int.self, forKey: .restSeconds)
        reps = try container.decodeIfPresent(String.self, forKey: .reps)
        intensityMultiplier = try container.decodeIfPresent(Double.self, forKey: .intensityMultiplier) ?? 1.0
        coachingCue = try container.decodeIfPresent(String.self, forKey: .coachingCue) ?? "Quality before load."
        progressionCue = try container.decodeIfPresent(String.self, forKey: .progressionCue) ?? "Quality before load."
        loadScore = try container.decodeIfPresent(Double.self, forKey: .loadScore) ?? min(Double(exercise.intensity) / 5.0, 1.0)
        complexityLevel = try container.decodeIfPresent(Int.self, forKey: .complexityLevel) ?? 1
    }
}

struct FacialRoutine: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let title: String
    let focus: String
    let weekIndex: Int
    let dayIndex: Int
    let dayType: FacialTrainingDayType
    let prescriptions: [FacialExercisePrescription]
    let estimatedDurationSeconds: Int
    let intensityScore: Double
    let recoveryEmphasis: Bool
    let progressionSummary: String
    let neckLoadScore: Double
    let jawLoadScore: Double
    let postureLoadScore: Double

    init(
        id: UUID = UUID(),
        title: String,
        focus: String,
        weekIndex: Int,
        dayIndex: Int,
        dayType: FacialTrainingDayType = .integration,
        prescriptions: [FacialExercisePrescription],
        estimatedDurationSeconds: Int,
        intensityScore: Double,
        recoveryEmphasis: Bool,
        progressionSummary: String = "Adaptive volume based on feedback.",
        neckLoadScore: Double = 0,
        jawLoadScore: Double = 0,
        postureLoadScore: Double = 0
    ) {
        self.id = id
        self.title = title
        self.focus = focus
        self.weekIndex = weekIndex
        self.dayIndex = dayIndex
        self.dayType = dayType
        self.prescriptions = prescriptions
        self.estimatedDurationSeconds = estimatedDurationSeconds
        self.intensityScore = intensityScore
        self.recoveryEmphasis = recoveryEmphasis
        self.progressionSummary = progressionSummary
        self.neckLoadScore = neckLoadScore
        self.jawLoadScore = jawLoadScore
        self.postureLoadScore = postureLoadScore
    }

    var estimatedMinutes: Int {
        max(1, Int(ceil(Double(estimatedDurationSeconds) / 60.0)))
    }

    var progressTarget: Double {
        min(max(Double(dayIndex + 1) / 7.0, 0.05), 1)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case focus
        case weekIndex
        case dayIndex
        case dayType
        case prescriptions
        case estimatedDurationSeconds
        case intensityScore
        case recoveryEmphasis
        case progressionSummary
        case neckLoadScore
        case jawLoadScore
        case postureLoadScore
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        focus = try container.decode(String.self, forKey: .focus)
        weekIndex = try container.decode(Int.self, forKey: .weekIndex)
        dayIndex = try container.decode(Int.self, forKey: .dayIndex)
        dayType = try container.decodeIfPresent(FacialTrainingDayType.self, forKey: .dayType) ?? (try container.decodeIfPresent(Bool.self, forKey: .recoveryEmphasis) == true ? .recovery : .integration)
        prescriptions = try container.decode([FacialExercisePrescription].self, forKey: .prescriptions)
        estimatedDurationSeconds = try container.decode(Int.self, forKey: .estimatedDurationSeconds)
        intensityScore = try container.decodeIfPresent(Double.self, forKey: .intensityScore) ?? 0.4
        recoveryEmphasis = try container.decodeIfPresent(Bool.self, forKey: .recoveryEmphasis) ?? false
        progressionSummary = try container.decodeIfPresent(String.self, forKey: .progressionSummary) ?? "Adaptive volume based on feedback."
        neckLoadScore = try container.decodeIfPresent(Double.self, forKey: .neckLoadScore) ?? 0
        jawLoadScore = try container.decodeIfPresent(Double.self, forKey: .jawLoadScore) ?? 0
        postureLoadScore = try container.decodeIfPresent(Double.self, forKey: .postureLoadScore) ?? 0
    }
}

struct TrainingWeek: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let weekIndex: Int
    let title: String
    let phase: String
    let improvementGoal: String
    let routines: [FacialRoutine]
    let targetSessions: Int
    let deloadDays: [Int]

    init(
        id: UUID = UUID(),
        weekIndex: Int,
        title: String,
        phase: String,
        improvementGoal: String,
        routines: [FacialRoutine],
        targetSessions: Int,
        deloadDays: [Int]
    ) {
        self.id = id
        self.weekIndex = weekIndex
        self.title = title
        self.phase = phase
        self.improvementGoal = improvementGoal
        self.routines = routines
        self.targetSessions = targetSessions
        self.deloadDays = deloadDays
    }
}

struct UserTrainingGoals: Codable, Hashable, Sendable {
    var gender: FacialTrainingGender
    var age: Int
    var bodyFatEstimate: FacialBodyFatEstimate
    var goals: [FacialTrainingGoal]
    var equipment: [FacialTrainingEquipment]
    var availableDailyMinutes: Int
    var experience: FacialTrainingExperience
    var neckStrengthLevel: FacialTrainingCapacityLevel
    var postureLevel: FacialTrainingCapacityLevel

    static let empty = UserTrainingGoals(
        gender: .male,
        age: 25,
        bodyFatEstimate: .athletic,
        goals: [.sharperJawline, .betterPosture, .betterSideProfile],
        equipment: [.none],
        availableDailyMinutes: 12,
        experience: .beginner,
        neckStrengthLevel: .moderate,
        postureLevel: .moderate
    )

    init(
        gender: FacialTrainingGender,
        age: Int,
        bodyFatEstimate: FacialBodyFatEstimate,
        goals: [FacialTrainingGoal],
        equipment: [FacialTrainingEquipment],
        availableDailyMinutes: Int,
        experience: FacialTrainingExperience,
        neckStrengthLevel: FacialTrainingCapacityLevel = .moderate,
        postureLevel: FacialTrainingCapacityLevel = .moderate
    ) {
        self.gender = gender
        self.age = age
        self.bodyFatEstimate = bodyFatEstimate
        self.goals = goals
        self.equipment = equipment
        self.availableDailyMinutes = availableDailyMinutes
        self.experience = experience
        self.neckStrengthLevel = neckStrengthLevel
        self.postureLevel = postureLevel
    }

    private enum CodingKeys: String, CodingKey {
        case gender
        case age
        case bodyFatEstimate
        case goals
        case equipment
        case availableDailyMinutes
        case experience
        case neckStrengthLevel
        case postureLevel
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gender = try container.decodeIfPresent(FacialTrainingGender.self, forKey: .gender) ?? .preferNotToSay
        age = try container.decodeIfPresent(Int.self, forKey: .age) ?? 25
        bodyFatEstimate = try container.decodeIfPresent(FacialBodyFatEstimate.self, forKey: .bodyFatEstimate) ?? .unsure
        goals = try container.decodeIfPresent([FacialTrainingGoal].self, forKey: .goals) ?? [.sharperJawline, .betterPosture]
        equipment = try container.decodeIfPresent([FacialTrainingEquipment].self, forKey: .equipment) ?? [.none]
        availableDailyMinutes = try container.decodeIfPresent(Int.self, forKey: .availableDailyMinutes) ?? 12
        experience = try container.decodeIfPresent(FacialTrainingExperience.self, forKey: .experience) ?? .beginner
        neckStrengthLevel = try container.decodeIfPresent(FacialTrainingCapacityLevel.self, forKey: .neckStrengthLevel) ?? .moderate
        postureLevel = try container.decodeIfPresent(FacialTrainingCapacityLevel.self, forKey: .postureLevel) ?? .moderate
    }
}

struct SessionFeedback: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let routineID: UUID
    let date: Date
    let difficulty: Int
    let soreness: Int
    let enjoyment: Int
    let tensionLevel: Int
    let fatigue: Int
    let energy: Int
    let adherence: Int

    init(
        id: UUID = UUID(),
        routineID: UUID,
        date: Date = .now,
        difficulty: Int,
        soreness: Int,
        enjoyment: Int,
        tensionLevel: Int,
        fatigue: Int,
        energy: Int = 3,
        adherence: Int = 5
    ) {
        self.id = id
        self.routineID = routineID
        self.date = date
        self.difficulty = difficulty
        self.soreness = soreness
        self.enjoyment = enjoyment
        self.tensionLevel = tensionLevel
        self.fatigue = fatigue
        self.energy = energy
        self.adherence = adherence
    }

    var loadSignal: Double {
        let strain = Double(difficulty + soreness + fatigue + tensionLevel) / 20.0
        let lowEnergyPenalty = max(0, 3.0 - Double(energy)) * 0.05
        let enjoymentOffset = (Double(enjoyment) - 3.0) * 0.04
        let adherenceOffset = (Double(adherence) - 3.0) * 0.025
        return min(max(strain + lowEnergyPenalty - enjoymentOffset - adherenceOffset, 0), 1)
    }

    var readinessScore: Double {
        let recovery = 1.0 - loadSignal
        let energyBoost = (Double(energy) - 3.0) * 0.06
        return min(max(recovery + energyBoost, 0.05), 1.0)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case routineID
        case date
        case difficulty
        case soreness
        case enjoyment
        case tensionLevel
        case fatigue
        case energy
        case adherence
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        routineID = try container.decode(UUID.self, forKey: .routineID)
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? .now
        difficulty = try container.decodeIfPresent(Int.self, forKey: .difficulty) ?? 3
        soreness = try container.decodeIfPresent(Int.self, forKey: .soreness) ?? 2
        enjoyment = try container.decodeIfPresent(Int.self, forKey: .enjoyment) ?? 3
        tensionLevel = try container.decodeIfPresent(Int.self, forKey: .tensionLevel) ?? 2
        fatigue = try container.decodeIfPresent(Int.self, forKey: .fatigue) ?? 2
        energy = try container.decodeIfPresent(Int.self, forKey: .energy) ?? 3
        adherence = try container.decodeIfPresent(Int.self, forKey: .adherence) ?? 5
    }
}

struct ProgressSnapshot: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let date: Date
    let completedRoutineID: UUID
    let weekIndex: Int
    let durationSeconds: Int
    let completedExerciseIDs: [String]
    let readinessScore: Double
    let trainingLoadScore: Double
    let consistencyScore: Double

    init(
        id: UUID = UUID(),
        date: Date = .now,
        completedRoutineID: UUID,
        weekIndex: Int,
        durationSeconds: Int,
        completedExerciseIDs: [String],
        readinessScore: Double,
        trainingLoadScore: Double = 0.4,
        consistencyScore: Double = 0.5
    ) {
        self.id = id
        self.date = date
        self.completedRoutineID = completedRoutineID
        self.weekIndex = weekIndex
        self.durationSeconds = durationSeconds
        self.completedExerciseIDs = completedExerciseIDs
        self.readinessScore = readinessScore
        self.trainingLoadScore = trainingLoadScore
        self.consistencyScore = consistencyScore
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case date
        case completedRoutineID
        case weekIndex
        case durationSeconds
        case completedExerciseIDs
        case readinessScore
        case trainingLoadScore
        case consistencyScore
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? .now
        completedRoutineID = try container.decode(UUID.self, forKey: .completedRoutineID)
        weekIndex = try container.decodeIfPresent(Int.self, forKey: .weekIndex) ?? 1
        durationSeconds = try container.decodeIfPresent(Int.self, forKey: .durationSeconds) ?? 0
        completedExerciseIDs = try container.decodeIfPresent([String].self, forKey: .completedExerciseIDs) ?? []
        readinessScore = try container.decodeIfPresent(Double.self, forKey: .readinessScore) ?? 0.76
        trainingLoadScore = try container.decodeIfPresent(Double.self, forKey: .trainingLoadScore) ?? 0.4
        consistencyScore = try container.decodeIfPresent(Double.self, forKey: .consistencyScore) ?? 0.5
    }
}

struct FacialTrainingAdaptationState: Codable, Hashable, Sendable {
    var readinessScore: Double
    var consistencyScore: Double
    var sorenessTrend: Double
    var fatigueTrend: Double
    var energyTrend: Double
    var adherenceTrend: Double
    var recommendedIntensityMultiplier: Double
    var recoveryPressure: Double
    var coachingSummary: String

    static let baseline = FacialTrainingAdaptationState(
        readinessScore: 0.76,
        consistencyScore: 0.5,
        sorenessTrend: 2.0,
        fatigueTrend: 2.0,
        energyTrend: 3.0,
        adherenceTrend: 5.0,
        recommendedIntensityMultiplier: 1.0,
        recoveryPressure: 0.22,
        coachingSummary: "Baseline plan. Calibrate with the first completed sessions."
    )
}

struct FacialTrainingPlan: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var createdAt: Date
    var profile: UserTrainingGoals
    var difficultyTier: FacialDifficultyTier
    var recoverySchedule: String
    var weeks: [TrainingWeek]
    var adaptationMultiplier: Double
    var adaptationState: FacialTrainingAdaptationState
    var lastUpdatedAt: Date

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        profile: UserTrainingGoals,
        difficultyTier: FacialDifficultyTier,
        recoverySchedule: String,
        weeks: [TrainingWeek],
        adaptationMultiplier: Double,
        adaptationState: FacialTrainingAdaptationState = .baseline,
        lastUpdatedAt: Date = .now
    ) {
        self.id = id
        self.createdAt = createdAt
        self.profile = profile
        self.difficultyTier = difficultyTier
        self.recoverySchedule = recoverySchedule
        self.weeks = weeks
        self.adaptationMultiplier = adaptationMultiplier
        self.adaptationState = adaptationState
        self.lastUpdatedAt = lastUpdatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case profile
        case difficultyTier
        case recoverySchedule
        case weeks
        case adaptationMultiplier
        case adaptationState
        case lastUpdatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
        profile = try container.decode(UserTrainingGoals.self, forKey: .profile)
        difficultyTier = try container.decodeIfPresent(FacialDifficultyTier.self, forKey: .difficultyTier) ?? .foundation
        recoverySchedule = try container.decodeIfPresent(String.self, forKey: .recoverySchedule) ?? "Two lower-load recovery days weekly."
        weeks = try container.decodeIfPresent([TrainingWeek].self, forKey: .weeks) ?? []
        adaptationMultiplier = try container.decodeIfPresent(Double.self, forKey: .adaptationMultiplier) ?? profile.experience.intensitySeed
        adaptationState = try container.decodeIfPresent(FacialTrainingAdaptationState.self, forKey: .adaptationState) ?? .baseline
        lastUpdatedAt = try container.decodeIfPresent(Date.self, forKey: .lastUpdatedAt) ?? .now
    }
}

enum FacialTrainingFormat {
    static func time(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%d:%02d", minutes, remainder)
    }

    static func compactMinutes(_ seconds: Int) -> String {
        "\(max(1, Int(ceil(Double(seconds) / 60.0))))m"
    }
}
