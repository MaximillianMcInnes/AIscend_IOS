//
//  AIscendUpgradeView.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import Foundation
import SwiftUI

enum AIscendUpgradePlanID: String, CaseIterable, Identifiable {
    case monthly
    case yearly

    var id: String { rawValue }
}

struct AIscendUpgradePlan: Identifiable, Equatable {
    let id: AIscendUpgradePlanID
    let title: String
    let badge: String?
    let price: String
    let periodLabel: String
    let secondaryLabel: String
    let trialLabel: String
    let billingDetail: String
    let highlight: String
    let savingsNote: String?
    let benefitHighlights: [String]
    let accent: RoutineAccent

    static func mockPlans(trialEligible: Bool) -> [AIscendUpgradePlan] {
        [
            AIscendUpgradePlan(
                id: .monthly,
                title: "Pro Monthly",
                badge: nil,
                price: "$14.99",
                periodLabel: "per month",
                secondaryLabel: "Flexible access with the full Pro layer.",
                trialLabel: trialEligible ? "7 days free, then billed monthly." : "Starts immediately with monthly billing.",
                billingDetail: trialEligible ? "Payment begins after your 7-day trial unless canceled beforehand." : "Billed every month until canceled in Settings.",
                highlight: "Full reports, advanced insights, and priority processing.",
                savingsNote: nil,
                benefitHighlights: [
                    "Advanced AI appearance reports",
                    "Side-profile and harmony analysis",
                    "Priority processing for new scans"
                ],
                accent: .dawn
            ),
            AIscendUpgradePlan(
                id: .yearly,
                title: "Pro Yearly",
                badge: "Best Value",
                price: "$89.99",
                periodLabel: "per year",
                secondaryLabel: "Equivalent to $7.50 / month with the full Pro layer.",
                trialLabel: trialEligible ? "7 days free, then billed yearly." : "Starts immediately with yearly billing.",
                billingDetail: trialEligible ? "One yearly charge begins after trial ends unless canceled beforehand." : "Billed once per year. Cancel anytime in Settings.",
                highlight: "The strongest rate for deeper analysis and future Pro modules.",
                savingsNote: "Save 50% vs monthly",
                benefitHighlights: [
                    "Advanced AI reports and full breakdowns",
                    "Deeper history, trend visibility, and archive access",
                    "Early access to premium modules as they ship"
                ],
                accent: .sky
            )
        ]
    }
}

struct AIscendUpgradeFeature: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let symbol: String
    let accent: RoutineAccent

    static let primary: [AIscendUpgradeFeature] = [
        AIscendUpgradeFeature(
            title: "Advanced AI appearance reports",
            detail: "Move beyond surface scoring with sharper breakdowns of strengths, weaknesses, and highest-leverage changes.",
            symbol: "sparkles.rectangle.stack.fill",
            accent: .sky
        ),
        AIscendUpgradeFeature(
            title: "Side-profile and harmony analysis",
            detail: "Unlock fuller structural reads, ratio commentary, and a more complete view of how the face presents.",
            symbol: "person.crop.rectangle.stack.fill",
            accent: .dawn
        ),
        AIscendUpgradeFeature(
            title: "Priority scan processing",
            detail: "Get into your next report faster, with a more responsive premium layer when you are actively improving.",
            symbol: "clock.badge.checkmark.fill",
            accent: .mint
        ),
        AIscendUpgradeFeature(
            title: "Deeper progress visibility",
            detail: "Track meaningful movement over time with stronger history, clearer comparisons, and cleaner AI signal.",
            symbol: "chart.line.uptrend.xyaxis",
            accent: .sky
        ),
        AIscendUpgradeFeature(
            title: "Premium tools and future modules",
            detail: "Step into the more complete AIScend system as new high-value features and analysis layers arrive.",
            symbol: "lock.shield.fill",
            accent: .dawn
        )
    ]
}

private enum UpgradeComparisonTone {
    case muted
    case neutral
    case positive
}

private struct AIscendUpgradeComparisonValue {
    let label: String
    let tone: UpgradeComparisonTone
}

private struct AIscendUpgradeComparisonRow: Identifiable {
    let id = UUID()
    let title: String
    let free: AIscendUpgradeComparisonValue
    let pro: AIscendUpgradeComparisonValue

