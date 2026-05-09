//
//  NutritionDashboardView.swift
//  AIscend
//

import SwiftUI
import UIKit

struct NutritionDashboardView: View {
    @ObservedObject var store: NutritionStore
    let onDismiss: () -> Void

    @State private var showingFoodLog = false
    @State private var showingFoodScanner = false
    @State private var showingRecompositionEngine = false
    @State private var showingAnalytics = false
    @State private var showingDailySummary = false
    @State private var pulse = false

    private var summary: NutritionDailySummary {
        store.summary()
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AIscendBackdrop()
                DashboardAmbientLayer()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                        topBar(topInset: geometry.safeAreaInsets.top)
                        heroCard
                        goalSystem
                        macroSystem
                        FacialImpactCard(scores: summary.scores)
                        NutritionInsightsCard(insights: summary.insights, recommendations: summary.recommendations)
                        HydrationIntelligenceCard(
                            macros: summary.macros,
                            targets: summary.targets,
                            score: summary.scores.hydrationQuality,
                            onLogWater: {
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                store.logHydration(liters: 0.5)
                            }
                        )
                        MealTimelineView(
                            meals: store.entries(),
                            onDuplicate: { meal in
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                store.duplicate(meal)
                            },
                            onFavorite: { meal in
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                store.toggleFavorite(meal)
                            }
                        )
                        streakSystem
                        futureArchitecture
                    }
                    .frame(maxWidth: 620)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                    .padding(.top, AIscendTheme.Spacing.small)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 112)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .fullScreenCover(isPresented: $showingFoodLog) {
            FoodLogView(store: store) {
                showingFoodLog = false
            }
        }
        .fullScreenCover(isPresented: $showingFoodScanner) {
            FoodScannerView(store: store) {
                showingFoodScanner = false
            }
        }
        .fullScreenCover(isPresented: $showingRecompositionEngine) {
            AestheticRecompositionView(store: store) {
                showingRecompositionEngine = false
            }
        }
        .fullScreenCover(isPresented: $showingAnalytics) {
            NutritionAnalyticsView(summary: summary, bodyEntries: store.bodyCompositionEntries) {
                showingAnalytics = false
            }
        }
        .sheet(isPresented: $showingDailySummary) {
            NutritionDailySummaryView(summary: summary)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func topBar(topInset: CGFloat) -> some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(AIscendTheme.Colors.surfaceGlass))
                    .overlay(Circle().stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                showingAnalytics = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chart.xyaxis.line")
                    Text("Analytics")
                }
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                .padding(.horizontal, AIscendTheme.Spacing.small)
                .frame(height: 42)
                .background(Capsule(style: .continuous).fill(AIscendTheme.Colors.surfaceGlass))
                .overlay(Capsule(style: .continuous).stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, topInset + AIscendTheme.Spacing.small)
    }

    private var heroCard: some View {
        DashboardGlassCard(tone: .hero) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        HStack(spacing: AIscendTheme.Spacing.small) {
                            AIscendBadge(title: "Nutrition OS", symbol: "sparkles", style: .accent)
                            AIscendBadge(title: store.selectedGoal.title, symbol: "scope", style: .neutral)
                        }

                        Text("Fuel the face, not just the body.")
                            .font(.system(size: 36, weight: .bold, design: .default))
                            .foregroundStyle(AIscendTheme.Colors.textPrimary)
                            .lineLimit(3)
                            .minimumScaleFactor(0.78)

                        Text("Calories, macros, hydration, and sodium translated into jawline sharpness, puffiness risk, skin support, and recovery.")
                            .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: AIscendTheme.Spacing.medium)

                    ZStack {
                        Circle()
                            .fill(AIscendTheme.Colors.accentPrimary.opacity(pulse ? 0.28 : 0.16))
                            .blur(radius: 20)
                            .frame(width: 130, height: 130)

                        VStack(spacing: 0) {
                            Text("\(summary.scores.faceImpactScore)")
                                .font(.system(size: 46, weight: .bold, design: .default))
                                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                                .monospacedDigit()
                            Text("FACE")
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                        }
                        .frame(width: 116, height: 116)
                        .background(Circle().fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.82)))
                        .overlay(Circle().stroke(AIscendTheme.Colors.accentGlow.opacity(0.36), lineWidth: 1))
                    }
                }

                HStack(spacing: AIscendTheme.Spacing.small) {
                    Button {
                        showingFoodScanner = true
                    } label: {
                        AIscendButtonLabel(title: "AI Scan", leadingSymbol: "camera.viewfinder")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .primary))

                    Button {
                        showingFoodLog = true
                    } label: {
                        AIscendButtonLabel(title: "Log Food", leadingSymbol: "plus")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .secondary))
                }

                HStack(spacing: AIscendTheme.Spacing.small) {
                    Button {
                        showingRecompositionEngine = true
                    } label: {
                        AIscendButtonLabel(title: "Recomp AI", leadingSymbol: "chart.xyaxis.line")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .ghost))

                    Button {
                        showingDailySummary = true
                    } label: {
                        AIscendButtonLabel(title: "Daily Read", leadingSymbol: "doc.text.magnifyingglass")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .ghost))
                }
            }
        }
    }

    private var goalSystem: some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "Goal System",
                    title: "Adaptive aesthetic target",
                    subtitle: store.selectedGoal.detail
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        ForEach(NutritionGoalMode.allCases) { goal in
                            Button {
                                UISelectionFeedbackGenerator().selectionChanged()
                                withAnimation(AIscendTheme.Motion.reveal) {
                                    store.selectedGoal = goal
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(goal.title)
                                        .aiscendTextStyle(.buttonLabel, color: store.selectedGoal == goal ? AIscendTheme.Colors.textPrimary : AIscendTheme.Colors.textSecondary)
                                    Text(goal.detail)
                                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                                        .lineLimit(2)
                                }
                                .frame(width: 142, alignment: .leading)
                                .padding(AIscendTheme.Spacing.medium)
                                .background(
                                    RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                                        .fill(store.selectedGoal == goal ? AIscendTheme.Colors.accentPrimary.opacity(0.24) : AIscendTheme.Colors.surfaceHighlight.opacity(0.58))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                                        .stroke(store.selectedGoal == goal ? AIscendTheme.Colors.accentGlow.opacity(0.42) : AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var macroSystem: some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                AIscendSectionHeader(
                    eyebrow: "Daily Calories",
                    title: "\(summary.macros.calories) / \(summary.targets.calories) kcal",
                    subtitle: calorieStatus
                )

                calorieBalanceBar

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.medium) {
                    MacroRingView(title: "Protein", value: summary.macros.protein, target: summary.targets.protein, unit: "g", tint: AIscendTheme.Colors.accentGlow)
                    MacroRingView(title: "Carbs", value: summary.macros.carbs, target: summary.targets.carbs, unit: "g", tint: AIscendTheme.Colors.accentCyan)
                    MacroRingView(title: "Fat", value: summary.macros.fat, target: summary.targets.fat, unit: "g", tint: AIscendTheme.Colors.accentAmber)
                    MacroRingView(title: "Fiber", value: summary.macros.fiber, target: summary.targets.fiber, unit: "g", tint: AIscendTheme.Colors.success)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
                    metricPill(title: "Burned", value: "\(summary.targets.burned)")
                    metricPill(title: "Sodium", value: "\(Int(summary.macros.sodium))mg")
                    metricPill(title: "Water", value: String(format: "%.1fL", summary.macros.water))
                }
            }
        }
    }

    private var calorieStatus: String {
        let delta = summary.calorieDelta
        if abs(delta) < 120 {
            return "Energy intake is aligned with the current adaptive target."
        }

        if delta > 0 {
            return "\(delta) kcal surplus. Useful for lean gain, but watch sodium and sugar if facial sharpness is the priority."
        }

        return "\(abs(delta)) kcal deficit. Protein timing matters now to protect tissue and recovery."
    }

    private var calorieBalanceBar: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let progress = min(max(Double(summary.macros.calories) / Double(max(summary.targets.calories, 1)), 0), 1.24)
            let clamped = min(progress, 1)

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.76))

                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AIscendTheme.Colors.accentGlow, AIscendTheme.Colors.accentPrimary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width * clamped)
                    .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.28), radius: 14, x: 0, y: 0)

                if progress > 1 {
                    Capsule(style: .continuous)
                        .fill(AIscendTheme.Colors.accentAmber.opacity(0.92))
                        .frame(width: min(width * (progress - 1), width * 0.24))
                        .offset(x: width * 0.98)
                }
            }
        }
        .frame(height: 14)
    }

    private var streakSystem: some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "Retention Loops",
                    title: "Streak systems",
                    subtitle: "Consistency is tracked by the behaviors that actually affect the face."
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
                    streakTile(title: "Nutrition", value: store.nutritionStreak, symbol: "flame.fill")
                    streakTile(title: "Hydration", value: store.hydrationStreak, symbol: "drop.fill")
                    streakTile(title: "Protein", value: store.proteinStreak, symbol: "shield.fill")
                    streakTile(title: "Face Opt", value: store.facialOptimisationStreak, symbol: "sparkles")
                }
            }
        }
    }

    private var futureArchitecture: some View {
        DashboardGlassCard(tone: .subtle) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "Scalable Architecture",
                    title: "Ready for deeper intelligence",
                    subtitle: "HealthKit, wearables, barcode scanning, AI meal vision, supplements, groceries, restaurant recommendations, and generated meal plans can feed this same engine."
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
                    architectureChip("Apple Health", "heart.text.square.fill")
                    architectureChip("Wearables", "applewatch")
                    architectureChip("AI Meal Scan", "camera.viewfinder")
                    architectureChip("Supplements", "pills.fill")
                }
            }
        }
    }

    private func metricPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .aiscendTextStyle(.buttonLabel)
                .monospacedDigit()
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.66))
        )
    }

    private func streakTile(title: String, value: Int, symbol: String) -> some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            AIscendIconOrb(symbol: symbol, accent: .dawn, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)d")
                    .aiscendTextStyle(.metricCompact)
                    .monospacedDigit()
                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }
            Spacer(minLength: 0)
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

    private func architectureChip(_ title: String, _ symbol: String) -> some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Image(systemName: symbol)
                .foregroundStyle(AIscendTheme.Colors.accentGlow)
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.56))
        )
    }
}

