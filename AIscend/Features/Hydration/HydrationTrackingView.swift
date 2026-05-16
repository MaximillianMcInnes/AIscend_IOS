//
//  HydrationTrackingView.swift
//  AIscend
//
//  Created by Codex on 4/19/26.
//

import SwiftUI
import UIKit

struct HydrationTrackingScreen: View {
    @ObservedObject var store: HydrationTrackingStore
    @ObservedObject var electrolyteStore: ElectrolyteTrackingStore
    var onOpenChat: (String) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AIscendBackdrop()
                DashboardAmbientLayer()

                ScrollView(showsIndicators: false) {
                    HydrationTrackingView(
                        store: store,
                        electrolyteStore: electrolyteStore,
                        onOpenChat: onOpenChat
                    )
                    .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                    .padding(.top, AIscendTheme.Spacing.large)
                    .padding(.bottom, AIscendTheme.Spacing.xxLarge)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.fraction(0.94)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(34)
        .presentationBackground(.ultraThinMaterial)
    }
}

struct HydrationTrackingView: View {
    @ObservedObject var store: HydrationTrackingStore
    @ObservedObject var electrolyteStore: ElectrolyteTrackingStore
    var onOpenChat: (String) -> Void

    private var drinkDaySummary: HydrationDaySummary {
        store.todayHydrationSummary
    }

    private var hydrationState: HydrationState {
        store.engine.evaluateState(
            totalWaterMl: drinkDaySummary.hydrationCreditMl,
            targetWaterMl: drinkDaySummary.targetHydrationMl
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            HydrationPageHeader(
                summary: drinkDaySummary,
                hydrationState: hydrationState
            )

            HydrationQuickWaterLogSection(store: store)

            DrinkSearchView(
                store: store,
                electrolyteStore: electrolyteStore
            )

            HydrationTodayTotalsSection(summary: drinkDaySummary)

            HydrationTimelineSection(
                store: store,
                summary: drinkDaySummary
            )

            HydrationSmartSuggestionCard(summary: drinkDaySummary)
        }
    }
}

struct HydrationDashboardCard: View {
    @ObservedObject var store: HydrationTrackingStore
    @ObservedObject var electrolyteStore: ElectrolyteTrackingStore
    let onOpenHydration: () -> Void
    let onOpenChat: (String) -> Void

    private var summary: HydrationDaySummary {
        store.todayHydrationSummary
    }

    private var hydrationState: HydrationState {
        store.engine.evaluateState(
            totalWaterMl: summary.hydrationCreditMl,
            targetWaterMl: summary.targetHydrationMl
        )
    }

    private var lastDrinkText: String {
        guard let lastLog = summary.logs.first else {
            return "No drinks logged yet"
        }

        return "\(lastLog.drinkName) · \(HydrationTrackingEngine.formatWater(lastLog.amountMl, prefersCompact: true))"
    }

    var body: some View {
        Button(action: onOpenHydration) {
            DashboardGlassCard(tone: .standard) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                    HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                            Text("Hydration")
                                .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)

                            Text("All drink logs today")
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                        }

                        Spacer(minLength: 0)

                        HStack(spacing: AIscendTheme.Spacing.xSmall) {
                            Text("Track")
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        }
                        .padding(.horizontal, AIscendTheme.Spacing.medium)
                        .padding(.vertical, AIscendTheme.Spacing.xSmall)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.86))
                        )
                    }

                    HStack(spacing: AIscendTheme.Spacing.small) {
                        HydrationStatePill(state: hydrationState)
                        ElectrolyteBalancePill(state: summary.electrolyteBalanceStatus)
                    }

                    HydrationDashboardProgressBar(progress: summary.dailyGoalProgress)

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: AIscendTheme.Spacing.small) {
                            HydrationCompactMetric(
                                title: "Credit",
                                value: "\(HydrationTrackingEngine.formatWater(summary.hydrationCreditMl, prefersCompact: true)) / \(HydrationTrackingEngine.formatWater(summary.targetHydrationMl, prefersCompact: true))"
                            )

                            HydrationCompactMetric(
                                title: "Water-only",
                                value: HydrationTrackingEngine.formatWater(summary.waterOnlyMl, prefersCompact: true)
                            )

                            HydrationCompactMetric(
                                title: "Fluid",
                                value: HydrationTrackingEngine.formatWater(summary.totalFluidMl, prefersCompact: true)
                            )
                        }

                        VStack(spacing: AIscendTheme.Spacing.small) {
                            HydrationCompactMetric(
                                title: "Credit",
                                value: "\(HydrationTrackingEngine.formatWater(summary.hydrationCreditMl, prefersCompact: true)) / \(HydrationTrackingEngine.formatWater(summary.targetHydrationMl, prefersCompact: true))"
                            )

                            HydrationCompactMetric(
                                title: "Water-only",
                                value: HydrationTrackingEngine.formatWater(summary.waterOnlyMl, prefersCompact: true)
                            )

                            HydrationCompactMetric(
                                title: "Fluid",
                                value: HydrationTrackingEngine.formatWater(summary.totalFluidMl, prefersCompact: true)
                            )
                        }
                    }

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        Text(lastDrinkText)
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                            .lineLimit(1)

                        HStack(spacing: AIscendTheme.Spacing.xSmall) {
                            HydrationDashboardElectrolyteChip(title: "Na", value: summary.sodiumMg, tint: AIscendTheme.Colors.accentAmber)
                            HydrationDashboardElectrolyteChip(title: "K", value: summary.potassiumMg, tint: AIscendTheme.Colors.accentMint)
                            HydrationDashboardElectrolyteChip(title: "Mg", value: summary.magnesiumMg, tint: AIscendTheme.Colors.accentCyan)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct HydrationDashboardProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.68))

                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AIscendTheme.Colors.accentCyan, AIscendTheme.Colors.accentMint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: proxy.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 8)
    }
}

