//
//  FoodLogView.swift
//  AIscend
//

import SwiftUI
import UIKit

struct FoodLogView: View {
    @ObservedObject var store: NutritionStore
    let onDismiss: () -> Void

    @State private var mealType: NutritionMealType = .lunch
    @State private var name = ""
    @State private var detail = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var fiber = ""
    @State private var sodium = ""
    @State private var water = ""
    @State private var sugar = ""
    @State private var potassium = ""

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    topBar

                    AIscendSectionHeader(
                        eyebrow: "Food Log",
                        title: "Add intake signal",
                        subtitle: "Log macros quickly. Barcode and AI food recognition architecture is staged for the next data layer.",
                        prominence: .hero
                    )

                    architectureCard
                    manualEntryCard
                    quickActionsCard
                    recentMealsCard
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, AIscendTheme.Spacing.xxLarge)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack {
            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(AIscendTheme.Colors.surfaceGlass))
                    .overlay(Circle().stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var architectureCard: some View {
        DashboardGlassCard(tone: .premium) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "Capture Architecture",
                    title: "Manual now. AI-ready next.",
                    subtitle: "The logger separates data source from meal model, so barcode, computer vision, meal plans, supplements, and restaurant intelligence can feed the same engine."
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
                    captureMode(title: "Manual", symbol: "slider.horizontal.3", active: true)
                    captureMode(title: "Barcode", symbol: "barcode.viewfinder", active: false)
                    captureMode(title: "AI Vision", symbol: "camera.metering.center.weighted", active: false)
                    captureMode(title: "Templates", symbol: "square.stack.3d.up.fill", active: true)
                }
            }
        }
    }

    private var manualEntryCard: some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "Manual Entry",
                    title: "Food intelligence input"
                )

                Picker("Meal", selection: $mealType) {
                    ForEach(NutritionMealType.allCases.filter { $0 != .hydration }) { type in
                        Text(type.title).tag(type)
                    }
                }
                .pickerStyle(.segmented)

                field("Meal name", text: $name)
                field("Composition note", text: $detail)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
                    field("Calories", text: $calories, keyboard: .numberPad)
                    field("Protein g", text: $protein, keyboard: .decimalPad)
                    field("Carbs g", text: $carbs, keyboard: .decimalPad)
                    field("Fat g", text: $fat, keyboard: .decimalPad)
                    field("Fiber g", text: $fiber, keyboard: .decimalPad)
                    field("Sodium mg", text: $sodium, keyboard: .decimalPad)
                    field("Water L", text: $water, keyboard: .decimalPad)
                    field("Sugar g", text: $sugar, keyboard: .decimalPad)
                }

                field("Potassium mg", text: $potassium, keyboard: .decimalPad)

                Button(action: addManualMeal) {
                    AIscendButtonLabel(title: "Add Meal Signal", leadingSymbol: "plus")
                }
                .buttonStyle(AIscendButtonStyle(variant: .primary))
                .disabled(!canAdd)
                .opacity(canAdd ? 1 : 0.55)
            }
        }
    }

    private var quickActionsCard: some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "Quick Add",
                    title: "Templates and hydration"
                )

                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    store.logHydration(liters: 0.5)
                } label: {
                    AIscendButtonLabel(title: "Log 500ml Water", leadingSymbol: "drop.fill")
                }
                .buttonStyle(AIscendButtonStyle(variant: .secondary))

                ForEach(store.templates()) { template in
                    Button {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        store.duplicate(template)
                    } label: {
                        HStack(spacing: AIscendTheme.Spacing.medium) {
                            AIscendIconOrb(symbol: template.mealType.symbol, accent: .mint, size: 42)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(template.name)
                                    .aiscendTextStyle(.buttonLabel)
                                Text("\(template.macros.calories) kcal / \(Int(template.macros.protein))g protein")
                                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(AIscendTheme.Colors.accentGlow)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var recentMealsCard: some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "Recent / Favorites",
                    title: "Repeat what works"
                )

                ForEach(repeatableMeals) { meal in
                    Button {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        store.duplicate(meal)
                    } label: {
                        HStack(spacing: AIscendTheme.Spacing.medium) {
                            Image(systemName: meal.isFavorite ? "star.fill" : meal.mealType.symbol)
                                .foregroundStyle(AIscendTheme.Colors.accentGlow)
                                .frame(width: 34, height: 34)
                                .background(Circle().fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.82)))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(meal.name)
                                    .aiscendTextStyle(.buttonLabel)
                                Text(meal.facialImpactEstimate)
                                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                                    .lineLimit(2)
                            }

                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var repeatableMeals: [NutritionMealEntry] {
        var seen = Set<UUID>()
        return (Array(store.favoriteMeals().prefix(4)) + store.recentMeals(limit: 4))
            .filter { meal in
                seen.insert(meal.id).inserted
            }
    }

    private var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && Int(calories) != nil
    }

    private func field(_ title: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            TextField(title, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.words)
                .font(AIscendTheme.Typography.input)
                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                .padding(AIscendTheme.Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                        .fill(AIscendTheme.Colors.fieldFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                        .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                )
        }
    }

    private func captureMode(title: String, symbol: String, active: Bool) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(active ? AIscendTheme.Colors.accentGlow : AIscendTheme.Colors.textMuted)

            Text(title)
                .aiscendTextStyle(.buttonLabel)

            Text(active ? "Available" : "Architecture ready")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(active ? 0.78 : 0.46))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(active ? AIscendTheme.Colors.accentGlow.opacity(0.28) : AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private func addManualMeal() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.7)
        let macros = NutritionMacros(
            calories: Int(calories) ?? 0,
            protein: Double(protein) ?? 0,
            carbs: Double(carbs) ?? 0,
            fat: Double(fat) ?? 0,
            fiber: Double(fiber) ?? 0,
            sodium: Double(sodium) ?? 0,
            water: Double(water) ?? 0,
            sugar: Double(sugar) ?? 0,
            potassium: Double(potassium) ?? 0
        )

        let sodiumRisk = macros.sodium > store.summary().targets.sodiumLimit ? "Sodium may soften tomorrow's facial read." : "Low facial water-retention load."
        let aestheticRating = max(40, min(96, 78 + Int(macros.protein / 8) + Int(macros.fiber / 2) - Int(macros.sodium / 520)))

        store.addMeal(
            NutritionMealEntry(
                mealType: mealType,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                detail: detail.isEmpty ? "Manual macro entry" : detail,
                macros: macros,
                satietyScore: max(20, min(95, Int(macros.protein + macros.fiber * 2))),
                glycemicImpact: max(5, min(95, Int(macros.carbs * 0.72 + macros.sugar * 0.8))),
                aestheticRating: aestheticRating,
                facialImpactEstimate: sodiumRisk,
                source: .manual
            )
        )

        name = ""
        detail = ""
        calories = ""
        protein = ""
        carbs = ""
        fat = ""
        fiber = ""
        sodium = ""
        water = ""
        sugar = ""
        potassium = ""
    }
}
