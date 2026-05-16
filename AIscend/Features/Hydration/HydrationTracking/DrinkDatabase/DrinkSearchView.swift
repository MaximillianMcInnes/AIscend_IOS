//
//  DrinkSearchView.swift
//  AIscend
//
//  Created by Codex on 5/10/26.
//

import SwiftUI
import UIKit

struct DrinkSearchView: View {
    @ObservedObject var store: HydrationTrackingStore
    @ObservedObject var electrolyteStore: ElectrolyteTrackingStore

    var library: DrinkLibraryProviding = DrinkLibrary.shared

    @State private var query = ""
    @State private var selectedCategory: DrinkCategory?
    @State private var selectedDrink: DrinkItem?
    @State private var amountMl = 500
    @State private var lastLoggedDrinkID: String?

    private let waterPresetAmounts = [250, 500, 750, 1_000]

    private var recentLogs: [DrinkLogEntry] {
        store.recentDrinkLogs(limit: 12)
    }

    private var recentDrinks: [DrinkItem] {
        Array(library.recentCompatibleDrinks(from: recentLogs).prefix(5))
    }

    private var visibleDrinks: [DrinkItem] {
        let baseDrinks: [DrinkItem]

        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if let selectedCategory {
                baseDrinks = library.drinks(in: selectedCategory)
            } else {
                baseDrinks = library.popularDrinks()
            }
        } else {
            baseDrinks = library.search(query: query)
        }

        guard let selectedCategory else {
            return baseDrinks
        }

        return baseDrinks.filter { $0.category == selectedCategory }
    }

    var body: some View {
        DashboardGlassCard(tone: .standard) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                header

                VStack(spacing: AIscendTheme.Spacing.small) {
                    DrinkSearchBar(query: $query)

                    DrinkCategoryFilterChips(selectedCategory: $selectedCategory)
                }

                if !recentDrinks.isEmpty {
                    recentSection
                }

                resultsSection
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                Text("Drinks")
                    .aiscendTextStyle(.sectionTitle, color: AIscendTheme.Colors.textPrimary)

                Text("Search common drinks, adjust the amount, and log hydration credit with drink details.")
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Image(systemName: "drop.degreesign.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.accentCyan)
                .padding(11)
                .background(Circle().fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.84)))
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            Text("Recent drinks")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            VStack(spacing: AIscendTheme.Spacing.small) {
                ForEach(recentDrinks) { drink in
                    RecentDrinkRow(
                        drink: drink,
                        recentLog: recentLogs.first { $0.drinkId == drink.id },
                        isSelected: selectedDrink?.id == drink.id,
                        onSelect: {
                            select(drink)
                        }
                    )
                }
            }
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            Text(sectionTitle)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            if visibleDrinks.isEmpty {
                emptyState
            } else {
                VStack(spacing: AIscendTheme.Spacing.small) {
                    ForEach(visibleDrinks) { drink in
                        VStack(spacing: AIscendTheme.Spacing.small) {
                            DrinkResultRow(
                                drink: drink,
                                isSelected: selectedDrink?.id == drink.id,
                                quickLogAmounts: drink.category == .water ? waterPresetAmounts : [],
                                onSelect: {
                                    select(drink)
                                },
                                onQuickLog: { amount in
                                    log(drink, amountMl: amount)
                                }
                            )

                            if selectedDrink?.id == drink.id {
                                DrinkLogConfirmationCard(
                                    drink: drink,
                                    amountMl: $amountMl,
                                    waterPresetAmounts: drink.category == .water ? waterPresetAmounts : [],
                                    didLog: lastLoggedDrinkID == drink.id,
                                    onLog: {
                                        log(drink, amountMl: amountMl)
                                    }
                                )
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .top)),
                                    removal: .opacity
                                ))
                            }
                        }
                    }
                }
            }
        }
    }

    private var sectionTitle: String {
        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Search results"
        }

        if let selectedCategory {
            return selectedCategory.title
        }

        return "Popular drinks"
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
            Text("No drinks found")
                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textPrimary)

            Text("Try another name, brand, or category.")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.54))
        )
    }

    private func select(_ drink: DrinkItem) {
        withAnimation(AIscendTheme.Motion.reveal) {
            if selectedDrink?.id == drink.id {
                selectedDrink = nil
            } else {
                selectedDrink = drink
                amountMl = drink.category == .water ? 500 : drink.servingSizeMl
            }
        }
    }

    private func log(_ drink: DrinkItem, amountMl: Int) {
        let safeAmount = max(amountMl, 1)
        _ = store.logDrink(drink, amountMl: safeAmount)

        withAnimation(AIscendTheme.Motion.soft) {
            selectedDrink = drink
            self.amountMl = safeAmount
            lastLoggedDrinkID = drink.id
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        resetLoggedState(for: drink.id)
    }

    private func resetLoggedState(for drinkID: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            guard lastLoggedDrinkID == drinkID else {
                return
            }

            withAnimation(AIscendTheme.Motion.soft) {
                lastLoggedDrinkID = nil
            }
        }
    }
}

