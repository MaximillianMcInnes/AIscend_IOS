//
//  AIscendPremiumOnboardingExperienceView.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import Foundation
import SwiftUI
import UserNotifications

enum PremiumOnboardingStage: Int, CaseIterable {
    case splash, carousel, graph, plan, halo, impact, notifications, accuracy, goals, name

    static let visibleCount = allCases.count - 1

    var progressIndex: Int? { self == .splash ? nil : rawValue }

    var label: String {
        switch self {
        case .splash: "Intro"
        case .carousel: "System"
        case .graph: "Projection"
        case .plan: "Calibration"
        case .halo: "Psychology"
        case .impact: "Outcomes"
        case .notifications: "Consistency"
        case .accuracy: "Trust"
        case .goals: "Priorities"
        case .name: "Identity"
        }
    }
}

enum PremiumOnboardingDirection {
    case forward, backward
}

enum PremiumNotificationState {
    case idle, enabled, denied, unavailable

    var footerNote: String {
        switch self {
        case .idle: "Quiet reminders only. No clutter."
        case .enabled: "Notifications are enabled."
        case .denied: "You can enable reminders later in Settings."
        case .unavailable: "You can configure reminders later."
        }
    }

    var badgeTitle: String {
        switch self {
        case .idle: "Optional"
        case .enabled: "Enabled"
        case .denied: "Later"
        case .unavailable: "Unavailable"
        }
    }

    var badgeStyle: AIscendBadgeStyle {
        switch self {
        case .enabled: .success
        case .idle: .neutral
        case .denied, .unavailable: .subtle
        }
    }
}

struct OnboardingSlide: Identifiable {
    enum Kind {
        case analysis, metrics, strategy
    }

    let id = UUID()
    let eyebrow: String
    let title: String
    let copy: String
    let chips: [String]
    let kind: Kind

    static let defaultSlides: [OnboardingSlide] = [
        .init(
            eyebrow: "AI Analysis",
            title: "AI-Powered Facial Analysis",
            copy: "Understand your structure, not just your appearance.",
            chips: ["Structure map", "Symmetry read", "Profile insight"],
            kind: .analysis
        ),
        .init(
            eyebrow: "Metrics",
            title: "Optimise What Matters",
            copy: "Backed by facial metrics, not opinions.",
            chips: ["Signal over noise", "Data-forward", "Measurable shifts"],
            kind: .metrics
        ),
        .init(
            eyebrow: "Strategy",
            title: "Your Personal Upgrade Plan",
            copy: "Custom roadmap based on your face.",
            chips: ["Priority sequence", "Daily actions", "Long-term compounding"],
            kind: .strategy
        )
    ]
}

struct OnboardingImpactMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: Double
}

struct AIscendPremiumOnboardingExperienceView: View {
    @Bindable var model: AppModel
    let isAuthenticated: Bool

    @State private var stage: PremiumOnboardingStage = .splash
    @State private var direction: PremiumOnboardingDirection = .forward
    @State private var planProgress = 0.0
    @State private var planMarker = 0
    @State private var notificationState: PremiumNotificationState = .idle
    @State private var isRequestingNotifications = false
    @FocusState private var isNameFocused: Bool

    private let stageAnimation = Animation.easeInOut(duration: 0.55)
    private let slides = OnboardingSlide.defaultSlides
    private let planSteps = [
        "Analyzing growth factors",
        "Scanning genetic data",
        "Mapping growth window",
        "Building your plan",
        "Setting daily routine"
    ]
    private let impactMetrics = [
        OnboardingImpactMetric(title: "Dating", value: 0.80),
        OnboardingImpactMetric(title: "Popularity", value: 0.65),
        OnboardingImpactMetric(title: "Career", value: 0.35),
        OnboardingImpactMetric(title: "Income", value: 0.30)
    ]

