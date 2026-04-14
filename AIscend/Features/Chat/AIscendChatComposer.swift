//
//  AIscendChatComposer.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import SwiftUI

struct AIscendChatComposer: View {
    @Binding var text: String

    let isSending: Bool
    let isDisabled: Bool
    let focusBinding: FocusState<Bool>.Binding
    let onSend: () -> Void

    private var sendDisabled: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isDisabled
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: AIscendTheme.Spacing.small) {
            TextField(
                "Ask for strategy, refinement, or your next best move",
                text: $text,
                axis: .vertical
            )
            .focused(focusBinding)
            .font(AIscendTheme.Typography.input)
            .foregroundStyle(AIscendTheme.Colors.textPrimary)
            .lineLimit(1...5)
            .submitLabel(.send)
            .onSubmit(onSend)
            .textInputAutocapitalization(.sentences)
            .autocorrectionDisabled(false)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.02))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
            )

            Button(action: onSend) {
                ZStack {
                    Circle()
                        .fill(
                            sendDisabled
                            ? LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.surfaceInteractive,
                                    AIscendTheme.Colors.surfaceMuted
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.accentGlow,
                                    AIscendTheme.Colors.accentSoft,
                                    AIscendTheme.Colors.accentPrimary
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    if isSending {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(AIscendTheme.Colors.textPrimary)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(
                                sendDisabled
                                ? AIscendTheme.Colors.textMuted
                                : AIscendTheme.Colors.textPrimary
                            )
                    }
                }
                .overlay(
                    Circle()
                        .stroke(
                            sendDisabled
                            ? AIscendTheme.Colors.borderSubtle
                            : AIscendTheme.Colors.accentGlow.opacity(0.38),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: sendDisabled ? .clear : AIscendTheme.Colors.accentPrimary.opacity(0.22),
                    radius: 14,
                    x: 0,
                    y: 8
                )
            }
            .buttonStyle(.plain)
            .disabled(sendDisabled)
        }
        .padding(.horizontal, AIscendTheme.Spacing.small + 2)
        .padding(.vertical, AIscendTheme.Spacing.small + 2)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AIscendChatPalette.chrome)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white.opacity(0.03))
                        .blur(radius: 18)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AIscendChatPalette.surfaceBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.34), radius: 20, x: 0, y: 10)
        .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.06), radius: 18, x: 0, y: 0)
    }
}
