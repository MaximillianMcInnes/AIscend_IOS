//
//  HydrationTrackingPageSections.swift
//  AIscend
//
//  Created by Codex on 5/10/26.
//

import SwiftUI
import UIKit

struct HydrationPageHeader: View {
    let summary: HydrationDaySummary
    let hydrationState: HydrationState

    var body: some View {
        DashboardGlassCard(tone: .hero) {
            ViewThatFits(in: .horizontal) {
                horizontalLayout
                verticalLayout
            }
        }
    }

    private var horizontalLayout: some View {
        HStack(alignment: .center, spacing: AIscendTheme.Spacing.xLarge) {
            copy
            Spacer(minLength: AIscendTheme.Spacing.medium)
            HydrationCreditProgressRing(
                progress: summary.dailyGoalProgress,
                hydrationCreditMl: summary.hydrationCreditMl,
                targetHydrationMl: summary.targetHydrationMl,
                state: hydrationState
            )
        }
    }

    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            copy
            HydrationCreditProgressRing(
                progress: summary.dailyGoalProgress,
                hydrationCreditMl: summary.hydrationCreditMl,
                targetHydrationMl: summary.targetHydrationMl,
                state: hydrationState
            )
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendBadge(title: "Today", symbol: "drop.degreesign.fill", style: .accent)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                Text("Hydration")
                    .aiscendTextStyle(.screenTitle, color: AIscendTheme.Colors.textPrimary)

                Text("Water, drinks and electrolyte balance")
                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: AIscendTheme.Spacing.small) {
                HydrationStatePill(state: hydrationState)
                ElectrolyteBalancePill(state: summary.electrolyteBalanceStatus)
            }

            Text("\(summary.progressPercentage)% of today’s hydration credit target")
                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textMuted)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HydrationQuickWaterLogSection: View {
    @ObservedObject var store: HydrationTrackingStore

    @State private var highlightedAmount: Int?

    var body: some View {
        DashboardGlassCard(tone: .standard) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                sectionHeader

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: AIscendTheme.Spacing.small), GridItem(.flexible())],
                    spacing: AIscendTheme.Spacing.small
                ) {
                    ForEach(store.quickAddAmountsMl, id: \.self) { amount in
                        Button {
                            log(amount)
                        } label: {
                            HydrationQuickAddButton(amountMl: amount, highlighted: highlightedAmount == amount)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Log \(amount) millilitres of water")
                    }
                }
            }
        }
    }

    private var sectionHeader: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                Text("Quick Water Log")
                    .aiscendTextStyle(.sectionTitle, color: AIscendTheme.Colors.textPrimary)

                Text("One tap for common water amounts.")
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "bolt.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.accentCyan)
                .frame(width: 36, height: 36)
                .background(Circle().fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.78)))
        }
    }

    private func log(_ amount: Int) {
        withAnimation(AIscendTheme.Motion.reveal) {
            store.addWater(amountMl: amount, sourceName: "Water")
            highlightedAmount = amount
        }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation(AIscendTheme.Motion.soft) {
                highlightedAmount = nil
            }
        }
    }
}

struct HydrationTodayTotalsSection: View {
    let summary: HydrationDaySummary

    private let columns = [
        GridItem(.flexible(), spacing: AIscendTheme.Spacing.small),
        GridItem(.flexible(), spacing: AIscendTheme.Spacing.small)
    ]

