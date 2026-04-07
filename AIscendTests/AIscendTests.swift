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

}
