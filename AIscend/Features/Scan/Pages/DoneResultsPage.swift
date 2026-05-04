//
//  DoneResultsPage.swift
//  AIscend
//

import SwiftUI

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
    let onOpenChat: () -> Void
    let onOpenCheckIn: () -> Void
    let onOpenStreakHub: () -> Void
    let streakDays: Int
    let checkedInToday: Bool
    let badgeCount: Int
    let onShare: () -> Void
    let onReturnHome: () -> Void

    var body: some View {
        ResultsSectionShell(
            pageIndex: pageIndex,
            totalPages: totalPages,
            title: title,
            subtitle: subtitle,
            badge: "Completion",
            shareActionTitle: "Share result",
            onShare: onShare
        ) {
            DashboardGlassCard(tone: .hero) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    ForEach(cards) { card in
                        ResultsCompletionCard(card: card)
                    }
                }
            }

            if allowsPostResultActions {
                DashboardGlassCard(tone: .premium) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                        AIscendSectionHeader(
                            eyebrow: "Accountability",
                            title: checkedInToday ? "Today's check-in is protected" : "Start the daily accountability loop",
                            subtitle: checkedInToday
                                ? "Your streak stays intact. The consistency layer is already working in the background."
                                : "Lock in the day, protect the streak, and give the result a reason to keep mattering tomorrow."
                        )

                        HStack(spacing: AIscendTheme.Spacing.small) {
                            PlacementBadge(
                                title: "\(streakDays)d",
                                detail: "Current streak"
                            )
                            PlacementBadge(
                                title: "\(badgeCount)",
                                detail: "Badges unlocked"
                            )
                        }

                        Button(action: onOpenCheckIn) {
                            AIscendButtonLabel(
                                title: checkedInToday ? "Review Daily Check-In" : "Start Daily Check-In",
                                leadingSymbol: "calendar.badge.checkmark"
                            )
                        }
                        .buttonStyle(AIscendButtonStyle(variant: .secondary))

                        Button(action: onOpenStreakHub) {
                            AIscendButtonLabel(title: "Open Consistency Hub", leadingSymbol: "flame.fill")
                        }
                        .buttonStyle(AIscendButtonStyle(variant: .ghost))
                    }
                }

                Button(action: onPrimary) {
                    AIscendButtonLabel(title: primaryTitle, leadingSymbol: isPremium ? "scope" : "crown.fill")
                }
                .buttonStyle(AIscendButtonStyle(variant: .primary))

                Button(action: onOpenChat) {
                    AIscendButtonLabel(title: "Ask Advisor To Explain", leadingSymbol: "message.fill")
                }
                .buttonStyle(AIscendButtonStyle(variant: .secondary))
            }

            Button(action: onReturnHome) {
                AIscendButtonLabel(title: allowsPostResultActions ? (isPremium ? "Back to Dashboard" : "Maybe Later") : "Close", leadingSymbol: "xmark")
            }
            .buttonStyle(AIscendButtonStyle(variant: .ghost))
        }
    }
}