    var body: some View {
        DashboardGlassCard(tone: .standard) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                Text("Today’s Totals")
                    .aiscendTextStyle(.sectionTitle, color: AIscendTheme.Colors.textPrimary)

                LazyVGrid(columns: columns, spacing: AIscendTheme.Spacing.small) {
                    HydrationTotalTile(title: "Total fluid", value: HydrationTrackingEngine.formatWater(summary.totalFluidMl, prefersCompact: true), symbol: "drop.fill", tint: AIscendTheme.Colors.accentCyan)
                    HydrationTotalTile(title: "Hydration credit", value: HydrationTrackingEngine.formatWater(summary.hydrationCreditMl, prefersCompact: true), symbol: "gauge.with.dots.needle.50percent", tint: AIscendTheme.Colors.accentMint)
                    HydrationTotalTile(title: "Water-only", value: HydrationTrackingEngine.formatWater(summary.waterOnlyMl, prefersCompact: true), symbol: "waterbottle.fill", tint: AIscendTheme.Colors.success)
                    HydrationTotalTile(title: "Sodium", value: "\(summary.sodiumMg)mg", symbol: "waveform.path.ecg", tint: AIscendTheme.Colors.accentAmber)
                    HydrationTotalTile(title: "Potassium", value: "\(summary.potassiumMg)mg", symbol: "leaf.fill", tint: AIscendTheme.Colors.accentMint)
                    HydrationTotalTile(title: "Magnesium", value: "\(summary.magnesiumMg)mg", symbol: "capsule.fill", tint: AIscendTheme.Colors.accentCyan)
                    HydrationTotalTile(title: "Caffeine", value: "\(summary.caffeineMg)mg", symbol: "cup.and.saucer.fill", tint: AIscendTheme.Colors.textSecondary)
                    HydrationTotalTile(title: "Calories", value: "\(summary.calories)", symbol: "flame.fill", tint: AIscendTheme.Colors.accentAmber)
                    HydrationTotalTile(title: "Sugar", value: "\(formatSugar(summary.sugarG))g", symbol: "cube.fill", tint: AIscendTheme.Colors.textMuted)
                }
            }
        }
    }

    private func formatSugar(_ sugar: Double) -> String {
        sugar.rounded() == sugar ? "\(Int(sugar))" : String(format: "%.1f", sugar)
    }
}

struct HydrationTimelineSection: View {
    @ObservedObject var store: HydrationTrackingStore
    let summary: HydrationDaySummary

    var body: some View {
        DashboardGlassCard(tone: .standard) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Timeline")
                        .aiscendTextStyle(.sectionTitle, color: AIscendTheme.Colors.textPrimary)

                    Spacer(minLength: 0)

                    Text("\(summary.logs.count) logged")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                        .monospacedDigit()
                }

                if summary.logs.isEmpty {
                    HydrationEmptyTimeline()
                } else {
                    VStack(spacing: AIscendTheme.Spacing.small) {
                        ForEach(summary.logs) { entry in
                            HydrationDrinkTimelineRow(entry: entry, store: store)
                        }
                    }
                }
            }
        }
    }
}

struct HydrationSmartSuggestionCard: View {
    let summary: HydrationDaySummary

    var body: some View {
        DashboardGlassCard(tone: .subtle) {
            HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AIscendTheme.Colors.accentGlow)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(AIscendTheme.Colors.accentGlow.opacity(0.12)))

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                    Text("Smart Suggestion")
                        .aiscendTextStyle(.sectionTitle, color: AIscendTheme.Colors.textPrimary)

                    Text(summary.smartSuggestionText)
                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Calculated from today’s approximate drink log totals.")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                }
            }
        }
    }
}

private struct HydrationCreditProgressRing: View {
    let progress: Double
    let hydrationCreditMl: Int
    let targetHydrationMl: Int
    let state: HydrationState

