//
//  RoadmapBuilderView.swift
//  AIscend
//

import SwiftUI

struct RoadmapBuilderView: View {
    let scanSignal: RoadmapScanSignal
    let onBuild: (RoadmapBuilderProfile) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var profile = RoadmapBuilderProfile()
    @State private var step = 0

    private let stepTitles = ["Goal", "Concern", "Time", "Intensity"]

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                        header
                        RoadmapBuilderStepRail(stepTitles: stepTitles, currentStep: step)
                        currentStepContent
                    }
                    .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                    .padding(.top, AIscendTheme.Spacing.large)
                    .padding(.bottom, AIscendTheme.Spacing.large)
                    .frame(maxWidth: 720, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }

                footer
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                AIscendBadge(
                    title: scanSignal.hasScan ? "Scan-aware builder" : "Template builder",
                    symbol: scanSignal.hasScan ? "viewfinder.circle.fill" : "sparkles",
                    style: .accent
                )

                Text("Build my roadmap")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)

                Text(scanSignal.hasScan ? scanSignal.sourceSummary : "Answer four prompts. AIScend will build a local 30/60/90-day plan and sharpen it when scan data exists.")
                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AIscendTheme.Spacing.small)

            AIscendTopBarButton(symbol: "xmark", action: { dismiss() })
        }
    }

    @ViewBuilder
    private var currentStepContent: some View {
        switch step {
        case 0:
            optionSection(
                title: "Main goal",
                subtitle: "Pick the strategic direction for the next 90 days.",
                options: RoadmapGoal.allCases,
                selection: profile.goal,
                optionTitle: \.title,
                optionDetail: \.detail
            ) { profile.goal = $0 }
        case 1:
            optionSection(
                title: "Biggest concern",
                subtitle: "This tells AIScend where to bias the early-phase plan.",
                options: RoadmapConcern.allCases,
                selection: profile.concern,
                optionTitle: \.title,
                optionDetail: { _ in "Priority bias" }
            ) { profile.concern = $0 }
        case 2:
            optionSection(
                title: "Time available",
                subtitle: "Keep this honest. The best plan is the one you can repeat.",
                options: RoadmapDailyTime.allCases,
                selection: profile.dailyTime,
                optionTitle: \.title,
                optionDetail: { option in "\(option.minutes) minutes per day" }
            ) { profile.dailyTime = $0 }
        default:
            optionSection(
                title: "Consistency mode",
                subtitle: "Choose the intensity without turning the roadmap into punishment.",
                options: RoadmapConsistencyMode.allCases,
                selection: profile.consistencyMode,
                optionTitle: \.title,
                optionDetail: \.detail
            ) { profile.consistencyMode = $0 }
        }
    }

    private var footer: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Button {
                withAnimation(AIscendTheme.Motion.reveal) {
                    step = max(step - 1, 0)
                }
            } label: {
                AIscendButtonLabel(title: "Back", leadingSymbol: "chevron.left")
            }
            .buttonStyle(AIscendButtonStyle(variant: .secondary))
            .disabled(step == 0)
            .opacity(step == 0 ? 0.48 : 1)

            Button {
                if step < stepTitles.count - 1 {
                    withAnimation(AIscendTheme.Motion.reveal) {
                        step += 1
                    }
                } else {
                    onBuild(profile)
                    dismiss()
                }
            } label: {
                AIscendButtonLabel(
                    title: step == stepTitles.count - 1 ? "Generate Roadmap" : "Continue",
                    trailingSymbol: step == stepTitles.count - 1 ? "sparkles" : "chevron.right"
                )
            }
            .buttonStyle(AIscendButtonStyle(variant: .primary))
        }
        .padding(.horizontal, AIscendTheme.Spacing.screenInset)
        .padding(.top, AIscendTheme.Spacing.medium)
        .padding(.bottom, AIscendTheme.Spacing.large)
        .background(
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.appBackground.opacity(0),
                    AIscendTheme.Colors.appBackground.opacity(0.9),
                    AIscendTheme.Colors.appBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private func optionSection<Option: Identifiable & Hashable>(
        title: String,
        subtitle: String,
        options: [Option],
        selection: Option,
        optionTitle: @escaping (Option) -> String,
        optionDetail: @escaping (Option) -> String,
        onSelect: @escaping (Option) -> Void
    ) -> some View {
        DashboardGlassCard(tone: .premium) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                AIscendSectionHeader(
                    eyebrow: "Step \(step + 1) of \(stepTitles.count)",
                    title: title,
                    subtitle: subtitle
                )

                LazyVStack(spacing: AIscendTheme.Spacing.small) {
                    ForEach(options) { option in
                        Button {
                            withAnimation(AIscendTheme.Motion.press) {
                                onSelect(option)
                            }
                        } label: {
                            HStack(spacing: AIscendTheme.Spacing.medium) {
                                ZStack {
                                    Circle()
                                        .fill(selection == option ? AIscendTheme.Colors.accentPrimary.opacity(0.34) : Color.white.opacity(0.07))
                                        .frame(width: 36, height: 36)

                                    Image(systemName: selection == option ? "checkmark" : "circle")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(selection == option ? AIscendTheme.Colors.accentGlow : AIscendTheme.Colors.textMuted)
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(optionTitle(option))
                                        .aiscendTextStyle(.cardTitle)

                                    Text(optionDetail(option))
                                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer(minLength: 0)
                            }
                            .padding(AIscendTheme.Spacing.medium)
                            .background(
                                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                                    .fill(selection == option ? AIscendTheme.Colors.surfaceGlass.opacity(0.86) : Color.white.opacity(0.045))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                                    .stroke(selection == option ? AIscendTheme.Colors.accentGlow.opacity(0.34) : AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct RoadmapBuilderStepRail: View {
    let stepTitles: [String]
    let currentStep: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(stepTitles.enumerated()), id: \.offset) { index, title in
                VStack(spacing: AIscendTheme.Spacing.xSmall) {
                    ZStack {
                        Circle()
                            .fill(index <= currentStep ? RoutineAccent.sky.gradient : LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 42, height: 42)
                            .overlay(
                                Circle()
                                    .stroke(index == currentStep ? AIscendTheme.Colors.accentGlow.opacity(0.48) : AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                            )

                        Text("\(index + 1)")
                            .aiscendTextStyle(.buttonLabel)
                    }

                    Text(title)
                        .aiscendTextStyle(.caption, color: index == currentStep ? AIscendTheme.Colors.textPrimary : AIscendTheme.Colors.textMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .frame(maxWidth: .infinity)

                if index < stepTitles.count - 1 {
                    Rectangle()
                        .fill(index < currentStep ? AIscendTheme.Colors.accentGlow.opacity(0.52) : AIscendTheme.Colors.borderSubtle)
                        .frame(height: 2)
                        .offset(y: -12)
                }
            }
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.48))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}