private struct HydrationDashboardElectrolyteChip: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        Text("\(title) \(value)mg")
            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, AIscendTheme.Spacing.small)
            .padding(.vertical, AIscendTheme.Spacing.xSmall)
            .background(Capsule(style: .continuous).fill(tint.opacity(0.12)))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(tint.opacity(0.2), lineWidth: 1)
            )
    }
}

struct HydrationStatePill: View {
    let state: HydrationState

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            Circle()
                .fill(tint)
                .frame(width: 7, height: 7)

            Text(state.title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
        }
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, AIscendTheme.Spacing.xSmall)
        .background(
            Capsule(style: .continuous)
                .fill(tint.opacity(0.14))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(tint.opacity(0.22), lineWidth: 1)
        )
    }

    private var tint: Color {
        switch state {
        case .optimal:
            AIscendTheme.Colors.success
        case .onTrack:
            AIscendTheme.Colors.accentCyan
        case .high:
            AIscendTheme.Colors.accentAmber
        case .low, .behind:
            AIscendTheme.Colors.accentGlow
        }
    }
}

private struct HydrationProgressOrb: View {
    let progress: Double
    let totalWaterMl: Int
    let targetWaterMl: Int
    let state: HydrationState

    @State private var displayedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            tint.opacity(0.22),
                            .clear
                        ],
                        center: .center,
                        startRadius: 12,
                        endRadius: 90
                    )
                )

            Circle()
                .stroke(AIscendTheme.Colors.surfaceHighlight.opacity(0.62), lineWidth: 15)

            Circle()
                .trim(from: 0, to: min(max(displayedProgress, 0.04), 1))
                .stroke(
                    AngularGradient(
                        colors: [tint.opacity(0.5), tint, AIscendTheme.Colors.accentGlow],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 15, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: tint.opacity(0.28), radius: 14, x: 0, y: 8)

            VStack(spacing: 6) {
                Text(HydrationTrackingEngine.formatWater(totalWaterMl, prefersCompact: true))
                    .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
                    .monospacedDigit()

                Text("of \(HydrationTrackingEngine.formatWater(targetWaterMl, prefersCompact: true))")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }
        }
        .frame(width: 160, height: 160)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.88)) {
                displayedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.58, dampingFraction: 0.88)) {
                displayedProgress = newValue
            }
        }
    }

    private var tint: Color {
        switch state {
        case .optimal:
            AIscendTheme.Colors.success
        case .onTrack:
            AIscendTheme.Colors.accentCyan
        case .high:
            AIscendTheme.Colors.accentAmber
        case .low, .behind:
            AIscendTheme.Colors.accentGlow
        }
    }
}

struct HydrationQuickAddButton: View {
    let amountMl: Int
    let highlighted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            Text("+\(amountMl)ml")
                .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
                .monospacedDigit()

            Text("Quick water log")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.mediumLarge)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.surfaceHighlight.opacity(highlighted ? 0.94 : 0.78),
                            AIscendTheme.Colors.surfaceInteractive.opacity(highlighted ? 0.92 : 0.74)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(
                    highlighted ? AIscendTheme.Colors.accentGlow.opacity(0.42) : AIscendTheme.Colors.borderSubtle,
                    lineWidth: 1
                )
        )
        .scaleEffect(highlighted ? 1.02 : 1)
        .shadow(color: highlighted ? AIscendTheme.Colors.accentPrimary.opacity(0.18) : .clear, radius: 16, x: 0, y: 10)
    }
}

