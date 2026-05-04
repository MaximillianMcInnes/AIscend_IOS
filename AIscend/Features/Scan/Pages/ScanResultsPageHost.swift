//
//  ScanResultsPageHost.swift
//  AIscend
//

import SwiftUI

struct ScanResultsPageHost: View {
    let page: ScanResultsPageID
    let pageIndex: Int
    @ObservedObject var viewModel: ScanResultsViewModel
    @ObservedObject var badgeManager: BadgeManager
    @ObservedObject var dailyCheckInStore: DailyCheckInStore
    let onShare: (ScanResultsPageID) -> Void
    let onPresentPaywall: (PaywallVariant, Bool, String?, Bool) -> Void
    let allowsPostResultActions: Bool
    let onOpenRoutine: () -> Void
    let onOpenChat: () -> Void
    let onOpenCheckIn: () -> Void
    let onOpenStreakHub: () -> Void
    let onReturnHome: () -> Void

    var body: some View {
        switch page {
        case .overview:
            OverviewResultsPage(
                viewModel: viewModel,
                pageIndex: pageIndex,
                onShare: { onShare(.overview) },
                onContinue: viewModel.advance
            )

        case .placement:
            PlacementResultsPage(
                pageIndex: pageIndex,
                totalPages: viewModel.pageCount,
                title: viewModel.title(for: .placement),
                subtitle: viewModel.subtitle(for: .placement),
                result: viewModel.result,
                onShare: { onShare(.placement) },
                onContinue: viewModel.advance
            )

        case .harmony:
            HarmonyResultsPage(
                face: viewModel.combinedSideProfile().merging(viewModel.combinedFrontProfile()) { _, front in front },
                isPaid: viewModel.isPremium,
                step: pageIndex + 1,
                total: viewModel.pageCount,
                goNext: viewModel.advance,
                onUpgrade: {
                    onPresentPaywall(.deepReport, true, "harmony-premium", true)
                }
            )

        case .eyes:
            EyesResultsPage(
                face: viewModel.combinedFrontProfile(),
                isPaid: viewModel.isPremium,
                step: pageIndex + 1,
                total: viewModel.pageCount,
                goNext: viewModel.advance,
                onUpgrade: {
                    onPresentPaywall(.lockedInsight, true, "locked-eyes", false)
                }
            )

        case .lips:
            LipsResultsPage(
                face: viewModel.combinedFrontProfile(),
                isPaid: viewModel.isPremium,
                step: pageIndex + 1,
                total: viewModel.pageCount,
                goNext: viewModel.advance,
                onUpgrade: {
                    onPresentPaywall(.deepReport, true, "lips-premium", false)
                }
            )

        case .jaw:
            JawResultsPage(
                face: viewModel.combinedFrontProfile(),
                isPaid: viewModel.isPremium,
                step: pageIndex + 1,
                total: viewModel.pageCount,
                goNext: viewModel.advance,
                onUpgrade: {
                    onPresentPaywall(.deepReport, true, "jaw-premium", true)
                }
            )

        case .sideProfile:
            SideProfileResultsPage(
                nose: viewModel.combinedFrontProfile().merging(viewModel.combinedSideProfile()) { _, side in side },
                harmony: viewModel.combinedFrontProfile().merging(viewModel.combinedSideProfile()) { _, side in side },
                isPaid: viewModel.isPremium,
                step: pageIndex + 1,
                total: viewModel.pageCount,
                goNext: {
                    viewModel.goToPage(0)
                },
                onUpgrade: {
                    onPresentPaywall(.deepReport, true, "side-premium", true)
                }
            )

        case .premiumPush:
            PremiumPushResultsPage(
                pageIndex: pageIndex,
                totalPages: viewModel.pageCount,
                title: viewModel.title(for: .premiumPush),
                subtitle: viewModel.subtitle(for: .premiumPush),
                onUpgrade: {
                    onPresentPaywall(.rewardLoop, true, "premium-push-primary", true)
                },
                onContinue: viewModel.advance
            )

        case .done:
            DoneResultsPage(
                pageIndex: pageIndex,
                totalPages: viewModel.pageCount,
                title: viewModel.title(for: .done),
                subtitle: viewModel.subtitle(for: .done),
                isPremium: viewModel.isPremium,
                cards: viewModel.completionCards,
                primaryTitle: viewModel.primaryDoneTitle(),
                allowsPostResultActions: allowsPostResultActions,
                onPrimary: {
                    guard allowsPostResultActions else {
                        return
                    }

                    if viewModel.isPremium {
                        badgeManager.recordGlowUpOpened()
                        onOpenRoutine()
                    } else {
                        onPresentPaywall(.glowUpGate, true, "glow-up-gate", true)
                    }
                },
                onOpenChat: {
                    guard allowsPostResultActions else {
                        return
                    }

                    badgeManager.recordAdvisorOpened()
                    onOpenChat()
                },
                onOpenCheckIn: onOpenCheckIn,
                onOpenStreakHub: onOpenStreakHub,
                streakDays: dailyCheckInStore.snapshot.currentStreak,
                checkedInToday: dailyCheckInStore.hasCheckedInToday,
                badgeCount: badgeManager.earnedBadges.count,
                onShare: { onShare(.done) },
                onReturnHome: onReturnHome
            )
        }
    }
}
