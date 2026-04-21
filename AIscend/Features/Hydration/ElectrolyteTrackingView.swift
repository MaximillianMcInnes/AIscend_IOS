//
//  ElectrolyteTrackingView.swift
//  AIscend
//
//  Created by Codex on 4/19/26.
//

import SwiftUI
import UIKit

struct ElectrolyteTrackingView: View {
    @ObservedObject var store: ElectrolyteTrackingStore
    var waterIntakeMl: Int?
    var onOpenChat: (String) -> Void

    @State private var showingManualEntry = false
    @State private var highlightedPresetID: String?

    private var summary: ElectrolyteDailySummary {
        store.todaySummary(waterIntakeMl: waterIntakeMl)
    }

    var body: some View {
        DashboardGlassCard(tone: .premium) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                header
                statRow
                quickAddRow
                actionRow

                if !summary.entries.isEmpty {
                    recentEntries
                }
            }
        }
        .sheet(isPresented: $showingManualEntry) {
            ElectrolyteManualEntrySheet(store: store)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                    Text("Electrolytes")
                        .aiscendTextStyle(.sectionTitle, color: AIscendTheme.Colors.textPrimary)

                    Text("Support hydration retention and daily performance")
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                }

                Spacer(minLength: 0)

                ElectrolyteBalancePill(state: summary.balanceState)
            }

            Text(summary.shortInsight)
                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
        }
    }

    private var statRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AIscendTheme.Spacing.small) {
                ElectrolyteMetricTile(title: "Sodium", value: summary.totalSodiumMg, symbol: "waveform.path.ecg", accent: AIscendTheme.Colors.accentAmber)
                ElectrolyteMetricTile(title: "Potassium", value: summary.totalPotassiumMg, symbol: "leaf.fill", accent: AIscendTheme.Colors.accentMint)
                ElectrolyteMetricTile(title: "Magnesium", value: summary.totalMagnesiumMg, symbol: "capsule.fill", accent: AIscendTheme.Colors.accentCyan)
            }

            VStack(spacing: AIscendTheme.Spacing.small) {
                ElectrolyteMetricTile(title: "Sodium", value: summary.totalSodiumMg, symbol: "waveform.path.ecg", accent: AIscendTheme.Colors.accentAmber)
                ElectrolyteMetricTile(title: "Potassium", value: summary.totalPotassiumMg, symbol: "leaf.fill", accent: AIscendTheme.Colors.accentMint)
                ElectrolyteMetricTile(title: "Magnesium", value: summary.totalMagnesiumMg, symbol: "capsule.fill", accent: AIscendTheme.Colors.accentCyan)
            }
        }
    }

    private var quickAddRow: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            Text("Quick add")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    ForEach(store.presets) { preset in
                        Button {
                            withAnimation(AIscendTheme.Motion.reveal) {
                                store.addPreset(preset)
                            }
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            highlightedPresetID = preset.id
                            resetPresetHighlight()
                        } label: {
                            ElectrolytePresetChip(
                                preset: preset,
                                highlighted: highlightedPresetID == preset.id
                            )
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                onOpenChat(
                                    store.chatPrompt(
                                        for: .presetInfo(preset),
                                        waterIntakeMl: waterIntakeMl
                                    )
                                )
                            } label: {
                                Label("Ask AI about this", systemImage: "message.fill")
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var actionRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AIscendTheme.Spacing.small) {
                Button {
                    showingManualEntry = true
                } label: {
                    ElectrolyteActionLabel(title: "Manual entry", symbol: "slider.horizontal.3")
                }
                .buttonStyle(AIscendButtonStyle(variant: .ghost))

                Button {
                    onOpenChat(
                        store.chatPrompt(
                            for: .estimateToday,
                            waterIntakeMl: waterIntakeMl
                        )
                    )
                } label: {
                    ElectrolyteActionLabel(title: "Ask AI", symbol: "message.fill")
                }
                .buttonStyle(AIscendButtonStyle(variant: .secondary))
            }

            VStack(spacing: AIscendTheme.Spacing.small) {
                Button {
                    showingManualEntry = true
                } label: {
                    ElectrolyteActionLabel(title: "Manual entry", symbol: "slider.horizontal.3")
                }
                .buttonStyle(AIscendButtonStyle(variant: .ghost))

                Button {
                    onOpenChat(
                        store.chatPrompt(
                            for: .estimateToday,
                            waterIntakeMl: waterIntakeMl
                        )
                    )
                } label: {
                    ElectrolyteActionLabel(title: "Ask AI", symbol: "message.fill")
                }
                .buttonStyle(AIscendButtonStyle(variant: .secondary))
            }
        }
    }

    private var recentEntries: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            Text("Recent")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            VStack(spacing: AIscendTheme.Spacing.small) {
                ForEach(store.recentEntries(limit: 3)) { entry in
                    ElectrolyteRecentEntryRow(entry: entry) {
                        withAnimation(AIscendTheme.Motion.soft) {
                            store.delete(entry)
                        }
                    }
                }
            }
        }
    }

    private func resetPresetHighlight() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            highlightedPresetID = nil
        }
    }
}