private struct HydrationRecentWaterEntryRow: View {
    let entry: WaterEntry
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.sourceName ?? "Water")
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textPrimary)

                Text(entry.date, style: .time)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }

            Spacer(minLength: AIscendTheme.Spacing.small)

            Text("\(entry.amountMl)ml")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                .monospacedDigit()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AIscendTheme.Colors.textMuted)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.7))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.52))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct HydrationCompactMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            Text(value)
                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct HydrationCustomAmountSheet: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var store: HydrationTrackingStore

    @State private var amountText = ""

    private var parsedAmount: Int? {
        Int(amountText.filter(\.isNumber))
    }

    var body: some View {
        HydrationNumericEntrySheet(
            badgeTitle: "Custom amount",
            title: "Add a custom water entry",
            subtitle: "Use this when the quick add amounts are close but not quite right.",
            valueText: $amountText,
            buttonTitle: "Save amount",
            onSave: {
                guard let parsedAmount, parsedAmount > 0 else {
                    return
                }

                store.addWater(amountMl: parsedAmount, sourceName: "Custom water")
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                dismiss()
            }
        )
    }
}

private struct HydrationTargetEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var store: HydrationTrackingStore
    let currentTargetMl: Int

    @State private var targetText: String

    init(store: HydrationTrackingStore, currentTargetMl: Int) {
        self.store = store
        self.currentTargetMl = currentTargetMl
        _targetText = State(initialValue: "\(currentTargetMl)")
    }

    private var parsedTarget: Int? {
        Int(targetText.filter(\.isNumber))
    }

    var body: some View {
        HydrationNumericEntrySheet(
            badgeTitle: "Daily target",
            title: "Edit your water target",
            subtitle: "Keep this practical and easy to hit on an ordinary day.",
            valueText: $targetText,
            buttonTitle: "Save target",
            onSave: {
                guard let parsedTarget, parsedTarget > 0 else {
                    return
                }

                store.setTarget(parsedTarget)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                dismiss()
            }
        )
    }
}

private struct HydrationNumericEntrySheet: View {
    let badgeTitle: String
    let title: String
    let subtitle: String
    @Binding var valueText: String
    let buttonTitle: String
    let onSave: () -> Void

    private var canSave: Bool {
        (Int(valueText.filter(\.isNumber)) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                AIscendBadge(title: badgeTitle, symbol: "drop.fill", style: .accent)

                Text(title)
                    .aiscendTextStyle(.sectionTitle, color: AIscendTheme.Colors.textPrimary)

                Text(subtitle)
                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    Text("Amount")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                    TextField("Enter ml", text: $valueText)
                        .keyboardType(.numberPad)
                        .font(AIscendTheme.Typography.input)
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .padding(.horizontal, AIscendTheme.Spacing.medium)
                        .padding(.vertical, AIscendTheme.Spacing.medium)
                        .background(
                            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                                .fill(AIscendTheme.Colors.fieldFill)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                        )
                }

                Button(action: onSave) {
                    AIscendButtonLabel(title: buttonTitle, leadingSymbol: "checkmark")
                }
                .buttonStyle(AIscendButtonStyle(variant: .primary))
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.5)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AIscendTheme.Spacing.screenInset)
            .padding(.top, AIscendTheme.Spacing.large)
            .padding(.bottom, AIscendTheme.Spacing.xxLarge)
            .background(AIscendTheme.Colors.appBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.fraction(0.52)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(30)
        .presentationBackground(.ultraThinMaterial)
    }
}

#Preview("Hydration Tracking") {
    HydrationTrackingPreviewContainer()
}

private struct HydrationTrackingPreviewContainer: View {
    @StateObject private var store: HydrationTrackingStore
    @StateObject private var electrolyteStore = ElectrolyteTrackingStore(
        defaults: UserDefaults(suiteName: "HydrationTrackingPreviewElectrolytes") ?? .standard
    )

    init() {
        let defaults = UserDefaults(suiteName: "HydrationTrackingPreview-\(UUID().uuidString)") ?? .standard
        _store = StateObject(wrappedValue: HydrationTrackingStore(defaults: defaults))
    }

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()

            ScrollView(showsIndicators: false) {
                HydrationTrackingView(
                    store: store,
                    electrolyteStore: electrolyteStore,
                    onOpenChat: { _ in }
                )
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, AIscendTheme.Spacing.xxLarge)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            seedPreviewLogsIfNeeded()
        }
    }

    private func seedPreviewLogsIfNeeded() {
        guard store.todayDrinkLogs().isEmpty else {
            return
        }

        _ = store.logDrink(DrinkLibrary.shared.drink(id: "water") ?? DrinkLibrary.shared.popularDrinks()[0], amountMl: 500)
        _ = store.logDrink(DrinkLibrary.shared.drink(id: "black-coffee") ?? DrinkLibrary.shared.popularDrinks()[7], amountMl: 240)
        _ = store.logDrink(DrinkLibrary.shared.drink(id: "electrolyte-tablet-drink") ?? DrinkLibrary.shared.popularDrinks()[3], amountMl: 500)
    }
}