    static let previewRows: [AIscendUpgradeComparisonRow] = [
        AIscendUpgradeComparisonRow(title: "Scan access", free: AIscendUpgradeComparisonValue(label: "Basic", tone: .neutral), pro: AIscendUpgradeComparisonValue(label: "Full", tone: .positive)),
        AIscendUpgradeComparisonRow(title: "Advanced reports", free: AIscendUpgradeComparisonValue(label: "Preview", tone: .muted), pro: AIscendUpgradeComparisonValue(label: "Included", tone: .positive)),
        AIscendUpgradeComparisonRow(title: "Side-profile analysis", free: AIscendUpgradeComparisonValue(label: "Locked", tone: .muted), pro: AIscendUpgradeComparisonValue(label: "Included", tone: .positive)),
        AIscendUpgradeComparisonRow(title: "Harmony and ratio metrics", free: AIscendUpgradeComparisonValue(label: "Limited", tone: .neutral), pro: AIscendUpgradeComparisonValue(label: "Full", tone: .positive)),
        AIscendUpgradeComparisonRow(title: "History and progress", free: AIscendUpgradeComparisonValue(label: "Recent", tone: .neutral), pro: AIscendUpgradeComparisonValue(label: "Extended", tone: .positive)),
        AIscendUpgradeComparisonRow(title: "Processing priority", free: AIscendUpgradeComparisonValue(label: "Standard", tone: .neutral), pro: AIscendUpgradeComparisonValue(label: "Priority", tone: .positive)),
        AIscendUpgradeComparisonRow(title: "Future Pro modules", free: AIscendUpgradeComparisonValue(label: "No", tone: .muted), pro: AIscendUpgradeComparisonValue(label: "Early", tone: .positive))
    ]
}

struct AIscendUpgradeFAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String

    static let previewItems: [AIscendUpgradeFAQItem] = [
        AIscendUpgradeFAQItem(question: "When does payment begin?", answer: "If a trial is active, payment begins after the trial ends unless you cancel beforehand. Without a trial, billing begins immediately after confirmation."),
        AIscendUpgradeFAQItem(question: "How does the free trial work?", answer: "Your trial unlocks the full Pro layer immediately. You can explore advanced reports, premium tools, and deeper analysis before any paid renewal begins."),
        AIscendUpgradeFAQItem(question: "Can I cancel anytime?", answer: "Yes. You can manage or cancel your subscription in Apple account settings. Access continues through the current billing period."),
        AIscendUpgradeFAQItem(question: "Why is yearly the better value?", answer: "Yearly unlocks the same full Pro layer at a substantially lower effective monthly rate, which makes it the strongest long-term option if you plan to keep improving."),
        AIscendUpgradeFAQItem(question: "What happens after cancellation?", answer: "Your Pro access remains active until the current period ends. After that, the app returns to the free layer while preserving your account and prior data.")
    ]
}

private enum UpgradeCardStyle {
    case hero
    case selected
    case standard
    case subtle
}

struct AIscendUpgradeView: View {
    let premiumURL: URL?
    let onDismiss: () -> Void
    var trialEligible: Bool = true
    var onSubscribe: ((AIscendUpgradePlan) -> Void)? = nil

    @Environment(\.openURL) private var openURL
    @State private var selectedPlanID: AIscendUpgradePlanID = .yearly
    @State private var expandedFAQID: AIscendUpgradeFAQItem.ID?
    @State private var hasAppeared = false

    private var plans: [AIscendUpgradePlan] {
        AIscendUpgradePlan.mockPlans(trialEligible: trialEligible)
    }

    private var selectedPlan: AIscendUpgradePlan {
        plans.first(where: { $0.id == selectedPlanID }) ?? plans[0]
    }

    private var purchaseReady: Bool {
        onSubscribe != nil || premiumURL != nil
    }

