//
//  JawExerciseCard.swift
//  AIscend
//
//  Created by Codex on 5/7/26.
//

import SwiftUI

struct JawExerciseCard: View {
    let exercise: JawExercise

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                JawMotionIndicator(pattern: exercise.movementPattern, accent: exercise.accent)
                    .frame(width: 76, height: 76)

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                    Text(exercise.name)
                        .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)

                    Text(exercise.description)
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    JawExerciseMetaPill(title: "Target", value: exercise.targetArea, symbol: "scope", accent: exercise.accent)
                    JawExerciseMetaPill(title: "Time", value: exercise.durationLabel, symbol: "timer", accent: .mint)
                    JawExerciseMetaPill(title: "Level", value: exercise.difficulty.title, symbol: "dial.low.fill", accent: .dawn)
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    JawExerciseMetaPill(title: "Target", value: exercise.targetArea, symbol: "scope", accent: exercise.accent)
                    JawExerciseMetaPill(title: "Time", value: exercise.durationLabel, symbol: "timer", accent: .mint)
                    JawExerciseMetaPill(title: "Level", value: exercise.difficulty.title, symbol: "dial.low.fill", accent: .dawn)
                }
            }

            HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AIscendTheme.Colors.warning)
                    .padding(.top, 2)

                Text(exercise.safetyNotes)
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
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.standard)
    }
}

private struct JawMotionIndicator: View {
    let pattern: JawExerciseMovementPattern
    let accent: RoutineAccent

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.surfaceHighlight.opacity(0.86),
                            AIscendTheme.Colors.surfaceMuted.opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(accent.tint.opacity(0.28), lineWidth: 1)
                )

            Circle()
                .fill(accent.tint.opacity(0.22))
                .frame(width: 44, height: 44)
                .blur(radius: 14)
                .scaleEffect(animate ? 1.15 : 0.82)

            movementShape
                .foregroundStyle(accent.gradient)
                .shadow(color: accent.glow, radius: 14, x: 0, y: 0)
        }
        .onAppear {
            guard !reduceMotion else {
                animate = true
                return
            }

            withAnimation(.easeInOut(duration: 1.25).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }

    @ViewBuilder
    private var movementShape: some View {
        switch pattern {
        case .chinTuck:
            VStack(spacing: 8) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 24, weight: .semibold))
                    .offset(x: animate ? -4 : 4)

                Image(systemName: "arrow.left.and.right")
                    .font(.system(size: 15, weight: .bold))
                    .opacity(0.9)
            }
        case .tongueHold:
            VStack(spacing: 7) {
                Image(systemName: "mouth.fill")
                    .font(.system(size: 26, weight: .semibold))
                Circle()
                    .frame(width: 8, height: 8)
                    .offset(y: animate ? -8 : 2)
            }
        case .jawOpenClose:
            VStack(spacing: animate ? 13 : 5) {
                Capsule(style: .continuous)
                    .frame(width: 32, height: 5)
                Capsule(style: .continuous)
                    .frame(width: 32, height: 5)
            }
        case .neckReset:
            VStack(spacing: 6) {
                Image(systemName: "figure.stand")
                    .font(.system(size: 28, weight: .semibold))
                    .offset(y: animate ? -3 : 3)
                Image(systemName: "arrow.up")
                    .font(.system(size: 13, weight: .bold))
            }
        case .massage:
            ZStack {
                Image(systemName: "face.smiling")
                    .font(.system(size: 28, weight: .semibold))
                Circle()
                    .stroke(lineWidth: 3)
                    .frame(width: 30, height: 30)
                    .rotationEffect(.degrees(animate ? 180 : 0))
                    .offset(x: animate ? 10 : -8, y: 7)
            }
        case .sideStretch:
            VStack(spacing: 6) {
                Image(systemName: "figure.stand")
                    .font(.system(size: 27, weight: .semibold))
                    .rotationEffect(.degrees(animate ? -7 : 7))
                Image(systemName: "arrow.left.and.right")
                    .font(.system(size: 13, weight: .bold))
            }
        case .resistancePress:
            VStack(spacing: 5) {
                Image(systemName: "hand.point.up.left.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .offset(y: animate ? -4 : 4)
                Image(systemName: "chevron.compact.up")
                    .font(.system(size: 18, weight: .bold))
            }
        }
    }
}

private struct JawExerciseMetaPill: View {
    let title: String
    let value: String
    let symbol: String
    let accent: RoutineAccent

    var body: some View {
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
