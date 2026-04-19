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
        ZStack(alignment: .top) {
            AIscendBackdrop()
            rootContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task(id: session.user?.id) {
            model.applyAuthenticatedUserID(session.user?.id)
        }
        .animation(.smooth(duration: 0.35), value: session.phase)
        .animation(.smooth(duration: 0.35), value: model.hasCompletedEntryOnboarding)
        .animation(.smooth(duration: 0.35), value: model.hasCompletedOnboarding)
    }

    @ViewBuilder
    private var rootContent: some View {
        switch session.phase {
        case .checking:
            SessionLoadingView()
        case .signedOut:
            if model.hasCompletedEntryOnboarding {
                AuthView(model: model, session: session)
            } else {
                AIscendPremiumOnboardingExperienceView(model: model, isAuthenticated: false)
            }
        case .signedIn:
            if model.hasCompletedOnboarding {
                AppShellView(model: model, session: session)
            } else {
                AIscendPremiumOnboardingExperienceView(model: model, isAuthenticated: true)
            }
        }
    }
}

private struct SessionLoadingView: View {
    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()

            VStack(spacing: AIscendTheme.Spacing.large) {
                ZStack {
                    Circle()
                        .fill(AIscendTheme.Colors.accentPrimary.opacity(0.14))
                        .frame(width: 118, height: 118)
                        .blur(radius: 12)

                    Circle()
                        .fill(AIscendTheme.Colors.surfaceGlass.opacity(0.82))
                        .frame(width: 96, height: 96)
                        .overlay(
                            Circle()
                                .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
                        )

                    AIscendBrandMark(size: 54)
                }

                VStack(spacing: AIscendTheme.Spacing.xSmall) {
                    Text("AIscend")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)

                    Text("Loading your workspace")
                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                }

                HStack(spacing: AIscendTheme.Spacing.small) {
                    AIscendLoadingIndicator(size: 18, lineWidth: 2)

                    Text("Restoring session")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                }
            }
            .frame(maxWidth: 320)
            .padding(.horizontal, AIscendTheme.Spacing.large)
        }
    }
}

#Preview {
    ContentView()
}
