//
//  JawTrainingModels.swift
//  AIscend
//
//  Created by Codex on 5/7/26.
//

import Foundation

enum JawTrainingGoal: String, CaseIterable, Codable, Identifiable {
    case jawlineDefinition
    case posture
    case reduceTension
    case consistency

    var id: String { rawValue }

    var title: String {
        switch self {
        case .jawlineDefinition:
            "Jawline definition"
        case .posture:
            "Posture"
        case .reduceTension:
            "Reduce tension"
        case .consistency:
            "Consistency"
        }
    }

    var detail: String {
        switch self {
        case .jawlineDefinition:
            "Low-intensity engagement and awareness work."
        case .posture:
            "Neck position, tongue posture, and alignment resets."
        case .reduceTension:
            "Gentle mobility and relaxation reminders."
        case .consistency:
            "A short plan that is easy to repeat daily."
        }
    }

    var symbol: String {
        switch self {
        case .jawlineDefinition:
            "diamond.fill"
        case .posture:
            "figure.stand"
        case .reduceTension:
            "hand.raised.fill"
        case .consistency:
            "flame.fill"
        }
    }
}

enum JawTrainingExperience: String, CaseIterable, Codable, Identifiable {
    case beginner
    case intermediate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beginner:
            "Beginner"
        case .intermediate:
            "Intermediate"
        }
    }
}

enum JawExerciseDifficulty: String, Codable, CaseIterable {
    case easy
    case moderate

    var title: String {
        switch self {
        case .easy:
            "Easy"
        case .moderate:
            "Moderate"
        }
    }
}

enum JawExerciseMovementPattern: String, Codable {
    case chinTuck
    case tongueHold
    case jawOpenClose
    case neckReset
    case massage
    case sideStretch
    case resistancePress
}

struct JawExercise: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let targetArea: String
    let durationSeconds: Int
    let reps: String?
    let difficulty: JawExerciseDifficulty
    let safetyNotes: String
    let movementPattern: JawExerciseMovementPattern
    let accent: RoutineAccent

    var durationLabel: String {
        if let reps {
            return reps
        }

        if durationSeconds >= 60 {
            let minutes = durationSeconds / 60
            let seconds = durationSeconds % 60
            return seconds == 0 ? "\(minutes) min" : "\(minutes)m \(seconds)s"
        }

        return "\(durationSeconds)s"
    }
}

struct JawTrainingPlan: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let subtitle: String
    let durationMinutes: Int
    let difficulty: JawExerciseDifficulty
    let exercises: [JawExercise]
    let accent: RoutineAccent
    let isCustom: Bool

    var totalSeconds: Int {
        exercises.reduce(0) { $0 + $1.durationSeconds }
    }

    var exerciseCountLabel: String {
        exercises.count == 1 ? "1 move" : "\(exercises.count) moves"
    }
}

struct JawTrainingCompletion: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let planID: String
    let planName: String
    let durationMinutes: Int

    init(
        id: UUID = UUID(),
        date: Date,
        planID: String,
        planName: String,
        durationMinutes: Int
    ) {
        self.id = id
        self.date = date
        self.planID = planID
        self.planName = planName
        self.durationMinutes = durationMinutes
    }
}

struct JawWeeklyProgressDay: Identifiable, Hashable {
    let id: String
    let date: Date
    let weekday: String
    let isCompleted: Bool
}

enum JawExerciseLibrary {
    static let chinTuckHold = JawExercise(
        id: "chin-tuck-hold",
        name: "Chin tuck hold",
        description: "Slide the chin straight back and keep the neck tall without forcing the jaw.",
        targetArea: "Deep neck flexors",
        durationSeconds: 45,
        reps: nil,
        difficulty: .easy,
        safetyNotes: "Keep the movement small. Stop if you feel dizziness, headache, jaw clicking, or neck pain.",
        movementPattern: .chinTuck,
        accent: .sky
    )

