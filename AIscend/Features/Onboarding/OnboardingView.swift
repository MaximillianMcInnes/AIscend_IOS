//
//  OnboardingView.swift
//  AIscend
//
//  Created by Codex on 4/7/26.
//

import SwiftUI

struct OnboardingView: View {
    @Bindable var model: AppModel
    @Bindable var session: AuthSessionStore
    @State private var currentStep: Int = 0
    @FocusState private var focusedField: Field?

    private let totalSteps = 3

    private enum Field {
        case name
        case intention
    }

    var body: some View {
        ZStack {
            AIscendBackdrop()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
                    topBar
                    stepProgress
                    stepContent
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, 152)
            }
        }
        .safeAreaInset(edge: .bottom) {
            footer
                .padding(.horizontal, AIscendTheme.Spacing.mediumLarge)
                .padding(.top, AIscendTheme.Spacing.small)
                .padding(.bottom, AIscendTheme.Spacing.mediumLarge)
                .background(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.appBackground.opacity(0),
                            AIscendTheme.Colors.appBackground.opacity(0.84),
                            AIscendTheme.Colors.appBackground
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }

    private var topBar: some View {
        AIscendEditorialHeroCard(
            eyebrow: "Calibration",
            title: "Build your operating profile.",
            subtitle: "This first pass defines the tone of the app: focused, controlled, and tuned to the way you want to move.",
            accent: .sky
        ) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    AIscendStatChip(title: "Steps", value: "\(totalSteps)", symbol: "square.grid.2x2.fill", accent: .sky)
                    AIscendStatChip(title: "Flow", value: "Guided", symbol: "sparkles", accent: .mint)

                    Spacer(minLength: AIscendTheme.Spacing.medium)

                    AIscendTopBarButton(symbol: "rectangle.portrait.and.arrow.right") {
                        session.signOut()
                    }
                    .accessibilityLabel("Sign out")
                }

                if let user = session.user {
                    HStack(spacing: AIscendTheme.Spacing.medium) {
                        ZStack {
                            Circle()
                                .fill(AIscendTheme.Colors.accentPrimary.opacity(0.18))
                                .frame(width: 46, height: 46)
                                .overlay(
                                    Circle()
                                        .stroke(AIscendTheme.Colors.accentGlow.opacity(0.32), lineWidth: AIscendTheme.Stroke.thin)
                                )

                            Text(user.initials)
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                        }

                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                            Text(user.displayName)
                                .aiscendTextStyle(.cardTitle)

                            Text(user.subtitle)
                                .aiscendTextStyle(.secondaryBody)
                        }

                        Spacer()

                        AIscendBadge(title: "Authenticated", symbol: "checkmark.shield.fill", style: .neutral)
                    }
                    .padding(AIscendTheme.Spacing.large)
                    .aiscendPanel(.standard)
                }
            }
        }
    }

    private var stepProgress: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            HStack(spacing: AIscendTheme.Spacing.xSmall) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(index <= currentStep ? AnyShapeStyle(RoutineAccent.sky.gradient) : AnyShapeStyle(AIscendTheme.Colors.surfaceHighlight))
                        .frame(maxWidth: .infinity)
                        .frame(height: 6)
                }
            }

            HStack {
                Text("Step \(currentStep + 1) of \(totalSteps)")
                    .aiscendTextStyle(.caption)

                Spacer()

                AIscendBadge(
                    title: stepLabel,
                    symbol: "slider.horizontal.below.rectangle",
                    style: .subtle
                )
            }
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.muted)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            identityStep
        case 1:
            focusStep
        default:
            rhythmStep
        }
    }

    private var identityStep: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            infoPanel(
                eyebrow: "Step 01",
                title: "Name the pursuit",
                copy: "Give the app the identity and objective it should optimize around from day one."
            )

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                Text("What should AIScend call you?")
                    .aiscendTextStyle(.cardTitle)

                TextField(
                    "",
                    text: $model.profile.name,
                    prompt: Text("Founder, operator, builder")
                        .foregroundStyle(AIscendTheme.Colors.textMuted)
                )
                .focused($focusedField, equals: .name)
                .textInputAutocapitalization(.words)
                .aiscendInputField(isFocused: focusedField == .name)
            }
            .padding(AIscendTheme.Spacing.large)
            .aiscendPanel(.standard)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                Text("What are you optimizing toward right now?")
                    .aiscendTextStyle(.cardTitle)

                TextField(
                    "",
                    text: $model.profile.intention,
                    prompt: Text("Ship the product, reclaim your mornings, sharpen your discipline")
                        .foregroundStyle(AIscendTheme.Colors.textMuted),
                    axis: .vertical
                )
                .focused($focusedField, equals: .intention)
                .lineLimit(4...6)
                .aiscendInputField(isFocused: focusedField == .intention)
            }
            .padding(AIscendTheme.Spacing.large)
            .aiscendPanel(.standard)
        }
    }

    private var focusStep: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            infoPanel(
                eyebrow: "Step 02",
                title: "Choose the operating mode",
                copy: "This controls the voice of the dashboard and the kind of structure AIScend applies to your day."
            )

            ForEach(FocusTrack.allCases) { track in
                Button {
                    withAnimation(AIscendTheme.Motion.reveal) {
                        model.profile.focusTrack = track
                    }
                } label: {
                    HStack(alignment: .top, spacing: AIscendTheme.Spacing.mediumLarge) {
                        AIscendIconOrb(
                            symbol: track.symbol,
                            accent: accent(for: track),
                            size: 52
                        )

                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                            Text(track.title)
                                .aiscendTextStyle(.sectionTitle)

                            Text(track.subtitle)
                                .aiscendTextStyle(.body)
                        }

                        Spacer()

                        Image(systemName: track == model.profile.focusTrack ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(track == model.profile.focusTrack ? AIscendTheme.Colors.accentGlow : AIscendTheme.Colors.textMuted)
                    }
                    .padding(AIscendTheme.Spacing.large)
                    .aiscendPanel(track == model.profile.focusTrack ? .hero : .standard)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var rhythmStep: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            infoPanel(
                eyebrow: "Step 03",
                title: "Set the rhythm",
                copy: "Define the daily start time and the habit anchors that keep the system repeatable without turning it noisy."
            )

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                Text("Preferred lift-off time")
                    .aiscendTextStyle(.cardTitle)

                DatePicker(
                    "Preferred lift-off time",
                    selection: wakeUpBinding,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(AIscendTheme.Colors.accentSoft)
                .colorScheme(.dark)

                AIscendBadge(
                    title: "Current target \(model.profile.wakeLabel)",
                    symbol: "alarm.fill",
                    style: .neutral
                )
            }
            .padding(AIscendTheme.Spacing.large)
            .aiscendPanel(.standard)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                Text("Habit anchors")
                    .aiscendTextStyle(.cardTitle)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
                    ForEach(HabitAnchor.allCases) { anchor in
                        Button {
                            withAnimation(AIscendTheme.Motion.reveal) {
                                model.toggleAnchor(anchor)
                            }
                        } label: {
                            AIscendCapsule(
                                title: anchor.title,
                                symbol: anchor.symbol,
                                isActive: model.profile.anchors.contains(anchor)
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AIscendTheme.Spacing.xSmall)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(model.profile.anchorSummary)
                    .aiscendTextStyle(.secondaryBody)
            }
            .padding(AIscendTheme.Spacing.large)
            .aiscendPanel(.standard)
        }
    }

    private func infoPanel(eyebrow: String, title: String, copy: String) -> some View {
        AIscendSectionHeader(
            eyebrow: eyebrow,
            title: title,
            subtitle: copy,
            prominence: .hero
        )
        .padding(AIscendTheme.Spacing.xLarge)
        .aiscendPanel(.hero)
    }

    private var footer: some View {
        HStack(spacing: AIscendTheme.Spacing.medium) {
            if currentStep > 0 {
                Button {
                    withAnimation(AIscendTheme.Motion.reveal) {
                        currentStep -= 1
                    }
                } label: {
                    AIscendButtonLabel(title: "Back", leadingSymbol: "arrow.left")
                }
                .buttonStyle(AIscendButtonStyle(variant: .secondary))
                .frame(maxWidth: 160)
            }

            Button {
                withAnimation(AIscendTheme.Motion.reveal) {
                    if currentStep < totalSteps - 1 {
                        currentStep += 1
                    } else {
                        model.completeOnboarding()
                    }
                }
            } label: {
                AIscendButtonLabel(
                    title: currentStep == totalSteps - 1 ? "Enter dashboard" : "Continue",
                    trailingSymbol: "arrow.right"
                )
            }
            .buttonStyle(AIscendButtonStyle(variant: .primary))
        }
    }

    private var wakeUpBinding: Binding<Date> {
        Binding(
            get: {
                model.profile.wakeDate
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                model.profile.wakeUpHour = components.hour ?? 7
                model.profile.wakeUpMinute = components.minute ?? 0
            }
        )
    }

    private var stepLabel: String {
        switch currentStep {
        case 0:
            "Identity"
        case 1:
            "Pace"
        default:
            "Rhythm"
        }
    }

    private func accent(for track: FocusTrack) -> RoutineAccent {
        switch track {
        case .momentum:
            .dawn
        case .mastery:
            .sky
        case .balance:
            .mint
        }
    }
}

#Preview {
    OnboardingView(model: AppModel(), session: AuthSessionStore())
}
