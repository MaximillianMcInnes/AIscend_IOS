//
//  FacialTrainingExerciseLibrary.swift
//  AIscend
//
//  Created by Codex on 5/10/26.
//

import Foundation

enum FacialTrainingExerciseLibrary {
    static let weightedNeckCurl = FacialExercise(
        id: "weighted-neck-curl",
        name: "Weighted neck curl",
        category: .neck,
        equipment: [.dumbbells, .neckHarness],
        instructions: [
            "Lie back with the head supported near the edge.",
            "Brace the ribs down and curl the chin toward the upper chest.",
            "Lower under control without letting the head drop."
        ],
        muscleFocus: "Anterior neck, deep neck flexors",
        breathingCue: "Exhale through the curl, nasal inhale on the lower.",
        safetyCue: "Use very light load. Stop for dizziness, headache, nerve symptoms, or neck pain.",
        baseDurationSeconds: 50,
        baseRestSeconds: 35,
        reps: "8-12 controlled reps",
        minWeek: 2,
        intensity: 4,
        animation: ExerciseAnimation(
            pattern: .neckCurl,
            primaryMuscleLabel: "Anterior chain",
            secondaryMuscleLabel: "Deep flexors",
            tempoDescription: "2s curl / 2s lower",
            accent: .dawn
        )
    )

    static let neckExtension = FacialExercise(
        id: "neck-extension",
        name: "Neck extension",
        category: .neck,
        equipment: [.resistanceBands, .neckHarness],
        instructions: [
            "Set the neck long with the chin slightly tucked.",
            "Extend against light resistance without shrugging.",
            "Return to neutral before the next rep."
        ],
        muscleFocus: "Posterior neck, upper cervical control",
        breathingCue: "Keep the breath quiet and nasal.",
        safetyCue: "Avoid aggressive range. Keep eyes level and stop for pinching.",
        baseDurationSeconds: 45,
        baseRestSeconds: 35,
        reps: "8 slow reps",
        minWeek: 3,
        intensity: 4,
        animation: ExerciseAnimation(
            pattern: .neckExtension,
            primaryMuscleLabel: "Posterior chain",
            secondaryMuscleLabel: "Cervical extensors",
            tempoDescription: "Smooth arc to neutral",
            accent: .sky
        )
    )

    static let sideNeckRaise = FacialExercise(
        id: "side-neck-raise",
        name: "Side neck raise",
        category: .neck,
        equipment: [.none, .resistanceBands],
        instructions: [
            "Lie or stand tall with the jaw relaxed.",
            "Raise the ear toward the shoulder in a small clean line.",
            "Pause, then return with control."
        ],
        muscleFocus: "Lateral neck, SCM support",
        breathingCue: "Exhale during the raise, inhale on the return.",
        safetyCue: "No bouncing or end-range forcing. Keep the movement compact.",
        baseDurationSeconds: 50,
        baseRestSeconds: 30,
        reps: "6 each side",
        minWeek: 2,
        intensity: 3,
        animation: ExerciseAnimation(
            pattern: .sideNeckRaise,
            primaryMuscleLabel: "Lateral neck",
            secondaryMuscleLabel: "SCM",
            tempoDescription: "Small lateral raise",
            accent: .mint
        )
    )

    static let deepNeckFlexorHold = FacialExercise(
        id: "deep-neck-flexor-hold",
        name: "Deep neck flexor hold",
        category: .neck,
        equipment: [.none],
        instructions: [
            "Lie down or stand against a wall.",
            "Nod the chin as if making a small double-chin.",
            "Hold the position while the throat stays relaxed."
        ],
        muscleFocus: "Deep neck flexors, cervical stack",
        breathingCue: "Four-second nasal inhale, six-second exhale.",
        safetyCue: "Keep effort at 4 out of 10. Stop if front-neck tension spikes.",
        baseDurationSeconds: 55,
        baseRestSeconds: 25,
        reps: nil,
        minWeek: 1,
        intensity: 2,
        animation: ExerciseAnimation(
            pattern: .deepNeckFlexor,
            primaryMuscleLabel: "Deep flexors",
            secondaryMuscleLabel: "Cervical stack",
            tempoDescription: "Isometric hold",
            accent: .sky
        )
    )

