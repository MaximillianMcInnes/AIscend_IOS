//
//  AIScendPremiumPaywallView.swift
//  AIscend
//

import SwiftUI

enum AIScendPremiumPaywallVariant: String, CaseIterable, Identifiable, Sendable {
    case transformation
    case diagnostics
    case progress
    case chat

    var id: String { rawValue }

    var eyebrow: String {
        switch self {
        case .transformation:
            "Scan intelligence ready"
        case .diagnostics:
            "Premium diagnostics"
        case .progress:
            "Strategy layer"
        case .chat:
            "AI coaching"
        }
    }

    var headline: String {
        switch self {
        case .transformation:
            "Your scan detected untapped potential."
        case .diagnostics:
            "Unlock the full facial intelligence layer."
        case .progress:
            "Turn your face scan into a strategy."
        case .chat:
            "Unlock unlimited AI coaching"
        }
    }

    var subheadline: String {
        switch self {
        case .transformation:
            "The preview is only the first signal. Premium opens the deeper breakdown, the highest-leverage changes, and the routine built around your face."
        case .diagnostics:
            "Reveal the structural read behind each locked section: proportions, feature-specific coaching, hidden strengths, and premium-only blind spots."
        case .progress:
            "Move from a one-time scan to a guided improvement loop with routines, progress history, streaks, and sharper next actions."
        case .chat:
            "Free users get one chat. Upgrade to keep building your routine, scans, and progress history."
        }
    }

    var symbol: String {
        switch self {
        case .transformation:
            "sparkles.rectangle.stack.fill"
        case .diagnostics:
            "waveform.path.ecg.rectangle.fill"
        case .progress:
            "chart.line.uptrend.xyaxis"
        case .chat:
            "message.badge.waveform.fill"
        }
    }

    var proofPoints: [String] {
        switch self {
        case .transformation:
            [
                "Full scan breakdown and premium scoring layers",
                "Personal blind spots translated into clear next actions",
                "Routine recommendations matched to your highest upside"
            ]
        case .diagnostics:
            [
                "Jaw, harmony, side-profile, eyes, and feature-level detail",
                "Analytical explanations behind each locked result",
                "Premium interpretation without generic beauty advice"
            ]
        case .progress:
            [
                "Premium routines generated from your scan profile",
                "Progress history, streaks, and consistency feedback",
                "Strategy updates as your daily actions compound"
            ]
        case .chat:
            [
                "Unlimited AI chats",
                "Full scan breakdowns",
                "Premium facial analysis pages",
                "Previous scan insights"
            ]
        }
    }
}

enum AIScendPremiumPaywallOffer: String, CaseIterable, Identifiable, Sendable {
    case threeDayTrial
    case startNow
    case closeDiscount

    var id: String { rawValue }

    var badge: String {
        switch self {
        case .threeDayTrial:
            "Premium access"
        case .startNow:
            "Premium access"
        case .closeDiscount:
            "Launch offer"
        }
    }

    var primaryCTA: String {
        switch self {
        case .threeDayTrial:
            "Unlock Premium"
        case .startNow:
            "Unlock Premium"
        case .closeDiscount:
            "Claim Discount"
        }
    }

    var billingLine: String {
        switch self {
        case .threeDayTrial:
            "Billed through Apple. Cancel anytime in Settings."
        case .startNow:
            "Premium unlocks immediately with your selected plan."
        case .closeDiscount:
            "Limited early-user discount applied at checkout when available."
        }
    }
}

struct AIScendPremiumPaywallPresentation: Identifiable, Hashable, Sendable {
    let id = UUID()
    let variant: AIScendPremiumPaywallVariant
    let offer: AIScendPremiumPaywallOffer

    init(
        variant: AIScendPremiumPaywallVariant,
        offer: AIScendPremiumPaywallOffer = .startNow
    ) {
        self.variant = variant
        self.offer = offer
    }
}

struct AIScendPremiumPaywallView: View {
    let variant: AIScendPremiumPaywallVariant
    let offer: AIScendPremiumPaywallOffer
    let onDismiss: () -> Void
    let onPurchase: (String) -> Void
    let onRestore: () -> Void

    @State private var selectedPlan: AIScendPremiumPlan = .monthly
    @State private var closeInterceptUsed = false
    @State private var closeSheet: AIScendCloseSheet?
    @State private var hasTrackedShown = false
    @State private var hasTrackedDismissed = false
    @State private var hasStartedPurchase = false

