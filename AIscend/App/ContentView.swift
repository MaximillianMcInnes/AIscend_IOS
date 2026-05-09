//
//  ContentView.swift
//  AIscend
//
//  Created by user294334 on 4/7/26.
//

import Foundation
import SwiftUI

struct ContentView: View {
    private static let minimumLaunchDisplayDuration: TimeInterval = 0.72

    @State private var model: AppModel = AppModel()
    @State private var session: AuthSessionStore = AuthSessionStore()
    @State private var displayedPhase: AuthSessionStore.Phase = .checking
    @State private var launchStartedAt = Date()

    var body: some View {
        ZStack(alignment: .top) {
            AIscendBackdrop()
            rootContent
                .id(displayedPhase.transitionID)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.995)),
                        removal: .opacity
                    )
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task(id: session.user?.id) {
            model.applyAuthenticatedUserID(session.user?.id)
        }
        .task(id: session.phase) {
            await synchronizeDisplayedPhase(with: session.phase)
        }
        .animation(.smooth(duration: 0.35), value: model.hasCompletedEntryIntro)
        .animation(.smooth(duration: 0.35), value: model.hasCompletedEntryOnboarding)
        .animation(.smooth(duration: 0.35), value: model.hasCompletedOnboarding)
    }

    @ViewBuilder
    private var rootContent: some View {
        switch displayedPhase {
        case .checking:
            AIscendLaunchLoadingView()
        case .signedOut:
            if model.hasCompletedEntryOnboarding {
                AuthView(model: model, session: session)
            } else if model.hasCompletedEntryIntro {
                EntryOnboardingFlowView(model: model)
            } else {
                EntrySlideshowOnboardingView(model: model)
            }
        case .signedIn:
            AppShellView(model: model, session: session)
        }
    }

    private func synchronizeDisplayedPhase(with phase: AuthSessionStore.Phase) async {
        guard phase != .checking else {
            if displayedPhase == .checking {
                launchStartedAt = Date()
            }
            return
        }

        if displayedPhase == .checking {
            let elapsed = Date().timeIntervalSince(launchStartedAt)
            let remaining = max(0, Self.minimumLaunchDisplayDuration - elapsed)

            if remaining > 0 {
                try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            }
        }

        guard !Task.isCancelled, displayedPhase != phase else {
            return
        }

        withAnimation(.smooth(duration: 0.46)) {
            displayedPhase = phase
        }
    }
}

private extension AuthSessionStore.Phase {
    var transitionID: String {
        switch self {
        case .checking:
            "checking"
        case .signedOut:
            "signedOut"
        case .signedIn:
            "signedIn"
        }
    }
}

#Preview {
    ContentView()
}