    var body: some View {
        ZStack {
            if stage == .splash { PremiumSplashBackdrop() } else { AIscendBackdrop() }

            VStack(spacing: 0) {
                if stage != .splash { header }

                ZStack {
                    screen
                        .id(stage.rawValue)
                        .transition(screenTransition)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(stageAnimation, value: stage)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if stage != .splash, let buttonTitle = primaryButtonTitle {
                footer(buttonTitle: buttonTitle)
                    .padding(.horizontal, AIscendTheme.Spacing.mediumLarge)
                    .padding(.top, AIscendTheme.Spacing.small)
                    .padding(.bottom, AIscendTheme.Spacing.mediumLarge)
                    .background(
                        LinearGradient(
                            colors: [
                                AIscendTheme.Colors.appBackground.opacity(0),
                                AIscendTheme.Colors.appBackground.opacity(0.88),
                                AIscendTheme.Colors.appBackground
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
        .task(id: stage) {
            await handleLifecycle()
        }
    }

    private var header: some View {
        HStack {
            if stage.rawValue > 1 {
                Button { stepBack() } label: {
                    ZStack {
                        Circle().fill(AIscendTheme.Colors.surfaceHighlight).frame(width: 44, height: 44)
                        Circle().stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1).frame(width: 44, height: 44)
                        Image(systemName: "arrow.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 44, height: 44)
            }

            Spacer()

            VStack(spacing: 4) {
                Text(stage.label.uppercased())
                    .aiscendTextStyle(.eyebrow, color: AIscendTheme.Colors.accentGlow)

                if let progressIndex = stage.progressIndex {
                    Text("\(progressIndex) / \(PremiumOnboardingStage.visibleCount)")
                        .aiscendTextStyle(.caption)
                }
            }

            Spacer()

            AIscendBrandMark(size: 34, showsWordmark: false)
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, AIscendTheme.Spacing.screenInset)
        .padding(.top, AIscendTheme.Spacing.medium)
    }

    @ViewBuilder
    private var screen: some View {
        switch stage {
        case .splash:
            PremiumSplashIntro()
        case .carousel:
            scroller { PremiumCarouselDeck(slides: slides) }
        case .graph:
            scroller {
                PremiumStageSection(
                    eyebrow: "Future Outcome",
                    title: "Optimisation creates long-term results",
                    subtitle: "Most people never reach their potential due to poor habits."
                ) {
                    PremiumProjectionCard()
                }
            }
        case .plan:
            scroller {
                PremiumStageSection(eyebrow: "Plan Generation", title: "Building your plan...", subtitle: nil) {
                    PremiumPlanCard(progress: planProgress, steps: planSteps, marker: planMarker)
                }
            }
        case .halo:
            scroller {
                PremiumStageSection(
                    eyebrow: "The Halo Effect",
                    title: "The Halo Effect",
                    subtitle: "People subconsciously assign traits like intelligence and success based on appearance."
                ) {
                    PremiumHaloCards()
                    PremiumGlassCard(emphasis: true) {
                        Text("Perception is reality")
                            .aiscendTextStyle(.sectionTitle)
                        Text("How you look influences how you're treated.")
                            .aiscendTextStyle(.body)
                    }
                }
            }
        case .impact:
            scroller {
                PremiumStageSection(eyebrow: "Influence", title: "Attractiveness influences outcomes", subtitle: nil) {
                    PremiumImpactBars(metrics: impactMetrics)
                    Text("Most people underestimate this.")
                        .aiscendTextStyle(.body)
                }
            }
        case .notifications:
            scroller {
                PremiumStageSection(
                    eyebrow: "Consistency",
                    title: "Stay consistent",
                    subtitle: "We'll remind you to follow your routine and track progress."
                ) {
                    PremiumNotificationCard(state: notificationState, isBusy: isRequestingNotifications)
                }
            }
        case .accuracy:
            scroller {
                PremiumStageSection(eyebrow: "Accuracy", title: "Built for accuracy", subtitle: nil) {
                    PremiumAccuracyBlock()
                }
            }
        case .goals:
            scroller {
                PremiumStageSection(
                    eyebrow: "Goals",
                    title: "What do you want to improve?",
                    subtitle: "Choose every area that matters right now."
                ) {
                    PremiumGoalsGrid(model: model)
                    PremiumGlassCard(emphasis: !model.analysisGoals.isEmpty) {
                        Text(model.analysisGoals.isEmpty ? "Select at least one priority." : model.analysisGoalSummary)
                            .aiscendTextStyle(.sectionTitle)
                        Text(
                            model.analysisGoals.isEmpty
                            ? "Your selections shape the tone of the plan."
                            : "AIScend will frame the first strategy around these priorities."
                        )
                        .aiscendTextStyle(.body)
                    }
                }
            }
        case .name:
            scroller {
                PremiumStageSection(
                    eyebrow: "Identity",
                    title: "What should we call you?",
                    subtitle: "A small detail, but it makes the system feel personal."
                ) {
                    PremiumNameCard(name: $model.profile.name, isFocused: $isNameFocused)
                }
            }
        }
    }

    private func scroller<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView(showsIndicators: false) {
            content()
                .frame(maxWidth: 620, alignment: .leading)
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, 164)
                .frame(maxWidth: .infinity, alignment: .top)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var primaryButtonTitle: String? {
        switch stage {
        case .splash, .plan: nil
        case .notifications:
            if isRequestingNotifications { return "Requesting Access" }
            return notificationState == .idle ? "Enable Notifications" : "Continue"
        case .name:
            return isAuthenticated ? "Enter AIScend" : "Continue"
        case .goals:
            return "Continue"
        default:
            return "Next"
        }
    }

    private var screenTransition: AnyTransition {
        let insertion: Edge = direction == .forward ? .trailing : .leading
        let removal: Edge = direction == .forward ? .leading : .trailing
        return .asymmetric(
            insertion: .opacity.combined(with: .move(edge: insertion)),
            removal: .opacity.combined(with: .move(edge: removal))
        )
    }

    private func footer(buttonTitle: String) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            if stage == .goals && model.analysisGoals.isEmpty {
                Text("Select at least one area to personalise the experience.")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.warning)
                    .padding(.horizontal, AIscendTheme.Spacing.xSmall)
            }

            if stage == .notifications {
                Text(notificationState.footerNote)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                    .padding(.horizontal, AIscendTheme.Spacing.xSmall)
            }

            Button { handlePrimaryAction() } label: {
                AIscendButtonLabel(
                    title: buttonTitle,
                    trailingSymbol: stage == .name && !isAuthenticated ? "lock.fill" : "arrow.right"
                )
            }
            .buttonStyle(AIscendButtonStyle(variant: .primary))
            .disabled(stage == .goals ? model.analysisGoals.isEmpty : isRequestingNotifications)
            .opacity(stage == .goals && model.analysisGoals.isEmpty ? 0.58 : 1)
        }
    }

    private func handlePrimaryAction() {
        switch stage {
        case .notifications:
            Task { await requestNotifications() }
        case .name:
            model.profile.name = model.profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
            withAnimation(stageAnimation) { model.completeOnboardingExperience() }
        default:
            stepForward()
        }
    }

    private func handleLifecycle() async {
        switch stage {
        case .splash:
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { stepForward() }
        case .plan:
            await runPlanSequence()
        case .notifications:
            await refreshNotificationState()
        case .name:
            await MainActor.run { isNameFocused = true }
        default:
            break
        }
    }

    private func runPlanSequence() async {
        await MainActor.run {
            planProgress = 0
            planMarker = 0
        }

        let marks: [(Double, Int, UInt64)] = [
            (0.18, 1, 550_000_000),
            (0.34, 2, 620_000_000),
            (0.48, 3, 620_000_000),
            (0.61, 4, 620_000_000),
            (0.72, 4, 550_000_000)
        ]

        for mark in marks {
            try? await Task.sleep(nanoseconds: mark.2)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(stageAnimation) {
                    planProgress = mark.0
                    planMarker = mark.1
                }
            }
        }

        try? await Task.sleep(nanoseconds: 650_000_000)
        guard !Task.isCancelled else { return }
        await MainActor.run { stepForward() }
    }

    private func refreshNotificationState() async {
        let settings = await notificationSettings()
        let next: PremiumNotificationState
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: next = .enabled
        case .denied: next = .denied
        case .notDetermined: next = .idle
        @unknown default: next = .unavailable
        }
        await MainActor.run { notificationState = next }
    }

    private func requestNotifications() async {
        guard !isRequestingNotifications else { return }
        await MainActor.run { isRequestingNotifications = true }
        defer { Task { @MainActor in isRequestingNotifications = false } }

        let settings = await notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            await MainActor.run { notificationState = .enabled; stepForward() }
        case .denied:
            await MainActor.run { notificationState = .denied; stepForward() }
        case .notDetermined:
            let granted: Bool = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
            await MainActor.run { notificationState = granted ? .enabled : .denied; stepForward() }
        @unknown default:
            await MainActor.run { notificationState = .unavailable; stepForward() }
        }
    }

    private func notificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { (continuation: CheckedContinuation<UNNotificationSettings, Never>) in
            UNUserNotificationCenter.current().getNotificationSettings { continuation.resume(returning: $0) }
        }
    }

    private func stepForward() {
        guard let next = PremiumOnboardingStage(rawValue: stage.rawValue + 1) else { return }
        direction = .forward
        withAnimation(stageAnimation) { stage = next }
    }

    private func stepBack() {
        guard let previous = PremiumOnboardingStage(rawValue: stage.rawValue - 1) else { return }
        direction = .backward
        withAnimation(stageAnimation) { stage = previous }
    }
}

#Preview {
    AIscendPremiumOnboardingExperienceView(model: AppModel(), isAuthenticated: false)
        .preferredColorScheme(.dark)
}
