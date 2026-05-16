//
//  DoneResultsPage.swift
//  AIscend
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct DoneResultsPage: View {
    let pageIndex: Int
    let totalPages: Int
    let title: String
    let subtitle: String
    let isPremium: Bool
    let cards: [ResultsCompletionCardModel]
    let primaryTitle: String
    let allowsPostResultActions: Bool
    let onPrimary: () -> Void
    let onOpenResults: () -> Void
    let onOpenChat: () -> Void
    let onOpenCheckIn: () -> Void
    let onOpenStreakHub: () -> Void
    let streakDays: Int
    let checkedInToday: Bool
    let badgeCount: Int
    let onShare: () -> Void
    let onReturnHome: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var completionStepIndex = 0

    private var slides: [ScanCompletionSlide] {
        [
            ScanCompletionSlide(
                id: "saved",
                symbol: "checkmark.circle.fill",
                title: "Scan complete.",
                body: "Your results are saved securely to your account.",
                hint: "Tap below to continue.",
                primaryLabel: "Continue"
            ),
            ScanCompletionSlide(
                id: "anytime",
                symbol: "chart.bar.xaxis",
                title: "Your results are always here.",
                body: "You can come back and view your breakdown whenever you want.",
                hint: "Tap below to continue.",
                primaryLabel: "Next",
                secondary: ScanCompletionSecondaryAction(
                    label: "Open results",
                    symbol: "chart.bar.xaxis",
                    action: onOpenResults
                )
            ),
            ScanCompletionSlide(
                id: "chat",
                symbol: "message.fill",
                title: "Ask the AI about any feature.",
                body: "Get personalised explanations and advice based on your scan.",
                hint: "Tap below to continue.",
                primaryLabel: "Next",
                secondary: ScanCompletionSecondaryAction(
                    label: "Open chatbot",
                    symbol: "message.fill",
                    action: onOpenChat
                )
            ),
            ScanCompletionSlide(
                id: "glowup",
                symbol: "sparkles",
                title: "Let's go to your Glow-Up plan.",
                body: "Your routine and next steps are ready.",
                hint: "You can revisit results anytime.",
                primaryLabel: isPremium ? "Go to Glow-Up" : "Unlock with Premium"
            )
        ]
    }

    private var slide: ScanCompletionSlide {
        slides[min(max(completionStepIndex, 0), max(slides.count - 1, 0))]
    }

    private var isLastSlide: Bool {
        completionStepIndex == slides.count - 1
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                completionDots
                    .padding(.top, geometry.safeAreaInsets.top + AIscendTheme.Spacing.large)

                Spacer(minLength: AIscendTheme.Spacing.large)

                slideContent
                    .frame(maxWidth: 420)
                    .frame(maxWidth: .infinity)

                Spacer(minLength: AIscendTheme.Spacing.large)

                bottomActions
                    .padding(.bottom, geometry.safeAreaInsets.bottom + AIscendTheme.Spacing.medium)
            }
            .padding(.horizontal, AIscendTheme.Spacing.screenInset)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            impact(style: .light)
        }
        .onChange(of: completionStepIndex) { _, _ in
            impact(style: isLastSlide ? .medium : .light)
        }
    }

    private var completionDots: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            ForEach(slides.indices, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index == completionStepIndex ? AIscendTheme.Colors.accentGlow : AIscendTheme.Colors.accentGlow.opacity(0.25))
                    .frame(width: index == completionStepIndex ? 18 : 7, height: 7)
                    .scaleEffect(index == completionStepIndex ? 1.08 : 1)
                    .shadow(
                        color: index == completionStepIndex ? AIscendTheme.Colors.accentGlow.opacity(0.42) : .clear,
                        radius: 14,
                        x: 0,
                        y: 0
                    )
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: completionStepIndex)
    }

    private var slideContent: some View {
        VStack(spacing: 0) {
            ZStack {
                if !reduceMotion {
                    Circle()
                        .fill(AIscendTheme.Colors.accentPrimary.opacity(0.18))
                        .frame(width: 250, height: 250)
                        .blur(radius: 46)
                        .offset(y: -18)

                    Circle()
                        .fill(Color(hex: "E858FF").opacity(0.10))
                        .frame(width: 280, height: 280)
                        .blur(radius: 56)
                        .offset(y: 44)
                }

                VStack(spacing: AIscendTheme.Spacing.medium) {
                    Image(systemName: slide.symbol)
                        .font(.system(size: 46, weight: .semibold))
                        .foregroundStyle(AIscendTheme.Colors.accentGlow)
                        .padding(.bottom, AIscendTheme.Spacing.small)

                    Text(slide.title)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(slide.body)
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 320)

                    if let hint = slide.hint {
                        Text(hint)
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted.opacity(0.84))
                            .padding(.top, 2)
                    }

                    if let secondary = slide.secondary, allowsPostResultActions {
                        Button {
                            impact(style: .soft)
                            secondary.action()
                        } label: {
                            HStack(spacing: AIscendTheme.Spacing.xSmall) {
                                Image(systemName: secondary.symbol)
                                    .font(.system(size: 14, weight: .semibold))

                                Text(secondary.label)
                                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                            }
                            .padding(.horizontal, AIscendTheme.Spacing.medium)
                            .padding(.vertical, 10)
                            .background(Capsule(style: .continuous).fill(Color.white.opacity(0.055)))
                            .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, AIscendTheme.Spacing.small)
                    }
                }
                .id(slide.id)
                .transition(reduceMotion ? .opacity : .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.88), value: completionStepIndex)
    }

    private var bottomActions: some View {
        VStack(spacing: AIscendTheme.Spacing.small) {
            Button(action: handlePrimary) {
                AIscendButtonLabel(
                    title: slide.primaryLabel,
                    trailingSymbol: isLastSlide && !isPremium ? "lock.fill" : "arrow.right"
                )
            }
            .buttonStyle(AIscendButtonStyle(variant: .primary))

            if isLastSlide {
                Button(action: onReturnHome) {
                    AIscendButtonLabel(title: isPremium ? "Back to Dashboard" : "Maybe Later", leadingSymbol: "xmark")
                }
                .buttonStyle(AIscendButtonStyle(variant: .ghost))
            }
        }
    }

    private func handlePrimary() {
        impact(style: isLastSlide ? .medium : .soft)

        guard allowsPostResultActions else {
            onReturnHome()
            return
        }

        guard !isLastSlide else {
            onPrimary()
            return
        }

        setCompletionStep(completionStepIndex + 1)
    }

    private func setCompletionStep(_ index: Int) {
        let nextIndex = min(max(index, 0), slides.count - 1)
        guard nextIndex != completionStepIndex else {
            return
        }

        if reduceMotion {
            completionStepIndex = nextIndex
        } else {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                completionStepIndex = nextIndex
            }
        }
    }

    private func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: style).impactOccurred()
        #endif
    }
}

private struct ScanCompletionSlide: Identifiable {
    let id: String
    let symbol: String
    let title: String
    let body: String
    let hint: String?
    let primaryLabel: String
    var secondary: ScanCompletionSecondaryAction?
}

private struct ScanCompletionSecondaryAction {
    let label: String
    let symbol: String
    let action: () -> Void
}
