//
//  OnboardingView.swift
//  AIscend
//
//  Created by Codex on 4/7/26.
//

import SwiftUI

struct OnboardingView: View {
    @Bindable var model: AppModel
    @State private var currentStep: Int = 0

    private let totalSteps = 3

    var body: some View {
        ZStack {
            AIscendBackdrop()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    topBar
                    stepProgress
                    stepContent
                }
                .padding(24)
                .padding(.top, 12)
                .padding(.bottom, 140)
            }
        }
        .safeAreaInset(edge: .bottom) {
            footer
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
                .background(.ultraThinMaterial)
        }
    }

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AIscend")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(AIscendTheme.mist.opacity(0.85))

            Text("Build a routine that feels calm, focused, and unmistakably yours.")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .accessibilityIdentifier("onboarding-title")

            Text("We will shape the first version now, then you can keep refining it as the app learns your rhythm.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(AIscendTheme.secondaryText)
        }
    }

    private var stepProgress: some View {
        HStack(spacing: 10) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index <= currentStep ? .white : .white.opacity(0.22))
                    .frame(height: 6)
            }
        }
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
        VStack(alignment: .leading, spacing: 20) {
            infoCard(
                eyebrow: "Step 1",
                title: "Name the climb",
                copy: "Give AIscend a little context so the routine feels personal from day one."
            )

            VStack(alignment: .leading, spacing: 12) {
                Text("What should AIscend call you?")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))

                TextField("Climber, founder, builder...", text: $model.profile.name)
                    .textInputAutocapitalization(.words)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.white.opacity(0.14), lineWidth: 1)
                    )
                    .foregroundStyle(.white)
            }
            .padding(22)
            .aiscendCard()

            VStack(alignment: .leading, spacing: 12) {
                Text("What are you ascending toward right now?")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))

                TextField(
                    "Ship the MVP, reclaim my mornings, finish the portfolio...",
                    text: $model.profile.intention,
                    axis: .vertical
                )
                .lineLimit(3...5)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.14), lineWidth: 1)
                )
                .foregroundStyle(.white)
            }
            .padding(22)
            .aiscendCard()
        }
    }

    private var focusStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            infoCard(
                eyebrow: "Step 2",
                title: "Choose your pace",
                copy: "This changes the voice of the dashboard and the kind of routine nudges AIscend gives you."
            )

            ForEach(FocusTrack.allCases) { track in
                Button {
                    withAnimation(.smooth(duration: 0.25)) {
                        model.profile.focusTrack = track
                    }
                } label: {
                    HStack(alignment: .top, spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(track == model.profile.focusTrack ? 0.22 : 0.12))
                                .frame(width: 50, height: 50)

                            Image(systemName: track.symbol)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(track.title)
                                .font(.system(.title3, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)

                            Text(track.subtitle)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(AIscendTheme.secondaryText)
                        }

                        Spacer()

                        Image(systemName: track == model.profile.focusTrack ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(track == model.profile.focusTrack ? AIscendTheme.sunrise : .white.opacity(0.45))
                    }
                    .padding(22)
                    .aiscendCard(highlighted: track == model.profile.focusTrack)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var rhythmStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            infoCard(
                eyebrow: "Step 3",
                title: "Set the rhythm",
                copy: "Pick the start time and habits that make your ascent repeatable, not exhausting."
            )

            VStack(alignment: .leading, spacing: 14) {
                Text("Preferred lift-off time")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))

                DatePicker(
                    "Preferred lift-off time",
                    selection: wakeUpBinding,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(AIscendTheme.sunrise)
                .foregroundStyle(.white)

                Text("Current target: \(model.profile.wakeLabel)")
                    .font(.system(.footnote, design: .rounded, weight: .medium))
                    .foregroundStyle(AIscendTheme.secondaryText)
            }
            .padding(22)
            .aiscendCard()

            VStack(alignment: .leading, spacing: 16) {
                Text("Habit anchors")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(HabitAnchor.allCases) { anchor in
                        Button {
                            withAnimation(.smooth(duration: 0.25)) {
                                model.toggleAnchor(anchor)
                            }
                        } label: {
                            AIscendCapsule(
                                title: anchor.title,
                                symbol: anchor.symbol,
                                isActive: model.profile.anchors.contains(anchor)
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(model.profile.anchorSummary)
                    .font(.system(.footnote, design: .rounded, weight: .medium))
                    .foregroundStyle(AIscendTheme.secondaryText)
            }
            .padding(22)
            .aiscendCard()
        }
    }

    private func infoCard(eyebrow: String, title: String, copy: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow)
                .font(.system(.footnote, design: .rounded, weight: .bold))
                .foregroundStyle(AIscendTheme.sunrise)

            Text(title)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            Text(copy)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(AIscendTheme.secondaryText)
        }
        .padding(22)
        .aiscendCard(highlighted: true)
    }

    private var footer: some View {
        HStack(spacing: 14) {
            if currentStep > 0 {
                Button("Back") {
                    withAnimation(.smooth(duration: 0.25)) {
                        currentStep -= 1
                    }
                }
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 14)
                .background(.white.opacity(0.10), in: Capsule(style: .continuous))
            }

            Spacer()

            Button(currentStep == totalSteps - 1 ? "Start my routine" : "Continue") {
                withAnimation(.smooth(duration: 0.25)) {
                    if currentStep < totalSteps - 1 {
                        currentStep += 1
                    } else {
                        model.completeOnboarding()
                    }
                }
            }
            .font(.system(.headline, design: .rounded, weight: .bold))
            .foregroundStyle(AIscendTheme.midnight)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(AIscendTheme.sunrise, in: Capsule(style: .continuous))
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
}

#Preview {
    OnboardingView(model: AppModel())
}
