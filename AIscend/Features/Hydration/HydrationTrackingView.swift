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

    @State private var showingCustomEntrySheet = false
    @State private var showingTargetSheet = false
    @State private var highlightedQuickAdd: Int?

    private var baseWaterSummary: WaterDailySummary {
        store.todaySummary()
    }

    private var electrolyteSummary: ElectrolyteDailySummary {
        electrolyteStore.todaySummary(waterIntakeMl: baseWaterSummary.totalWaterMl)
    }

    private var waterSummary: WaterDailySummary {
        store.todaySummary(electrolyteSummary: electrolyteSummary)
    }

    private var combinedInsight: String {
        store.combinedInsight(electrolyteSummary: electrolyteSummary)
    }

    private var lastPreset: ElectrolytePreset? {
        electrolyteStore.lastSelectedPreset()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            header
            heroCard
            waterLoggingCard
            ElectrolyteTrackingView(
                store: electrolyteStore,
                waterIntakeMl: waterSummary.totalWaterMl,
                onOpenChat: onOpenChat
            )
            aiSupportCard
        }
        .sheet(isPresented: $showingCustomEntrySheet) {
            HydrationCustomAmountSheet(store: store)
        }
        .sheet(isPresented: $showingTargetSheet) {
            HydrationTargetEditorSheet(store: store, currentTargetMl: waterSummary.targetWaterMl)
        }
    }

    private var header: some View {
        AIscendSectionHeader(
            eyebrow: "Hydration",
            title: "Hydration",
            subtitle: "Water intake, electrolyte support, and simple AI guidance in one premium view."
        )
    }

    private var heroCard: some View {
        DashboardGlassCard(tone: .hero) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                AIscendBadge(
                    title: "Hero hydration summary",
                    symbol: "drop.fill",
                    style: .accent
                )

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: AIscendTheme.Spacing.xLarge) {
                        HydrationProgressOrb(
                            progress: waterSummary.progress,
                            totalWaterMl: waterSummary.totalWaterMl,
                            targetWaterMl: waterSummary.targetWaterMl,
                            state: waterSummary.hydrationState
                        )

                        heroCopy
                    }

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                        HydrationProgressOrb(
                            progress: waterSummary.progress,
                            totalWaterMl: waterSummary.totalWaterMl,
                            targetWaterMl: waterSummary.targetWaterMl,
                            state: waterSummary.hydrationState
                        )

                        heroCopy
                    }
                }
            }
        }
    }

    private var heroCopy: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack(spacing: AIscendTheme.Spacing.small) {
                HydrationStatePill(state: waterSummary.hydrationState)
                ElectrolyteBalancePill(state: electrolyteSummary.balanceState)
            }

            Text(HydrationTrackingEngine.formatWater(waterSummary.totalWaterMl, prefersCompact: true))
                .aiscendTextStyle(.screenTitle, color: AIscendTheme.Colors.textPrimary)

            Text("Target \(HydrationTrackingEngine.formatWater(waterSummary.targetWaterMl, prefersCompact: true))")
                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)

            Text(waterSummary.shortInsight)
                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)

            Text(combinedInsight)
                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var waterLoggingCard: some View {
        DashboardGlassCard(tone: .standard) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                        Text("Water")
                            .aiscendTextStyle(.sectionTitle, color: AIscendTheme.Colors.textPrimary)

                        Text("Fast logging, custom amounts, and a target you can tune without friction.")
                            .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                    }

                    Spacer(minLength: 0)

                    Button {
                        showingTargetSheet = true
                    } label: {
                        AIscendBadge(
                            title: "Edit target",
                            symbol: "slider.horizontal.3",
                            style: .neutral
                        )
                    }
                    .buttonStyle(.plain)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
                    ForEach(store.quickAddAmountsMl, id: \.self) { amount in
                        Button {
                            withAnimation(AIscendTheme.Motion.reveal) {
                                store.addWater(amountMl: amount, sourceName: "Quick add")
                            }
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            highlightedQuickAdd = amount
                            resetQuickAddHighlight()
                        } label: {
                            HydrationQuickAddButton(amountMl: amount, highlighted: highlightedQuickAdd == amount)
                        }
                        .buttonStyle(.plain)
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        waterSecondaryButton(
                            title: "Custom amount",
                            symbol: "plus.circle.fill",
                            action: { showingCustomEntrySheet = true }
                        )

                        waterSecondaryButton(
                            title: "Undo last",
                            symbol: "arrow.uturn.backward",
                            action: { store.removeLastEntry() }
                        )
                        .opacity(store.recentEntries(limit: 1).isEmpty ? 0.5 : 1)
                        .disabled(store.recentEntries(limit: 1).isEmpty)
                    }

                    VStack(spacing: AIscendTheme.Spacing.small) {
                        waterSecondaryButton(
                            title: "Custom amount",
                            symbol: "plus.circle.fill",
                            action: { showingCustomEntrySheet = true }
                        )

                        waterSecondaryButton(
                            title: "Undo last",
                            symbol: "arrow.uturn.backward",
                            action: { store.removeLastEntry() }
                        )
                        .opacity(store.recentEntries(limit: 1).isEmpty ? 0.5 : 1)
                        .disabled(store.recentEntries(limit: 1).isEmpty)
                    }
                }

                if !store.recentEntries(limit: 3).isEmpty {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        Text("Recent water logs")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                        VStack(spacing: AIscendTheme.Spacing.small) {
                            ForEach(store.recentEntries(limit: 3)) { entry in
                                HydrationRecentWaterEntryRow(entry: entry) {
                                    withAnimation(AIscendTheme.Motion.soft) {
                                        store.delete(entry)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var aiSupportCard: some View {
        DashboardGlassCard(tone: .subtle) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                Text("AI help")
                    .aiscendTextStyle(.sectionTitle, color: AIscendTheme.Colors.textPrimary)

                Text("If you are unsure what to log or whether your balance looks reasonable, jump straight into chat instead of digging through extra screens.")
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        hydrationAIButton(
                            title: "Ask AI",
                            symbol: "message.fill",
                            prompt: store.combinedPrompt(
                                intent: .askAI,
                                electrolyteSummary: electrolyteSummary,
                                lastSelectedPreset: lastPreset
                            )
                        )

                        hydrationAIButton(
                            title: "Estimate for me",
                            symbol: "sparkles",
                            prompt: store.combinedPrompt(
                                intent: .estimate,
                                electrolyteSummary: electrolyteSummary,
                                lastSelectedPreset: lastPreset
                            )
                        )

                        hydrationAIButton(
                            title: "Why does this matter?",
                            symbol: "questionmark.circle.fill",
                            prompt: store.combinedPrompt(
                                intent: .explain,
                                electrolyteSummary: electrolyteSummary,
                                lastSelectedPreset: lastPreset
                            )
                        )
                    }

                    VStack(spacing: AIscendTheme.Spacing.small) {
                        hydrationAIButton(
                            title: "Ask AI",
                            symbol: "message.fill",
                            prompt: store.combinedPrompt(
                                intent: .askAI,
                                electrolyteSummary: electrolyteSummary,
                                lastSelectedPreset: lastPreset
                            )
                        )

                        hydrationAIButton(
                            title: "Estimate for me",
                            symbol: "sparkles",
                            prompt: store.combinedPrompt(
                                intent: .estimate,
                                electrolyteSummary: electrolyteSummary,
                                lastSelectedPreset: lastPreset
                            )
                        )

                        hydrationAIButton(
                            title: "Why does this matter?",
                            symbol: "questionmark.circle.fill",
                            prompt: store.combinedPrompt(
                                intent: .explain,
                                electrolyteSummary: electrolyteSummary,
                                lastSelectedPreset: lastPreset
                            )
                        )
                    }
                }
            }
        }
    }

    private func waterSecondaryButton(
        title: String,
        symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            AIscendButtonLabel(title: title, leadingSymbol: symbol)
        }
        .buttonStyle(AIscendButtonStyle(variant: .ghost))
    }

    private func hydrationAIButton(title: String, symbol: String, prompt: String) -> some View {
        Button {
            onOpenChat(prompt)
        } label: {
            AIscendButtonLabel(title: title, leadingSymbol: symbol)
        }
        .buttonStyle(AIscendButtonStyle(variant: .secondary))
    }

    private func resetQuickAddHighlight() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            highlightedQuickAdd = nil
        }
    }
}

