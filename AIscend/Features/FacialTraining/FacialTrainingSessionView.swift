//
//  FacialTrainingSessionView.swift
//  AIscend
//
//  Created by Codex on 5/10/26.
//

import SwiftUI

struct FacialTrainingSessionView: View {
    let routine: FacialRoutine
    @ObservedObject var store: FacialTrainingStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0
    @State private var elapsed = 0
    @State private var phase: FacialSessionPhase = .exercise
    @State private var isPaused = false
    @State private var dragTranslation: CGFloat = 0
    @State private var lastCountdownPulse: Int?
    @State private var completionScore = 0
    @State private var completionXP = 0
    @State private var difficulty = 3.0
    @State private var soreness = 2.0
    @State private var enjoyment = 4.0
    @State private var tension = 2.0
    @State private var fatigue = 2.0
    @State private var energy = 3.0
    @State private var adherence = 5.0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var currentPrescription: FacialExercisePrescription {
        routine.prescriptions[min(index, routine.prescriptions.count - 1)]
    }

    private var nextPrescription: FacialExercisePrescription? {
        let nextIndex = index + 1
        guard routine.prescriptions.indices.contains(nextIndex) else {
            return nil
        }
        return routine.prescriptions[nextIndex]
    }

    private var phaseDuration: Int {
        switch phase {
        case .exercise:
            currentPrescription.durationSeconds
        case .rest:
            currentPrescription.restSeconds
        case .feedback, .complete:
            1
        }
    }

    private var phaseProgress: Double {
        guard phaseDuration > 0 else {
            return 1
        }
        return min(Double(elapsed) / Double(phaseDuration), 1)
    }

    private var remainingSeconds: Int {
        max(phaseDuration - elapsed, 0)
    }

    private var totalProgress: Double {
        guard routine.estimatedDurationSeconds > 0 else {
            return 1
        }

        let completedSeconds = routine.prescriptions.prefix(index).reduce(0) { partial, prescription in
            partial + prescription.durationSeconds + prescription.restSeconds
        }
        let currentSeconds = phase == .rest ? currentPrescription.durationSeconds + elapsed : elapsed
        return min(Double(completedSeconds + currentSeconds) / Double(routine.estimatedDurationSeconds), 1)
    }

    private var currentVoiceCue: FacialVoiceCue {
        if phase == .rest {
            return FacialVoiceCue(
                timing: .rest,
                text: "Recover. Nasal breath. Jaw loose. Next block stays controlled.",
                offsetSeconds: elapsed
            )
        }

        if remainingSeconds <= 10 {
            return FacialVoiceCue(
                timing: .finalTen,
                text: "Final ten. Keep the line clean and leave reserve.",
                offsetSeconds: elapsed
            )
        }

        if elapsed >= max(currentPrescription.durationSeconds / 2, 1) {
            return FacialVoiceCue(
                timing: .midpoint,
                text: currentPrescription.exercise.breathingCue,
                offsetSeconds: elapsed
            )
        }

        return FacialVoiceCue(
            timing: .intro,
            text: currentPrescription.coachingCue,
            offsetSeconds: 0
        )
    }

    var body: some View {
        ZStack {
            FacialTrainingImmersiveBackground(
                accent: phase == .rest ? .mint : currentPrescription.exercise.animation.accent,
                progress: totalProgress,
                dimmed: phase == .feedback || phase == .complete
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    header
                    playerCard
                    cueStack
                    upcomingCard
                    controls
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, AIscendTheme.Spacing.xxLarge)
            }
            .scrollDisabled(abs(dragTranslation) > 30)
        }
        .overlay {
            if phase == .feedback {
                feedbackOverlay
            } else if phase == .complete {
                completionOverlay
            }
        }
        .gesture(sessionSwipeGesture)
        .onReceive(timer) { _ in
            tick()
        }
        .animation(AIscendTheme.Motion.reveal, value: index)
        .animation(AIscendTheme.Motion.reveal, value: phase)
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                AIscendBadge(title: phase == .rest ? "Rest interval" : "Live session", symbol: phase == .rest ? "timer" : "play.fill", style: .accent)