    var body: some View {
        ZStack {
            AIScendPremiumAmbientBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    topBar
                    heroSection
                    intelligenceStrip
                    planSelector
                    benefitsSection
                    restoreButton
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, 18)
                .padding(.bottom, 172)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomCTA
        }
        .sheet(item: $closeSheet) { sheet in
            closeSheetView(sheet)
                .presentationDetents([.height(sheet.height)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        .interactiveDismissDisabled(true)
        .preferredColorScheme(.dark)
        .onAppear {
            guard !hasTrackedShown else { return }
            hasTrackedShown = true
            track("paywall_shown", [
                "variant": variant.rawValue,
                "offer": offer.rawValue,
                "default_plan": selectedPlan.rawValue
            ])
        }
    }

    private var topBar: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            AIscendBadge(
                title: offer.badge,
                symbol: "crown.fill",
                style: .accent
            )

            Spacer()

            Button(action: handleCloseTap) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close paywall")
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AIscendTheme.Colors.accentPrimary.opacity(0.24))
                        .frame(width: 70, height: 70)
                        .blur(radius: 10)

                    Image(systemName: variant.symbol)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .frame(width: 62, height: 62)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(
                            Circle()
                                .stroke(AIscendTheme.Colors.accentGlow.opacity(0.38), lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(variant.eyebrow.uppercased())
                        .aiscendTextStyle(.eyebrow, color: AIscendTheme.Colors.accentGlow)

                    Text(variant.headline)
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .lineSpacing(-1)
                        .minimumScaleFactor(0.82)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(variant.subheadline)
                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            AIScendScanSignalCard()
        }
        .padding(22)
        .background(heroBackground)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(heroBorder, lineWidth: 1)
        )
        .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.22), radius: 34, x: 0, y: 22)
    }

    private var intelligenceStrip: some View {
        HStack(spacing: 10) {
            AIScendPaywallMetric(title: "Full", detail: "scan layer")
            AIScendPaywallMetric(title: "Unlimited", detail: "coaching")
            AIScendPaywallMetric(title: "Cancel", detail: "anytime")
        }
    }

    private var planSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Choose your access")
                    .aiscendTextStyle(.cardTitle)

                Spacer()

                Text("FROM £5.99")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(AIscendTheme.Colors.accentPrimary.opacity(0.34), in: Capsule(style: .continuous))
            }

            VStack(spacing: 10) {
                ForEach(AIScendPremiumPlan.allCases) { plan in
                    AIScendPlanRow(
                        plan: plan,
                        isSelected: selectedPlan == plan,
                        onSelect: {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                selectedPlan = plan
                            }
                            track("paywall_plan_selected", [
                                "variant": variant.rawValue,
                                "offer": offer.rawValue,
                                "plan": plan.rawValue,
                                "product_id": plan.productID
                            ])
                        }
                    )
                }
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Premium opens")
                .aiscendTextStyle(.cardTitle)

            ForEach(variant.proofPoints, id: \.self) { point in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AIscendTheme.Colors.accentGlow)
                        .padding(.top, 2)

                    Text(point)
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private var restoreButton: some View {
        Button {
            track("paywall_restore_tapped", [
                "variant": variant.rawValue,
                "offer": offer.rawValue
            ])
            onRestore()
        } label: {
            Text("Restore Purchases")
                .aiscendTextStyle(.buttonLabel, color: AIscendTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private var bottomCTA: some View {
        VStack(spacing: 10) {
            Button(action: handlePrimaryCTA) {
                HStack(spacing: 8) {
                    Image(systemName: hasStartedPurchase ? "lock.rotation" : "crown.fill")
                    Text(hasStartedPurchase ? "Opening Apple checkout…" : offer.primaryCTA)
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.accentGlow,
                            AIscendTheme.Colors.accentSoft,
                            AIscendTheme.Colors.accentPrimary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Capsule(style: .continuous)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
                .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.34), radius: 22, x: 0, y: 10)
            }
            .buttonStyle(.plain)
            .disabled(hasStartedPurchase)
            .opacity(hasStartedPurchase ? 0.72 : 1)

            Text("\(selectedPlan.price)/\(selectedPlan.period). \(offer.billingLine)")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AIscendTheme.Spacing.screenInset)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.appBackground.opacity(0),
                    AIscendTheme.Colors.appBackground.opacity(0.86),
                    AIscendTheme.Colors.appBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private var heroBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                Color.white.opacity(0.13),
                AIscendTheme.Colors.accentDeep.opacity(0.32),
                Color.black.opacity(0.42)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var heroBorder: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.22),
                AIscendTheme.Colors.accentGlow.opacity(0.35),
                Color.white.opacity(0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    private func closeSheetView(_ sheet: AIScendCloseSheet) -> some View {
        AIScendCloseInterceptSheet(
            sheet: sheet,
            isProcessing: hasStartedPurchase,
            onPrimary: {
                guard !hasStartedPurchase else { return }
                hasStartedPurchase = true
                track("paywall_cta_tapped", [
                    "variant": variant.rawValue,
                    "offer": sheet == .discount ? AIScendPremiumPaywallOffer.closeDiscount.rawValue : offer.rawValue,
                    "plan": selectedPlan.rawValue,
                    "product_id": selectedPlan.productID,
                    "source": sheet.analyticsSource
                ])
                Task { @MainActor in
                    await SubscriptionManager.shared.purchase(productID: selectedPlan.productID)
                    hasStartedPurchase = false
                }
            },
            onSecondary: {
                switch sheet {
                case .beforeYouGo:
                    track("paywall_discount_shown", [
                        "variant": variant.rawValue,
                        "plan": selectedPlan.rawValue
                    ])
                    closeSheet = .discount
                case .discount:
                    dismissPaywall()
                }
            }
        )
    }

    private func handlePrimaryCTA() {
        guard !hasStartedPurchase else { return }
        hasStartedPurchase = true

        track("paywall_cta_tapped", [
            "variant": variant.rawValue,
            "offer": offer.rawValue,
            "plan": selectedPlan.rawValue,
            "product_id": selectedPlan.productID,
            "source": "main"
        ])
        Task { @MainActor in
            await SubscriptionManager.shared.purchase(productID: selectedPlan.productID)
            hasStartedPurchase = false
        }
    }

    private func handleCloseTap() {
        track("paywall_close_tapped", [
            "variant": variant.rawValue,
            "offer": offer.rawValue,
            "intercept_used": closeInterceptUsed
        ])

        guard !closeInterceptUsed else {
            dismissPaywall()
            return
        }

        closeInterceptUsed = true
        closeSheet = .beforeYouGo
        track("paywall_close_intercept_shown", [
            "variant": variant.rawValue,
            "offer": offer.rawValue
        ])
    }

    private func dismissPaywall() {
        closeSheet = nil

        if !hasTrackedDismissed {
            hasTrackedDismissed = true
            track("paywall_dismissed", [
                "variant": variant.rawValue,
                "offer": offer.rawValue
            ])
        }

        onDismiss()
    }
}

private enum AIScendPremiumPlan: String, CaseIterable, Identifiable {
    case monthly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .monthly:
            "Monthly"
        case .yearly:
            "Yearly"
        }
    }

    var price: String {
        switch self {
        case .monthly:
            "£5.99"
        case .yearly:
            "£49.99"
        }
    }

    var period: String {
        switch self {
        case .monthly:
            "month"
        case .yearly:
            "year"
        }
    }

    var productID: String {
        switch self {
        case .monthly:
            "AIscend_Monthly"
        case .yearly:
            "AIscend_Pro_Yearly"
        }
    }

    var detail: String {
        switch self {
        case .monthly:
            "Flexible premium access"
        case .yearly:
            "Best value for long-term progress"
        }
    }

    var badge: String? {
        switch self {
        case .monthly:
            nil
        case .yearly:
            "Selected"
        }
    }
}

