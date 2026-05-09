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
                VStack(spacing: AIscendTheme.Spacing.large) {
                    headerBar

                    Spacer(minLength: 18)

                    loginPanel

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
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var headerBar: some View {
        HStack {
            Button {
                withAnimation(.smooth(duration: 0.3)) {
                    model.resetEntryIntro()
                }
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(AIscendTheme.Colors.surfaceGlass.opacity(0.72))
                    )
                    .overlay(
                        Circle()
                            .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to start")

            Spacer()
        }
    }

    private var loginPanel: some View {
        VStack(spacing: 24) {
            AIscendBrandMark(size: 62, showsWordmark: false)
                .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.24), radius: 26, x: 0, y: 14)

            VStack(spacing: 8) {
                Text("Sign in to save your plan")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Your routine is ready. Choose one secure way in.")
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textMuted)
                    .multilineTextAlignment(.center)
            }

            planSummaryStrip

            VStack(spacing: 12) {
                Button {
                    Task {
                        await session.signInWithGoogle()
                    }
                } label: {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        Text("G")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(AIscendTheme.Colors.textPrimary)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(Color.white.opacity(0.12)))

                        Text("Continue with Google")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(AIscendTheme.Colors.textPrimary)

                        Spacer()
                    }
                    .padding(.horizontal, AIscendTheme.Spacing.large)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.11))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!session.canUseGoogleSignIn || session.isPerformingAuthAction)
                .opacity(session.canUseGoogleSignIn ? 1 : 0.48)

                SignInWithAppleButton(.signIn) { request in
                    session.prepareAppleSignInRequest(request)
                } onCompletion: { result in
                    session.handleAppleSignInCompletion(result)
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: AIscendTheme.Stroke.thin)
                )
                .shadow(color: Color.black.opacity(0.24), radius: 18, x: 0, y: 12)
                .disabled(!session.canUseAppleSignIn || session.isPerformingAuthAction)
                .opacity(session.canUseAppleSignIn ? 1 : 0.48)
            }

            if session.isPerformingAuthAction {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    AIscendLoadingIndicator(size: 16, lineWidth: 2)

                    Text("Securing your session")
                        .aiscendTextStyle(.caption)
                }
                .frame(minHeight: 24)
            }
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 30)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.elevatedSurface.opacity(0.96),
                            AIscendTheme.Colors.surfaceInteractive.opacity(0.82)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [
                                    AIscendTheme.Colors.accentGlow.opacity(0.16),
                                    AIscendTheme.Colors.accentPrimary.opacity(0.06),
                                    .clear
                                ],
                                center: .top,
                                startRadius: 12,
                                endRadius: 280
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.22),
                                    AIscendTheme.Colors.accentGlow.opacity(0.18),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: AIscendTheme.Stroke.thin
                        )
                }
        }
        .shadow(color: AIscendTheme.Shadow.card, radius: 30, x: 0, y: 20)
        .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.12), radius: 28, x: 0, y: 0)
    }

    private var planSummaryStrip: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AIscendTheme.Colors.accentPrimary)
                .frame(width: 36, height: 36)
                .background(Circle().fill(AIscendTheme.Colors.accentPrimary.opacity(0.14)))

            VStack(alignment: .leading, spacing: 3) {
                Text("Private plan locked in")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)

                Text("Sync routine, scans, and progress")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AIscendTheme.Colors.textMuted)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
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

}

#Preview {
    AuthView(model: AppModel(), session: AuthSessionStore())
}
