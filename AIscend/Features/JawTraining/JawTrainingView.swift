//
//  JawTrainingView.swift
//  AIscend
//
//  Created by Codex on 5/7/26.
//

import SwiftUI

struct JawTrainingView: View {
    @ObservedObject var store: JawTrainingStore

    @Environment(\.dismiss) private var dismiss
    @State private var showingPlanBuilder = false
    @State private var activeSession: JawTrainingPlan?

    private var availablePlans: [JawTrainingPlan] {
        if store.selectedPlan.isCustom {
            return [store.selectedPlan] + JawTrainingPlanLibrary.predefined
        }

        return JawTrainingPlanLibrary.predefined
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AIscendBackdrop()
                DashboardAmbientLayer()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                        header
                        safetyDisclaimer
                        selectedPlanHero
                        JawProgressView(store: store)
                        planLibrary
                        exerciseLibrary
                    }
                    .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                    .padding(.top, AIscendTheme.Spacing.large)
                    .padding(.bottom, AIscendTheme.Spacing.xxLarge)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(isPresented: $showingPlanBuilder) {
            JawPlanBuilderView { plan in
                store.saveBuiltPlan(plan)
            }
        }
        .fullScreenCover(item: $activeSession) { plan in
            JawSessionView(plan: plan, store: store)
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            AIscendBadge(title: "AIScend routine layer", symbol: "waveform.path.ecg", style: .accent)

            Text("Jaw Training")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)

            Text("Guided facial posture, muscle engagement, tension awareness, and consistency tracking.")
                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var safetyDisclaimer: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.warning)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text("Safety first")
                    .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)

                Text("This is not medical advice and does not promise jaw growth, bone change, or guaranteed facial transformation. Stop if you feel pain, dizziness, TMJ discomfort, headaches, clicking, or jaw locking.")
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.muted)
    }

    private var selectedPlanHero: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: AIscendTheme.Spacing.large) {
                    selectedPlanCopy
                    Spacer(minLength: 0)
                    JawPlanDial(plan: store.selectedPlan, completedToday: store.hasCompletedToday)
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    selectedPlanCopy
                    HStack {
                        Spacer(minLength: 0)
                        JawPlanDial(plan: store.selectedPlan, completedToday: store.hasCompletedToday)
                        Spacer(minLength: 0)
                    }
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    AIscendStatChip(title: "Time", value: "\(store.selectedPlan.durationMinutes)m", symbol: "timer", accent: store.selectedPlan.accent)
                    AIscendStatChip(title: "Moves", value: "\(store.selectedPlan.exercises.count)", symbol: "square.grid.2x2.fill", accent: .mint)
                    AIscendStatChip(title: "Level", value: store.selectedPlan.difficulty.title, symbol: "gauge.with.dots.needle.50percent", accent: .dawn)
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    AIscendStatChip(title: "Time", value: "\(store.selectedPlan.durationMinutes)m", symbol: "timer", accent: store.selectedPlan.accent)
                    AIscendStatChip(title: "Moves", value: "\(store.selectedPlan.exercises.count)", symbol: "square.grid.2x2.fill", accent: .mint)
                    AIscendStatChip(title: "Level", value: store.selectedPlan.difficulty.title, symbol: "gauge.with.dots.needle.50percent", accent: .dawn)
                }
            }

            HStack(spacing: AIscendTheme.Spacing.small) {
                Button {
                    activeSession = store.selectedPlan
                } label: {
                    AIscendButtonLabel(title: "Start Routine", leadingSymbol: "play.fill")
                }
                .buttonStyle(AIscendButtonStyle(variant: .primary))

                Button {
                    showingPlanBuilder = true
                } label: {
                    AIscendButtonLabel(title: "Build My Plan", leadingSymbol: "slider.horizontal.3")
                }
                .buttonStyle(AIscendButtonStyle(variant: .secondary))
            }
        }
        .padding(AIscendTheme.Spacing.xLarge)
        .aiscendPanel(.hero)
    }

    private var selectedPlanCopy: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            AIscendBadge(
                title: store.hasCompletedToday ? "Completed today" : "Ready today",
                symbol: store.hasCompletedToday ? "checkmark.seal.fill" : "bolt.fill",
                style: store.hasCompletedToday ? .success : .accent
            )

            Text(store.selectedPlan.name)
                .aiscendTextStyle(.sectionTitle, color: AIscendTheme.Colors.textPrimary)

            Text(store.selectedPlan.subtitle)
                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var planLibrary: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendSectionHeader(
                eyebrow: "Plans",
                title: "Workout plans",
                subtitle: "Pick a plan or build one from the local exercise library."
            )

            VStack(spacing: AIscendTheme.Spacing.small) {
                ForEach(availablePlans) { plan in
                    Button {
                        withAnimation(AIscendTheme.Motion.reveal) {
                            store.selectPlan(plan)
                        }
                    } label: {
                        JawPlanRow(
                            plan: plan,
                            isSelected: store.selectedPlan.id == plan.id
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var exerciseLibrary: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendSectionHeader(
                eyebrow: "Exercise library",
                title: "Gentle movement patterns",
                subtitle: "No hard chewing routines. Keep every rep controlled and comfortable."
            )

            VStack(spacing: AIscendTheme.Spacing.medium) {
                ForEach(JawExerciseLibrary.all) { exercise in
                    JawExerciseCard(exercise: exercise)
                }
            }
        }
    }
}

private struct JawPlanDial: View {
    let plan: JawTrainingPlan
    let completedToday: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            plan.accent.tint.opacity(0.22),
                            plan.accent.tint.opacity(0.08),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 96
                    )
                )

            Circle()
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 13)
                .padding(10)

            Circle()
                .trim(from: 0, to: completedToday ? 1 : 0.72)
                .stroke(
                    plan.accent.gradient,
                    style: StrokeStyle(lineWidth: 13, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(10)
                .shadow(color: plan.accent.glow, radius: 18, x: 0, y: 0)

            VStack(spacing: AIscendTheme.Spacing.xxSmall) {
                Text("\(plan.durationMinutes)")
                    .aiscendTextStyle(.metricCompact, color: AIscendTheme.Colors.textPrimary)
                    .monospacedDigit()

                Text("min")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }
        }
        .frame(width: 150, height: 150)
    }
}

private struct JawPlanRow: View {
    let plan: JawTrainingPlan
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .center, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(
                symbol: plan.isCustom ? "sparkles" : "waveform.path.ecg",
                accent: plan.accent,
                size: 46
            )

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                HStack(spacing: AIscendTheme.Spacing.xSmall) {
                    Text(plan.name)
                        .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
                        .lineLimit(1)

                    if plan.isCustom {
                        AIscendBadge(title: "Built", symbol: "slider.horizontal.3", style: .accent)
                    }
                }

                Text(plan.subtitle)
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                    .lineLimit(2)

                Text("\(plan.durationMinutes)m / \(plan.exerciseCountLabel) / \(plan.difficulty.title)")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }

            Spacer(minLength: 0)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(isSelected ? plan.accent.tint : AIscendTheme.Colors.textMuted)
        }
        .padding(AIscendTheme.Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(isSelected ? 0.82 : 0.56))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                .stroke(isSelected ? plan.accent.tint.opacity(0.34) : AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}