private enum AIScendCloseSheet: String, Identifiable {
    case beforeYouGo
    case discount

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beforeYouGo:
            "Before you go…"
        case .discount:
            "Launch offer unlocked"
        }
    }

    var message: String {
        switch self {
        case .beforeYouGo:
            "Your full scan breakdown is already prepared. Premium unlocks the complete analysis, coaching, and locked result pages."
        case .discount:
            "Get full premium access today with a limited early-user discount."
        }
    }

    var primaryTitle: String {
        switch self {
        case .beforeYouGo:
            "Unlock Premium"
        case .discount:
            "Claim Discount"
        }
    }

    var secondaryTitle: String {
        switch self {
        case .beforeYouGo:
            "Not now"
        case .discount:
            "Maybe later"
        }
    }

    var height: CGFloat {
        switch self {
        case .beforeYouGo:
            344
        case .discount:
            388
        }
    }

    var analyticsSource: String {
        switch self {
        case .beforeYouGo:
            "close_intercept"
        case .discount:
            "discount_intercept"
        }
    }
}

private struct AIScendPlanRow: View {
    let plan: AIScendPremiumPlan
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(isSelected ? AIscendTheme.Colors.accentGlow : AIscendTheme.Colors.textMuted)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .aiscendTextStyle(.cardTitle)

                        if let badge = plan.badge {
                            Text(badge.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AIscendTheme.Colors.accentPrimary.opacity(0.38), in: Capsule())
                        }
                    }

                    Text(plan.detail)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                }

                Spacer(minLength: 10)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(plan.price)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)

                    Text("/\(plan.period)")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? AIscendTheme.Colors.accentPrimary.opacity(0.22) : Color.white.opacity(0.055))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? AIscendTheme.Colors.accentGlow.opacity(0.52) : Color.white.opacity(0.10), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AIScendPaywallMetric: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(detail)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}

