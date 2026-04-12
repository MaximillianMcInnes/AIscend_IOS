//
//  AIscendTests.swift
//  AIscendTests
//
//  Created by user294334 on 4/7/26.
//

import Foundation
import Testing
@testable import AIscend

struct AIscendTests {

    @MainActor
    @Test func onboardingStatePersistsAcrossLaunches() async throws {
        let suiteName = "AIscendTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        let model = AppModel(defaults: defaults, arguments: [])
        model.profile.name = "Ava"
        model.profile.intention = "Finish the first AIscend release with calm momentum."
        model.profile.focusTrack = .mastery
        model.completeOnboarding()

        let reloaded = AppModel(defaults: defaults, arguments: [])
        #expect(reloaded.hasCompletedOnboarding)
        #expect(reloaded.profile.name == "Ava")
        #expect(reloaded.profile.focusTrack == .mastery)

        defaults.removePersistentDomain(forName: suiteName)
    }

    @MainActor
    @Test func entryOnboardingStatePersistsAcrossLaunches() async throws {
        let suiteName = "AIscendTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        let model = AppModel(defaults: defaults, arguments: [])
        model.analysisGoals = [.presentation, .tracking]
        model.completeEntryOnboarding()

        let reloaded = AppModel(defaults: defaults, arguments: [])
        #expect(reloaded.hasCompletedEntryOnboarding)
        #expect(reloaded.analysisGoals == [.presentation, .tracking])

        defaults.removePersistentDomain(forName: suiteName)
    }

    @MainActor
    @Test func togglingRoutineStepUpdatesProgress() async throws {
        let suiteName = "AIscendTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        let model = AppModel(defaults: defaults, arguments: [])
        let firstStepID = try #require(model.routineSections.first?.steps.first?.id)

        #expect(model.progress == 0)
        model.toggleStep(firstStepID)
        #expect(model.completedStepIDs.contains(firstStepID))
        #expect(model.progress > 0)

        model.toggleStep(firstStepID)
        #expect(!model.completedStepIDs.contains(firstStepID))

        defaults.removePersistentDomain(forName: suiteName)
    }

    @MainActor
    @Test func authenticatedUsersGetIndependentRoutineState() async throws {
        let suiteName = "AIscendTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        let model = AppModel(defaults: defaults, arguments: [], userID: "alpha-user")
        model.profile.name = "Alpha"
        model.completeOnboarding()

        model.applyAuthenticatedUserID("beta-user")
        #expect(!model.hasCompletedOnboarding)
        #expect(model.profile.name != "Alpha")

        model.profile.name = "Beta"
        model.completeOnboarding()

        model.applyAuthenticatedUserID("alpha-user")
        #expect(model.hasCompletedOnboarding)
        #expect(model.profile.name == "Alpha")

        model.applyAuthenticatedUserID("beta-user")
        #expect(model.hasCompletedOnboarding)
        #expect(model.profile.name == "Beta")

        defaults.removePersistentDomain(forName: suiteName)
    }

}