    var body: some View {
        ZStack {
            AIscendBackdrop()
            UpgradeAmbientLayer()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxLarge) {
                    UpgradeHeader(onDismiss: onDismiss)
                        .upgradeReveal(isVisible: hasAppeared, delay: 0.02)

                    UpgradeHeroSection()
                        .upgradeReveal(isVisible: hasAppeared, delay: 0.08)

                    PlanSelectorSection(
                        plans: plans,
                        selectedPlanID: selectedPlanID,
                        onSelect: { plan in
                            withAnimation(.easeInOut(duration: 0.22)) {
                                selectedPlanID = plan.id
                            }
                        }
                    )
                    .upgradeReveal(isVisible: hasAppeared, delay: 0.14)

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                        AIscendSectionHeader(
                            eyebrow: "Value",
                            title: "What Pro actually unlocks",
                            subtitle: "AIScend Pro is about sharper visibility, deeper reads, and better tools for real self-improvement."
                        )

                        UpgradeFeatureStack(features: AIscendUpgradeFeature.primary)
                    }
                    .upgradeReveal(isVisible: hasAppeared, delay: 0.20)

                    MainUpgradeCard(
                        plan: selectedPlan,
                        purchaseReady: purchaseReady,
                        onSubscribe: primaryAction
                    )
                    .upgradeReveal(isVisible: hasAppeared, delay: 0.26)

                    ComparisonSection(rows: AIscendUpgradeComparisonRow.previewRows)
                        .upgradeReveal(isVisible: hasAppeared, delay: 0.32)

                    UpgradeCredibilitySection()
                        .upgradeReveal(isVisible: hasAppeared, delay: 0.38)

                    FAQSection(
                        items: AIscendUpgradeFAQItem.previewItems,
                        expandedID: expandedFAQID,
                        onToggle: { item in
                            withAnimation(.easeInOut(duration: 0.24)) {
                                expandedFAQID = expandedFAQID == item.id ? nil : item.id
                            }
                        }
                    )
                    .upgradeReveal(isVisible: hasAppeared, delay: 0.44)

                    TrustFooter(plan: selectedPlan)
                        .upgradeReveal(isVisible: hasAppeared, delay: 0.50)
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.medium)
                .padding(.bottom, AIscendTheme.Spacing.xxLarge + AIscendTheme.Spacing.large)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            hasAppeared = true
        }
    }

    private func primaryAction() {
        if let onSubscribe {
            onSubscribe(selectedPlan)
            return
        }

        guard let premiumURL else {
            return
        }

        openURL(premiumURL)
    }
}

private struct UpgradeAmbientLayer: View {
    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    AIscendTheme.Colors.accentPrimary.opacity(0.24),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 320
            )
            .offset(x: 130, y: -180)

            RadialGradient(
                colors: [
                    AIscendTheme.Colors.accentGlow.opacity(0.16),
                    .clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 260
            )
            .offset(x: -120, y: 140)

            RadialGradient(
                colors: [
                    Color.white.opacity(0.05),
                    .clear
                ],
                center: .topLeading,
                startRadius: 10,
                endRadius: 240
            )
            .offset(x: -160, y: -200)
        }
        .ignoresSafeArea()
    }
}

private struct UpgradeSurfaceCard<Content: View>: View {
    let style: UpgradeCardStyle
    private let content: Content

