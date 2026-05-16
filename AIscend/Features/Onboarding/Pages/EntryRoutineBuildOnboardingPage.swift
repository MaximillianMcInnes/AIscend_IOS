//
//  EntryRoutineBuildOnboardingPage.swift
//  AIscend
//

import SwiftUI

struct EntryRoutineBuildOnboardingPage: View {
    let dedicationMinutes: Double
    let goals: [AnalysisGoal]
    @Binding var isComplete: Bool

    @State private var ringsVisible = false
    @State private var stepsVisible = false
    @State private var orbitRotates = false
    @State private var sparklePulse = false
    @State private var buildProgress: Double = 0
    @State private var activeStep = 0
    @State private var buildTask: Task<Void, Never>?

    private var primaryGoals: [AnalysisGoal] {
        Array((goals.isEmpty ? [.overallAttractiveness, .skin, .symmetry] : goals).prefix(3))
    }

    private var buildSteps: [PlanBuildStep] {
        [
            PlanBuildStep(title: "Reading scan setup", detail: "Front, side, and calibration context", symbol: "faceid"),
            PlanBuildStep(title: "Mapping priorities", detail: primaryGoals.map(\.shortTitle).joined(separator: " + "), symbol: "sparkles"),
            PlanBuildStep(title: "Setting cadence", detail: "\(minutesLabel) minute daily commitment", symbol: "clock.fill"),
            PlanBuildStep(title: "Building routine", detail: "Exercises, check-ins, and scan reminders", symbol: "wand.and.stars"),
            PlanBuildStep(title: "AIScend plan ready", detail: "Saved for secure sign in", symbol: "checkmark.seal.fill")
        ]
    }

    private var minutesLabel: String {
        let minutes = Int(dedicationMinutes.rounded())
        return minutes >= 60 ? "60+" : "\(minutes)"
    }

