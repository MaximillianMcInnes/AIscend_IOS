//
//  AIscendChatScreen.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import SwiftUI

struct AIscendChatScreenContainer: View {
    let session: AuthSessionStore
    @State private var viewModel: AIscendChatViewModel

    init(session: AuthSessionStore) {
        self.session = session
        _viewModel = State(initialValue: AIscendChatViewModel(session: session))
    }

    var body: some View {
        AIscendChatScreen(viewModel: viewModel)
            .task(id: session.user?.id) {
                await viewModel.syncWithSession()
            }
    }
}

private struct AIscendChatScreen: View {
    @Bindable var viewModel: AIscendChatViewModel
    @FocusState private var composerFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AIscendBackdrop()
                ambientDecor

                VStack(spacing: 0) {
                    topBar(safeAreaTop: geometry.safeAreaInsets.top)

                    if let errorMessage = viewModel.errorMessage {
                        errorBanner(message: errorMessage)
                            .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                            .padding(.top, AIscendTheme.Spacing.small)
                    }

                    messageScroller
                }

                if let transientNotice = viewModel.transientNotice {
                    VStack {
                        AIscendChatTransientToast(text: transientNotice)
                            .padding(.top, geometry.safeAreaInsets.top + 8)

                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                if viewModel.isHistoryPresented {
                    historyOverlay
                }

                if viewModel.isBootstrapping {
                    AIscendChatBootOverlay()
                        .transition(.opacity)
                }
            }
            .sheet(isPresented: $viewModel.isPremiumUpsellPresented) {
                AIscendChatPremiumUpsellSheet(
                    premiumURL: viewModel.premiumURL,
                    onDismiss: viewModel.dismissPremiumUpsell,
                    trialEligible: viewModel.quota.trialEligible
                )
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                composer
                    .padding(.horizontal, AIscendTheme.Spacing.medium)
                    .padding(.top, AIscendTheme.Spacing.small)
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom, 10))
                    .background(
                        LinearGradient(
                            colors: [
                                AIscendTheme.Colors.appBackground.opacity(0),
                                AIscendTheme.Colors.appBackground.opacity(0.76),
                                AIscendTheme.Colors.appBackground.opacity(0.94)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
    }

    private var ambientDecor: some View {
        ZStack {
            RadialGradient(
                colors: [
                    AIscendTheme.Colors.accentGlow.opacity(0.12),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 280
            )
            .offset(x: 110, y: -120)

            RadialGradient(
                colors: [
                    Color.white.opacity(0.05),
                    .clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 210
            )
            .offset(x: -120, y: -160)
        }
        .ignoresSafeArea()
    }

    private func topBar(safeAreaTop: CGFloat) -> some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            chromeButton(symbol: "sidebar.left", action: viewModel.presentHistory)

            VStack(spacing: 4) {
                Text("AIScend")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                Text(viewModel.currentTitle)
                    .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
                    .lineLimit(1)

                Text(viewModel.currentSubtitle)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)

            chromeButton(symbol: "square.and.pencil", action: {
                composerFocused = false
                viewModel.startNewConversation()
            })
        }
        .padding(.horizontal, AIscendTheme.Spacing.screenInset)
        .padding(.top, safeAreaTop + 6)
        .padding(.bottom, AIscendTheme.Spacing.medium)
    }

    private var messageScroller: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    if viewModel.showQuotaBanner {
                        AIscendChatQuotaBanner(
                            quota: viewModel.quota,
                            style: .prominent,
                            onUpgradeTap: viewModel.presentPremiumUpsell
                        )
                    }

                    if !viewModel.isAuthenticated {
                        authRequiredState
                    } else if viewModel.showEmptyState {
                        AIscendChatEmptyState {
                            viewModel.startNewConversation()
                            composerFocused = true
                        }
                    } else {
                        ForEach(viewModel.messages) { message in
                            AIscendChatMessageBubble(
                                message: message,
                                onCopy: viewModel.copiedAssistantMessage
                            )
                        }

                        if viewModel.isAwaitingReply {
                            HStack {
                                AIscendChatTypingIndicator()
                                Spacer(minLength: 0)
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("bottom-anchor")
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.small)
                .padding(.bottom, AIscendTheme.Spacing.large)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                composerFocused = false
                viewModel.clearError()
            }
            .onChange(of: viewModel.scrollTrigger) { _, _ in
                withAnimation(.easeOut(duration: 0.28)) {
                    proxy.scrollTo("bottom-anchor", anchor: .bottom)
                }
            }
        }
    }

    private var composer: some View {
        AIscendChatComposer(
            text: $viewModel.draft,
            isSending: viewModel.isSending,
            isDisabled: !viewModel.canSend,
            quotaLabel: viewModel.isAuthenticated ? viewModel.currentSubtitle : "Sign in to continue",
            focusBinding: $composerFocused,
            onSend: {
                composerFocused = true
                Task {
                    await viewModel.sendCurrentDraft()
                }
            }
        )
    }

    private var authRequiredState: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            AIscendBadge(
                title: "Secure access",
                symbol: "lock.fill",
                style: .accent
            )

            AIscendSectionHeader(
                title: "Sign in to continue the conversation",
                subtitle: "AIScend keeps chat history private to the authenticated account, so the advisor screen stays locked until Firebase restores the session."
            )
        }
        .padding(AIscendTheme.Spacing.xLarge)
        .aiscendChatGlassCard(cornerRadius: 30, glowOpacity: 0.08)
    }

    private func chromeButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                .frame(width: 46, height: 46)
                .background(
                    Circle()
                        .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.82))
                )
                .overlay(
                    Circle()
                        .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private func errorBanner(message: String) -> some View {
        HStack(alignment: .center, spacing: AIscendTheme.Spacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AIscendTheme.Colors.warning)

            Text(message)
                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textPrimary)

            Spacer(minLength: 0)

            Button(action: viewModel.clearError) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AIscendTheme.Colors.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(hex: "261820").opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AIscendTheme.Colors.error.opacity(0.36), lineWidth: 1)
        )
    }

    private var historyOverlay: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.42)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.dismissHistory()
                }

            AIscendChatHistoryPanel(
                sections: viewModel.groupedThreads,
                activeThreadID: viewModel.activeThreadID,
                quota: viewModel.quota,
                onNewChat: {
                    composerFocused = true
                    viewModel.startNewConversation()
                },
                onSelect: { thread in
                    composerFocused = false
                    viewModel.selectThread(thread)
                },
                onDismiss: viewModel.dismissHistory,
                onUpgradeTap: viewModel.presentPremiumUpsell
            )
            .frame(maxWidth: .infinity)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.84)
            .padding(.horizontal, AIscendTheme.Spacing.small)
            .padding(.bottom, AIscendTheme.Spacing.small)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