private struct AIScendScanSignalCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI confidence map")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)

                Spacer()

                Text("Prepared")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
            }

            HStack(alignment: .bottom, spacing: 5) {
                ForEach(0..<24, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(signalGradient(index: index))
                        .frame(height: CGFloat([18, 28, 22, 36, 48, 40, 58, 46][index % 8]))
                }
            }
            .frame(height: 64, alignment: .bottom)
        }
        .padding(16)
        .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func signalGradient(index: Int) -> LinearGradient {
        LinearGradient(
            colors: [
                AIscendTheme.Colors.accentGlow.opacity(index.isMultiple(of: 3) ? 0.94 : 0.54),
                AIscendTheme.Colors.accentPrimary.opacity(0.28)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private struct AIScendCloseInterceptSheet: View {
    let sheet: AIScendCloseSheet
    let isProcessing: Bool
    let onPrimary: () -> Void
    let onSecondary: () -> Void

    var body: some View {
        ZStack {
            AIscendTheme.Colors.appBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                if sheet == .discount {
                    Text("LAUNCH ACCESS")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.accentAmber,
                                    AIscendTheme.Colors.accentSoft
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Capsule(style: .continuous)
                        )
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(sheet.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)

                    Text(sheet.message)
                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                VStack(spacing: 10) {
                    Button(action: onPrimary) {
                        Text(isProcessing ? "Opening Apple checkout…" : sheet.primaryTitle)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AIscendTheme.Colors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: [
                                        AIscendTheme.Colors.accentGlow,
                                        AIscendTheme.Colors.accentPrimary
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: Capsule(style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)
                    .opacity(isProcessing ? 0.72 : 1)

                    Button(action: onSecondary) {
                        Text(sheet.secondaryTitle)
                            .aiscendTextStyle(.buttonLabel, color: AIscendTheme.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AIscendTheme.Spacing.screenInset)
            .padding(.top, 26)
            .padding(.bottom, 14)
        }
    }
}

private struct AIScendPremiumAmbientBackground: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                LinearGradient(
                    colors: [
                        Color.black,
                        AIscendTheme.Colors.appBackground,
                        Color(hex: "160A2F"),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                GeometryReader { geometry in
                    ZStack {
                        ambientRibbon(
                            size: geometry.size,
                            time: time,
                            color: AIscendTheme.Colors.accentPrimary,
                            phase: 0.0
                        )

                        ambientRibbon(
                            size: geometry.size,
                            time: time,
                            color: Color(hex: "E858FF"),
                            phase: 1.7
                        )

                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.12),
                                Color.clear,
                                Color.black.opacity(0.54)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .ignoresSafeArea()
                }
            }
        }
    }

    private func ambientRibbon(size: CGSize, time: TimeInterval, color: Color, phase: Double) -> some View {
        let x = size.width * (0.5 + 0.28 * sin(time * 0.18 + phase))
        let y = size.height * (0.26 + 0.18 * cos(time * 0.15 + phase))
        let rotation = Angle.degrees(18 + sin(time * 0.12 + phase) * 16)

        return Capsule(style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        color.opacity(0.0),
                        color.opacity(0.28),
                        AIscendTheme.Colors.accentGlow.opacity(0.18),
                        color.opacity(0.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: size.width * 1.45, height: 230)
            .rotationEffect(rotation)
            .position(x: x, y: y)
            .blur(radius: 48)
            .blendMode(.plusLighter)
    }
}

private func track(_ name: String, _ params: [String: Any] = [:]) {
    print("AIScend paywall event:", name, params)
    // Firebase Analytics.logEvent(name, parameters: params)
    // Superwall removed. StoreKit purchase is handled by SubscriptionManager.
}

#Preview("Transformation Premium") {
    AIScendPremiumPaywallView(
        variant: .transformation,
        offer: .startNow,
        onDismiss: {},
        onPurchase: { productId in
            print("Start purchase:", productId)
        },
        onRestore: {
            print("Restore purchases")
        }
    )
}

#Preview("Diagnostics") {
    AIScendPremiumPaywallView(
        variant: .diagnostics,
        offer: .startNow,
        onDismiss: {},
        onPurchase: { _ in },
        onRestore: {}
    )
}

private struct AIScendPremiumPaywallExampleUsage: View {
    @State private var showPaywall = false

    var body: some View {
        Button("Show AIScend Paywall") {
            showPaywall = true
        }
        .fullScreenCover(isPresented: $showPaywall) {
            AIScendPremiumPaywallView(
                variant: .transformation,
                offer: .startNow,
                onDismiss: {
                    showPaywall = false
                },
                onPurchase: { productId in
                    Task {
                        await SubscriptionManager.shared.purchase(productID: productId)
                    }
                },
                onRestore: {
                    Task {
                        await SubscriptionManager.shared.restorePurchases()
                    }
                }
            )
        }
    }
}
