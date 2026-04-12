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
    let quotaLabel: String?
    let focusBinding: FocusState<Bool>.Binding
    let onSend: () -> Void

    private var sendDisabled: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isDisabled
    }

    var body: some View {
        VStack(spacing: AIscendTheme.Spacing.small) {
            HStack(spacing: AIscendTheme.Spacing.xSmall) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AIscendTheme.Colors.accentGlow)

                Text(quotaLabel ?? "Private advisor conversation")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)

                Spacer(minLength: 0)
            }

            HStack(alignment: .bottom, spacing: AIscendTheme.Spacing.small) {
                TextField(
                    "Ask for strategy, refinement, or your next best move",
                    text: $text,
                    axis: .vertical
                )
                .focused(focusBinding)
                .font(AIscendTheme.Typography.input)
                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                .lineLimit(1...6)
                .submitLabel(.send)
                .onSubmit(onSend)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled(false)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.04))
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
                                        AIscendTheme.Colors.tertiaryBackground,
                                        AIscendTheme.Colors.secondaryBackground
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [
                                        AIscendTheme.Colors.accentGlow,
                                        AIscendTheme.Colors.accentPrimary
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 52)

                        if isSending {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(AIscendTheme.Colors.textPrimary)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 18, weight: .bold))
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
                        color: sendDisabled ? .clear : AIscendTheme.Colors.accentPrimary.opacity(0.26),
                        radius: 16,
                        x: 0,
                        y: 8
                    )
                }
                .buttonStyle(.plain)
                .disabled(sendDisabled)
            }
        }
        .padding(.horizontal, AIscendTheme.Spacing.mediumLarge)
        .padding(.top, AIscendTheme.Spacing.medium)
        .padding(.bottom, AIscendTheme.Spacing.mediumLarge)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(AIscendChatPalette.chrome)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Color.white.opacity(0.03))
                        .blur(radius: 18)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(AIscendChatPalette.surfaceBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.42), radius: 24, x: 0, y: 10)
        .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.08), radius: 24, x: 0, y: 0)
    }
}