                Text(routine.title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text("Week \(routine.weekIndex) / \(index + 1) of \(routine.prescriptions.count) / \(Int(totalProgress * 100))%")
                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                    .monospacedDigit()

                FacialTrainingSessionProgressStrip(
                    count: routine.prescriptions.count,
                    activeIndex: index,
                    progress: totalProgress
                )
            }

            Spacer(minLength: 0)

            AIscendTopBarButton(symbol: "xmark", highlighted: false) {
                dismiss()
            }
            .accessibilityLabel("Close session")
        }
    }

    private var playerCard: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            ExerciseAnimationView(
                animation: currentPrescription.exercise.animation,
                progress: phase == .exercise ? phaseProgress : 1,
                parallax: dragTranslation
            )
            .id(currentPrescription.id)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.98)),
                removal: .move(edge: .leading).combined(with: .opacity).combined(with: .scale(scale: 0.98))
            ))

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: AIscendTheme.Spacing.large) {
                    SessionTimerRing(
                        progress: phaseProgress,
                        remainingSeconds: remainingSeconds,
                        accent: phase == .rest ? .mint : currentPrescription.exercise.animation.accent
                    )
                    sessionCopy
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    HStack {
                        Spacer(minLength: 0)
                        SessionTimerRing(
                            progress: phaseProgress,
                            remainingSeconds: remainingSeconds,
                            accent: phase == .rest ? .mint : currentPrescription.exercise.animation.accent
                        )
                        Spacer(minLength: 0)
                    }
                    sessionCopy
                }
            }

            sessionHUD
        }
        .padding(AIscendTheme.Spacing.large)
        .background(FacialTrainingLuxuryPanel())
        .scaleEffect(isPaused ? 0.985 : 1)
        .blur(radius: isPaused ? 0.4 : 0)
    }

    private var sessionHUD: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AIscendTheme.Spacing.small) {
                FacialTrainingHUDTile(title: "Reps", value: currentPrescription.reps ?? "Hold", symbol: "repeat", accent: .dawn)
                FacialTrainingHUDTile(title: "Level", value: difficultyLabel, symbol: "dial.low.fill", accent: .sky)
                FacialTrainingHUDTile(title: "Voice", value: currentVoiceCue.timing.title, symbol: "waveform", accent: .mint)
            }

            VStack(spacing: AIscendTheme.Spacing.small) {
                FacialTrainingHUDTile(title: "Reps", value: currentPrescription.reps ?? "Hold", symbol: "repeat", accent: .dawn)
                FacialTrainingHUDTile(title: "Level", value: difficultyLabel, symbol: "dial.low.fill", accent: .sky)
                FacialTrainingHUDTile(title: "Voice", value: currentVoiceCue.timing.title, symbol: "waveform", accent: .mint)
            }
        }
    }

    private var sessionCopy: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            Text(phase == .rest ? "Recover" : currentPrescription.exercise.category.title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

            Text(phase == .rest ? "Rest and reset" : currentPrescription.exercise.name)
                .aiscendTextStyle(.sectionTitle, color: AIscendTheme.Colors.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text(phase == .rest ? restCopy : currentPrescription.coachingCue)
                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if phase == .exercise {
                Text(currentPrescription.doseLabel)
                    .aiscendTextStyle(.caption, color: currentPrescription.exercise.animation.accent.tint)
                    .monospacedDigit()
            }
        }
    }

    private var difficultyLabel: String {
        switch currentPrescription.exercise.intensity {
        case 0...1:
            "Low"
        case 2...3:
            "Controlled"
        default:
            "Loaded"
        }
    }

    private var cueStack: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            FacialTrainingCueRow(title: "Muscle focus", value: currentPrescription.exercise.muscleFocus, symbol: "scope", accent: .sky)
            FacialTrainingCueRow(title: "Breathing cue", value: currentPrescription.exercise.breathingCue, symbol: "wind", accent: .mint)
            FacialTrainingCueRow(title: "Progression logic", value: currentPrescription.progressionCue, symbol: "chart.line.uptrend.xyaxis", accent: .sky)
            FacialTrainingCueRow(title: "Voice cue architecture", value: currentVoiceCue.text, symbol: "waveform.circle.fill", accent: .dawn)
            FacialTrainingCueRow(title: "Safety", value: currentPrescription.exercise.safetyCue, symbol: "exclamationmark.shield.fill", accent: .dawn)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                Text("Instructions")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                ForEach(Array(currentPrescription.exercise.instructions.enumerated()), id: \.offset) { pair in
                    HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
                        Text("\(pair.offset + 1)")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(currentPrescription.exercise.animation.accent.tint.opacity(0.22)))
                        Text(pair.element)
                            .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                    }
                }
            }
            .padding(AIscendTheme.Spacing.large)
            .aiscendPanel(.standard)
        }
    }

    @ViewBuilder
    private var upcomingCard: some View {
        if let nextPrescription {
            HStack(spacing: AIscendTheme.Spacing.medium) {
                AIscendIconOrb(symbol: "forward.fill", accent: nextPrescription.exercise.animation.accent, size: 42)
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                    Text("Next")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                    Text(nextPrescription.exercise.name)
                        .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
                    Text("\(nextPrescription.doseLabel) / rest \(nextPrescription.restSeconds)s")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(AIscendTheme.Spacing.large)
            .aiscendPanel(.standard)
        }
    }

    private var controls: some View {
        VStack(spacing: AIscendTheme.Spacing.small) {
            Button {
                withAnimation(AIscendTheme.Motion.reveal) {
                    isPaused.toggle()
                }
            } label: {
                AIscendButtonLabel(title: isPaused ? "Resume" : "Pause", leadingSymbol: isPaused ? "play.fill" : "pause.fill")
            }
            .buttonStyle(AIscendButtonStyle(variant: isPaused ? .primary : .secondary))

            Button {
                advanceManually()
            } label: {
                AIscendButtonLabel(title: phase == .rest ? "Skip Rest" : "Skip Exercise", trailingSymbol: "forward.fill")
            }
            .buttonStyle(AIscendButtonStyle(variant: .ghost))
        }
    }

    private var feedbackOverlay: some View {
        ZStack {
            AIscendTheme.Colors.overlayDark
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        AIscendBadge(title: "Adaptive feedback", symbol: "slider.horizontal.3", style: .accent)
                        Text("Calibrate tomorrow")
                            .aiscendTextStyle(.sectionTitle, color: AIscendTheme.Colors.textPrimary)
                        Text("Your next sessions adjust volume, rest, and progression pace from these signals.")
                            .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                    }

                    FacialFeedbackSlider(title: "Difficulty", value: $difficulty)
                    FacialFeedbackSlider(title: "Soreness", value: $soreness)
                    FacialFeedbackSlider(title: "Enjoyment", value: $enjoyment)
                    FacialFeedbackSlider(title: "Energy", value: $energy)
                    FacialFeedbackSlider(title: "Adherence", value: $adherence)
                    FacialFeedbackSlider(title: "Tension level", value: $tension)
                    FacialFeedbackSlider(title: "Fatigue", value: $fatigue)

                    Button {
                        submitFeedback()
                    } label: {
                        AIscendButtonLabel(title: "Save Session", leadingSymbol: "checkmark.seal.fill")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .primary))
                }
                .padding(AIscendTheme.Spacing.xLarge)
                .frame(maxWidth: 420)
                .background(FacialTrainingLuxuryPanel())
                .padding(AIscendTheme.Spacing.screenInset)
            }
        }
    }

    private var completionOverlay: some View {
        ZStack {
            AIscendTheme.Colors.overlayDark
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AIscendTheme.Spacing.large) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        AIscendTheme.Colors.accentAmber.opacity(0.28),
                                        AIscendTheme.Colors.accentGlow.opacity(0.12),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 6,
                                    endRadius: 128
                                )
                            )
                            .frame(width: 168, height: 168)

                        VStack(spacing: AIscendTheme.Spacing.xxSmall) {
                            Text("\(completionScore)")
                                .font(.system(size: 54, weight: .bold, design: .rounded))
                                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                                .monospacedDigit()

                            Text("session score")
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                        }
                    }

                    VStack(spacing: AIscendTheme.Spacing.xSmall) {
                        Text("Session locked")
                            .aiscendTextStyle(.sectionTitle, color: AIscendTheme.Colors.textPrimary)

                        Text("Progress saved. Your next blocks now account for soreness, difficulty, energy, adherence, tension, and fatigue.")
                            .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: AIscendTheme.Spacing.small) {
                            FacialCompletionMetric(title: "Streak", value: "\(store.currentStreak)d", symbol: "flame.fill", accent: .dawn)
                            FacialCompletionMetric(title: "XP", value: "+\(completionXP)", symbol: "bolt.fill", accent: .sky)
                            FacialCompletionMetric(title: "Readiness", value: "\(Int(store.latestReadinessScore * 100))%", symbol: "gauge.with.dots.needle.50percent", accent: .mint)
                        }

                        VStack(spacing: AIscendTheme.Spacing.small) {
                            FacialCompletionMetric(title: "Streak", value: "\(store.currentStreak)d", symbol: "flame.fill", accent: .dawn)
                            FacialCompletionMetric(title: "XP", value: "+\(completionXP)", symbol: "bolt.fill", accent: .sky)
                            FacialCompletionMetric(title: "Readiness", value: "\(Int(store.latestReadinessScore * 100))%", symbol: "gauge.with.dots.needle.50percent", accent: .mint)
                        }
                    }

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                        FacialTrainingCueRow(title: "Recovery recommendation", value: recoveryRecommendation, symbol: "bed.double.fill", accent: .mint)

                        if let next = store.nextRoutine(after: routine) {
                            FacialTrainingCueRow(
                                title: "Next session preview",
                                value: "\(next.title) / \(next.estimatedMinutes)m / \(next.prescriptions.count) movements",
                                symbol: "forward.end.fill",
                                accent: .sky
                            )
                        }
                    }

                    Button {
                        dismiss()
                    } label: {
                        AIscendButtonLabel(title: "Return to Facial Training", leadingSymbol: "arrow.down.right.and.arrow.up.left")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .primary))
                }
                .padding(AIscendTheme.Spacing.xLarge)
                .frame(maxWidth: 420)
                .background(FacialTrainingLuxuryPanel())
                .padding(AIscendTheme.Spacing.screenInset)
            }
        }
    }

    private var restCopy: String {
        "Nasal breathing only. Let the jaw soften, keep the tongue light, and leave reserve for the next block."
    }

    private var recoveryRecommendation: String {
        let strain = difficulty + soreness + fatigue + tension
        if strain >= 15 {
            return "Run tomorrow as a lower-load recovery day. Favor breathing, facial relaxation, and posture work."
        }

        if soreness >= 4 || tension >= 4 || energy <= 2 {
            return "Keep chewing and loaded neck work out of the next session unless symptoms settle."
        }

        if enjoyment >= 4 && difficulty <= 3 && adherence >= 4 {
            return "You are cleared for normal progression. Keep the same calm tempo and precise range."
        }

        return "Hydrate, keep nasal breathing quiet, and leave at least one high-quality recovery block before overload."
    }

    private var sessionSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 28, coordinateSpace: .local)
            .onChanged { value in
                guard phase == .exercise || phase == .rest else {
                    return
                }
                dragTranslation = value.translation.width
            }
            .onEnded { value in
                defer {
                    withAnimation(AIscendTheme.Motion.reveal) {
                        dragTranslation = 0
                    }
                }

                guard phase == .exercise || phase == .rest else {
                    return
                }

                if value.translation.width < -72 {
                    advanceManually()
                } else if value.translation.width > 72 {
                    goBack()
                }
            }
    }

    private func tick() {
        guard !isPaused, phase == .exercise || phase == .rest, routine.prescriptions.isEmpty == false else {
            return
        }

        if elapsed + 1 >= phaseDuration {
            advanceManually()
        } else {
            let nextElapsed = elapsed + 1
            elapsed = nextElapsed
            pulseCountdownIfNeeded(remaining: max(phaseDuration - nextElapsed, 0))
        }
    }

    private func advanceManually() {
        guard phase == .exercise || phase == .rest else {
            return
        }

        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        lastCountdownPulse = nil

        if phase == .exercise, currentPrescription.restSeconds > 0, index < routine.prescriptions.count - 1 {
            withAnimation(AIscendTheme.Motion.reveal) {
                phase = .rest
                elapsed = 0
            }
            return
        }

        if index < routine.prescriptions.count - 1 {
            withAnimation(AIscendTheme.Motion.reveal) {
                index += 1
                phase = .exercise
                elapsed = 0
            }
        } else {
            withAnimation(AIscendTheme.Motion.reveal) {
                isPaused = true
                phase = .feedback
                elapsed = 0
            }
        }
    }

    private func goBack() {
        guard phase == .exercise || phase == .rest else {
            return
        }

        UISelectionFeedbackGenerator().selectionChanged()
        lastCountdownPulse = nil

        if phase == .rest {
            withAnimation(AIscendTheme.Motion.reveal) {
                phase = .exercise
                elapsed = max(currentPrescription.durationSeconds - 5, 0)
            }
            return
        }

        guard index > 0 else {
            return
        }

        withAnimation(AIscendTheme.Motion.reveal) {
            index -= 1
            phase = .exercise
            elapsed = 0
        }
    }

    private func pulseCountdownIfNeeded(remaining: Int) {
        guard remaining <= 3, remaining > 0, remaining != lastCountdownPulse else {
            return
        }

        lastCountdownPulse = remaining
        UIImpactFeedbackGenerator(style: remaining == 1 ? .medium : .light).impactOccurred()
    }

    private func submitFeedback() {
        let feedback = SessionFeedback(
            routineID: routine.id,
            difficulty: Int(difficulty.rounded()),
            soreness: Int(soreness.rounded()),
            enjoyment: Int(enjoyment.rounded()),
            tensionLevel: Int(tension.rounded()),
            fatigue: Int(fatigue.rounded()),
            energy: Int(energy.rounded()),
            adherence: Int(adherence.rounded())
        )
        completionScore = sessionScore(for: feedback)
        completionXP = max(35, completionScore + routine.prescriptions.count * 5)
        store.recordCompletion(routine: routine, feedback: feedback)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(AIscendTheme.Motion.reveal) {
            phase = .complete
        }
    }

    private func sessionScore(for feedback: SessionFeedback) -> Int {
        let completion = 42.0
        let enjoymentBonus = Double(feedback.enjoyment) * 5.0
        let energyBonus = Double(feedback.energy) * 4.0
        let adherenceBonus = Double(feedback.adherence) * 3.0
        let controlBonus = max(0, 6.0 - Double(feedback.difficulty)) * 5.0
        let recoveryPenalty = Double(feedback.soreness + feedback.fatigue + feedback.tensionLevel) * 3.0
        let score = completion + enjoymentBonus + energyBonus + adherenceBonus + controlBonus - recoveryPenalty + Double(routine.prescriptions.count * 4)
        return Int(score.rounded()).clamped(to: 42...98)
    }
}