private struct NutritionDailySummaryView: View {
    let summary: NutritionDailySummary

    var body: some View {
        ZStack {
            AIscendBackdrop()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    AIscendSectionHeader(
                        eyebrow: "End of Day Read",
                        title: "Tomorrow appearance forecast",
                        subtitle: forecast,
                        prominence: .hero
                    )

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
                        summaryTile("Nutrition", summary.scores.nutritionQuality, "fork.knife")
                        summaryTile("Face", summary.scores.faceImpactScore, "face.smiling.inverse")
                        summaryTile("Hydration", summary.scores.hydrationQuality, "drop.fill")
                        summaryTile("Recovery", recoveryEstimate, "bed.double.fill")
                    }

                    ForEach(summary.insights) { insight in
                        NutritionSignalRowLite(insight: insight)
                    }
                }
                .padding(AIscendTheme.Spacing.large)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var recoveryEstimate: Int {
        max(0, min(100, Int(Double(summary.scores.nutritionQuality) * 0.46 + Double(summary.scores.hydrationQuality) * 0.34 + Double(100 - summary.scores.inflammationRisk) * 0.20)))
    }

    private var forecast: String {
        if summary.scores.inflammationRisk > 62 {
            return "Likely softer tomorrow. Reduce sodium, hydrate, and keep the final meal controlled."
        }

        if summary.scores.faceImpactScore >= 82 {
            return "Likely sharper tomorrow. Current intake supports skin, recovery, and jawline definition."
        }

        return "Neutral-to-positive. Close the protein and hydration gaps for a stronger morning read."
    }

    private func summaryTile(_ title: String, _ value: Int, _ symbol: String) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            AIscendIconOrb(symbol: symbol, accent: .sky, size: 40)
            Text("\(value)")
                .aiscendTextStyle(.metric)
                .monospacedDigit()
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.medium)
        .aiscendPanel(.standard)
    }
}

private struct NutritionSignalRowLite: View {
    let insight: NutritionInsight

    var body: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: insight.symbol, accent: .mint, size: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .aiscendTextStyle(.cardTitle)
                Text(insight.detail)
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
            }
        }
        .padding(AIscendTheme.Spacing.medium)
        .aiscendPanel(.muted)
    }
}

#Preview {
    NutritionDashboardView(store: NutritionStore(), onDismiss: {})
}
