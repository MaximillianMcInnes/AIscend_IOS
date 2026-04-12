//
//  AuthView.swift
//  AIscend
//
//  Created by Codex on 4/7/26.
//

import AuthenticationServices
import SwiftUI

struct AuthView: View {
    @Bindable var model: AppModel
    @Bindable var session: AuthSessionStore

    var body: some View {
        ZStack {
            AIscendBackdrop()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
                    heroPanel
                    signInPanel
                    infrastructurePanel

                    if let configurationMessage = session.configurationMessage {
                        statusPanel(
                            title: "Firebase Setup Needed",
                            message: configurationMessage,
                            style: .locked
                        )
                    }

                    if let googleSDKStatusMessage = session.googleSDKStatusMessage {
                        statusPanel(
                            title: "Google Sign-In Dependency",
                            message: googleSDKStatusMessage,
                            style: .neutral
                        )
                    }

                    if let errorMessage = session.errorMessage {
                        statusPanel(
                            title: "Sign-In Interrupted",
                            message: errorMessage,
                            style: .subtle
                        )
                    }
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, AIscendTheme.Spacing.xxLarge)
            }
        }
    }

    private var heroPanel: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            HStack {
                AIscendBrandMark(size: 56)

                Spacer()

                AIscendBadge(
                    title: "Encrypted",
                    symbol: "checkmark.seal.fill",
                    style: .neutral
                )
            }

            AIscendSectionHeader(
                eyebrow: "AIScend",
                title: "Secure the workspace and continue with intention.",
                subtitle: "Sign in to preserve the entry setup, keep the experience private, and move into a more structured AIScend environment built around \(model.analysisGoalSummary.lowercased()).",
                prominence: .hero
            )

            HStack(spacing: AIscendTheme.Spacing.small) {
                AIscendBadge(title: "Google", symbol: "globe", style: .neutral)
                AIscendBadge(title: "Apple", symbol: "apple.logo", style: .neutral)
                AIscendBadge(title: "Firebase", symbol: "bolt.fill", style: .neutral)
                if session.canUseGoogleSignIn {
                    AIscendBadge(title: "Ready", symbol: "checkmark.circle.fill", style: .success)
                }
            }

            if !model.analysisGoals.isEmpty {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    Text("Configured focus")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: AIscendTheme.Spacing.small) {
                            ForEach(model.analysisGoals.prefix(3)) { goal in
                                AIscendCapsule(
                                    title: goal.shortTitle,
                                    symbol: goal.symbol,
                                    isActive: true
                                )
                            }
                        }

                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                            ForEach(model.analysisGoals.prefix(3)) { goal in
                                AIscendCapsule(
                                    title: goal.shortTitle,
                                    symbol: goal.symbol,
                                    isActive: true
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(AIscendTheme.Spacing.xLarge)
        .aiscendPanel(.hero)
    }

    private var signInPanel: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            HStack(alignment: .center) {
                AIscendSectionHeader(
                    eyebrow: "Access",
                    title: "Enter the workspace",
                    subtitle: "Choose the identity provider you want tied to your private workspace, analysis intent, and future device state."
                )

                Spacer(minLength: AIscendTheme.Spacing.medium)

                if session.isPerformingAuthAction {
                    AIscendLoadingIndicator()
                        .frame(width: 44, height: 44)
                        .scaleEffect(0.6)
                }
            }

            Button {
                Task {
                    await session.signInWithGoogle()
                }
            } label: {
                AIscendButtonLabel(
                    title: "Continue with Google",
                    leadingSymbol: "globe",
                    trailingSymbol: "arrow.up.right"
                )
            }
            .buttonStyle(AIscendButtonStyle(variant: .secondary))
            .disabled(!session.canUseGoogleSignIn || session.isPerformingAuthAction)
            .opacity(session.canUseGoogleSignIn ? 1 : 0.55)

            SignInWithAppleButton(.signIn) { request in
                session.prepareAppleSignInRequest(request)
            } onCompletion: { result in
                session.handleAppleSignInCompletion(result)
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 56)
            .clipShape(RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous))
            .disabled(!session.canUseAppleSignIn || session.isPerformingAuthAction)
            .opacity(session.canUseAppleSignIn ? 1 : 0.55)

            Text("Google relies on the reversed client ID from `GoogleService-Info.plist`, and Apple requires the Apple provider to be enabled inside Firebase Authentication.")
                .aiscendTextStyle(.secondaryBody)
        }
        .padding(AIscendTheme.Spacing.xLarge)
        .aiscendPanel(.elevated)
    }

    private var infrastructurePanel: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            AIscendSectionHeader(
                eyebrow: "Why this matters",
                title: "Built like a private members dashboard",
                subtitle: "The visual system is dark, controlled, and data-forward. Auth is the gate that keeps the rest of the product feeling personal and high-trust."
            )

            VStack(spacing: AIscendTheme.Spacing.medium) {
                authPoint(
                    symbol: "lock.fill",
                    title: "Session-gated experience",
                    copy: "Onboarding, dashboard, and account views stay behind a Firebase-authenticated session."
                )
                authPoint(
                    symbol: "person.crop.circle.badge.checkmark",
                    title: "Provider-aware account state",
                    copy: "AIScend tracks Apple and Google sign-in cleanly so sign-out and restoration are predictable."
                )
                authPoint(
                    symbol: "chart.bar.doc.horizontal.fill",
                    title: "Per-user local continuity",
                    copy: "Routine choices and progress are namespaced by Firebase user ID on the device."
                )
            }
        }
        .padding(AIscendTheme.Spacing.xLarge)
        .aiscendPanel(.standard)
    }

    private func statusPanel(title: String, message: String, style: AIscendBadgeStyle) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendBadge(title: title, symbol: "info.circle.fill", style: style)

            Text(message)
                .aiscendTextStyle(.body)
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.muted)
    }

    private func authPoint(symbol: String, title: String, copy: String) -> some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: symbol, accent: .sky, size: 42)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                Text(title)
                    .aiscendTextStyle(.cardTitle)

                Text(copy)
                    .aiscendTextStyle(.body)
            }
        }
    }
}

#Preview {
    AuthView(model: AppModel(), session: AuthSessionStore())
}