struct DrinkSearchBar: View {
    @Binding var query: String

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.textMuted)

            TextField("Search water, coffee, sports drinks", text: $query)
                .font(AIscendTheme.Typography.input)
                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AIscendTheme.Colors.textMuted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear drink search")
            }
        }
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
}

struct DrinkCategoryFilterChips: View {
    @Binding var selectedCategory: DrinkCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AIscendTheme.Spacing.xSmall) {
                chip(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }

                ForEach(DrinkCategory.allCases) { category in
                    chip(title: category.title, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func chip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .aiscendTextStyle(.caption, color: isSelected ? AIscendTheme.Colors.textPrimary : AIscendTheme.Colors.textSecondary)
                .lineLimit(1)
                .padding(.horizontal, AIscendTheme.Spacing.medium)
                .padding(.vertical, AIscendTheme.Spacing.xSmall)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? AIscendTheme.Colors.accentPrimary.opacity(0.26) : AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(isSelected ? AIscendTheme.Colors.accentGlow.opacity(0.34) : AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct DrinkResultRow: View {
    let drink: DrinkItem
    let isSelected: Bool
    var quickLogAmounts: [Int] = []
    let onSelect: () -> Void
    var onQuickLog: (Int) -> Void = { _ in }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    categoryIcon

                    VStack(alignment: .leading, spacing: 4) {
                        Text(drink.name)
                            .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textPrimary)
                            .lineLimit(1)

                        Text(subtitle)
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                            .lineLimit(1)
                    }

                    Spacer(minLength: AIscendTheme.Spacing.small)

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(HydrationTrackingEngine.formatWater(drink.hydrationCreditMl, prefersCompact: true))
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentCyan)
                            .monospacedDigit()

                        Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AIscendTheme.Colors.textMuted)
                    }
                }

                if !quickLogAmounts.isEmpty {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: AIscendTheme.Spacing.xSmall) {
                            quickLogButtons
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.xSmall) {
                            quickLogButtons
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AIscendTheme.Spacing.medium)
            .background(rowBackground)
            .overlay(rowBorder)
        }
        .buttonStyle(.plain)
    }

    private var categoryIcon: some View {
        Image(systemName: iconName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(iconTint)
            .frame(width: 36, height: 36)
            .background(Circle().fill(iconTint.opacity(0.14)))
    }

    private var quickLogButtons: some View {
        ForEach(quickLogAmounts, id: \.self) { amount in
            Button {
                onQuickLog(amount)
            } label: {
                Text("\(amount)ml")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                    .monospacedDigit()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, AIscendTheme.Spacing.small)
                    .padding(.vertical, 7)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AIscendTheme.Colors.surfaceInteractive.opacity(0.84))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var subtitle: String {
        let brand = drink.brand.map { "\($0) · " } ?? ""
        let sugarLabel = drink.sugarG > 0 ? " · sugar tracked" : ""
        return "\(brand)\(drink.category.title) · \(drink.servingSizeMl)ml serving\(sugarLabel)"
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
            .fill(isSelected ? AIscendTheme.Colors.surfaceInteractive.opacity(0.92) : AIscendTheme.Colors.surfaceHighlight.opacity(0.58))
    }

    private var rowBorder: some View {
        RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
            .stroke(isSelected ? AIscendTheme.Colors.accentGlow.opacity(0.32) : AIscendTheme.Colors.borderSubtle, lineWidth: 1)
    }

    private var iconName: String {
        switch drink.category {
        case .water, .sparklingWater:
            return "drop.fill"
        case .electrolyteDrink, .sportsDrink:
            return "bolt.fill"
        case .coffee:
            return "cup.and.saucer.fill"
        case .tea:
            return "leaf.fill"
        case .milk, .proteinShake:
            return "takeoutbag.and.cup.and.straw.fill"
        case .juice, .smoothie:
            return "waterbottle.fill"
        case .softDrink, .energyDrink:
            return "bubbles.and.sparkles.fill"
        case .custom:
            return "plus.circle.fill"
        }
    }

    private var iconTint: Color {
        switch drink.category {
        case .water, .sparklingWater:
            return AIscendTheme.Colors.accentCyan
        case .electrolyteDrink, .sportsDrink:
            return AIscendTheme.Colors.accentMint
        case .coffee, .tea:
            return AIscendTheme.Colors.accentAmber
        case .softDrink, .energyDrink:
            return AIscendTheme.Colors.accentGlow
        default:
            return AIscendTheme.Colors.textSecondary
        }
    }
}

struct DrinkAmountPicker: View {
    @Binding var amountMl: Int
    let presetAmounts: [Int]

    private let stepAmount = 50

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            HStack {
                Text("Amount")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                Spacer(minLength: 0)

                Text("\(amountMl)ml")
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textPrimary)
                    .monospacedDigit()
            }

            HStack(spacing: AIscendTheme.Spacing.small) {
                amountButton(symbol: "minus", disabled: amountMl <= stepAmount) {
                    amountMl = max(stepAmount, amountMl - stepAmount)
                }

                Slider(
                    value: Binding(
                        get: { Double(amountMl) },
                        set: { amountMl = max(stepAmount, Int(($0 / Double(stepAmount)).rounded()) * stepAmount) }
                    ),
                    in: 50...1_500,
                    step: Double(stepAmount)
                )
                .tint(AIscendTheme.Colors.accentCyan)

                amountButton(symbol: "plus", disabled: amountMl >= 1_500) {
                    amountMl = min(1_500, amountMl + stepAmount)
                }
            }

            if !presetAmounts.isEmpty {
                HStack(spacing: AIscendTheme.Spacing.xSmall) {
                    ForEach(presetAmounts, id: \.self) { amount in
                        Button {
                            amountMl = amount
                        } label: {
                            Text("\(amount)ml")
                                .aiscendTextStyle(.caption, color: amountMl == amount ? AIscendTheme.Colors.textPrimary : AIscendTheme.Colors.textSecondary)
                                .monospacedDigit()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AIscendTheme.Spacing.xSmall)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(amountMl == amount ? AIscendTheme.Colors.accentPrimary.opacity(0.22) : AIscendTheme.Colors.surfaceHighlight.opacity(0.58))
                                )
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(amountMl == amount ? AIscendTheme.Colors.accentGlow.opacity(0.32) : AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func amountButton(symbol: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(disabled ? AIscendTheme.Colors.textMuted : AIscendTheme.Colors.textPrimary)
                .frame(width: 40, height: 40)
                .background(Circle().fill(AIscendTheme.Colors.surfaceHighlight.opacity(disabled ? 0.38 : 0.82)))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

struct DrinkLogConfirmationCard: View {
    let drink: DrinkItem
    @Binding var amountMl: Int
    let waterPresetAmounts: [Int]
    let didLog: Bool
    let onLog: () -> Void

    private var entryPreview: DrinkLogEntry {
        drink.logEntry(amountMl: amountMl)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            DrinkAmountPicker(amountMl: $amountMl, presetAmounts: waterPresetAmounts)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
                metric(title: "Hydration", value: HydrationTrackingEngine.formatWater(entryPreview.hydrationCreditMl, prefersCompact: true), tint: AIscendTheme.Colors.accentCyan)
                metric(title: "Sodium", value: "\(entryPreview.sodiumMg)mg", tint: AIscendTheme.Colors.accentMint)
                metric(title: "Potassium", value: "\(entryPreview.potassiumMg)mg", tint: AIscendTheme.Colors.success)
                metric(title: "Magnesium", value: "\(entryPreview.magnesiumMg)mg", tint: AIscendTheme.Colors.accentGlow)
                metric(title: "Caffeine", value: "\(entryPreview.caffeineMg)mg", tint: AIscendTheme.Colors.accentAmber)
                metric(title: "Calories", value: "\(entryPreview.calories)", tint: AIscendTheme.Colors.textSecondary)
            }

            HStack(spacing: AIscendTheme.Spacing.small) {
                Text("Sugar \(formatSugar(entryPreview.sugarG))g")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                    .monospacedDigit()

                Spacer(minLength: 0)

                if didLog {
                    Label("Logged", systemImage: "checkmark.circle.fill")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.success)
                }
            }

            Button(action: onLog) {
                AIscendButtonLabel(title: "Log Drink", leadingSymbol: "plus")
            }
            .buttonStyle(AIscendButtonStyle(variant: .primary))
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.surfaceInteractive.opacity(0.92),
                            AIscendTheme.Colors.surfaceMuted.opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.accentCyan.opacity(0.2), lineWidth: 1)
        )
    }

    private func metric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                .lineLimit(1)

            Text(value)
                .aiscendTextStyle(.secondaryBody, color: tint)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.58))
        )
    }

    private func formatSugar(_ sugar: Double) -> String {
        sugar.rounded() == sugar ? "\(Int(sugar))" : String(format: "%.1f", sugar)
    }
}

struct RecentDrinkRow: View {
    let drink: DrinkItem
    let recentLog: DrinkLogEntry?
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: AIscendTheme.Spacing.small) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AIscendTheme.Colors.accentGlow)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(AIscendTheme.Colors.accentGlow.opacity(0.12)))

                VStack(alignment: .leading, spacing: 4) {
                    Text(drink.name)
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textPrimary)
                        .lineLimit(1)

                    Text(detail)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                        .lineLimit(1)
                }

                Spacer(minLength: AIscendTheme.Spacing.small)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? AIscendTheme.Colors.success : AIscendTheme.Colors.textMuted)
            }
            .padding(AIscendTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .fill(isSelected ? AIscendTheme.Colors.surfaceInteractive.opacity(0.88) : AIscendTheme.Colors.surfaceHighlight.opacity(0.48))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .stroke(isSelected ? AIscendTheme.Colors.accentGlow.opacity(0.3) : AIscendTheme.Colors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var detail: String {
        guard let recentLog else {
            return "\(drink.category.title) · \(drink.servingSizeMl)ml default"
        }

        return "\(recentLog.amountMl)ml · \(recentLog.loggedAt.formatted(date: .omitted, time: .shortened))"
    }
}
