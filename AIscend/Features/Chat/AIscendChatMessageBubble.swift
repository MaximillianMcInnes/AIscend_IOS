//
//  AIscendChatMessageBubble.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import SwiftUI
import UIKit

struct AIscendChatMessageBubble: View {
    let message: AIscendChatMessage
    let onCopy: () -> Void

    @State private var actionVisible = false
    @State private var copied = false

    private var isAssistant: Bool {
        message.sender == .bot
    }

    var body: some View {
        HStack {
            if !isAssistant {
                Spacer(minLength: 48)
            }

            VStack(alignment: isAssistant ? .leading : .trailing, spacing: AIscendTheme.Spacing.xSmall) {
                if isAssistant && (actionVisible || copied) {
                    HStack(spacing: AIscendTheme.Spacing.xSmall) {
                        Button {
                            UIPasteboard.general.string = message.text
                            copied = true
                            onCopy()

                            Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 1_100_000_000)
                                copied = false
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 11, weight: .bold))

                                Text(copied ? "Copied" : "Copy")
                                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                            }
                            .padding(.horizontal, AIscendTheme.Spacing.small)
                            .padding(.vertical, 7)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.92))
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: 0)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    AIscendChatMarkdownText(
                        text: message.text,
                        color: AIscendTheme.Colors.textPrimary
                    )

                    if isAssistant && !message.sources.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AIscendTheme.Spacing.xSmall) {
                                ForEach(message.sources.prefix(3)) { source in
                                    sourceChip(source)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, AIscendTheme.Spacing.medium)
                .padding(.vertical, AIscendTheme.Spacing.medium)
                .frame(maxWidth: 320, alignment: .leading)
                .background(bubbleBackground)
                .overlay(bubbleBorder)
                .shadow(color: bubbleShadow, radius: 18, x: 0, y: 12)
                .onTapGesture {
                    guard isAssistant else {
                        return
                    }

                    withAnimation(AIscendTheme.Motion.reveal) {
                        actionVisible.toggle()
                    }
                }
            }

            if isAssistant {
                Spacer(minLength: 48)
            }
        }
        .frame(maxWidth: .infinity, alignment: isAssistant ? .leading : .trailing)
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(isAssistant ? AIscendChatPalette.assistantBubble : AIscendChatPalette.userBubble)
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isAssistant ? 0.05 : 0.12),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
            )
    }

    @ViewBuilder
    private var bubbleBorder: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .stroke(
                isAssistant
                ? AIscendChatPalette.surfaceBorder
                : LinearGradient(
                    colors: [
                        Color.white.opacity(0.16),
                        AIscendTheme.Colors.accentGlow.opacity(0.28)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    private var bubbleShadow: Color {
        isAssistant
        ? Color.black.opacity(0.22)
        : AIscendTheme.Colors.accentPrimary.opacity(0.22)
    }

    @ViewBuilder
    private func sourceChip(_ source: AIscendChatSource) -> some View {
        let content = HStack(spacing: 6) {
            Image(systemName: "arrow.up.right")
                .font(.system(size: 10, weight: .semibold))

            Text(source.displayTitle)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(AIscendTheme.Colors.secondaryBackground.opacity(0.92))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )

        if let urlString = source.url, let url = URL(string: urlString) {
            Link(destination: url) {
                content
            }
        } else {
            content
        }
    }
}
