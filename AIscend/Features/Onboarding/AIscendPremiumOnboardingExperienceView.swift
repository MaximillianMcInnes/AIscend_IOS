//
//  AIscendPremiumOnboardingExperienceView.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import Foundation
import SwiftUI
import UserNotifications

enum PremiumOnboardingChapter: Int, CaseIterable {
    case discover
    case prove
    case configure

    var title: String {
        switch self {
        case .discover: "Discover"
        case .prove: "Proof"
        case .configure: "Setup"
        }
    }

    var detail: String {
        switch self {
        case .discover:
            "See the promise quickly, with only the essentials on each screen."
        case .prove:
            "Build trust before asking the user to commit to the workflow."
        case .configure:
            "Personalize the first session so the product feels immediately useful."
        }
    }
}

enum PremiumOnboardingStage: Int, CaseIterable {
    case splash, carousel, graph, plan, halo, impact, notifications, accuracy, goals, name

    static let visibleCount = allCases.count - 1

    var progressIndex: Int? {
        self == .splash ? nil : rawValue
    }

    var chapter: PremiumOnboardingChapter {
        switch self {
        case .splash, .carousel, .graph:
            .discover
        case .plan, .halo, .impact, .accuracy:
            .prove
        case .notifications, .goals, .name:
            .configure
        }
    }

    var label: String {
        switch self {
        case .splash: "Intro"
        case .carousel: "System"
        case .graph: "Projection"
        case .plan: "Calibration"
        case .halo: "Perception"
        case .impact: "Outcomes"
        case .notifications: "Consistency"
        case .accuracy: "Trust"
        case .goals: "Priorities"
        case .name: "Identity"
        }
    }
}

enum PremiumOnboardingDirection {
    case forward
    case backward
}

enum PremiumNotificationState {
    case idle
    case enabled
    case denied
    case unavailable

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
}

struct OnboardingSlide: Identifiable {
    enum Kind {
        case analysis
        case metrics
        case strategy
    }

    let id = UUID()
    let eyebrow: String
    let title: String
    let copy: String
    let chips: [String]
    let kind: Kind

