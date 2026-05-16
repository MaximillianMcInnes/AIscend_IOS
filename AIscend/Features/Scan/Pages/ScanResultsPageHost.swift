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
    let isUserPremium: Bool
    let onOpenRoutine: () -> Void
    let onOpenGlowUpPlan: (PersistedScanRecord) -> Void
    let onOpenChat: () -> Void
    let onOpenCheckIn: () -> Void
    let onOpenStreakHub: () -> Void
    let onReturnHome: () -> Void

    private var canViewPremiumResults: Bool {
        isUserPremium
    }

    var body: some View {
        if page.requiresPremiumAccess && !canViewPremiumResults {
            ScanResultsPremiumGatePage(
                title: viewModel.title(for: page),
                step: pageIndex + 1,
                total: viewModel.pageCount,
                onUpgrade: {
                    onPresentPaywall(.deepReport, true, "scan_results_premium_gate", true)
                },
                onBackToOverview: {
                    viewModel.goToPage(0)
                }
            )
        } else {
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
                face: viewModel.harmonyProfile(),
                isPaid: canViewPremiumResults,
                step: pageIndex + 1,
                total: viewModel.pageCount,
                goNext: viewModel.advance,
                onUpgrade: {
                    onPresentPaywall(.deepReport, true, "harmony-premium", true)
                }
            )

        case .eyes:
            EyesResultsPage(
                traits: viewModel.sectionTraits(for: .eyes),
                isPaid: canViewPremiumResults,
                step: pageIndex + 1,
                total: viewModel.pageCount,
                goNext: viewModel.advance,
                onUpgrade: {
                    onPresentPaywall(.lockedInsight, true, "locked-eyes", false)
                }
            )

        case .lips:
            LipsResultsPage(
                lips: viewModel.lipsProfile(),
                face: viewModel.combinedFrontProfile(),
                isPaid: canViewPremiumResults,
                step: pageIndex + 1,
                total: viewModel.pageCount,
                goNext: viewModel.advance,
                onUpgrade: {
                    onPresentPaywall(.deepReport, true, "lips-premium", false)
                }
            )

        case .jaw:
            JawResultsPage(
                traits: viewModel.sectionTraits(for: .jaw),
                isPaid: canViewPremiumResults,
                step: pageIndex + 1,
                total: viewModel.pageCount,
                goNext: viewModel.advance,
                onUpgrade: {
                    onPresentPaywall(.deepReport, true, "jaw-premium", true)
                }
            )

        case .sideProfile:
            SideProfileResultsPage(
                sideProfile: viewModel.combinedSideProfile(),
                isPaid: canViewPremiumResults,
                step: pageIndex + 1,
                total: viewModel.pageCount,
                goNext: viewModel.advance,
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
                isPremium: isUserPremium,
                cards: viewModel.completionCards,
                primaryTitle: viewModel.primaryDoneTitle(isUserPremium: isUserPremium),
                allowsPostResultActions: allowsPostResultActions,
                onPrimary: {
                    guard allowsPostResultActions else {
                        return
                    }

                    if isUserPremium, let result = viewModel.result {
                        badgeManager.recordGlowUpOpened()
                        onOpenGlowUpPlan(result)
                    } else {
                        onPresentPaywall(.glowUpGate, true, "glow-up-gate", true)
                    }
                },
                onOpenResults: {
                    guard allowsPostResultActions else {
                        return
                    }

                    viewModel.goToPage(0)
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
}

private extension ScanResultsPageID {
    var requiresPremiumAccess: Bool {
        switch self {
        case .placement, .harmony, .eyes, .lips, .jaw, .sideProfile:
            return true
        case .overview, .premiumPush, .done:
            return false
        }
    }
}

private struct ScanResultsPremiumGatePage: View {
    let title: String
    let step: Int
    let total: Int
    let onUpgrade: () -> Void
    let onBackToOverview: () -> Void

    @State private var appeared = false

    var body: some View {
        ResultsFullscreenShell(
            title: title,
            subtitle: "Premium result section",
            step: step,
            total: total,
            topRight: {
                ScanResultsAccessPill(isPaid: false, onUpgrade: onUpgrade)
            },
            bottomCTA: {
                ResultsNextButton(title: "Unlock Premium", systemImage: "lock.open.fill", action: onUpgrade)
            },
            content: {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    ScanResultsFeatureIntroPanel(
                        title: "Unlock the full facial analysis",
                        copy: "This section is part of the Premium scan report. Free access keeps the overview available without exposing locked analysis.",
                        systemImage: "lock.fill"
                    )

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                        PremiumGateBenefit(title: "Full scan breakdowns", symbol: "waveform.path.ecg.rectangle.fill")
                        PremiumGateBenefit(title: "Premium facial analysis pages", symbol: "face.smiling.inverse")
                        PremiumGateBenefit(title: "Previous scan insights", symbol: "clock.arrow.circlepath")
                    }

                    Button(action: onBackToOverview) {
                        AIscendButtonLabel(title: "Back to Overview", leadingSymbol: "arrow.uturn.left")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .secondary))
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)
            }
        )
        .onAppear {
            AIScendSuperwallAnalytics.track(
                "scan_results_premium_gate",
                params: ["section": title]
            )
            withAnimation(.smooth(duration: 0.32)) {
                appeared = true
            }
        }
    }
}

private struct PremiumGateBenefit: View {
    let title: String
    let symbol: String

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AIscendTheme.Colors.accentGlow)
                .frame(width: 24, height: 24)

            Text(title)
                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.medium)
        .aiscendPanel(.muted)
    }
}
