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

    /// Raise this if your custom tab bar is taller.
    private let tabBarClearance: CGFloat = 86

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AIscendBackdrop()
                ambientDecor

                VStack(spacing: 0) {
                    topBar

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
                    .zIndex(3)
                }

                if viewModel.isHistoryPresented {
                    historyOverlay
                        .zIndex(4)
                }

                if viewModel.isBootstrapping {
                    AIscendChatBootOverlay()
                        .transition(.opacity)
                        .zIndex(5)
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
                    .padding(.bottom, composerFocused ? AIscendTheme.Spacing.small : tabBarClearance + AIscendTheme.Spacing.small)
                    .background(
                        LinearGradient(
                            colors: [
                                AIscendTheme.Colors.appBackground.opacity(0),
                                AIscendTheme.Colors.appBackground.opacity(0.68),
                                AIscendTheme.Colors.appBackground.opacity(0.88),
                                AIscendTheme.Colors.appBackground.opacity(0.97)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .animation(.easeOut(duration: 0.22), value: composerFocused)
            }
            .onChange(of: viewModel.isHistoryPresented) { _, isPresented in
                if isPresented {
                    dismissComposer()
                }
            }
        }
    }

    private var ambientDecor: some View {
        ZStack {
            RadialGradient(
                colors: [
                    AIscendTheme.Colors.accentGlow.opacity(0.16),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 320
            )
            .offset(x: 110, y: -120)

            RadialGradient(
                colors: [
                    AIscendTheme.Colors.accentCyan.opacity(0.06),
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

    private var topBar: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            chromeButton(symbol: "sidebar.left") {
                dismissComposer()
                viewModel.presentHistory()
            }

            VStack(spacing: 4) {
                AIscendBadge(
                    title: "Private advisor",
                    symbol: "lock.shield.fill",
                    style: .accent
                )

                Text(viewModel.currentTitle)
                    .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
                    .lineLimit(1)

                Text(viewModel.currentSubtitle)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)

            chromeButton(symbol: "square.and.pencil", action: {
                dismissComposer()
                viewModel.startNewConversation()
            })
        }
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                .fill(AIscendChatPalette.chrome)
                .overlay(
                    RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                        .stroke(AIscendChatPalette.surfaceBorder, lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.32), radius: 18, x: 0, y: 12)
        .padding(.horizontal, AIscendTheme.Spacing.screenInset)
        .padding(.top, AIscendTheme.Spacing.small)
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
                        AIscendChatEmptyState(
                            onStart: {
                                viewModel.startNewConversation()
                                composerFocused = true
                            },
                            onPromptTap: { prompt in
                                viewModel.startNewConversation()
                                viewModel.draft = prompt
                                composerFocused = true

                                Task {
                                    await viewModel.sendCurrentDraft()
                                }
                            }
                        )
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
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    dismissComposer()
                }
            )
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
        AIscendTopBarButton(symbol: symbol, action: action)
    }

    private func dismissComposer() {
        composerFocused = false
        viewModel.clearError()
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
