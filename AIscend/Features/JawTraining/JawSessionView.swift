//
//  JawSessionView.swift
//  AIscend
//
//  Created by Codex on 5/7/26.
//

import SwiftUI

struct JawSessionView: View {
    let plan: JawTrainingPlan
    @ObservedObject var store: JawTrainingStore

    @Environment(\.dismiss) private var dismiss
    @State private var exerciseIndex = 0
    @State private var elapsedInExercise = 0
    @State private var isPaused = false
    @State private var didComplete = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var currentExercise: JawExercise {
        plan.exercises[min(exerciseIndex, plan.exercises.count - 1)]
    }

    private var nextExercise: JawExercise? {
        let nextIndex = exerciseIndex + 1
        guard plan.exercises.indices.contains(nextIndex) else {
            return nil
        }

        return plan.exercises[nextIndex]
    }

    private var currentProgress: Double {
        guard currentExercise.durationSeconds > 0 else {
            return 1
        }

        return min(Double(elapsedInExercise) / Double(currentExercise.durationSeconds), 1)
    }

    private var totalElapsedSeconds: Int {
        let completed = plan.exercises.prefix(exerciseIndex).reduce(0) { $0 + $1.durationSeconds }
        return completed + elapsedInExercise
    }

    private var totalProgress: Double {
        guard plan.totalSeconds > 0 else {
            return 1
        }

        return min(Double(totalElapsedSeconds) / Double(plan.totalSeconds), 1)
    }

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    sessionHeader
                    currentExerciseCard
                    nextExerciseCard
                    safetyStrip
                    controls
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, AIscendTheme.Spacing.xxLarge)
            }
        }
        .overlay {
            if didComplete {
                completionOverlay
            }
        }
        .onReceive(timer) { _ in
            tick()
        }
        .preferredColorScheme(.dark)
    }

    private var sessionHeader: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                AIscendBadge(title: "Live session", symbol: isPaused ? "pause.fill" : "play.fill", style: .accent)

                Text(plan.name)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)

                Text("\(exerciseIndex + 1) of \(plan.exercises.count) / \(Int(totalProgress * 100))% complete")
                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                    .monospacedDigit()
            }

            Spacer(minLength: 0)

            AIscendTopBarButton(symbol: "xmark", highlighted: false) {
                dismiss()
            }
            .accessibilityLabel("Close session")
        }
    }

    private var currentExerciseCard: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            HStack(alignment: .center, spacing: AIscendTheme.Spacing.large) {
                SessionProgressRing(
                    progress: currentProgress,
                    remainingSeconds: max(currentExercise.durationSeconds - elapsedInExercise, 0),
                    accent: currentExercise.accent
                )

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    Text("Current exercise")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                    Text(currentExercise.name)
                        .aiscendTextStyle(.sectionTitle, color: AIscendTheme.Colors.textPrimary)

                    Text(currentExercise.description)
                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            currentExerciseDetail
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.hero)
    }

    private var currentExerciseDetail: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    sessionMetaPill(title: "Target", value: currentExercise.targetArea, symbol: "scope", accent: currentExercise.accent)
                    sessionMetaPill(title: "Dose", value: currentExercise.durationLabel, symbol: "timer", accent: .mint)
                    sessionMetaPill(title: "Level", value: currentExercise.difficulty.title, symbol: "dial.low.fill", accent: .dawn)
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    sessionMetaPill(title: "Target", value: currentExercise.targetArea, symbol: "scope", accent: currentExercise.accent)
                    sessionMetaPill(title: "Dose", value: currentExercise.durationLabel, symbol: "timer", accent: .mint)
                    sessionMetaPill(title: "Level", value: currentExercise.difficulty.title, symbol: "dial.low.fill", accent: .dawn)
                }
            }

            HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AIscendTheme.Colors.warning)
                    .padding(.top, 2)

                Text(currentExercise.safetyNotes)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(AIscendTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.54))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .stroke(AIscendTheme.Colors.warning.opacity(0.22), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private var nextExerciseCard: some View {
        if let nextExercise {
            HStack(alignment: .center, spacing: AIscendTheme.Spacing.medium) {
                AIscendIconOrb(symbol: "forward.fill", accent: nextExercise.accent, size: 42)

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                    Text("Next")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                    Text(nextExercise.name)
                        .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)

                    Text(nextExercise.durationLabel)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                }

                Spacer(minLength: 0)
            }
            .padding(AIscendTheme.Spacing.large)
            .aiscendPanel(.standard)
        }
    }

    private var safetyStrip: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.warning)
                .padding(.top, 2)

            Text("Stop immediately if you feel pain, dizziness, TMJ discomfort, headaches, clicking, or jaw locking.")
                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.muted)
    }

    private var controls: some View {
        VStack(spacing: AIscendTheme.Spacing.small) {
            Button {
                withAnimation(AIscendTheme.Motion.reveal) {
                    isPaused.toggle()
                }
            } label: {
                AIscendButtonLabel(
                    title: isPaused ? "Resume" : "Pause",
                    leadingSymbol: isPaused ? "play.fill" : "pause.fill"
                )
            }
            .buttonStyle(AIscendButtonStyle(variant: isPaused ? .primary : .secondary))

            Button {
                completeSession()
            } label: {
                AIscendButtonLabel(title: "Complete Routine", leadingSymbol: "checkmark.seal.fill")
            }
            .buttonStyle(AIscendButtonStyle(variant: .primary))
        }
    }

    private var completionOverlay: some View {
        ZStack {
            AIscendTheme.Colors.overlayDark
                .ignoresSafeArea()

            VStack(spacing: AIscendTheme.Spacing.large) {
                AIscendIconOrb(symbol: "checkmark.seal.fill", accent: .mint, size: 72)

                VStack(spacing: AIscendTheme.Spacing.xSmall) {
                    Text("Session complete")
                        .aiscendTextStyle(.sectionTitle, color: AIscendTheme.Colors.textPrimary)

                    Text("Today's Jaw Training completion is saved locally.")
                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Button {
                    dismiss()
                } label: {
                    AIscendButtonLabel(title: "Return to Jaw Training", leadingSymbol: "arrow.down.right.and.arrow.up.left")
                }
                .buttonStyle(AIscendButtonStyle(variant: .primary))
            }
            .padding(AIscendTheme.Spacing.xLarge)
            .frame(maxWidth: 340)
            .aiscendPanel(.hero)
        }
    }

    private func tick() {
        guard !isPaused, !didComplete, !plan.exercises.isEmpty else {
            return
        }

        let nextElapsed = elapsedInExercise + 1
        if nextElapsed >= currentExercise.durationSeconds {
            if exerciseIndex >= plan.exercises.count - 1 {
                completeSession()
            } else {
                withAnimation(AIscendTheme.Motion.reveal) {
                    exerciseIndex += 1
                    elapsedInExercise = 0
                }
            }
        } else {
            elapsedInExercise = nextElapsed
        }
    }

    private func completeSession() {
        guard !didComplete else {
            return
        }

        isPaused = true
        store.markCompleted(plan: plan)
        withAnimation(AIscendTheme.Motion.reveal) {
            didComplete = true
        }
    }

    private func sessionMetaPill(title: String, value: String, symbol: String, accent: RoutineAccent) -> some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(accent.tint)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                Text(value)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, AIscendTheme.Spacing.xSmall)
        .background(
            Capsule(style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.74))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(accent.tint.opacity(0.22), lineWidth: 1)
        )
    }
}

private struct SessionProgressRing: View {
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
                Text(timeLabel)
                    .aiscendTextStyle(.metricCompact, color: AIscendTheme.Colors.textPrimary)
                    .monospacedDigit()

                Text("left")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }
        }
        .frame(width: 128, height: 128)
    }

    private var timeLabel: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