    var body: some View {
        EntryOnboardingPageContainer(
            title: isComplete ? "Your routine is ready" : "Building your AIScend plan",
            subtitle: "AIScend is turning your scan setup, goals, and daily commitment into your first routine before you sign in.",
            usesTypewriterSubtitle: false
        ) {
            VStack(spacing: 14) {
                routineOrb
                    .frame(maxWidth: .infinity)

                VStack(spacing: 9) {
                    ForEach(Array(buildSteps.enumerated()), id: \.element.id) { index, step in
                        routineStep(step: step, index: index)
                            .opacity(stepsVisible ? 1 : 0)
                            .offset(y: stepsVisible ? 0 : 18)
                            .animation(
                                .smooth(duration: 0.32).delay(Double(index) * 0.08),
                                value: stepsVisible
                            )
                    }
                }
            }
            .onAppear {
                isComplete = false
                ringsVisible = false
                stepsVisible = false
                orbitRotates = false
                sparklePulse = false
                buildProgress = 0
                activeStep = 0

                withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true)) {
                    ringsVisible = true
                }

                withAnimation(.linear(duration: 5.2).repeatForever(autoreverses: false)) {
                    orbitRotates = true
                }

                withAnimation(.easeInOut(duration: 0.86).repeatForever(autoreverses: true)) {
                    sparklePulse = true
                }

                withAnimation(.smooth(duration: 0.1).delay(0.18)) {
                    stepsVisible = true
                }

                startBuildSequence()
            }
            .onDisappear {
                buildTask?.cancel()
                buildTask = nil
            }
        }
    }

    private var routineOrb: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: max(buildProgress, 0.04))
                .stroke(
                    AngularGradient(
                        colors: [
                            EntryOnboardingStyle.purpleSoft,
                            .white.opacity(0.88),
                            EntryOnboardingStyle.purple,
                            EntryOnboardingStyle.purpleSoft
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 194, height: 194)
                .rotationEffect(.degrees(-90))
                .shadow(color: EntryOnboardingStyle.purpleSoft.opacity(0.36), radius: 18)
                .animation(.spring(response: 0.42, dampingFraction: 0.82), value: buildProgress)

            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .stroke(
                        EntryOnboardingStyle.purpleSoft.opacity(0.18 + Double(ring) * 0.11),
                        lineWidth: CGFloat(10 - ring * 2)
                    )
                    .frame(width: CGFloat(132 + ring * 30), height: CGFloat(132 + ring * 30))
                    .scaleEffect(ringsVisible ? 1 + CGFloat(ring) * 0.025 : 0.96)
                    .opacity(ringsVisible ? 1 : 0.58)
            }

            ForEach(0..<6, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index.isMultiple(of: 2) ? EntryOnboardingStyle.purpleSoft : .white.opacity(0.72))
                    .frame(width: 6, height: index.isMultiple(of: 2) ? 18 : 12)
                    .offset(y: -104)
                    .rotationEffect(.degrees(Double(index) * 60 + (orbitRotates ? 360 : 0)))
                    .opacity(isComplete ? 0.26 : 0.78)
                    .blur(radius: index.isMultiple(of: 2) ? 0 : 0.5)
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            EntryOnboardingStyle.purple.opacity(0.58),
                            EntryOnboardingStyle.purpleDeep.opacity(0.26),
                            Color.white.opacity(0.06)
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 132
                    )
                )
                .frame(width: 152, height: 152)
                .shadow(color: EntryOnboardingStyle.purple.opacity(0.38), radius: 34, x: 0, y: 16)

            VStack(spacing: 8) {
                Image(systemName: isComplete ? "checkmark" : "sparkles")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
                    .scaleEffect(sparklePulse && !isComplete ? 1.16 : 1)
                    .shadow(color: EntryOnboardingStyle.purpleSoft.opacity(sparklePulse ? 0.62 : 0.22), radius: 14)

                Text(isComplete ? "Ready" : "\(Int(buildProgress * 100))%")
                    .font(.system(size: 35, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                Text(isComplete ? "daily plan" : "building")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(EntryOnboardingStyle.purpleSoft)
            }
        }
        .frame(height: 214)
        .rotationEffect(.degrees(isComplete ? 0 : 0.001))
        .animation(.smooth(duration: 0.24), value: buildProgress)
        .animation(.spring(response: 0.36, dampingFraction: 0.76), value: isComplete)
    }

    private func routineStep(step: PlanBuildStep, index: Int) -> some View {
        let isActive = index == activeStep && !isComplete
        let isDone = isComplete || index < activeStep

        return HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill((isDone || isActive) ? EntryOnboardingStyle.purple.opacity(0.22) : Color.white.opacity(0.07))

                Image(systemName: isDone ? "checkmark" : step.symbol)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle((isDone || isActive) ? EntryOnboardingStyle.purpleSoft : Color.white.opacity(0.44))
            }
            .frame(width: 38, height: 38)
            .scaleEffect(isActive ? 1.08 : 1)

            VStack(alignment: .leading, spacing: 5) {
                Text(step.title)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text(step.detail.isEmpty ? "Balancing your first routine" : step.detail)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(EntryOnboardingStyle.mutedText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.84)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 23, weight: .bold))
                .foregroundStyle(isDone ? EntryOnboardingStyle.purpleSoft : Color.white.opacity(0.20))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isActive ? EntryOnboardingStyle.purple.opacity(0.13) : EntryOnboardingStyle.panelStrong)
        )
        .shadow(
            color: EntryOnboardingStyle.purple.opacity(isActive ? 0.18 : 0),
            radius: isActive ? 18 : 0,
            x: 0,
            y: 8
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isActive ? EntryOnboardingStyle.purpleSoft.opacity(0.48) : Color.white.opacity(0.07), lineWidth: 1)
        )
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: activeStep)
        .animation(.smooth(duration: 0.22), value: isComplete)
    }

    private func startBuildSequence() {
        buildTask?.cancel()
        let steps = buildSteps.count

        buildTask = Task {
            for step in 0..<steps {
                guard !Task.isCancelled else {
                    return
                }

                await MainActor.run {
                    withAnimation(.smooth(duration: 0.28)) {
                        activeStep = step
                        buildProgress = Double(step) / Double(max(steps, 1))
                    }
                    EntryOnboardingHaptics.selection()
                }

                try? await Task.sleep(nanoseconds: 840_000_000)
            }

            await MainActor.run {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                    buildProgress = 1
                    activeStep = steps
                    isComplete = true
                }
                EntryOnboardingHaptics.success()
            }
        }
    }
}

private struct PlanBuildStep: Identifiable {
    let title: String
    let detail: String
    let symbol: String

    var id: String { title }
}

#Preview {
    EntryRoutineBuildOnboardingPage(
        dedicationMinutes: 60,
        goals: [.jawline, .skin, .symmetry],
        isComplete: .constant(false)
    )
    .background(Color.black)
}