private enum FacialSessionPhase: Equatable {
    case exercise
    case rest
    case feedback
    case complete
}

private struct FacialTrainingImmersiveBackground: View {
    let accent: RoutineAccent
    let progress: Double
    let dimmed: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 0.8 : 1.0 / 30.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let drift = reduceMotion ? 0 : sin(time * 0.18)
            let counter = reduceMotion ? 0 : cos(time * 0.14)

            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "050608"),
                        Color(hex: "0B0D13"),
                        AIscendTheme.Colors.secondaryBackground.opacity(0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [
                        accent.tint.opacity(dimmed ? 0.08 : 0.22),
                        accent.tint.opacity(dimmed ? 0.04 : 0.08),
                        .clear
                    ],
                    center: UnitPoint(x: 0.22 + drift * 0.08, y: 0.16 + counter * 0.05),
                    startRadius: 8,
                    endRadius: 360
                )

                RadialGradient(
                    colors: [
                        AIscendTheme.Colors.accentGlow.opacity(dimmed ? 0.05 : 0.14),
                        .clear
                    ],
                    center: UnitPoint(x: 0.78 + counter * 0.08, y: 0.72 + drift * 0.05),
                    startRadius: 18,
                    endRadius: 420
                )

                VStack {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    accent.tint.opacity(0.12),
                                    AIscendTheme.Colors.accentAmber.opacity(0.08)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 220)
                        .blur(radius: 32)
                        .offset(y: 72)
                }

                VStack {
                    Spacer()
                    GeometryReader { proxy in
                        RoundedRectangle(cornerRadius: 1, style: .continuous)
                            .fill(accent.tint.opacity(0.34))
                            .frame(width: proxy.size.width * min(max(progress, 0), 1), height: 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .offset(y: proxy.size.height - 2)
                    }
                    .frame(height: 4)
                }
            }
            .overlay(Color.black.opacity(dimmed ? 0.34 : 0.08))
        }
    }
}