    init(style: UpgradeCardStyle = .standard, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AIscendTheme.Spacing.xLarge)
            .background(background)
            .clipShape(shape)
            .overlay(shape.stroke(border, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.34), radius: shadowRadius, x: 0, y: 18)
            .shadow(color: glowColor, radius: 30, x: 0, y: 0)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
    }

    private var shadowRadius: CGFloat {
        switch style {
        case .hero, .selected:
            30
        case .standard:
            22
        case .subtle:
            16
        }
    }

    private var glowColor: Color {
        switch style {
        case .hero:
            AIscendTheme.Colors.accentGlow.opacity(0.20)
        case .selected:
            AIscendTheme.Colors.accentPrimary.opacity(0.18)
        case .standard:
            AIscendTheme.Colors.accentPrimary.opacity(0.08)
        case .subtle:
            .clear
        }
    }

    private var fill: LinearGradient {
        switch style {
        case .hero:
            LinearGradient(
                colors: [
                    Color(hex: "1A1622").opacity(0.98),
                    Color(hex: "0E1117").opacity(1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .selected:
            LinearGradient(
                colors: [
                    Color(hex: "1A1727").opacity(0.98),
                    Color(hex: "10131A").opacity(1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .standard:
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.secondaryBackground.opacity(0.95),
                    Color(hex: "10141B").opacity(0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .subtle:
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.secondaryBackground.opacity(0.86),
                    AIscendTheme.Colors.appBackground.opacity(0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var border: LinearGradient {
        LinearGradient(
            colors: [
                style == .selected ? AIscendTheme.Colors.accentGlow.opacity(0.46) : AIscendTheme.Colors.borderStrong,
                AIscendTheme.Colors.borderSubtle,
                AIscendTheme.Colors.borderSubtle
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var background: some View {
        ZStack {
            shape.fill(fill)
            shape.fill(.ultraThinMaterial).opacity(0.10)
            shape.fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.06),
                        .clear,
                        AIscendTheme.Colors.accentGlow.opacity(style == .hero || style == .selected ? 0.10 : 0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            if style == .hero || style == .selected {
                Circle()
                    .fill(AIscendTheme.Colors.accentGlow.opacity(style == .hero ? 0.16 : 0.10))
                    .frame(width: 220, height: 220)
                    .blur(radius: 32)
                    .offset(x: 90, y: -130)
            }
        }
    }
}

private struct UpgradeHeader: View {
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.9))
                    )
                    .overlay(
                        Circle()
                            .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close upgrade screen")
        }
        .padding(.top, AIscendTheme.Spacing.small)
    }
}

private struct UpgradeHeroSection: View {
    var body: some View {
        UpgradeSurfaceCard(style: .hero) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                AIscendBadge(
                    title: "AIScend Pro",
                    symbol: "crown.fill",
                    style: .accent
                )

                Text("Unlock the full system")
                    .font(.system(size: 36, weight: .bold, design: .default))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Deeper analysis. Better visibility. More control.")
                    .aiscendTextStyle(.sectionTitle, color: AIscendTheme.Colors.textSecondary)

                Text("Step into the more complete AIScend layer with sharper reports, better progress signal, and tools built for focused self-improvement.")
                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        UpgradeMicroPill(title: "Private")
                        UpgradeMicroPill(title: "Priority processing")
                        UpgradeMicroPill(title: "Full reports")
                    }

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                        UpgradeMicroPill(title: "Private")
                        UpgradeMicroPill(title: "Priority processing")
                        UpgradeMicroPill(title: "Full reports")
                    }
                }
            }
        }
    }
}

private struct UpgradeMicroPill: View {
    let title: String

    var body: some View {
        Text(title)
            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
            .padding(.horizontal, AIscendTheme.Spacing.small)
            .padding(.vertical, AIscendTheme.Spacing.xSmall)
            .background(
                Capsule(style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.84))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
            )
    }
}

private struct PlanSelectorSection: View {
    let plans: [AIscendUpgradePlan]
    let selectedPlanID: AIscendUpgradePlanID
    let onSelect: (AIscendUpgradePlan) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendSectionHeader(
                eyebrow: "Plans",
                title: "Choose your access layer",
                subtitle: "Yearly is positioned as the strongest value. Monthly keeps the full Pro layer flexible."
            )

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    ForEach(plans) { plan in
                        UpgradePlanCard(
                            plan: plan,
                            isSelected: plan.id == selectedPlanID,
                            onTap: { onSelect(plan) }
                        )
                    }
                }

                VStack(spacing: AIscendTheme.Spacing.small) {
                    ForEach(plans) { plan in
                        UpgradePlanCard(
                            plan: plan,
                            isSelected: plan.id == selectedPlanID,
                            onTap: { onSelect(plan) }
                        )
                    }
                }
            }
        }
    }
}

private struct UpgradePlanCard: View {
    let plan: AIscendUpgradePlan
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            UpgradeSurfaceCard(style: isSelected ? .selected : .standard) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                            if let badge = plan.badge {
                                AIscendBadge(
                                    title: badge,
                                    symbol: "sparkles",
                                    style: .accent
                                )
                            } else {
                                AIscendBadge(
                                    title: "Pro",
                                    symbol: "scope",
                                    style: .neutral
                                )
                            }

                            Text(plan.title)
                                .aiscendTextStyle(.cardTitle)
                        }

                        Spacer(minLength: AIscendTheme.Spacing.small)

                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(isSelected ? AIscendTheme.Colors.accentGlow : AIscendTheme.Colors.textMuted)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: AIscendTheme.Spacing.xSmall) {
                        Text(plan.price)
                            .font(.system(size: 34, weight: .bold, design: .default))
                            .foregroundStyle(AIscendTheme.Colors.textPrimary)

                        Text(plan.periodLabel)
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                    }

                    Text(plan.secondaryLabel)
                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)

                    if let savingsNote = plan.savingsNote {
                        UpgradeStatStrip(text: savingsNote)
                    } else {
                        UpgradeStatStrip(text: "Full Pro access")
                    }

                    Text(plan.trialLabel)
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.accentGlow)

                    Text(plan.highlight)
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scaleEffect(isSelected ? 1 : 0.985)
            .animation(.easeInOut(duration: 0.22), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

private struct UpgradeStatStrip: View {
    let text: String

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            Image(systemName: "arrow.down.forward")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)

            Text(text)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
        }
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, AIscendTheme.Spacing.xSmall)
        .background(
            Capsule(style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.84))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct UpgradeFeatureStack: View {
    let features: [AIscendUpgradeFeature]

    var body: some View {
        UpgradeSurfaceCard {
            VStack(spacing: AIscendTheme.Spacing.medium) {
                ForEach(features) { feature in
                    BenefitRow(feature: feature)
                }
            }
        }
    }
}

