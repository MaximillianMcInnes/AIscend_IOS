//
//  RoutineDashboardView.swift
//  AIscend
//
//  Created by Codex on 4/7/26.
//

import SwiftUI

struct RoutineDashboardView: View {
    @Bindable var model: AppModel
    @ObservedObject var dailyCheckInStore: DailyCheckInStore
    @ObservedObject var badgeManager: BadgeManager
    var onOpenAdvisor: () -> Void = {}
    var onOpenRoutine: () -> Void = {}
    var onOpenCheckIn: () -> Void = {}
    var onOpenConsistency: () -> Void = {}
    var onOpenAccount: () -> Void = {}
    var onRefine: () -> Void = {}

    @State private var hasAppeared = false
    @State private var showingPremium = false
    @StateObject private var shareCoordinator = ShareCoordinator()

    private var snapshot: DashboardSnapshot {
        .live(from: model)
    }

    private var firstName: String {
        let trimmed = model.profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "Climber"
        }

        return trimmed.split(separator: " ").first.map(String.init) ?? trimmed
    }

    private var avatarInitials: String {
        let parts = model.profile.displayName
            .split(separator: " ")
            .map(String.init)

        if parts.count >= 2 {
            return String(parts.prefix(2).compactMap(\.first)).uppercased()
        }

        let fallback = String(model.profile.displayName.prefix(2)).uppercased()
        return fallback.isEmpty ? "AI" : fallback
    }

    private var scanCountLabel: String {
        let count = snapshot.scans.count
        return count == 1 ? "1 baseline" : "\(count) baselines"
    }

    private var liveStreakDays: Int {
        dailyCheckInStore.snapshot.currentStreak
    }

    private var checkedInToday: Bool {
        dailyCheckInStore.hasCheckedInToday
    }

    private var routinePreviewSteps: [RoutineStep] {
        let allSteps = model.routineSections.flatMap(\.steps)
        let openSteps = allSteps.filter { !$0.isComplete }
        let completedSteps = allSteps.filter(\.isComplete)
        return Array((openSteps + completedSteps).prefix(3))
    }

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
                        DashboardHeader(
                            greeting: "\(model.greeting), \(firstName)",
                            subtitle: snapshot.headerSubtitle,
                            streakDays: liveStreakDays,
                            checkedInToday: checkedInToday,
                            initials: avatarInitials,
                            onOpenStreaks: onOpenConsistency,
                            onOpenAccount: onOpenAccount
                        )
                        .dashboardReveal(isVisible: hasAppeared, delay: 0.02)

                        DashboardHeroCard(
                            snapshot: snapshot,
                            scanCountLabel: scanCountLabel,
                            onPrimary: onOpenAdvisor,
                            onSecondary: onOpenRoutine
                        )
                        .dashboardReveal(isVisible: hasAppeared, delay: 0.08)

                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                            DashboardSectionHeading(
                                eyebrow: "Command",
                                title: "Quick access",
                                subtitle: "Move across scans, routines, strategy, and your deeper archive without breaking focus."
                            )

                            DashboardGlassCard(tone: .subtle) {
                                DashboardQuickActionGrid { action in
                                    handle(action, proxy: proxy)
                                }
                            }
                        }
                        .dashboardReveal(isVisible: hasAppeared, delay: 0.14)

                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                            DashboardSectionHeading(
                                eyebrow: "Analytics",
                                title: "Measured movement",
                                subtitle: "Your score, cadence, and improvement signals are designed to read like a control surface instead of a noisy habit app."
                            )

                            DashboardProgressCard(snapshot: snapshot)
                        }
                        .id(DashboardSectionID.analytics)
                        .dashboardReveal(isVisible: hasAppeared, delay: 0.20)

                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                            DashboardSectionHeading(
                                eyebrow: "Signals",
                                title: "Where the leverage sits",
                                subtitle: "AIScend keeps the analysis concise so attention stays on the highest-return variables."
                            )

                            DashboardInsightsDeck(insights: snapshot.insights)
                        }
                        .id(DashboardSectionID.insights)
                        .dashboardReveal(isVisible: hasAppeared, delay: 0.26)

                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                            DashboardSectionHeading(
                                eyebrow: "Consistency",
                                title: "Today's operating layer",
                                subtitle: "Quiet execution is still the fastest way to move the read."
                            )

                            DashboardRoutineCard(
                                progress: model.progress,
                                streakDays: liveStreakDays,
                                checkedInToday: checkedInToday,
                                steps: routinePreviewSteps,
                                onToggle: toggle,
                                onShare: {
                                    shareCoordinator.present(
                                        .routineProgress(
                                            progress: model.progress,
                                            streakDays: liveStreakDays,
                                            nextStep: model.nextOpenStep,
                                            identityLine: AIScendSharePayload.identityLine(displayName: model.profile.displayName)
                                        )
                                    )
                                },
                                onOpenCheckIn: onOpenCheckIn,
                                onOpenConsistency: onOpenConsistency,
                                onOpenRoutine: onOpenRoutine
                            )
                        }
                        .id(DashboardSectionID.routine)
                        .dashboardReveal(isVisible: hasAppeared, delay: 0.32)

                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                            DashboardSectionHeading(
                                eyebrow: "Archive",
                                title: "Recent baselines",
                                subtitle: "A clean preview of the latest reads and capture context."
                            )

                            DashboardScanArchiveCard(scans: snapshot.scans)
                        }
                        .id(DashboardSectionID.scans)
                        .dashboardReveal(isVisible: hasAppeared, delay: 0.38)

                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                            DashboardSectionHeading(
                                eyebrow: "Advanced",
                                title: "Go deeper when you want sharper reads",
                                subtitle: "Premium should feel like unlocking another layer of the system, not a loud interruption."
                            )

                            DashboardPremiumCard {
                                showingPremium = true
                            }
                        }
                        .id(DashboardSectionID.premium)
                        .dashboardReveal(isVisible: hasAppeared, delay: 0.44)
                    }
                    .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                    .padding(.top, AIscendTheme.Spacing.large)
                    .padding(.bottom, AIscendTheme.Spacing.xxLarge + AIscendTheme.Spacing.large)
                }
            }
        }
        .sheet(isPresented: $showingPremium) {
            DashboardPremiumUpsellSheet(
                premiumURL: AIscendChatConfiguration.live.premiumURL,
                onDismiss: { showingPremium = false }
            )
        }
        .sheet(item: $shareCoordinator.activePayload) { payload in
            SharePreviewView(
                payload: payload,
                onDismiss: { shareCoordinator.dismiss() }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            hasAppeared = true
        }
    }

    private func handle(_ action: DashboardQuickAction, proxy: ScrollViewProxy) {
        switch action {
        case .advisor:
            onOpenAdvisor()
        case .progress:
            scroll(to: .analytics, proxy: proxy)
        case .routine:
            onOpenRoutine()
        case .insights:
            scroll(to: .insights, proxy: proxy)
        case .archive:
            scroll(to: .scans, proxy: proxy)
        case .refine:
            withAnimation(AIscendTheme.Motion.reveal) {
                onRefine()
            }
        }
    }

    private func scroll(to section: DashboardSectionID, proxy: ScrollViewProxy) {
        withAnimation(AIscendTheme.Motion.reveal) {
            proxy.scrollTo(section, anchor: .top)
        }
    }

    private func toggle(_ step: RoutineStep) {
        withAnimation(AIscendTheme.Motion.reveal) {
            model.toggleStep(step.id)
        }

        badgeManager.recordRoutineProgress(
            progress: model.progress,
            streak: dailyCheckInStore.snapshot.currentStreak
        )
    }
}

private struct DashboardRevealModifier: ViewModifier {
    let isVisible: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 18)
            .animation(.easeOut(duration: 0.48).delay(delay), value: isVisible)
    }
}

private extension View {
    func dashboardReveal(isVisible: Bool, delay: Double) -> some View {
        modifier(DashboardRevealModifier(isVisible: isVisible, delay: delay))
    }
}

#Preview {
    RoutineDashboardView(
        model: {
            let model = AppModel()
            model.profile.name = "Max Voss"
            model.profile.intention = "Sharpen lower-face structure, protect presentation quality, and keep the total read moving upward."
            model.profile.focusTrack = .mastery
            model.profile.anchors = [.movement, .planning, .reflection]
            model.analysisGoals = [.jawline, .skin, .symmetry]
            model.toggleStep("mission")
            model.toggleStep("deep-work")
            return model
        }(),
        dailyCheckInStore: DailyCheckInStore(),
        badgeManager: BadgeManager()
    )
}