    static let scmBrace = FacialExercise(
        id: "scm-brace",
        name: "SCM brace",
        category: .neck,
        equipment: [.none, .resistanceBands],
        instructions: [
            "Turn the head slightly while keeping the chin level.",
            "Brace gently against two fingers at the jaw angle.",
            "Hold without clenching the teeth."
        ],
        muscleFocus: "SCM, jaw-neck coordination",
        breathingCue: "Long exhale, low-rib control.",
        safetyCue: "Use gentle pressure only. Avoid visible strain or pulsing effort.",
        baseDurationSeconds: 45,
        baseRestSeconds: 25,
        reps: "4 holds each side",
        minWeek: 2,
        intensity: 3,
        animation: ExerciseAnimation(
            pattern: .scmBrace,
            primaryMuscleLabel: "SCM",
            secondaryMuscleLabel: "Jaw angle",
            tempoDescription: "Gently brace and release",
            accent: .dawn
        )
    )

    static let chinTuck = FacialExercise(
        id: "chin-tuck",
        name: "Chin tuck",
        category: .jawHyoid,
        equipment: [.none],
        instructions: [
            "Stand tall with ears stacked over shoulders.",
            "Slide the chin straight back, not down.",
            "Hold briefly, then release without jutting forward."
        ],
        muscleFocus: "Submental control, deep neck flexors",
        breathingCue: "Exhale as the chin glides back.",
        safetyCue: "Small range only. Do not jam the jaw or force the throat.",
        baseDurationSeconds: 55,
        baseRestSeconds: 20,
        reps: "8 clean reps",
        minWeek: 1,
        intensity: 2,
        animation: ExerciseAnimation(
            pattern: .chinTuck,
            primaryMuscleLabel: "Submental line",
            secondaryMuscleLabel: "Deep neck",
            tempoDescription: "Linear glide",
            accent: .sky
        )
    )

    static let tonguePostureHold = FacialExercise(
        id: "tongue-posture-hold",
        name: "Tongue posture hold",
        category: .jawHyoid,
        equipment: [.none],
        instructions: [
            "Rest the tongue broadly against the palate.",
            "Keep teeth lightly apart and lips closed.",
            "Breathe only through the nose."
        ],
        muscleFocus: "Tongue posture, hyoid awareness",
        breathingCue: "Silent nasal breathing with relaxed jaw.",
        safetyCue: "Use light contact. Do not press hard or clench.",
        baseDurationSeconds: 65,
        baseRestSeconds: 20,
        reps: nil,
        minWeek: 1,
        intensity: 1,
        animation: ExerciseAnimation(
            pattern: .tonguePosture,
            primaryMuscleLabel: "Palate contact",
            secondaryMuscleLabel: "Hyoid",
            tempoDescription: "Quiet isometric",
            accent: .mint
        )
    )

    static let hyoidEngagement = FacialExercise(
        id: "hyoid-engagement",
        name: "Hyoid engagement drill",
        category: .jawHyoid,
        equipment: [.none],
        instructions: [
            "Set tongue lightly to the palate.",
            "Make a small swallow-like lift without clenching.",
            "Hold the lifted sensation, then fully release."
        ],
        muscleFocus: "Hyoid, suprahyoid control",
        breathingCue: "Reset with one slow nasal breath after each hold.",
        safetyCue: "No aggressive swallowing or throat squeezing.",
        baseDurationSeconds: 55,
        baseRestSeconds: 25,
        reps: "6 light holds",
        minWeek: 2,
        intensity: 2,
        animation: ExerciseAnimation(
            pattern: .hyoidEngagement,
            primaryMuscleLabel: "Hyoid sling",
            secondaryMuscleLabel: "Lower third",
            tempoDescription: "Lift / hold / release",
            accent: .mint
        )
    )