struct ElectrolyteBalancePill: View {
    let state: ElectrolyteBalanceState

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
                .stroke(tint.opacity(0.24), lineWidth: 1)
        )
    }

    private var tint: Color {
        switch state {
        case .balanced:
            AIscendTheme.Colors.success
        case .moderate:
            AIscendTheme.Colors.accentCyan
        case .highSodiumLowPotassium:
            AIscendTheme.Colors.accentAmber
        case .lowSodiumHighWater, .low:
            AIscendTheme.Colors.accentGlow
        case .unknown:
            AIscendTheme.Colors.textMuted
        }
    }
}

private struct ElectrolyteMetricTile: View {
    let title: String
    let value: Int
    let symbol: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            HStack(spacing: AIscendTheme.Spacing.xSmall) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accent)

                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }

            Text("\(value)mg")
                .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(accent.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct ElectrolytePresetChip: View {
    let preset: ElectrolytePreset
    let highlighted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            HStack(spacing: AIscendTheme.Spacing.xSmall) {
                Image(systemName: preset.iconName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AIscendTheme.Colors.accentGlow)

                Text(preset.title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                    .lineLimit(1)
            }

            Text(preset.subtitle)
                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                .lineLimit(2)

            Text("\(preset.sodiumMg) Na • \(preset.potassiumMg) K • \(preset.magnesiumMg) Mg")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                .lineLimit(1)
        }
        .frame(width: 176, alignment: .leading)
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.surfaceHighlight.opacity(highlighted ? 0.92 : 0.78),
                            AIscendTheme.Colors.surfaceInteractive.opacity(highlighted ? 0.88 : 0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(
                    highlighted ? AIscendTheme.Colors.accentGlow.opacity(0.46) : AIscendTheme.Colors.borderSubtle,
                    lineWidth: 1
                )
        )
        .scaleEffect(highlighted ? 1.02 : 1)
        .shadow(color: highlighted ? AIscendTheme.Colors.accentPrimary.opacity(0.18) : .clear, radius: 14, x: 0, y: 8)
    }
}

private struct ElectrolyteActionLabel: View {
    let title: String
    let symbol: String

    var body: some View {
        AIscendButtonLabel(title: title, leadingSymbol: symbol)
    }
}

private struct ElectrolyteRecentEntryRow: View {
    let entry: ElectrolyteEntry
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.sourceName)
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textPrimary)

                Text(entry.date, style: .time)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }

            Spacer(minLength: AIscendTheme.Spacing.small)

            Text("\(entry.sodiumMg)/\(entry.potassiumMg)/\(entry.magnesiumMg)mg")
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

private struct ElectrolyteManualEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var store: ElectrolyteTrackingStore

    @State private var sodiumText = ""
    @State private var potassiumText = ""
    @State private var magnesiumText = ""
    @State private var note = ""

    private var canSave: Bool {
        (parsedValue(from: sodiumText) ?? 0) > 0 ||
        (parsedValue(from: potassiumText) ?? 0) > 0 ||
        (parsedValue(from: magnesiumText) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    header
                    fieldGroup

                    Button {
                        store.addManualEntry(
                            sodiumMg: parsedValue(from: sodiumText),
                            potassiumMg: parsedValue(from: potassiumText),
                            magnesiumMg: parsedValue(from: magnesiumText),
                            note: note
                        )
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        dismiss()
                    } label: {
                        AIscendButtonLabel(title: "Save entry", leadingSymbol: "checkmark")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .primary))
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.5)
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, AIscendTheme.Spacing.xxLarge)
            }
            .toolbar(.hidden, for: .navigationBar)
            .background(AIscendTheme.Colors.appBackground.ignoresSafeArea())
        }
        .presentationDetents([.fraction(0.82)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(30)
        .presentationBackground(.ultraThinMaterial)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            AIscendBadge(
                title: "Manual entry",
                symbol: "slider.horizontal.3",
                style: .accent
            )

            Text("Add only what you know")
                .aiscendTextStyle(.sectionTitle, color: AIscendTheme.Colors.textPrimary)

            Text("You can log sodium, potassium, magnesium, or just one of them.")
                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
        }
    }

    private var fieldGroup: some View {
        VStack(spacing: AIscendTheme.Spacing.medium) {
            ElectrolyteInputField(title: "Sodium", placeholder: "Optional mg", text: $sodiumText)
            ElectrolyteInputField(title: "Potassium", placeholder: "Optional mg", text: $potassiumText)
            ElectrolyteInputField(title: "Magnesium", placeholder: "Optional mg", text: $magnesiumText)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                Text("Note")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                TextField("Optional note", text: $note, axis: .vertical)
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
        }
        .padding(AIscendTheme.Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceGlass.opacity(0.84))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private func parsedValue(from rawValue: String) -> Int? {
        let digits = rawValue.filter(\.isNumber)
        guard !digits.isEmpty else {
            return nil
        }

        return Int(digits)
    }
}

private struct ElectrolyteInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            TextField(placeholder, text: $text)
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
    }
}
