//
//  EntryOnboardingFlowView.swift
//  AIscend
//

import SwiftUI

enum EntryOnboardingGender: String, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"
    case other = "Other"

    var id: String { rawValue }
}

struct EntryOnboardingDraft: Equatable {
    var gender: EntryOnboardingGender?
    var name = ""
    var referralCode = ""
    var age: Double = 18
    var heightFeet = 5
    var heightInches = 7
    var weightPounds = 150
    var usesMetricMeasurements = false
    var heightCentimeters = 170
    var weightKilograms = 68
    var goals: [AnalysisGoal] = []
    var celebrityPreferences: Set<EntryCelebrityPreference> = []
    var skippedCelebrityPreferences = false
    var dailyDedicationMinutes: Double = 15
    var notificationChoice: EntryNotificationChoice?
    var rating: Int = 0
    var hasShownRatingPrompt = false
}

enum EntryOnboardingPage: Int, CaseIterable, Identifiable {
    case gender
    case name
    case age
    case heightWeight
    case goals
    case celebrities
    case dedication
    case notifications
    case results
    case confidence
    case blindspots
    case habits
    case rating
    case referral
    case faceScan
    case routineBuild

    var id: Int { rawValue }

    var progress: Double {
        Double(rawValue + 1) / Double(Self.allCases.count)
    }
}

struct EntryOnboardingFlowView: View {
    @Bindable var model: AppModel

    @State private var pageIndex = 0
    @State private var pageDirection: EntryOnboardingPageDirection = .forward
    @State private var draft = EntryOnboardingDraft()
    @State private var showsRatingPrompt = false
    @State private var languageIsEnglish = true
    @State private var chromeAppeared = false
    @State private var routineBuildIsComplete = false

    private let pages = EntryOnboardingPage.allCases

    private var currentPage: EntryOnboardingPage {
        pages[min(pageIndex, pages.count - 1)]
    }

    private var canAdvance: Bool {
        canAdvance(from: currentPage)
    }