    static let jawResistance = FacialExercise(
        id: "jaw-resistance",
        name: "Jaw resistance press",
        category: .jawHyoid,
        equipment: [.none],
        instructions: [
            "Place two fingers beneath the chin.",
            "Open slightly into gentle resistance.",
            "Close smoothly with the jaw tracking centered."
        ],
        muscleFocus: "Mandibular control, lower-third tension balance",
        breathingCue: "Exhale through the press, inhale on release.",
        safetyCue: "Skip if you have TMJ pain, clicking, locking, or dental discomfort.",
        baseDurationSeconds: 45,
        baseRestSeconds: 30,
        reps: "5-8 light reps",
        minWeek: 2,
        intensity: 3,
        animation: ExerciseAnimation(
            pattern: .jawResistance,
            primaryMuscleLabel: "Mandible path",
            secondaryMuscleLabel: "Lower third",
            tempoDescription: "Soft resistance",
            accent: .dawn
        )
    )

    static let chewingProtocol = FacialExercise(
        id: "chewing-protocol",
        name: "Chewing protocol",
        category: .jawHyoid,
        equipment: [.chewingGum],
        instructions: [
            "Use soft gum and split work evenly between sides.",
            "Keep posture tall and the tongue relaxed.",
            "Stop before fatigue changes your bite pattern."
        ],
        muscleFocus: "Masseter endurance, symmetry control",
        breathingCue: "Nasal breathing only; slow the pace if breath gets loud.",
        safetyCue: "Do not use hard gum. Skip for TMJ symptoms, dental work, or headaches.",
        baseDurationSeconds: 90,
        baseRestSeconds: 35,
        reps: "45s each side",
        minWeek: 3,
        intensity: 4,
        animation: ExerciseAnimation(
            pattern: .chewingProtocol,
            primaryMuscleLabel: "Masseter",
            secondaryMuscleLabel: "Symmetry",
            tempoDescription: "Even side-to-side work",
            accent: .dawn
        )
    )

    static let wallPostureHold = FacialExercise(
        id: "wall-posture-hold",
        name: "Wall posture hold",
        category: .posture,
        equipment: [.none],
        instructions: [
            "Stand with hips, ribs, and upper back organized.",
            "Float the crown of the head tall.",
            "Keep the jaw loose and the tongue lightly set."
        ],
        muscleFocus: "Cervical stack, rib position, side profile",
        breathingCue: "Slow nasal breathing into the low ribs.",
        safetyCue: "Do not force the head against the wall. Stack gently.",
        baseDurationSeconds: 70,
        baseRestSeconds: 20,
        reps: nil,
        minWeek: 1,
        intensity: 1,
        animation: ExerciseAnimation(
            pattern: .wallPosture,
            primaryMuscleLabel: "Spinal stack",
            secondaryMuscleLabel: "Side profile",
            tempoDescription: "Static alignment",
            accent: .sky
        )
    )

    static let scapularRetraction = FacialExercise(
        id: "scapular-retraction",
        name: "Scapular retraction",
        category: .posture,
        equipment: [.none, .resistanceBands],
        instructions: [
            "Let the shoulders drop away from the ears.",
            "Draw shoulder blades back and slightly down.",
            "Hold without flaring the ribs."
        ],
        muscleFocus: "Mid traps, upper back, neck positioning",
        breathingCue: "Exhale as the shoulder blades set.",
        safetyCue: "Avoid shrugging. Keep the neck quiet.",
        baseDurationSeconds: 55,
        baseRestSeconds: 25,
        reps: "10 slow reps",
        minWeek: 1,
        intensity: 2,
        animation: ExerciseAnimation(
            pattern: .scapularRetraction,
            primaryMuscleLabel: "Mid traps",
            secondaryMuscleLabel: "Shoulder line",
            tempoDescription: "Back / down / release",
            accent: .mint
        )
    )

    static let thoracicExtension = FacialExercise(
        id: "thoracic-extension",
        name: "Thoracic extension",
        category: .posture,
        equipment: [.none],
        instructions: [
            "Interlace hands behind the head.",
            "Extend gently through the upper back.",
            "Keep the chin slightly tucked."
        ],
        muscleFocus: "Thoracic spine, neck posture",
        breathingCue: "Inhale into extension, exhale to settle.",
        safetyCue: "Move through the upper back, not the low back.",
        baseDurationSeconds: 55,
        baseRestSeconds: 25,
        reps: "6 extensions",
        minWeek: 1,
        intensity: 2,
        animation: ExerciseAnimation(
            pattern: .thoracicExtension,
            primaryMuscleLabel: "Thoracic spine",
            secondaryMuscleLabel: "Neck stack",
            tempoDescription: "Open and reset",
            accent: .sky
        )
    )

