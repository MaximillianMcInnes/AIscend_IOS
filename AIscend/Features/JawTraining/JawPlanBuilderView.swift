//
//  JawPlanBuilderView.swift
//  AIscend
//
//  Created by Codex on 5/7/26.
//

import SwiftUI

struct JawPlanBuilderView: View {
    let onSave: (JawTrainingPlan) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedGoal: JawTrainingGoal = .posture
    @State private var selectedMinutes = 5
    @State private var selectedExperience: JawTrainingExperience = .beginner
    @State private var generatedPlan: JawTrainingPlan?

    private let availableMinutes = [3, 5, 8, 10]

    var body: some View {
        NavigationStack {
            ZStack {
                AIscendBackdrop()
                DashboardAmbientLayer()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                        header
                        goalSection
                        timeSection
                        experienceSection

                        if let generatedPlan {
                            generatedPlanPreview(generatedPlan)
                        }

                        actionStack
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
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            AIscendBadge(title: "Plan builder", symbol: "slider.horizontal.3", style: .accent)

            Text("Build my plan")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)

            Text("Choose a goal, time window, and experience level. AIScend will assemble a local plan from gentle predefined movements.")
                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
        }
    }

    private var goalSection: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendSectionHeader(
                eyebrow: "Goal",
                title: "What are we optimizing for?",
                subtitle: "No medical claims, no extreme routines. This is posture, engagement, tension awareness, and tracking."
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
                ForEach(JawTrainingGoal.allCases) { goal in
                    builderOption(
                        title: goal.title,
                        detail: goal.detail,
                        symbol: goal.symbol,
                        isSelected: selectedGoal == goal
                    ) {
                        withAnimation(AIscendTheme.Motion.reveal) {
                            selectedGoal = goal
                            generatedPlan = nil
                        }
                    }
                }
            }
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.standard)
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendSectionHeader(
                eyebrow: "Time",
                title: "Available time",
                subtitle: "Short sessions are intentionally valid here."
            )

            HStack(spacing: AIscendTheme.Spacing.small) {
                ForEach(availableMinutes, id: \.self) { minutes in
                    Button {
                        withAnimation(AIscendTheme.Motion.reveal) {
                            selectedMinutes = minutes
                            generatedPlan = nil
                        }
                    } label: {
                        Text("\(minutes)m")
                            .aiscendTextStyle(.buttonLabel, color: selectedMinutes == minutes ? .white : AIscendTheme.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AIscendTheme.Spacing.medium)
                            .background(
                                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                                    .fill(
                                        selectedMinutes == minutes
                                            ? AnyShapeStyle(RoutineAccent.sky.gradient)
                                            : AnyShapeStyle(AIscendTheme.Colors.surfaceHighlight.opacity(0.6))
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                                    .stroke(
                                        selectedMinutes == minutes ? AIscendTheme.Colors.accentGlow.opacity(0.42) : AIscendTheme.Colors.borderSubtle,
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.elevated)
    }

    private var experienceSection: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendSectionHeader(
                eyebrow: "Experience",
                title: "Intensity ceiling",
                subtitle: "Beginner keeps everything easy. Intermediate may include very gentle resistance."
            )

            HStack(spacing: AIscendTheme.Spacing.small) {
                ForEach(JawTrainingExperience.allCases) { experience in
                    Button {
                        withAnimation(AIscendTheme.Motion.reveal) {
                            selectedExperience = experience
                            generatedPlan = nil
                        }
                    } label: {
                        HStack {
                            Image(systemName: selectedExperience == experience ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 16, weight: .semibold))

                            Text(experience.title)
                                .aiscendTextStyle(.buttonLabel, color: AIscendTheme.Colors.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AIscendTheme.Spacing.medium)
                        .background(
                            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(selectedExperience == experience ? 0.82 : 0.52))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                                .stroke(selectedExperience == experience ? AIscendTheme.Colors.accentGlow.opacity(0.42) : AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.standard)
    }

    private var actionStack: some View {
        VStack(spacing: AIscendTheme.Spacing.small) {
            Button {
                withAnimation(AIscendTheme.Motion.reveal) {
                    generatedPlan = JawTrainingPlanLibrary.plan(
                        goal: selectedGoal,
                        availableMinutes: selectedMinutes,
                        experience: selectedExperience
                    )
                }
            } label: {
                AIscendButtonLabel(title: "Generate Plan", leadingSymbol: "sparkles")
            }
            .buttonStyle(AIscendButtonStyle(variant: .primary))

            if let generatedPlan {
                Button {
                    onSave(generatedPlan)
                    dismiss()
                } label: {
                    AIscendButtonLabel(title: "Use This Plan", leadingSymbol: "checkmark.seal.fill")
                }
                .buttonStyle(AIscendButtonStyle(variant: .secondary))
            }
        }
    }

    private func generatedPlanPreview(_ plan: JawTrainingPlan) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendSectionHeader(
                eyebrow: "Generated",
                title: plan.name,
                subtitle: plan.subtitle
            )

            HStack(spacing: AIscendTheme.Spacing.small) {
                AIscendStatChip(title: "Time", value: "\(plan.durationMinutes)m", symbol: "timer", accent: plan.accent)
                AIscendStatChip(title: "Moves", value: "\(plan.exercises.count)", symbol: "square.grid.2x2.fill", accent: .mint)
            }

            VStack(spacing: AIscendTheme.Spacing.small) {
                ForEach(plan.exercises) { exercise in
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        AIscendIconOrb(symbol: "waveform.path.ecg", accent: exercise.accent, size: 34)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.name)
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)

                            Text(exercise.durationLabel)
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(AIscendTheme.Spacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                            .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.58))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                            .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                    )
                }
            }
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.hero)
    }

    private func builderOption(
        title: String,
        detail: String,
        symbol: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                AIscendIconOrb(symbol: symbol, accent: isSelected ? .sky : .mint, size: 38)

                Text(title)
                    .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
                    .lineLimit(2)

                Text(detail)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
            .padding(AIscendTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(isSelected ? 0.82 : 0.52))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .stroke(isSelected ? AIscendTheme.Colors.accentGlow.opacity(0.44) : AIscendTheme.Colors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