struct HydrationDashboardCard: View {
    @ObservedObject var store: HydrationTrackingStore
    @ObservedObject var electrolyteStore: ElectrolyteTrackingStore
    let onOpenHydration: () -> Void
    let onOpenChat: (String) -> Void

    private var baseWaterSummary: WaterDailySummary {
        store.todaySummary()
    }

    private var electrolyteSummary: ElectrolyteDailySummary {
        electrolyteStore.todaySummary(waterIntakeMl: baseWaterSummary.totalWaterMl)
    }

    private var waterSummary: WaterDailySummary {
        store.todaySummary(electrolyteSummary: electrolyteSummary)
    }

    private var combinedInsight: String {
        store.combinedInsight(electrolyteSummary: electrolyteSummary)
    }

    var body: some View {
        DashboardGlassCard(tone: .standard) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                        Text("Hydration")
                            .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)

                        Text("Water + electrolyte support")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                    }

                    Spacer(minLength: 0)

                    Button(action: onOpenHydration) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AIscendTheme.Colors.textPrimary)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.84))
                            )
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: AIscendTheme.Spacing.small) {
                    HydrationStatePill(state: waterSummary.hydrationState)
                    ElectrolyteBalancePill(state: electrolyteSummary.balanceState)
                }

                Text(combinedInsight)
                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        HydrationCompactMetric(
                            title: "Water",
                            value: "\(HydrationTrackingEngine.formatWater(waterSummary.totalWaterMl, prefersCompact: true)) / \(HydrationTrackingEngine.formatWater(waterSummary.targetWaterMl, prefersCompact: true))"
                        )

                        HydrationCompactMetric(
                            title: "Electrolytes",
                            value: electrolyteSummary.balanceState.title
                        )
                    }

                    VStack(spacing: AIscendTheme.Spacing.small) {
                        HydrationCompactMetric(
                            title: "Water",
                            value: "\(HydrationTrackingEngine.formatWater(waterSummary.totalWaterMl, prefersCompact: true)) / \(HydrationTrackingEngine.formatWater(waterSummary.targetWaterMl, prefersCompact: true))"
                        )

                        HydrationCompactMetric(
                            title: "Electrolytes",
                            value: electrolyteSummary.balanceState.title
                        )
                    }
                }

                HStack(spacing: AIscendTheme.Spacing.small) {
                    Menu {
                        ForEach(store.quickAddAmountsMl, id: \.self) { amount in
                            Button("+\(amount)ml") {
                                store.addWater(amountMl: amount, sourceName: "Quick add")
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            }
                        }

                        Divider()

                        Button("Open Hydration") {
                            onOpenHydration()
                        }
                    } label: {
                        HStack(spacing: AIscendTheme.Spacing.xSmall) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                            Text("Quick add")
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                        }
                        .padding(.horizontal, AIscendTheme.Spacing.medium)
                        .padding(.vertical, AIscendTheme.Spacing.small)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.86))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        onOpenChat(
                            store.combinedPrompt(
                                intent: .estimate,
                                electrolyteSummary: electrolyteSummary,
                                lastSelectedPreset: electrolyteStore.lastSelectedPreset()
                            )
                        )
                    } label: {
                        HStack(spacing: AIscendTheme.Spacing.xSmall) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Ask AI")
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                        }
                        .padding(.horizontal, AIscendTheme.Spacing.medium)
                        .padding(.vertical, AIscendTheme.Spacing.small)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AIscendTheme.Colors.surfaceInteractive.opacity(0.84))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(AIscendTheme.Colors.accentGlow.opacity(0.18), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 0)
                }
            }
        }
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

private struct HydrationQuickAddButton: View {
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