    static let breathingReset = FacialExercise(
        id: "breathing-reset",
        name: "Breathing reset",
        category: .recovery,
        equipment: [.none],
        instructions: [
            "Close the lips and rest the tongue lightly.",
            "Inhale through the nose for four seconds.",
            "Exhale for six seconds and let the jaw soften."
        ],
        muscleFocus: "Recovery, jaw relaxation, parasympathetic downshift",
        breathingCue: "Four in, six out, no breath holding.",
        safetyCue: "Return to normal breathing if lightheaded.",
        baseDurationSeconds: 70,
        baseRestSeconds: 15,
        reps: nil,
        minWeek: 1,
        intensity: 1,
        animation: ExerciseAnimation(
            pattern: .breathingReset,
            primaryMuscleLabel: "Breath rhythm",
            secondaryMuscleLabel: "Jaw release",
            tempoDescription: "4:6 nasal cadence",
            accent: .mint
        )
    )

    static let facialRelaxation = FacialExercise(
        id: "facial-relaxation",
        name: "Facial relaxation",
        category: .recovery,
        equipment: [.none],
        instructions: [
            "Release forehead, eye area, jaw, and tongue in sequence.",
            "Let the teeth separate.",
            "Hold a tall, quiet posture."
        ],
        muscleFocus: "Masseter, temporalis, eye area tension",
        breathingCue: "Exhale as each zone releases.",
        safetyCue: "No stretching or force. This is a downshift.",
        baseDurationSeconds: 60,
        baseRestSeconds: 15,
        reps: nil,
        minWeek: 1,
        intensity: 1,
        animation: ExerciseAnimation(
            pattern: .facialRelaxation,
            primaryMuscleLabel: "Facial tension",
            secondaryMuscleLabel: "Eye area",
            tempoDescription: "Sequential release",
            accent: .mint
        )
    )

    static let lymphaticMassage = FacialExercise(
        id: "lymphatic-massage",
        name: "Lymphatic massage guidance",
        category: .recovery,
        equipment: [.none],
        instructions: [
            "Use feather-light pressure below the jaw.",
            "Sweep from chin toward the ear and down the side neck.",
            "Keep strokes slow and symmetrical."
        ],
        muscleFocus: "Recovery, submental area, facial fluid movement",
        breathingCue: "Exhale during each sweep.",
        safetyCue: "Avoid swollen, painful, or irritated areas. Pressure should be light.",
        baseDurationSeconds: 75,
        baseRestSeconds: 15,
        reps: "5 sweeps each side",
        minWeek: 1,
        intensity: 1,
        animation: ExerciseAnimation(
            pattern: .lymphaticMassage,
            primaryMuscleLabel: "Submental path",
            secondaryMuscleLabel: "Side neck",
            tempoDescription: "Slow directional sweep",
            accent: .mint
        )
    )

    static let all: [FacialExercise] = [
        weightedNeckCurl,
        neckExtension,
        sideNeckRaise,
        deepNeckFlexorHold,
        scmBrace,
        chinTuck,
        tonguePostureHold,
        hyoidEngagement,
        jawResistance,
        chewingProtocol,
        wallPostureHold,
        scapularRetraction,
        thoracicExtension,
        breathingReset,
        facialRelaxation,
        lymphaticMassage
    ]

    static func available(for profile: UserTrainingGoals, week: Int) -> [FacialExercise] {
        all.filter { exercise in
            guard exercise.minWeek <= week else {
                return false
            }

            guard !exercise.equipment.isEmpty else {
                return true
            }

            if exercise.equipment.contains(.none) {
                return true
            }

            return exercise.equipment.contains { profile.equipment.contains($0) }
        }
    }
}