    static let defaultSlides: [OnboardingSlide] = [
        .init(
            eyebrow: "System",
            title: "See structure with a calmer frame",
            copy: "AIScend organizes front and side analysis into a guided reveal instead of a noisy score dump.",
            chips: ["Front + side input", "Structured reveal", "Private-first flow"],
            kind: .analysis
        ),
        .init(
            eyebrow: "Signal",
            title: "Focus on the levers that move presentation",
            copy: "The product is designed to surface what already reads well and where refinement has the clearest payoff.",
            chips: ["Signal over noise", "Feature prioritization", "Better capture discipline"],
            kind: .metrics
        ),
        .init(
            eyebrow: "Action",
            title: "Leave with a starting plan, not just a reaction",
            copy: "Onboarding sets the tone for a more deliberate improvement loop from the first scan onward.",
            chips: ["Priority sequence", "Daily rhythm", "Compounding improvements"],
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
        "Scanning capture quality",
        "Mapping improvement window",
        "Building your first plan",
        "Setting the opening routine"
    ]
    private let impactMetrics = [
        OnboardingImpactMetric(title: "Dating", value: 0.80),
        OnboardingImpactMetric(title: "Popularity", value: 0.65),
        OnboardingImpactMetric(title: "Career", value: 0.35),
        OnboardingImpactMetric(title: "Income", value: 0.30)
    ]

    private var currentChapter: PremiumOnboardingChapter {
        stage.chapter
    }

    var body: some View {
        ZStack {
            PremiumOnboardingAtmosphere(stage: stage)

            VStack(spacing: 0) {
                if stage != .splash {
                    header
                }

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
                                Color.clear,
                                PremiumOnboardingPalette.background.opacity(0.84),
                                PremiumOnboardingPalette.background
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
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack {
                if stage.rawValue > 1 {
                    Button(action: stepBack) {
                        ZStack {
                            Circle()
                                .fill(PremiumOnboardingPalette.surfaceStrong)
                                .frame(width: 44, height: 44)
                            Circle()
                                .stroke(PremiumOnboardingPalette.borderStrong, lineWidth: 1)
                                .frame(width: 44, height: 44)
                            Image(systemName: "arrow.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(PremiumOnboardingPalette.textPrimary)
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(width: 44, height: 44)
                }

                Spacer()

                AIscendBrandMark(size: 34, showsWordmark: false)
                    .frame(width: 44, height: 44)

                Spacer()

                Button(action: skipFlow) {
                    Text(skipButtonTitle)
                        .aiscendTextStyle(.caption, color: PremiumOnboardingPalette.textPrimary)
                        .padding(.horizontal, AIscendTheme.Spacing.medium)
                        .padding(.vertical, AIscendTheme.Spacing.small)
                        .background(
                            Capsule(style: .continuous)
                                .fill(PremiumOnboardingPalette.surfaceStrong)
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(PremiumOnboardingPalette.borderStrong, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            PremiumOnboardingHeaderCard(
                chapter: currentChapter,
                stage: stage,
                visibleIndex: stage.progressIndex ?? 0,
                visibleCount: PremiumOnboardingStage.visibleCount
            )
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
            scroller {
                PremiumStageSection(
                    eyebrow: "Discover",
                    title: "AIScend turns facial analysis into a guided premium flow",
                    subtitle: "We show the system first, then the proof, then the setup. No clutter."
                ) {
                    PremiumCarouselDeck(slides: slides)
                }
            }
        case .graph:
            scroller {
                PremiumStageSection(
                    eyebrow: "Step 1",
                    title: "Start with a system that reduces guesswork",
                    subtitle: "AIScend turns raw capture data into a guided, easier-to-read breakdown from the beginning."
                ) {
                    PremiumProjectionCard()
                    PremiumOnboardingNoteCard(
                        title: "Why this matters",
                        detail: "The onboarding should quickly explain the value loop: cleaner input, clearer read, better action."
                    )
                }
            }
        case .plan:
            scroller {
                PremiumStageSection(
                    eyebrow: "Step 2",
                    title: "Build confidence before asking for commitment",
                    subtitle: "This stage keeps the experience feeling premium and deliberate while the plan calibrates."
                ) {
                    PremiumPlanCard(progress: planProgress, steps: planSteps, marker: planMarker)
                }
            }
        case .halo:
            scroller {
                PremiumStageSection(
                    eyebrow: "Perception",
                    title: "Presentation changes how people read you before you speak",
                    subtitle: "The point is not vanity. It is understanding how first-impression signals compound."
                ) {
                    PremiumHaloCards()
                    PremiumOnboardingNoteCard(
                        title: "Perception compounds",
                        detail: "A premium onboarding flow should connect analysis to outcomes without drifting into cheap fear tactics."
                    )
                }
            }
        case .impact:
            scroller {
                PremiumStageSection(
                    eyebrow: "Outcomes",
                    title: "Looks leak into real-world outcomes",
                    subtitle: "AIScend frames this as leverage: stronger presentation can affect social, romantic, and professional reads."
                ) {
                    PremiumImpactBars(metrics: impactMetrics)
                    PremiumOnboardingNoteCard(
                        title: "Keep it measured",
                        detail: "We show believable impact ranges here so the product feels grounded rather than exaggerated."
                    )
                }
            }
        case .notifications:
            scroller {
                PremiumStageSection(
                    eyebrow: "Step 3",
                    title: "Set up a low-noise consistency loop",
                    subtitle: "Quiet reminders help the plan stick without making the app feel needy."
                ) {
                    PremiumNotificationCard(state: notificationState, isBusy: isRequestingNotifications)
                }
            }
        case .accuracy:
            scroller {
                PremiumStageSection(
                    eyebrow: "Trust",
                    title: "Accuracy depends on disciplined capture",
                    subtitle: "The product feels more premium when it explains what powers the read and what improves it."
                ) {
                    PremiumAccuracyBlock()
                }
            }
        case .goals:
            scroller {
                PremiumStageSection(
                    eyebrow: "Priorities",
                    title: "Choose the levers you want AIScend to prioritize",
                    subtitle: "Multiple selections are allowed. This tunes the first strategy around what you care about most."
                ) {
                    PremiumGoalsGrid(model: model)
                    PremiumOnboardingSelectionSummary(
                        summary: model.analysisGoalSummary,
                        hasSelection: !model.analysisGoals.isEmpty
                    )
                }
            }
        case .name:
            scroller {
                PremiumStageSection(
                    eyebrow: "Identity",
                    title: isAuthenticated ? "Finish setting up your workspace" : "One last detail before sign in",
                    subtitle: "A small touch, but it makes the system feel like it belongs to you from the first scan."
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
                .padding(.bottom, 172)
                .frame(maxWidth: .infinity, alignment: .top)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var primaryButtonTitle: String? {
        switch stage {
        case .splash, .plan:
            return nil
        case .notifications:
            if isRequestingNotifications {
                return "Requesting Access"
            }
            return notificationState == .idle ? "Enable Quiet Reminders" : "Continue Setup"
        case .name:
            return isAuthenticated ? "Enter AIScend" : "Continue to Sign In"
        case .goals:
            return "Continue Setup"
        case .carousel:
            return "See How It Works"
        case .graph:
            return "Show Me The Proof"
        case .halo, .impact, .accuracy:
            return "Keep Going"
        }
    }

    private var skipButtonTitle: String {
        isAuthenticated ? "Skip" : "Skip to sign in"
    }

    private var footerHeadline: String {
        switch currentChapter {
        case .discover:
            "Discover the product"
        case .prove:
            "Build confidence"
        case .configure:
            "Personalize the setup"
        }
    }

    private var footerDetail: String {
        if stage == .goals && model.analysisGoals.isEmpty {
            return "Select at least one area so the first strategy feels tailored instead of generic."
        }

        if stage == .notifications {
            return notificationState.footerNote
        }

        return currentChapter.detail
    }

    private var primaryDisabled: Bool {
        stage == .goals ? model.analysisGoals.isEmpty : isRequestingNotifications
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
        PremiumOnboardingActionDock(
            title: footerHeadline,
            detail: footerDetail,
            buttonTitle: buttonTitle,
            buttonSymbol: stage == .name && !isAuthenticated ? "lock.fill" : "arrow.right",
            disabled: primaryDisabled,
            action: handlePrimaryAction
        )
    }

    private func handlePrimaryAction() {
        switch stage {
        case .notifications:
            Task {
                await requestNotifications()
            }
        case .name:
            model.profile.name = model.profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
            withAnimation(stageAnimation) {
                model.completeOnboardingExperience()
            }
        default:
            stepForward()
        }
    }

    private func skipFlow() {
        withAnimation(stageAnimation) {
            if isAuthenticated {
                model.completeOnboarding()
            } else {
                model.completeEntryOnboarding()
            }
        }
    }

    private func handleLifecycle() async {
        switch stage {
        case .splash:
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else {
                return
            }
            await MainActor.run {
                stepForward()
            }
        case .plan:
            await runPlanSequence()
        case .notifications:
            await refreshNotificationState()
        case .name:
            await MainActor.run {
                isNameFocused = true
            }
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
            guard !Task.isCancelled else {
                return
            }
            await MainActor.run {
                withAnimation(stageAnimation) {
                    planProgress = mark.0
                    planMarker = mark.1
                }
            }
        }

        try? await Task.sleep(nanoseconds: 650_000_000)
        guard !Task.isCancelled else {
            return
        }
        await MainActor.run {
            stepForward()
        }
    }

    private func refreshNotificationState() async {
        let settings = await notificationSettings()
        let next: PremiumNotificationState

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            next = .enabled
        case .denied:
            next = .denied
        case .notDetermined:
            next = .idle
        @unknown default:
            next = .unavailable
        }

        await MainActor.run {
            notificationState = next
        }
    }

    private func requestNotifications() async {
        guard !isRequestingNotifications else {
            return
        }

        await MainActor.run {
            isRequestingNotifications = true
        }

        defer {
            Task { @MainActor in
                isRequestingNotifications = false
            }
        }

        let settings = await notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            await MainActor.run {
                notificationState = .enabled
                stepForward()
            }
        case .denied:
            await MainActor.run {
                notificationState = .denied
                stepForward()
            }
        case .notDetermined:
            let granted: Bool = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
            await MainActor.run {
                notificationState = granted ? .enabled : .denied
                stepForward()
            }
        @unknown default:
            await MainActor.run {
                notificationState = .unavailable
                stepForward()
            }
        }
    }

    private func notificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { (continuation: CheckedContinuation<UNNotificationSettings, Never>) in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    private func stepForward() {
        guard let next = PremiumOnboardingStage(rawValue: stage.rawValue + 1) else {
            return
        }

        direction = .forward
        withAnimation(stageAnimation) {
            stage = next
        }
    }

    private func stepBack() {
        guard let previous = PremiumOnboardingStage(rawValue: stage.rawValue - 1) else {
            return
        }

        direction = .backward
        withAnimation(stageAnimation) {
            stage = previous
        }
    }
}

#Preview {
    AIscendPremiumOnboardingExperienceView(model: AppModel(), isAuthenticated: false)
        .preferredColorScheme(.dark)
}