private struct BenefitRow: View {
    let feature: AIscendUpgradeFeature

    var body: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: feature.symbol, accent: feature.accent, size: 46)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(feature.title)
                    .aiscendTextStyle(.cardTitle)

                Text(feature.detail)
                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.66))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct MainUpgradeCard: View {
    let plan: AIscendUpgradePlan
    let purchaseReady: Bool
    let onSubscribe: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendSectionHeader(
                eyebrow: "Upgrade",
                title: "Continue into the stronger AIScend layer",
                subtitle: "This is the main conversion surface: clear plan visibility, calm billing language, and a single obvious next step."
            )

            UpgradeSurfaceCard(style: .selected) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                            AIscendBadge(
                                title: "Selected Plan",
                                symbol: "crown.fill",
                                style: .accent
                            )

                            Text(plan.title)
                                .font(.system(size: 28, weight: .bold, design: .default))
                                .foregroundStyle(AIscendTheme.Colors.textPrimary)

                            Text(plan.trialLabel)
                                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                        }

                        Spacer(minLength: AIscendTheme.Spacing.medium)

                        VStack(alignment: .trailing, spacing: AIscendTheme.Spacing.xxSmall) {
                            Text(plan.price)
                                .font(.system(size: 30, weight: .bold, design: .default))
                                .foregroundStyle(AIscendTheme.Colors.textPrimary)

                            Text(plan.periodLabel)
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                        }
                    }

                    if let savingsNote = plan.savingsNote {
                        UpgradeStatStrip(text: savingsNote)
                    }

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        ForEach(plan.benefitHighlights, id: \.self) { line in
                            HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AIscendTheme.Colors.accentGlow)
                                    .padding(.top, 2)

                                Text(line)
                                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                            }
                        }
                    }

                    Text(plan.billingDetail)
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textMuted)

                    Button(action: onSubscribe) {
                        AIscendButtonLabel(
                            title: purchaseReady ? "Start with \(plan.title)" : "Purchase link unavailable",
                            leadingSymbol: purchaseReady ? "arrow.up.forward" : "exclamationmark.triangle.fill"
                        )
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .primary))
                    .disabled(!purchaseReady)
                    .opacity(purchaseReady ? 1 : 0.7)

                    Text("Secure payments via Apple. Cancel anytime in Settings.")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                }
            }
        }
    }
}

private struct ComparisonSection: View {
    let rows: [AIscendUpgradeComparisonRow]

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendSectionHeader(
                eyebrow: "Comparison",
                title: "Free vs Pro",
                subtitle: "The upgrade should feel rational as well as aspirational."
            )

            UpgradeSurfaceCard(style: .standard) {
                VStack(spacing: AIscendTheme.Spacing.medium) {
                    HStack {
                        Text("Capability")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                        Spacer()

                        comparisonHeader(title: "Free")
                        comparisonHeader(title: "Pro")
                    }

                    ForEach(rows) { row in
                        HStack(alignment: .center, spacing: AIscendTheme.Spacing.small) {
                            Text(row.title)
                                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            UpgradeComparisonPill(value: row.free)
                            UpgradeComparisonPill(value: row.pro)
                        }
                        .padding(.vertical, AIscendTheme.Spacing.xSmall)

                        if row.id != rows.last?.id {
                            Divider()
                                .overlay(AIscendTheme.Colors.divider)
                        }
                    }

                    Text("Yearly keeps the full Pro layer at the strongest effective rate without changing what you unlock.")
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                        .padding(.top, AIscendTheme.Spacing.small)
                }
            }
        }
    }

    private func comparisonHeader(title: String) -> some View {
        Text(title)
            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
            .frame(width: 86)
    }
}

private struct UpgradeComparisonPill: View {
    let value: AIscendUpgradeComparisonValue