    static let tonguePostureHold = JawExercise(
        id: "tongue-posture-hold",
        name: "Tongue posture hold",
        description: "Rest the tongue gently on the roof of the mouth while breathing through the nose.",
        targetArea: "Tongue posture",
        durationSeconds: 50,
        reps: nil,
        difficulty: .easy,
        safetyNotes: "Use light contact only. Do not clench the teeth or press hard into the palate.",
        movementPattern: .tongueHold,
        accent: .mint
    )

    static let controlledJawOpenClose = JawExercise(
        id: "controlled-jaw-open-close",
        name: "Controlled jaw open/close",
        description: "Open and close slowly while keeping the motion smooth and centered.",
        targetArea: "Jaw control",
        durationSeconds: 60,
        reps: "6 slow reps",
        difficulty: .easy,
        safetyNotes: "Stay in a pain-free range. Stop if you notice clicking, locking, or TMJ discomfort.",
        movementPattern: .jawOpenClose,
        accent: .sky
    )

    static let neckPostureReset = JawExercise(
        id: "neck-posture-reset",
        name: "Neck posture reset",
        description: "Stack ears over shoulders, soften the ribs, and hold a tall neutral neck.",
        targetArea: "Neck alignment",
        durationSeconds: 45,
        reps: nil,
        difficulty: .easy,
        safetyNotes: "Avoid forcing the head backward. Keep breathing slow and easy.",
        movementPattern: .neckReset,
        accent: .mint
    )

    static let masseterRelaxation = JawExercise(
        id: "masseter-relaxation",
        name: "Masseter relaxation reminder",
        description: "Use light fingertip circles on the jaw muscle and release any clenching.",
        targetArea: "Jaw tension awareness",
        durationSeconds: 60,
        reps: nil,
        difficulty: .easy,
        safetyNotes: "Use gentle pressure only. Skip tender spots and stop if discomfort increases.",
        movementPattern: .massage,
        accent: .dawn
    )

    static let sideNeckStretch = JawExercise(
        id: "side-neck-stretch",
        name: "Side neck stretch",
        description: "Let one ear drift toward the shoulder and keep the opposite shoulder relaxed.",
        targetArea: "Side neck",
        durationSeconds: 60,
        reps: "30s each side",
        difficulty: .easy,
        safetyNotes: "No pulling or bouncing. Stop if you feel tingling, pain, or dizziness.",
        movementPattern: .sideStretch,
        accent: .mint
    )

    static let gentleResistancePress = JawExercise(
        id: "gentle-resistance-jaw-press",
        name: "Slow resistance jaw press",
        description: "Place two fingers under the chin and press very gently while the jaw stays relaxed.",
        targetArea: "Light jaw engagement",
        durationSeconds: 45,
        reps: "5 gentle presses",
        difficulty: .moderate,
        safetyNotes: "Very gentle only. Do not clench, strain, or push through TMJ discomfort.",
        movementPattern: .resistancePress,
        accent: .sky
    )

    static let all: [JawExercise] = [
        chinTuckHold,
        tonguePostureHold,
        controlledJawOpenClose,
        neckPostureReset,
        masseterRelaxation,
        sideNeckStretch,
        gentleResistancePress
    ]
}

enum JawTrainingPlanLibrary {
    static let beginner = JawTrainingPlan(
        id: "beginner-plan",
        name: "Beginner Plan",
        subtitle: "A short foundation for posture, breathing, and gentle jaw control.",
        durationMinutes: 3,
        difficulty: .easy,
        exercises: [
            JawExerciseLibrary.neckPostureReset,
            JawExerciseLibrary.chinTuckHold,
            JawExerciseLibrary.tonguePostureHold,
            JawExerciseLibrary.controlledJawOpenClose
        ],
        accent: .sky,
        isCustom: false
    )

    static let postureReset = JawTrainingPlan(
        id: "posture-reset-plan",
        name: "Posture Reset Plan",
        subtitle: "Neck stacking, tongue posture, and tension awareness after long screen sessions.",
        durationMinutes: 5,
        difficulty: .easy,
        exercises: [
            JawExerciseLibrary.neckPostureReset,
            JawExerciseLibrary.chinTuckHold,
            JawExerciseLibrary.sideNeckStretch,
            JawExerciseLibrary.tonguePostureHold,
            JawExerciseLibrary.masseterRelaxation
        ],
        accent: .mint,
        isCustom: false
    )

