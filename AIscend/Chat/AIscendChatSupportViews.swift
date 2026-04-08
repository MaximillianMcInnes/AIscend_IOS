//
//  AIscendChatSupportViews.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import SwiftUI
import UIKit

enum AIscendChatPalette {
    static let userBubble = LinearGradient(
        colors: [
            Color(hex: "9567FF"),
            Color(hex: "6A35F0"),
            Color(hex: "4D249F")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let assistantBubble = LinearGradient(
        colors: [
            Color(hex: "171B24").opacity(0.94),
            Color(hex: "10141B").opacity(0.98)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let chrome = LinearGradient(
        colors: [
            Color(hex: "141923").opacity(0.92),
            Color(hex: "0F131A").opacity(0.96)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let surfaceBorder = LinearGradient(
        colors: [
            Color.white.opacity(0.14),
            AIscendTheme.Colors.accentGlow.opacity(0.18),
            Color.white.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGlow = RadialGradient(
        colors: [
            AIscendTheme.Colors.accentGlow.opacity(0.22),
            AIscendTheme.Colors.accentPrimary.opacity(0.08),
            .clear
        ],
        center: .topTrailing,
        startRadius: 16,
        endRadius: 340
    )
}

struct AIscendChatGlassCard: ViewModifier {
    let cornerRadius: CGFloat
    let glowOpacity: Double

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AIscendChatPalette.chrome)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.white.opacity(0.03))
                            .blur(radius: 24)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AIscendChatPalette.surfaceBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.34), radius: 22, x: 0, y: 12)
            .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(glowOpacity), radius: 28, x: 0, y: 0)
    }
}

extension View {
    func aiscendChatGlassCard(cornerRadius: CGFloat = 28, glowOpacity: Double = 0.08) -> some View {
        modifier(AIscendChatGlassCard(cornerRadius: cornerRadius, glowOpacity: glowOpacity))
    }
}

struct AIscendBlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemUltraThinMaterialDark

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct AIscendChatMarkdownText: View {
    let text: String
    let color: Color

    init(text: String, color: Color = AIscendTheme.Colors.textPrimary) {
        self.text = text
        self.color = color
    }

    private var renderedText: AttributedString? {
        try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
        )
    }

    var body: some View {
        Group {
            if let renderedText {
                Text(renderedText)
            } else {
                Text(text)
            }
        }
        .font(.system(size: 16, weight: .regular, design: .default))
        .foregroundStyle(color)
        .lineSpacing(5)
        .multilineTextAlignment(.leading)
        .textSelection(.enabled)
        .tint(AIscendTheme.Colors.accentGlow)
    }
}

struct AIscendChatTypingIndicator: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.medium) {
            HStack(spacing: 7) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(AIscendTheme.Colors.accentGlow.opacity(0.88))
                        .frame(width: 8, height: 8)
                        .scaleEffect(animate ? 1 : 0.58)
                        .opacity(animate ? 1 : 0.42)
                        .animation(
                            .easeInOut(duration: 0.72)
                            .repeatForever()
                            .delay(Double(index) * 0.14),
                            value: animate
                        )
                }
            }

            Text("Thinking")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
        }
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .background(
            Capsule(style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.84))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
        .onAppear {
            animate = true
        }
    }
}

struct AIscendChatBootOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.36)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                AIscendBrandMark(size: 52)

                AIscendBadge(
                    title: "Private advisor",
                    symbol: "sparkles.rectangle.stack.fill",
                    style: .accent
                )

                AIscendLoadingIndicator()

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                    Text("Preparing your secure chat workspace")
                        .aiscendTextStyle(.sectionTitle)

                    Text("AIScend is restoring recent conversations, validating quota, and loading the current advisor context.")
                        .aiscendTextStyle(.body)
                }
            }
            .padding(AIscendTheme.Spacing.xLarge)
            .frame(maxWidth: 440, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(AIscendChatPalette.chrome)
                    .overlay(AIscendChatPalette.heroGlow.clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(AIscendChatPalette.surfaceBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.46), radius: 36, x: 0, y: 18)
            .padding(AIscendTheme.Spacing.screenInset)
        }
    }
}

struct AIscendChatTransientToast: View {
    let text: String

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))

            Text(text)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
        }
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .background(
            Capsule(style: .continuous)
                .fill(AIscendTheme.Colors.secondaryBackground.opacity(0.96))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.34), radius: 16, x: 0, y: 10)
    }
}

struct AIscendChatEmptyState: View {
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            AIscendBadge(
                title: "Private advisor",
                symbol: "lock.shield.fill",
                style: .accent
            )

            AIscendSectionHeader(
                title: "No conversations yet",
                subtitle: "Ask anything about improvement, aesthetics, strategy, or your next move. The first response should feel like a private briefing, not a generic chat bot."
            )

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                ForEach(
                    [
                        "What should I focus on this week to improve fastest?",
                        "Give me a strategic plan for better presentation.",
                        "Review my habits and tell me what to tighten."
                    ],
                    id: \.self
                ) { prompt in
                    Text(prompt)
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                        .padding(.horizontal, AIscendTheme.Spacing.medium)
                        .padding(.vertical, AIscendTheme.Spacing.small)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                        )
                }
            }

            Button(action: onStart) {
                AIscendButtonLabel(title: "Start a new conversation", leadingSymbol: "plus")
            }
            .buttonStyle(AIscendButtonStyle(variant: .primary))
        }
        .padding(AIscendTheme.Spacing.xLarge)
        .aiscendChatGlassCard(cornerRadius: 30, glowOpacity: 0.12)
    }
}

struct AIscendChatPremiumUpsellSheet: View {
    let premiumURL: URL?
    let onDismiss: () -> Void

    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            AIscendBackdrop()

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack {
                    AIscendBadge(
                        title: "Premium",
                        symbol: "sparkles",
                        style: .accent
                    )

                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AIscendTheme.Colors.textPrimary)
                            .frame(width: 34, height: 34)
                            .background(
                                Circle()
                                    .fill(AIscendTheme.Colors.surfaceHighlight)
                            )
                    }
                    .buttonStyle(.plain)
                }

                AIscendSectionHeader(
                    title: "Unlock unlimited advisor conversations",
                    subtitle: "Continue with unlimited chats, priority responses, and a cleaner runway for longer strategic sessions."
                )

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    premiumPoint("Unlimited advisor chats with full history")
                    premiumPoint("Faster responses for longer sessions")
                    premiumPoint("A private workspace built for deeper strategy")
                }

                if let premiumURL {
                    Button {
                        openURL(premiumURL)
                    } label: {
                        AIscendButtonLabel(title: "Start your 7-day trial", leadingSymbol: "arrow.up.forward")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .primary))
                }

                Button(action: onDismiss) {
                    AIscendButtonLabel(title: "Continue in chat", leadingSymbol: "chevron.left")
                }
                .buttonStyle(AIscendButtonStyle(variant: .secondary))
            }
            .padding(AIscendTheme.Spacing.xLarge)
            .aiscendChatGlassCard(cornerRadius: 30, glowOpacity: 0.14)
            .padding(AIscendTheme.Spacing.screenInset)
        }
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    private func premiumPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.accentGlow)
                .padding(.top, 2)

            Text(text)
                .aiscendTextStyle(.body)
        }
    }
}
