//
//  RoutineDashboardView.swift
//  AIscend
//
//  Created by Codex on 4/7/26.
//

import SwiftUI

struct RoutineDashboardView: View {
    @Bindable var model: AppModel

    private let cardColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            AIscendBackdrop()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    heroCard
                    signalGrid
                    routineDeck
                }
                .padding(24)
                .padding(.bottom, 40)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(model.greeting + ", " + model.profile.displayName)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text("Today's ascent")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(AIscendTheme.secondaryText)
            }

            Spacer()

            Button {
                withAnimation(.smooth(duration: 0.35)) {
                    model.resetOnboarding()
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(.white.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Refine onboarding")
        }
    }

    private var heroCard: some View {
        HStack(alignment: .center, spacing: 20) {
            ProgressRing(progress: model.progress, label: model.progressLabel)

            VStack(alignment: .leading, spacing: 10) {
                Text("Routine status")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text(model.nextOpenStep?.title ?? "Today's runway is clear.")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text(model.nextOpenStep?.detail ?? "You completed the current AIscend routine. Keep the evening close-out gentle.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(AIscendTheme.secondaryText)

                HStack(spacing: 10) {
                    AIscendCapsule(title: model.profile.focusTrack.title, symbol: model.profile.focusTrack.symbol, isActive: true)
                    AIscendCapsule(title: model.profile.wakeLabel, symbol: "alarm.fill", isActive: false)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .aiscendCard(highlighted: true)
        .accessibilityIdentifier("routine-hero")
    }

    private var signalGrid: some View {
        LazyVGrid(columns: cardColumns, spacing: 12) {
            signalCard(
                title: "Climb statement",
                value: model.profile.intention,
                symbol: "mountain.2.fill",
                accent: .dawn
            )
            signalCard(
                title: "Focus track",
                value: model.profile.focusTrack.routinePrompt,
                symbol: model.profile.focusTrack.symbol,
                accent: .sky
            )
            signalCard(
                title: "Lift-off",
                value: "Target start is \(model.profile.wakeLabel).",
                symbol: "clock.fill",
                accent: .dawn
            )
            signalCard(
                title: "Anchors",
                value: model.profile.anchorSummary,
                symbol: "sparkles",
                accent: .mint
            )
        }
    }

    private var routineDeck: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("App routine")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            Text("Tap a step as you complete it. AIscend keeps the day framed as a climb instead of a checklist dump.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AIscendTheme.secondaryText)

            ForEach(model.routineSections) { section in
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.title)
                                .font(.system(.title3, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)

                            Text(section.subtitle)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(AIscendTheme.secondaryText)
                        }

                        Spacer()

                        Text(section.accent.rawValue.capitalized)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(section.accent.tint)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(section.accent.tint.opacity(0.14), in: Capsule(style: .continuous))
                    }

                    VStack(spacing: 14) {
                        ForEach(section.steps) { step in
                            routineStepRow(step)
                        }
                    }
                }
                .padding(22)
                .aiscendCard()
            }
        }
    }

    private func signalCard(title: String, value: String, symbol: String, accent: RoutineAccent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.gradient.opacity(0.28))
                    .frame(width: 44, height: 44)

                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            Text(value)
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(AIscendTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .padding(20)
        .aiscendCard()
    }

    private func routineStepRow(_ step: RoutineStep) -> some View {
        Button {
            withAnimation(.smooth(duration: 0.22)) {
                model.toggleStep(step.id)
            }
        } label: {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(step.accent.gradient.opacity(0.28))
                        .frame(width: 44, height: 44)

                    Image(systemName: step.symbol)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(step.title)
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)

                    Text(step.detail)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AIscendTheme.secondaryText)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: step.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(step.isComplete ? step.accent.tint : .white.opacity(0.45))
                    .padding(.top, 4)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ProgressRing: View {
    let progress: Double
    let label: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.12), lineWidth: 14)

            Circle()
                .trim(from: 0, to: max(progress, 0.04))
                .stroke(
                    LinearGradient(
                        colors: [AIscendTheme.sunrise, AIscendTheme.mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text(label)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text("done")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(AIscendTheme.secondaryText)
            }
        }
        .frame(width: 110, height: 110)
    }
}

#Preview {
    RoutineDashboardView(model: AppModel())
}