    static let definitionConsistency = JawTrainingPlan(
        id: "definition-consistency-plan",
        name: "Definition & Consistency Plan",
        subtitle: "Low-intensity engagement and tracking without extreme chewing or strain.",
        durationMinutes: 8,
        difficulty: .moderate,
        exercises: [
            JawExerciseLibrary.neckPostureReset,
            JawExerciseLibrary.tonguePostureHold,
            JawExerciseLibrary.controlledJawOpenClose,
            JawExerciseLibrary.gentleResistancePress,
            JawExerciseLibrary.chinTuckHold,
            JawExerciseLibrary.masseterRelaxation
        ],
        accent: .sky,
        isCustom: false
    )

    static let predefined: [JawTrainingPlan] = [
        beginner,
        postureReset,
        definitionConsistency
    ]

    static func plan(goal: JawTrainingGoal, availableMinutes: Int, experience: JawTrainingExperience) -> JawTrainingPlan {
        let baseExercises: [JawExercise]
        let accent: RoutineAccent
        let subtitle: String

        switch goal {
        case .jawlineDefinition:
            baseExercises = [
                JawExerciseLibrary.neckPostureReset,
                JawExerciseLibrary.tonguePostureHold,
                JawExerciseLibrary.controlledJawOpenClose,
                JawExerciseLibrary.gentleResistancePress,
                JawExerciseLibrary.chinTuckHold,
                JawExerciseLibrary.masseterRelaxation
            ]
            accent = .sky
            subtitle = "Gentle engagement, posture control, and repeatable tracking."
        case .posture:
            baseExercises = [
                JawExerciseLibrary.neckPostureReset,
                JawExerciseLibrary.chinTuckHold,
                JawExerciseLibrary.sideNeckStretch,
                JawExerciseLibrary.tonguePostureHold,
                JawExerciseLibrary.masseterRelaxation
            ]
            accent = .mint
            subtitle = "A clean reset for screen posture and facial tension awareness."
        case .reduceTension:
            baseExercises = [
                JawExerciseLibrary.masseterRelaxation,
                JawExerciseLibrary.sideNeckStretch,
                JawExerciseLibrary.neckPostureReset,
                JawExerciseLibrary.controlledJawOpenClose,
                JawExerciseLibrary.tonguePostureHold
            ]
            accent = .dawn
            subtitle = "Gentle reminders to unclench and move through a comfortable range."
        case .consistency:
            baseExercises = [
                JawExerciseLibrary.neckPostureReset,
                JawExerciseLibrary.tonguePostureHold,
                JawExerciseLibrary.chinTuckHold,
                JawExerciseLibrary.masseterRelaxation
            ]
            accent = .sky
            subtitle = "Short enough to repeat, structured enough to count."
        }

        let targetSeconds = availableMinutes * 60
        var selected: [JawExercise] = []
        var runningSeconds = 0

        for exercise in baseExercises {
            guard selected.isEmpty || runningSeconds + exercise.durationSeconds <= targetSeconds + 45 else {
                continue
            }

            if experience == .beginner && exercise.difficulty == .moderate && availableMinutes < 8 {
                continue
            }

            selected.append(exercise)
            runningSeconds += exercise.durationSeconds
        }

        if selected.isEmpty {
            selected = [
                JawExerciseLibrary.neckPostureReset,
                JawExerciseLibrary.tonguePostureHold,
                JawExerciseLibrary.masseterRelaxation
            ]
        }

        return JawTrainingPlan(
            id: "built-\(goal.rawValue)-\(availableMinutes)-\(experience.rawValue)",
            name: "Built \(goal.title) Plan",
            subtitle: subtitle,
            durationMinutes: max(1, Int(ceil(Double(selected.reduce(0) { $0 + $1.durationSeconds }) / 60.0))),
            difficulty: experience == .beginner ? .easy : .moderate,
            exercises: selected,
            accent: accent,
            isCustom: true
        )
    }
}