    private func canAdvance(from page: EntryOnboardingPage) -> Bool {
        switch page {
        case .gender:
            draft.gender != nil
        case .name:
            !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .goals:
            !draft.goals.isEmpty
        case .celebrities:
            draft.skippedCelebrityPreferences || !draft.celebrityPreferences.isEmpty
        case .notifications:
            draft.notificationChoice != nil
        case .routineBuild:
            routineBuildIsComplete
        default:
            true
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let topInset: CGFloat = 18
            let pageTopInset = topInset + 46
            let footerBottomInset = max(geometry.safeAreaInsets.bottom + 10, 18)
            let pageBottomInset = footerBottomInset + 112

            ZStack(alignment: .top) {
                EntryOnboardingBackdrop()

                ZStack {
                    pageView(for: currentPage)
                        .id(currentPage.id)
                        .padding(.top, pageTopInset)
                        .padding(.bottom, pageBottomInset)
                        .transition(pageTransition)
                }
                .animation(.smooth(duration: 0.32), value: pageIndex)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, topInset)
                    .opacity(chromeAppeared ? 1 : 0)
                    .offset(y: chromeAppeared ? 0 : -14)
                    .animation(.spring(response: 0.52, dampingFraction: 0.86), value: chromeAppeared)

                if showsFooter {
                    footer
                        .padding(.horizontal, 24)
                        .padding(.bottom, footerBottomInset)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .opacity(chromeAppeared ? 1 : 0)
                        .offset(y: chromeAppeared ? 0 : 18)
                        .animation(.spring(response: 0.56, dampingFraction: 0.88).delay(0.08), value: chromeAppeared)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .ignoresSafeArea(edges: .bottom)
                }

                if showsRatingPrompt {
                    EntryRatingPrompt(
                        rating: $draft.rating,
                        onDismiss: {
                            withAnimation(.smooth(duration: 0.22)) {
                                showsRatingPrompt = false
                            }
                        }
                    )
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                    .zIndex(10)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.52, dampingFraction: 0.86)) {
                chromeAppeared = true
            }
        }
    }

    private var pageTransition: AnyTransition {
        let insertionEdge: Edge = pageDirection == .forward ? .trailing : .leading
        let removalEdge: Edge = pageDirection == .forward ? .leading : .trailing

        return .asymmetric(
            insertion: .move(edge: insertionEdge).combined(with: .opacity),
            removal: .move(edge: removalEdge).combined(with: .opacity)
        )
    }

    private var showsFooter: Bool {
        currentPage != .gender && currentPage != .faceScan
    }

    private var topBar: some View {
        HStack(spacing: 20) {
            Button {
                EntryOnboardingHaptics.tap()
                moveBack()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(Circle().fill(Color.white.opacity(0.08)))
                    .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
            .buttonStyle(EntryOnboardingTactileButtonStyle())
            .accessibilityLabel(pageIndex == 0 ? "Back to intro" : "Previous page")

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.18))

                    Capsule(style: .continuous)
                        .fill(EntryOnboardingStyle.primaryGradient)
                        .frame(width: geometry.size.width * currentPage.progress)
                        .shadow(
                            color: EntryOnboardingStyle.purpleSoft.opacity(0.30 + 0.45 * currentPage.progress),
                            radius: 8 + 18 * currentPage.progress,
                            x: 0,
                            y: 0
                        )
                        .animation(.smooth(duration: 0.28), value: currentPage.progress)
                }
            }
            .frame(height: 7)

            Button {
                EntryOnboardingHaptics.tap()
                withAnimation(.smooth(duration: 0.2)) {
                    languageIsEnglish.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Text("US")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(EntryOnboardingStyle.purple)

                    Text(languageIsEnglish ? "EN" : "US")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(width: 84, height: 54)
                .background(Capsule(style: .continuous).fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(EntryOnboardingTactileButtonStyle())
            .accessibilityLabel("Language")
        }
        .frame(height: 54)
    }

    @ViewBuilder
    private func pageView(for page: EntryOnboardingPage) -> some View {
        switch page {
        case .gender:
            EntryGenderOnboardingPage(draft: $draft) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    guard currentPage == .gender, draft.gender != nil else {
                        return
                    }

                    moveForward()
                }
            }
        case .name:
            EntryNameOnboardingPage(draft: $draft)
        case .age:
            EntryAgeOnboardingPage(draft: $draft)
        case .heightWeight:
            EntryHeightWeightOnboardingPage(draft: $draft)
        case .goals:
            EntryGoalsSelectionOnboardingPage(draft: $draft)
        case .celebrities:
            EntryCelebrityPreferenceOnboardingPage(draft: $draft)
        case .dedication:
            EntrySleepOnboardingPage(draft: $draft)
        case .notifications:
            EntryNotificationsOnboardingPage(draft: $draft)
        case .results:
            EntryLongTermResultsPage()
        case .confidence:
            EntryConfidenceOnboardingPage()
        case .blindspots:
            EntryBlindspotsOnboardingPage()
        case .habits:
            EntryHabitImpactOnboardingPage()
        case .rating:
            EntryRatingOnboardingPage(
                rating: $draft.rating,
                showsRatingPrompt: $showsRatingPrompt
            )
        case .referral:
            EntryReferralOnboardingPage(draft: $draft)
        case .faceScan:
            EntryFaceScanOnboardingPage(
                onSkip: {
                    EntryOnboardingHaptics.advance()
                    moveForward()
                },
                onComplete: {
                    EntryOnboardingHaptics.success()
                    moveForward()
                }
            )
        case .routineBuild:
            EntryRoutineBuildOnboardingPage(
                dedicationMinutes: draft.dailyDedicationMinutes,
                goals: draft.goals,
                isComplete: $routineBuildIsComplete
            )
        }
    }

    private var footer: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    Color.black.opacity(0),
                    Color.black.opacity(0.88),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 86)

            Button {
                guard canAdvance else {
                    EntryOnboardingHaptics.warning()
                    return
                }

                if currentPage == .rating {
                    EntryOnboardingHaptics.success()
                } else {
                    EntryOnboardingHaptics.advance()
                }

                moveForward()
            } label: {
                EntryOnboardingPrimaryButtonLabel(
                    title: primaryButtonTitle,
                    isActive: canAdvance,
                    progress: currentPage.progress
                )
            }
            .buttonStyle(EntryOnboardingTactileButtonStyle())
            .accessibilityHint(canAdvance ? "Moves to the next onboarding stage" : "Choose an option to continue")
        }
    }

    private var primaryButtonTitle: String {
        switch currentPage {
        case .faceScan:
            "Build my routine"
        case .routineBuild:
            routineBuildIsComplete ? "Continue to sign in" : "Building your plan"
        default:
            "Next"
        }
    }

    private func moveBack() {
        guard pageIndex > 0 else {
            withAnimation(.smooth(duration: 0.3)) {
                model.resetEntryIntro()
            }
            return
        }

        withAnimation(.smooth(duration: 0.25)) {
            pageDirection = .backward
            pageIndex -= 1
            showsRatingPrompt = false
        }

        EntryOnboardingHaptics.stage()
    }

    private func moveForward() {
        guard currentPage != .routineBuild else {
            withAnimation(.smooth(duration: 0.32)) {
                applyDraft()
                model.completeEntryOnboarding()
            }
            return
        }

        withAnimation(.smooth(duration: 0.25)) {
            pageDirection = .forward
            pageIndex += 1
        }

        EntryOnboardingHaptics.stage()
        showRatingPromptIfNeeded()
    }

    private func showRatingPromptIfNeeded() {
        guard currentPage == .rating, !draft.hasShownRatingPrompt else {
            return
        }

        draft.hasShownRatingPrompt = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard currentPage == .rating else {
                return
            }

            EntryOnboardingHaptics.tap()
            withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                showsRatingPrompt = true
            }
        }
    }

    private func applyDraft() {
        let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            model.profile.name = trimmedName
        }

        if !draft.goals.isEmpty {
            model.analysisGoals = draft.goals
        }
    }
}

private enum EntryOnboardingPageDirection {
    case forward
    case backward
}

#Preview {
    EntryOnboardingFlowView(model: AppModel())
}
