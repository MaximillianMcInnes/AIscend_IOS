//
//  GlowUpTrackerView.swift
//  AIscend
//

import SwiftUI

@MainActor
final class GlowUpTrackerStore: ObservableObject {
    @Published private(set) var scans: [GlowUpTimelineScan] = []
    @Published private(set) var comparison: GlowUpComparison?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var preferences: GlowUpTrackerPreferences {
        didSet {
            savePreferences()
            rebuildComparison()
        }
    }

    private let repository: ScanResultsRepositoryProtocol
    private let defaults: UserDefaults
    private let preferencesKey = "aiscend.glowUpTracker.preferences"

    init(
        repository: ScanResultsRepositoryProtocol = ScanResultsRepository(),
        defaults: UserDefaults = .standard
    ) {
        self.repository = repository
        self.defaults = defaults
        self.preferences = Self.loadPreferences(from: defaults, key: preferencesKey)
    }

    func load() async {
        guard !isLoading else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        let records = await repository.loadPersistedArchive()
        scans = GlowUpComparisonEngine.timeline(from: records)
        errorMessage = nil
        rebuildComparison(from: records)
    }

    func updateRange(_ range: GlowUpComparisonRange) {
        preferences.selectedRange = range
    }

    func updateMetricView(_ metricView: GlowUpMetricView) {
        preferences.preferredMetricView = metricView
    }

    func togglePrivacyMode() {
        preferences.isPrivacyModeEnabled.toggle()
    }

    private func rebuildComparison() {
        rebuildComparison(from: scans.map(\.record))
    }

    private func rebuildComparison(from records: [PersistedScanRecord]) {
        comparison = GlowUpComparisonEngine.comparison(
            from: records,
            range: preferences.selectedRange
        )
    }

    private func savePreferences() {
        guard let encoded = try? JSONEncoder().encode(preferences) else {
            return
        }

        defaults.set(encoded, forKey: preferencesKey)
    }

    private static func loadPreferences(from defaults: UserDefaults, key: String) -> GlowUpTrackerPreferences {
        guard let data = defaults.data(forKey: key),
              let preferences = try? JSONDecoder().decode(GlowUpTrackerPreferences.self, from: data)
        else {
            return GlowUpTrackerPreferences()
        }

        return preferences
    }
}

struct GlowUpTrackerView: View {
    let onDismiss: (() -> Void)?

    @StateObject private var store = GlowUpTrackerStore()

    init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    header

                    if store.isLoading && store.scans.isEmpty {
                        loadingState
                    } else if store.scans.count < 2 {
                        GlowUpEmptyState(scanCount: store.scans.count)
                    } else if let comparison = store.comparison {
                        loadedContent(comparison)
                    } else {
                        GlowUpEmptyState(scanCount: store.scans.count)
                    }
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, AIscendTheme.Layout.floatingTabBarClearance)
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
        .task {
            await store.load()
        }
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    AIscendBadge(
                        title: "Private Progress Archive",
                        symbol: "lock.shield.fill",
                        style: .accent
                    )

                    Text("Glow-Up Tracker")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    Text("Compare scans over time and see which routine inputs may be correlating with visible presentation changes.")
                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: AIscendTheme.Spacing.small)

                if let onDismiss {
                    AIscendTopBarButton(symbol: "xmark", action: onDismiss)
                }
            }

            controls
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            GlowUpSegmentedControl(
                selection: store.preferences.selectedRange,
                options: GlowUpComparisonRange.allCases,
                title: \.title,
                onSelect: store.updateRange
            )

            HStack(spacing: AIscendTheme.Spacing.small) {
                GlowUpSegmentedControl(
                    selection: store.preferences.preferredMetricView,
                    options: GlowUpMetricView.allCases,
                    title: \.title,
                    onSelect: store.updateMetricView
                )

                Button(action: store.togglePrivacyMode) {
                    AIscendBadge(
                        title: store.preferences.isPrivacyModeEnabled ? "Private" : "Photos on",
                        symbol: store.preferences.isPrivacyModeEnabled ? "eye.slash.fill" : "eye.fill",
                        style: store.preferences.isPrivacyModeEnabled ? .accent : .neutral
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Toggle privacy mode")
            }
        }
    }

    private func loadedContent(_ comparison: GlowUpComparison) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            GlowUpComparisonCard(comparison: comparison)

            GlowUpTimelineView(
                scans: store.scans,
                comparison: comparison,
                isPrivacyModeEnabled: store.preferences.isPrivacyModeEnabled
            )

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                DashboardSectionHeading(
                    eyebrow: "What changed?",
                    title: store.preferences.preferredMetricView == .whatChanged ? "Scan movement" : "Metric deltas",
                    subtitle: "Cautious comparisons based on the available scan data."
                )

                LazyVStack(spacing: AIscendTheme.Spacing.medium) {
                    ForEach(comparison.metricDeltas) { delta in
                        GlowUpMetricDeltaCard(
                            delta: delta,
                            mode: store.preferences.preferredMetricView
                        )
                    }
                }
            }

            GlowUpShareCard(
                comparison: comparison,
                isPrivacyModeEnabled: store.preferences.isPrivacyModeEnabled
            )
        }
    }

    private var loadingState: some View {
        DashboardGlassCard(tone: .standard) {
            HStack(spacing: AIscendTheme.Spacing.medium) {
                AIscendLoadingIndicator()

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                    Text("Loading archive")
                        .aiscendTextStyle(.cardTitle)

                    Text("Building your private progress view.")
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                }
            }
        }
    }
}

private struct GlowUpSegmentedControl<Option: Identifiable & Hashable>: View {
    let selection: Option
    let options: [Option]
    let title: (Option) -> String
    let onSelect: (Option) -> Void

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            ForEach(options) { option in
                Button {
                    withAnimation(AIscendTheme.Motion.press) {
                        onSelect(option)
                    }
                } label: {
                    Text(title(option))
                        .aiscendTextStyle(.caption, color: selection == option ? AIscendTheme.Colors.textPrimary : AIscendTheme.Colors.textSecondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AIscendTheme.Spacing.small)
                        .background(
                            Capsule(style: .continuous)
                                .fill(selection == option ? AIscendTheme.Colors.accentPrimary.opacity(0.28) : Color.white.opacity(0.055))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(selection == option ? AIscendTheme.Colors.accentGlow.opacity(0.38) : AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    GlowUpTrackerView()
}

