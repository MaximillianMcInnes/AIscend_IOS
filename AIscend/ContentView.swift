//
//  ContentView.swift
//  AIscend
//
//  Created by user294334 on 4/7/26.
//

import SwiftUI

struct ContentView: View {
    @State private var model: AppModel = AppModel()
    @State private var session: AuthSessionStore = AuthSessionStore()

    var body: some View {
        Group {
            switch session.phase {
            case .checking:
                SessionLoadingView()
            case .signedOut:
                if model.hasCompletedEntryOnboarding {
                    AuthView(model: model, session: session)
                } else {
                    EntryOnboardingFlowView(model: model)
                }
            case .signedIn:
                if model.hasCompletedOnboarding {
                    AppShellView(model: model, session: session)
                } else {
                    OnboardingView(model: model, session: session)
                }
            }
        }
        .task(id: session.user?.id) {
            model.applyAuthenticatedUserID(session.user?.id)
        }
        .animation(.smooth(duration: 0.35), value: session.phase)
        .animation(.smooth(duration: 0.35), value: model.hasCompletedEntryOnboarding)
        .animation(.smooth(duration: 0.35), value: model.hasCompletedOnboarding)
    }
}

private struct SessionLoadingView: View {
    var body: some View {
        ZStack {
            AIscendBackdrop()

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                AIscendBrandMark(size: 60)

                AIscendBadge(
                    title: "Secure Session",
                    symbol: "lock.shield.fill",
                    style: .accent
                )

                AIscendLoadingIndicator()

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                    Text("Restoring your private workspace")
                        .aiscendTextStyle(.sectionTitle)

                    Text("AIScend is re-establishing the session, validating your auth state, and loading the dashboard context.")
                        .aiscendTextStyle(.body)
                }
            }
            .frame(maxWidth: 460, alignment: .leading)
            .padding(AIscendTheme.Spacing.xLarge)
            .aiscendPanel(.hero)
            .padding(AIscendTheme.Spacing.screenInset)
        }
    }
}

#Preview {
    ContentView()
}