private struct FacialTrainingSessionProgressStrip: View {
    let count: Int
    let activeIndex: Int
    let progress: Double

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<max(count, 1), id: \.self) { item in
                Capsule(style: .continuous)
                    .fill(fill(for: item))
                    .frame(height: 4)
            }
        }
        .overlay(alignment: .leading) {
            Capsule(style: .continuous)
                .fill(AIscendTheme.Colors.accentGlow.opacity(0.38))
                .frame(maxWidth: .infinity)
                .scaleEffect(x: min(max(progress, 0.02), 1), y: 1, anchor: .leading)
                .frame(height: 2)
                .offset(y: 9)
        }
        .padding(.top, AIscendTheme.Spacing.xSmall)
    }

    private func fill(for item: Int) -> AnyShapeStyle {
        if item < activeIndex {
            return AnyShapeStyle(RoutineAccent.mint.gradient)
        }

        if item == activeIndex {
            return AnyShapeStyle(RoutineAccent.dawn.gradient)
        }

        return AnyShapeStyle(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
    }
}

private struct FacialTrainingHUDTile: View {
    let title: String
    let value: String
    let symbol: String
    let accent: RoutineAccent

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(accent.tint)
                .frame(width: 26, height: 26)
                .background(Circle().fill(accent.tint.opacity(0.16)))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                Text(value)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)
        }
        .padding(AIscendTheme.Spacing.medium)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.58))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(accent.tint.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct FacialCompletionMetric: View {
    let title: String
    let value: String
    let symbol: String
    let accent: RoutineAccent

    var body: some View {
        VStack(spacing: AIscendTheme.Spacing.xSmall) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(accent.tint)

            Text(value)
                .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
                .monospacedDigit()

            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.62))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(accent.tint.opacity(0.20), lineWidth: 1)
        )
    }
}