    @State private var displayedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [tint.opacity(0.22), .clear],
                        center: .center,
                        startRadius: 14,
                        endRadius: 92
                    )
                )

            Circle()
                .stroke(AIscendTheme.Colors.surfaceHighlight.opacity(0.62), lineWidth: 14)

            Circle()
                .trim(from: 0, to: min(max(displayedProgress, 0.035), 1))
                .stroke(
                    AngularGradient(
                        colors: [tint.opacity(0.55), tint, AIscendTheme.Colors.accentGlow.opacity(0.82)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: tint.opacity(0.24), radius: 14, x: 0, y: 8)

            VStack(spacing: 5) {
                Text(HydrationTrackingEngine.formatWater(hydrationCreditMl, prefersCompact: true))
                    .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
                    .monospacedDigit()

                Text("credit")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }
        }
        .frame(width: 142, height: 142)
        .onAppear {
            withAnimation(.spring(response: 0.62, dampingFraction: 0.88)) {
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

private struct HydrationTotalTile: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(Circle().fill(tint.opacity(0.12)))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(value)
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.56))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct HydrationDrinkTimelineRow: View {
    let entry: DrinkLogEntry
    @ObservedObject var store: HydrationTrackingStore

    @State private var isEditing = false
    @State private var draftAmountMl: Int

    init(entry: DrinkLogEntry, store: HydrationTrackingStore) {
        self.entry = entry
        self.store = store
        _draftAmountMl = State(initialValue: entry.amountMl)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconTint)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(iconTint.opacity(0.13)))

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.drinkName)
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textPrimary)
                        .lineLimit(1)

                    Text(detailText)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: AIscendTheme.Spacing.xSmall)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(HydrationTrackingEngine.formatWater(entry.hydrationCreditMl, prefersCompact: true))
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentCyan)
                        .monospacedDigit()

                    Text(entry.loggedAt, style: .time)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                }
            }

            if isEditing {
                DrinkAmountPicker(amountMl: $draftAmountMl, presetAmounts: entry.drinkCategory == .water ? [250, 500, 750, 1_000] : [])
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            HStack(spacing: AIscendTheme.Spacing.small) {
                Button {
                    withAnimation(AIscendTheme.Motion.reveal) {
                        if isEditing {
                            store.updateLog(entry, amountMl: draftAmountMl)
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        } else {
                            draftAmountMl = entry.amountMl
                        }
                        isEditing.toggle()
                    }
                } label: {
                    Label(isEditing ? "Save" : "Edit", systemImage: isEditing ? "checkmark" : "slider.horizontal.3")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, AIscendTheme.Spacing.medium)
                .padding(.vertical, AIscendTheme.Spacing.xSmall)
                .background(Capsule(style: .continuous).fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.74)))

                Button {
                    withAnimation(AIscendTheme.Motion.soft) {
                        store.deleteLog(entry)
                    }
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                } label: {
                    Label("Delete", systemImage: "trash")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
        .onChange(of: entry.amountMl) { _, newValue in
            draftAmountMl = newValue
        }
    }

    private var detailText: String {
        let amount = "\(entry.amountMl)ml fluid"
        let category = entry.drinkCategory?.title ?? "Drink"
        let sugar = entry.sugarG > 0 ? " · sugar \(formatSugar(entry.sugarG))g" : ""
        let caffeine = entry.caffeineMg > 0 ? " · caffeine \(entry.caffeineMg)mg" : ""
        return "\(category) · \(amount)\(sugar)\(caffeine)"
    }

    private var iconName: String {
        switch entry.drinkCategory {
        case .water, .sparklingWater:
            return "drop.fill"
        case .electrolyteDrink, .sportsDrink:
            return "bolt.fill"
        case .coffee:
            return "cup.and.saucer.fill"
        case .tea:
            return "leaf.fill"
        case .energyDrink, .softDrink:
            return "bubbles.and.sparkles.fill"
        default:
            return "takeoutbag.and.cup.and.straw.fill"
        }
    }

    private var iconTint: Color {
        switch entry.drinkCategory {
        case .water, .sparklingWater:
            return AIscendTheme.Colors.accentCyan
        case .electrolyteDrink, .sportsDrink:
            return AIscendTheme.Colors.accentMint
        case .coffee, .tea:
            return AIscendTheme.Colors.accentAmber
        case .energyDrink, .softDrink:
            return AIscendTheme.Colors.accentGlow
        default:
            return AIscendTheme.Colors.textSecondary
        }
    }

    private func formatSugar(_ sugar: Double) -> String {
        sugar.rounded() == sugar ? "\(Int(sugar))" : String(format: "%.1f", sugar)
    }
}

private struct HydrationEmptyTimeline: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
            Text("No drinks logged yet")
                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textPrimary)

            Text("Use quick water log or search the drink database to start today’s timeline.")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.48))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}
