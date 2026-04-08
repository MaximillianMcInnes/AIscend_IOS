//
//  AIscendChatHistoryPanel.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import SwiftUI

struct AIscendChatHistoryPanel: View {
    let sections: [AIscendChatHistorySection]
    let activeThreadID: String?
    let quota: AIscendChatQuota
    let onNewChat: () -> Void
    let onSelect: (AIscendChatThread) -> Void
    let onDismiss: () -> Void
    let onUpgradeTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.18))
                .frame(width: 42, height: 5)
                .padding(.top, AIscendTheme.Spacing.small)
                .padding(.bottom, AIscendTheme.Spacing.medium)

            HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                    AIscendBadge(
                        title: "History",
                        symbol: "clock.arrow.circlepath",
                        style: .accent
                    )

                    Text("Your recent conversations")
                        .aiscendTextStyle(.sectionTitle)

                    Text("Return to any advisor thread without leaving the mobile flow.")
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                }

                Spacer(minLength: 0)

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .frame(width: 34, height: 34)
                        .background(
                            Circle()
                                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.82))
                        )
                        .overlay(
                            Circle()
                                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AIscendTheme.Spacing.large)
            .padding(.bottom, AIscendTheme.Spacing.mediumLarge)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    Button(action: onNewChat) {
                        HStack(spacing: AIscendTheme.Spacing.small) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill(AIscendTheme.Colors.accentPrimary.opacity(0.22))
                                )

                            Text("New Chat")
                                .aiscendTextStyle(.buttonLabel, color: AIscendTheme.Colors.textPrimary)

                            Spacer(minLength: 0)
                        }
                        .padding(AIscendTheme.Spacing.mediumLarge)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    if quota.shouldShowUpsell {
                        AIscendChatQuotaBanner(
                            quota: quota,
                            style: .compact,
                            onUpgradeTap: onUpgradeTap
                        )
                    }

                    if sections.isEmpty {
                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                            Text("No conversations yet")
                                .aiscendTextStyle(.cardTitle)

                            Text("Start a conversation and it will appear here, grouped cleanly so the next session is always close at hand.")
                                .aiscendTextStyle(.body)
                        }
                        .padding(AIscendTheme.Spacing.large)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .aiscendChatGlassCard(cornerRadius: 24, glowOpacity: 0.06)
                    } else {
                        ForEach(sections) { section in
                            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                                Text(section.key.title.uppercased())
                                    .aiscendTextStyle(.eyebrow, color: AIscendTheme.Colors.accentGlow)

                                VStack(spacing: AIscendTheme.Spacing.xSmall) {
                                    ForEach(section.threads) { thread in
                                        historyRow(for: thread)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, AIscendTheme.Spacing.large)
                .padding(.bottom, AIscendTheme.Spacing.xxLarge)
            }
        }
        .background(
            ZStack {
                AIscendBlurView(style: .systemChromeMaterialDark)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                    )

                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "131820").opacity(0.96),
                                Color(hex: "0D1016").opacity(0.98)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(0.92)

                AIscendChatPalette.heroGlow
                    .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(AIscendChatPalette.surfaceBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.48), radius: 32, x: 0, y: 16)
    }

    private func historyRow(for thread: AIscendChatThread) -> some View {
        let isActive = thread.id == activeThreadID

        return Button {
            onSelect(thread)
        } label: {
            HStack(alignment: .center, spacing: AIscendTheme.Spacing.small) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(thread.displayTitle)
                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textPrimary)
                        .lineLimit(1)

                    if let latestText = thread.messages.last?.text,
                       !latestText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    {
                        Text(latestText)
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                Text(thread.updatedAt.formatted(date: .omitted, time: .shortened))
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }
            .padding(.horizontal, AIscendTheme.Spacing.medium)
            .padding(.vertical, AIscendTheme.Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        isActive
                        ? LinearGradient(
                            colors: [
                                AIscendTheme.Colors.accentPrimary.opacity(0.22),
                                AIscendTheme.Colors.accentDeep.opacity(0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [
                                AIscendTheme.Colors.surfaceHighlight.opacity(0.68),
                                AIscendTheme.Colors.surfaceHighlight.opacity(0.46)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isActive ? AIscendTheme.Colors.accentGlow.opacity(0.4) : AIscendTheme.Colors.borderSubtle,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