    var body: some View {
        Text(value.label)
            .aiscendTextStyle(.caption, color: foreground)
            .frame(width: 86)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(border, lineWidth: 1)
            )
    }

    private var foreground: Color {
        switch value.tone {
        case .muted:
            AIscendTheme.Colors.textMuted
        case .neutral, .positive:
            AIscendTheme.Colors.textPrimary
        }
    }

    private var background: Color {
        switch value.tone {
        case .muted:
            AIscendTheme.Colors.surfaceHighlight.opacity(0.46)
        case .neutral:
            AIscendTheme.Colors.surfaceHighlight.opacity(0.74)
        case .positive:
            AIscendTheme.Colors.accentPrimary.opacity(0.24)
        }
    }

    private var border: Color {
        switch value.tone {
        case .muted:
            AIscendTheme.Colors.borderSubtle
        case .neutral:
            AIscendTheme.Colors.borderStrong
        case .positive:
            AIscendTheme.Colors.accentGlow.opacity(0.36)
        }
    }
}

private struct UpgradeCredibilitySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendSectionHeader(
                eyebrow: "Trust",
                title: "Designed for better signal, less noise",
                subtitle: "AIScend Pro should read like a more capable system, not a louder one."
            )

            UpgradeSurfaceCard(style: .subtle) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                    credibilityRow(
                        symbol: "shield.lefthalf.filled",
                        title: "Private by design",
                        detail: "The screen presents access calmly, with no countdowns, gimmicks, or fake urgency."
                    )
                    credibilityRow(
                        symbol: "scope",
                        title: "Built for focused self-improvement",
                        detail: "The value is in sharper analysis, cleaner feedback loops, and more useful visibility."
                    )
                    credibilityRow(
                        symbol: "slider.horizontal.3",
                        title: "Strategic, not noisy",
                        detail: "Pro unlocks deeper tools without changing AIScend into a cluttered, gamified experience."
                    )
                }
            }
        }
    }

    private func credibilityRow(symbol: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: symbol, accent: .sky, size: 42)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(title)
                    .aiscendTextStyle(.cardTitle)

                Text(detail)
                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
            }
        }
    }
}

private struct FAQSection: View {
    let items: [AIscendUpgradeFAQItem]
    let expandedID: AIscendUpgradeFAQItem.ID?
    let onToggle: (AIscendUpgradeFAQItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendSectionHeader(
                eyebrow: "FAQ",
                title: "Questions, answered cleanly",
                subtitle: "Billing, trials, and cancellation should feel simple and transparent."
            )

            UpgradeSurfaceCard(style: .standard) {
                VStack(spacing: AIscendTheme.Spacing.small) {
                    ForEach(items) { item in
                        UpgradeFAQRow(
                            item: item,
                            isExpanded: expandedID == item.id,
                            onTap: { onToggle(item) }
                        )
                    }
                }
            }
        }
    }
}

private struct UpgradeFAQRow: View {
    let item: AIscendUpgradeFAQItem
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            Button(action: onTap) {
                HStack(alignment: .center, spacing: AIscendTheme.Spacing.small) {
                    Text(item.question)
                        .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: AIscendTheme.Spacing.small)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AIscendTheme.Colors.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(item.answer)
                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.62))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct TrustFooter: View {
    let plan: AIscendUpgradePlan

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack(spacing: AIscendTheme.Spacing.small) {
                footerBadge(symbol: "lock.fill", title: "Secure payments")
                footerBadge(symbol: "xmark.circle.fill", title: "Cancel anytime")
            }

            Text("Selected: \(plan.title). Billing stays transparent, access stays controlled, and the app remains usable even if you return to the free layer later.")
                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)

            Text("Subscriptions renew automatically unless canceled at least 24 hours before the current period ends.")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func footerBadge(symbol: String, title: String) -> some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)

            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
        }
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, AIscendTheme.Spacing.xSmall)
        .background(
            Capsule(style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.82))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct UpgradeRevealModifier: ViewModifier {
    let isVisible: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 16)
            .animation(.easeOut(duration: 0.45).delay(delay), value: isVisible)
    }
}

private extension View {
    func upgradeReveal(isVisible: Bool, delay: Double) -> some View {
        modifier(UpgradeRevealModifier(isVisible: isVisible, delay: delay))
    }
}

#Preview {
    AIscendUpgradeView(
        premiumURL: URL(string: "https://aiscend.app/upgrade"),
        onDismiss: {}
    )
}
