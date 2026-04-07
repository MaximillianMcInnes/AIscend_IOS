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
        GridItem(.flexible(), spacing: AIscendTheme.Spacing.small),
        GridItem(.flexible(), spacing: AIscendTheme.Spacing.small)
    ]

    var body: some View {
        ZStack {
            AIscendBackdrop()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
                    header
                    heroCard
                    signalGrid
                    routineDeck
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, AIscendTheme.Spacing.xxLarge)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.mediumLarge) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                AIscendBadge(
                    title: "Private Briefing",
                    symbol: "sparkles",
                    style: .accent
                )

                AIscendSectionHeader(
                    title: "Daily intelligence",
                    subtitle: "\(model.greeting), \(model.profile.displayName). Your routine environment is calibrated and ready to execute.",
                    prominence: .hero
                )

                HStack(spacing: AIscendTheme.Spacing.small) {
                    AIscendCapsule(
                        title: model.profile.focusTrack.title,
                        symbol: model.profile.focusTrack.symbol,
                        isActive: true
                    )
                    AIscendCapsule(
                        title: model.profile.wakeLabel,
                        symbol: "alarm.fill",
                        isActive: false
                    )
                }
            }

            Spacer(minLength: AIscendTheme.Spacing.medium)

            Button {
                withAnimation(AIscendTheme.Motion.reveal) {
                    model.resetOnboarding()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(AIscendTheme.Colors.surfaceHighlight)
                        .frame(width: 46, height: 46)
                        .overlay(
                            Circle()
                                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: AIscendTheme.Stroke.thin)
                        )

                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Refine onboarding")
        }
    }

    private var heroCard: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: AIscendTheme.Spacing.xLarge) {
                dashboardHeroBody
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                dashboardHeroBody
            }
        }
        .padding(AIscendTheme.Spacing.xLarge)
        .aiscendPanel(.hero)
        .accessibilityIdentifier("routine-hero")
    }

    private var dashboardHeroBody: some View {
        Group {
            PrecisionRing(progress: model.progress, label: model.progressLabel)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                AIscendBadge(
                    title: model.nextOpenStep == nil ? "Clear" : "Live Priority",
                    symbol: "waveform.path.ecg",
                    style: .neutral
                )

                Text(model.nextOpenStep?.title ?? "The current runway is clear.")
                    .aiscendTextStyle(.sectionTitle)

                Text(
                    model.nextOpenStep?.detail ??
                    "You completed the active routine sequence. Keep the close-out clean and low-friction."
                )
                .aiscendTextStyle(.body)

                Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                    .aiscendTextStyle(.caption)
            }

            Spacer(minLength: 0)
        }
    }

    private var signalGrid: some View {
        LazyVGrid(columns: cardColumns, spacing: AIscendTheme.Spacing.small) {
            AIscendMetricCard(
                title: "Climb statement",
                value: "Core",
                detail: model.profile.intention,
                symbol: "mountain.2.fill",
                accent: .dawn,
                highlighted: true
            )
            AIscendMetricCard(
                title: "Focus track",
                value: model.profile.focusTrack.title,
                detail: model.profile.focusTrack.routinePrompt,
                symbol: model.profile.focusTrack.symbol,
                accent: .sky
            )
            AIscendMetricCard(
                title: "Lift-off",
                value: model.profile.wakeLabel,
                detail: "Planned start time for the operating window.",
                symbol: "clock.fill",
                accent: .dawn
            )
            AIscendMetricCard(
                title: "Anchors",
                value: "\(model.profile.anchors.count)",
                detail: model.profile.anchorSummary,
                symbol: "sparkles",
                accent: .mint
            )
        }
    }

    private var routineDeck: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            AIscendSectionHeader(
                eyebrow: "Execution",
                title: "Routine sequence",
                subtitle: "Tap a step as it completes. AIScend keeps the day structured like a private operating brief instead of a cluttered checklist."
            )

            ForEach(model.routineSections) { section in
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                            Text(section.title)
                                .aiscendTextStyle(.sectionTitle)

                            Text(section.subtitle)
                                .aiscendTextStyle(.body)
                        }

                        Spacer()

                        AIscendBadge(
                            title: section.accent.rawValue,
                            symbol: "sparkles",
                            style: .neutral
                        )
                    }

                    VStack(spacing: AIscendTheme.Spacing.medium) {
                        ForEach(section.steps) { step in
                            routineStepRow(step)
                        }
                    }
                }
                .padding(AIscendTheme.Spacing.large)
                .aiscendPanel(.standard)
            }
        }
    }

    private func routineStepRow(_ step: RoutineStep) -> some View {
        Button {
            withAnimation(AIscendTheme.Motion.reveal) {
                model.toggleStep(step.id)
            }
        } label: {
            HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                AIscendIconOrb(symbol: step.symbol, accent: step.accent, size: 44)

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                    Text(step.title)
                        .aiscendTextStyle(.cardTitle)

                    Text(step.detail)
                        .aiscendTextStyle(.body)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: step.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(step.isComplete ? step.accent.tint : AIscendTheme.Colors.textMuted)
                    .padding(.top, AIscendTheme.Spacing.xxSmall)
            }
            .padding(AIscendTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(step.isComplete ? 0.92 : 0.62))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                    .stroke(
                        step.isComplete ? step.accent.tint.opacity(0.34) : AIscendTheme.Colors.borderSubtle,
                        lineWidth: AIscendTheme.Stroke.thin
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PrecisionRing: View {
    let progress: Double
    let label: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 16)

            Circle()
                .trim(from: 0, to: max(progress, 0.06))
                .stroke(
                    RoutineAccent.sky.gradient,
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: RoutineAccent.sky.glow, radius: 20, x: 0, y: 0)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AIscendTheme.Colors.accentGlow.opacity(0.16),
                            .clear
                        ],
                        center: .center,
                        startRadius: 12,
                        endRadius: 72
                    )
                )

            VStack(spacing: AIscendTheme.Spacing.xxSmall) {
                Text(label)
                    .aiscendTextStyle(.metric)

                Text("complete")
                    .aiscendTextStyle(.caption)
            }
        }
        .frame(width: 136, height: 136)
    }
}

#Preview {
    RoutineDashboardView(model: AppModel())
}