private struct SessionTimerRing: View {
    let progress: Double
    let remainingSeconds: Int
    let accent: RoutineAccent

    var body: some View {
        ZStack {
            Circle()
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 14)

            Circle()
                .trim(from: 0, to: max(CGFloat(progress), 0.04))
                .stroke(
                    accent.gradient,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: accent.glow, radius: 18, x: 0, y: 0)

            VStack(spacing: AIscendTheme.Spacing.xxSmall) {
                Text(FacialTrainingFormat.time(remainingSeconds))
                    .aiscendTextStyle(.metricCompact, color: AIscendTheme.Colors.textPrimary)
                    .monospacedDigit()

                Text("left")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }
        }
        .frame(width: 128, height: 128)
    }
}

private struct FacialTrainingCueRow: View {
    let title: String
    let value: String
    let symbol: String
    let accent: RoutineAccent

    var body: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: symbol, accent: accent, size: 38)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                Text(value)
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(AIscendTheme.Spacing.medium)
        .aiscendPanel(.standard)
    }
}

private struct FacialFeedbackSlider: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            HStack {
                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                Spacer()
                Text("\(Int(value.rounded()))/5")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                    .monospacedDigit()
            }

            Slider(value: $value, in: 1...5, step: 1)
                .tint(AIscendTheme.Colors.accentAmber)
        }
        .padding(AIscendTheme.Spacing.medium)
        .aiscendPanel(.standard)
    }
}

private extension FacialVoiceCueTiming {
    var title: String {
        switch self {
        case .intro:
            "Intro"
        case .midpoint:
            "Mid"
        case .finalTen:
            "Final 10"
        case .rest:
            "Rest"
        case .transition:
            "Next"
        }
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
