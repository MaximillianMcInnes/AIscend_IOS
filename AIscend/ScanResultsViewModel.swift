//
//  ScanResultsViewModel.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import Foundation
import SwiftUI
import UIKit

@MainActor
final class ScanResultsViewModel: ObservableObject {
    enum LoadState: Equatable {
        case loading
        case empty
        case ready
    }

    @Published private(set) var loadState: LoadState = .loading
    @Published private(set) var result: PersistedScanRecord?
    @Published private(set) var pages: [ScanResultsPageID] = []
    @Published private(set) var autoSaveState: ScanAutoSaveState = .idle
    @Published var currentPageIndex: Int = 0

    private let session: AuthSessionStore
    private let repository: ScanResultsRepositoryProtocol
    private var hasLoaded = false

    init(
        session: AuthSessionStore,
        repository: ScanResultsRepositoryProtocol = ScanResultsRepository()
    ) {
        self.session = session
        self.repository = repository
    }

    var pageCount: Int {
        pages.count
    }

    var accessLevel: ScanResultsAccess {
        result?.accessLevel ?? .free
    }

    var isPremium: Bool {
        accessLevel == .premium
    }

    var currentPageID: ScanResultsPageID? {
        guard pages.indices.contains(currentPageIndex) else {
            return nil
        }

        return pages[currentPageIndex]
    }

    var currentStepLabel: String {
        guard pageCount > 0 else {
            return ""
        }

        return "\(currentPageIndex + 1) / \(pageCount)"
    }

    var syncStatusLine: String? {
        autoSaveState.statusLine
    }

    var scoreCards: [ResultsMetricCardModel] {
        guard let result else {
            return []
        }

        return [
            ResultsMetricCardModel(
                title: "Overall",
                value: scoreText(result.overallScore),
                detail: result.tierTitle,
                symbol: "sparkles.rectangle.stack.fill",
                accent: .sky
            ),
            ResultsMetricCardModel(
                title: "Potential",
                value: scoreText(result.potentialScore),
                detail: "Visible upside",
                symbol: "arrow.up.right",
                accent: .dawn
            ),
            ResultsMetricCardModel(
                title: "Eyes",
                value: scoreText(result.payload.scores.eyes ?? result.overallScore - 3),
                detail: "Upper-face read",
                symbol: "eye.fill",
                accent: .mint
            ),
            ResultsMetricCardModel(
                title: isPremium ? "Jaw" : "Skin",
                value: scoreText(isPremium ? (result.payload.scores.jaw ?? result.overallScore - 1) : (result.payload.scores.skin ?? result.overallScore - 4)),
                detail: isPremium ? "Lower-third strength" : "Surface quality",
                symbol: isPremium ? "triangle.bottomhalf.filled" : "drop.fill",
                accent: .sky
            )
        ]
    }

    var completionCards: [ResultsCompletionCardModel] {
        [
            ResultsCompletionCardModel(
                title: completionArchiveTitle,
                detail: completionArchiveDetail,
                symbol: "tray.full.fill",
                accent: .sky
            ),
            ResultsCompletionCardModel(
                title: "Advisor can unpack the result",
                detail: "Use chat to translate any section into a sharper action plan or improvement priority list.",
                symbol: "message.fill",
                accent: .dawn
            ),
            ResultsCompletionCardModel(
                title: isPremium ? "Glow-up planning is the next move" : "The next layer is the full improvement plan",
                detail: isPremium
                ? "Take the scan into your routine so the result becomes a cleaner execution plan."
                : "Unlock the full plan to move from curiosity into guided execution.",
                symbol: "scope",
                accent: .mint
            )
        ]
    }

    func load(initialResult: PersistedScanRecord? = nil) async {
        if hasLoaded && initialResult == nil {
            return
        }

        loadState = .loading
        autoSaveState = .idle
        currentPageIndex = 0

        if let initialResult {
            await repository.storeLatestPersistedResult(initialResult)
        }

        let resolvedResult = initialResult ?? await repository.loadLatestPersistedResult()

        guard let resolvedResult, resolvedResult.isDisplayable else {
            result = nil
            pages = []
            loadState = .empty
            hasLoaded = true
            return
        }

        result = resolvedResult
        pages = resolvedResult.pageSequence
        loadState = .ready

        if resolvedResult.isFreshScanCandidate {
            autoSaveState = .syncing
        }

        let autoSave = await repository.autoSaveFreshResultIfNeeded(
            resolvedResult,
            sessionUser: session.user
        )

        result = autoSave.result
        pages = autoSave.result.pageSequence
        autoSaveState = autoSave.state
        loadState = .ready
        hasLoaded = true
    }

    func advance() {
        guard currentPageIndex < pageCount - 1 else {
            return
        }

        UIImpactFeedbackGenerator(style: .soft).impactOccurred()

        withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
            currentPageIndex += 1
        }
    }

    func goToPage(_ index: Int) {
        guard pages.indices.contains(index) else {
            return
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
            currentPageIndex = index
        }
    }

    func handlePageChange(from oldValue: Int, to newValue: Int) {
        guard oldValue != newValue else {
            return
        }

        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    func title(for page: ScanResultsPageID) -> String {
        switch page {
        case .overview:
            "The read is in"
        case .placement:
            "Where you place"
        case .harmony:
            "Harmony and facial balance"
        case .eyes:
            "Eye area and frame"
        case .lips:
            "Lips and mouth area"
        case .jaw:
            "Jaw and lower third"
        case .sideProfile:
            "Side profile read"
        case .premiumPush:
            "Unlock the full report"
        case .done:
            "Scan complete"
        }
    }

    func subtitle(for page: ScanResultsPageID) -> String {
        guard let result else {
            return ""
        }

        switch page {
        case .overview:
            result.headline
        case .placement:
            result.placementNarrative
        case .harmony:
            "AIScend is reading how the face holds together as a whole, not just how isolated features score."
        case .eyes:
            isPremium
            ? "This section focuses on eye-area structure, brow framing, and the details that shape alertness and intensity."
            : "You can see the first layer of eye-area insight here, with deeper structure unlocked in premium."
        case .lips:
            "This section keeps the mouth area concise and useful so the result feels clear instead of noisy."
        case .jaw:
            "Jawline structure changes how the full face reads. Premium goes deeper into leverage and visual payoff."
        case .sideProfile:
            "The side profile often changes the total impression more than expected. This page isolates that angle cleanly."
        case .premiumPush:
            "Move from preview mode into the complete report with jaw, skin, side profile detail, and deeper guidance."
        case .done:
            switch autoSaveState {
            case .saved:
                "The result has been archived and is ready for the next move."
            default:
                "The result is ready to use, revisit, and turn into an actual plan."
            }
        }
    }

    func harmonyTraits() -> [ScanTraitRowModel] {
        if let matched = traits(
            keywords: ["harmony", "symmetry", "balance", "proportion", "ratio", "alignment"],
            in: combinedFrontProfile()
        ), !matched.isEmpty {
            return Array(matched.prefix(4))
        }

        guard let result else {
            return []
        }

        return [
            trait(label: "Overall symmetry", value: qualitativeLabel(for: result.overallScore - 1), explanation: "The face reads composed when the major planes stay orderly relative to each other."),
            trait(label: "Feature balance", value: qualitativeLabel(for: result.overallScore), explanation: "The strongest global improvement now comes from keeping each feature working in the same direction."),
            trait(label: "Lower-third composition", value: qualitativeLabel(for: result.payload.scores.jaw ?? result.overallScore - 2), explanation: "The lower third has enough structure to keep the read masculine without feeling forced."),
            trait(label: "Presentation coherence", value: qualitativeLabel(for: result.potentialScore), explanation: "The scan suggests the total impression responds well to disciplined routine and cleaner captures.")
        ]
    }

    func sectionTraits(for page: ScanResultsPageID) -> [ScanTraitRowModel] {
        guard let result else {
            return []
        }

        let baseTraits: [ScanTraitRowModel]

        switch page {
        case .eyes:
            baseTraits = traits(
                keywords: ["eye", "brow", "canthal", "orbital", "eyelid"],
                in: combinedFrontProfile()
            ) ?? fallbackTraits(for: .eyes, result: result)
        case .lips:
            baseTraits = traits(
                keywords: ["lip", "mouth", "philtrum", "smile"],
                in: combinedFrontProfile()
            ) ?? fallbackTraits(for: .lips, result: result)
        case .jaw:
            baseTraits = traits(
                keywords: ["jaw", "chin", "mandible", "lower"],
                in: combinedFrontProfile()
            ) ?? fallbackTraits(for: .jaw, result: result)
        case .sideProfile:
            baseTraits = traits(
                keywords: ["side", "profile", "nose", "projection", "convexity", "chin"],
                in: combinedSideProfile()
            ) ?? fallbackTraits(for: .sideProfile, result: result)
        default:
            baseTraits = []
        }

        guard page == .eyes, !isPremium else {
            return baseTraits
        }

        let unlocked = Array(baseTraits.prefix(3))
        let locked = baseTraits.dropFirst(3).map {
            ScanTraitRowModel(
                id: $0.id,
                label: $0.label,
                value: "Premium unlock",
                explanation: "Unlock premium to view the full eye-area read and deeper guidance for this feature.",
                locked: true
            )
        }

        return unlocked + locked
    }

    func photoURL(for sideProfile: Bool) -> URL? {
        guard let raw = sideProfile ? result?.meta.sideUrl : result?.meta.frontUrl else {
            return nil
        }

        return URL(string: raw)
    }

    func primaryDoneTitle() -> String {
        isPremium ? "Open Glow-Up Plan" : "Unlock Full Plan"
    }

    private var completionArchiveTitle: String {
        switch autoSaveState {
        case .saved:
            "Saved to your archive"
        case .localOnly:
            "Stored locally for now"
        case .failed:
            "Result ready to revisit"
        case .idle, .skipped, .syncing:
            "Scan captured"
        }
    }

    private var completionArchiveDetail: String {
        switch autoSaveState {
        case .saved:
            "This scan now lives in your archive, so you can revisit it without losing the reveal."
        case .localOnly:
            "The scan is available on this device, even if archive sync is not active right now."
        case .failed:
            "The result is still available, and you can retry archive sync later from the app."
        case .idle, .skipped, .syncing:
            "Your result is ready to use now and can still be turned into a stronger plan."
        }
    }

    private var shareIdentityLine: String? {
        AIScendSharePayload.identityLine(
            displayName: session.user?.displayName,
            email: session.user?.email ?? result?.meta.email
        )
    }
}

extension ScanResultsViewModel {
    func sharePayload(for page: ScanResultsPageID) -> AIScendSharePayload? {
        guard let result else {
            return nil
        }

        switch page {
        case .overview, .done:
            return .scanResult(from: result, identityLine: shareIdentityLine)
        case .placement:
            return .placement(from: result, identityLine: shareIdentityLine)
        case .eyes, .lips, .jaw, .sideProfile:
            guard let highlight = sectionTraits(for: page).first(where: { !$0.locked }) else {
                return nil
            }

            return .traitHighlight(
                sectionTitle: title(for: page),
                trait: highlight,
                record: result,
                identityLine: shareIdentityLine
            )
        case .harmony:
            guard let highlight = harmonyTraits().first else {
                return nil
            }

            return .traitHighlight(
                sectionTitle: title(for: page),
                trait: highlight,
                record: result,
                identityLine: shareIdentityLine
            )
        case .premiumPush:
            return nil
        }
    }

    func scoreText(_ value: Double) -> String {
        ScanJSONValue.formatted(number: value.rounded())
    }

    func qualitativeLabel(for value: Double) -> String {
        switch value {
        case ..<62:
            "Developing"
        case ..<72:
            "Balanced"
        case ..<82:
            "Strong"
        default:
            "Elite"
        }
    }

    func trait(label: String, value: String, explanation: String, locked: Bool = false) -> ScanTraitRowModel {
        ScanTraitRowModel(
            id: label.lowercased().replacingOccurrences(of: " ", with: "-"),
            label: label,
            value: value,
            explanation: explanation,
            locked: locked
        )
    }

    func traits(
        keywords: [String],
        in source: [String: ScanJSONValue]
    ) -> [ScanTraitRowModel]? {
        let flattened = flatten(source)
        let matches = flattened
            .filter { item in
                let lowered = item.key.lowercased()
                return keywords.contains(where: { lowered.contains($0) })
            }
            .compactMap { makeTraitRow(key: $0.key, value: $0.value) }

        guard !matches.isEmpty else {
            return nil
        }

        return deduplicated(matches)
    }

    func fallbackTraits(
        for page: ScanResultsPageID,
        result: PersistedScanRecord
    ) -> [ScanTraitRowModel] {
        switch page {
        case .eyes:
            return [
                trait(label: "Eye spacing", value: qualitativeLabel(for: result.payload.scores.eyes ?? result.overallScore - 3), explanation: "Spacing is one of the main variables that shapes how calm or intense the face reads."),
                trait(label: "Brow frame", value: qualitativeLabel(for: result.payload.scores.eyes ?? result.overallScore - 1), explanation: "The brow line influences eye presence more than most users expect."),
                trait(label: "Upper lid exposure", value: qualitativeLabel(for: result.overallScore - 2), explanation: "Cleaner upper-lid support helps the eyes read more awake and more composed."),
                trait(label: "Canthal tilt", value: qualitativeLabel(for: result.overallScore - 1), explanation: "Tilt influences how sharp and energised the eyes feel at first glance."),
                trait(label: "Orbital support", value: qualitativeLabel(for: result.potentialScore - 4), explanation: "Orbital structure affects how stable and rested the eye area appears.")
            ]
        case .lips:
            return [
                trait(label: "Lip balance", value: qualitativeLabel(for: result.overallScore - 1), explanation: "Balanced lip proportion keeps the centre face looking composed."),
                trait(label: "Upper lip definition", value: qualitativeLabel(for: result.payload.scores.skin ?? result.overallScore - 4), explanation: "Definition can be lifted through hydration, skin quality, and better contrast."),
                trait(label: "Mouth width", value: qualitativeLabel(for: result.overallScore - 2), explanation: "Width changes how grounded the lower half of the face feels."),
                trait(label: "Philtrum read", value: qualitativeLabel(for: result.potentialScore - 5), explanation: "The philtrum subtly shapes balance through the centre face.")
            ]
        case .jaw:
            return [
                trait(label: "Jaw definition", value: qualitativeLabel(for: result.payload.scores.jaw ?? result.overallScore), explanation: "This is one of the strongest masculine-read levers in the scan."),
                trait(label: "Chin support", value: qualitativeLabel(for: result.payload.scores.jaw ?? result.overallScore - 2), explanation: "Chin support determines how complete the lower third feels."),
                trait(label: "Lower-third balance", value: qualitativeLabel(for: result.payload.scores.jaw ?? result.overallScore - 1), explanation: "A stable lower third helps the whole face read cleaner."),
                trait(label: "Mandible sharpness", value: qualitativeLabel(for: result.potentialScore - 2), explanation: "Sharper angles usually amplify presence when paired with clean body composition.")
            ]
        case .sideProfile:
            return [
                trait(label: "Nasal profile", value: qualitativeLabel(for: result.payload.scores.side ?? result.overallScore - 2), explanation: "Profile harmony depends on nose, chin, and neck line reading together."),
                trait(label: "Chin projection", value: qualitativeLabel(for: result.payload.scores.side ?? result.overallScore - 1), explanation: "Projection controls how supported the profile line feels."),
                trait(label: "Facial convexity", value: qualitativeLabel(for: result.potentialScore - 3), explanation: "Convexity changes whether the profile reads calm, balanced, or over-pronounced."),
                trait(label: "Posture line", value: qualitativeLabel(for: result.overallScore), explanation: "The profile often improves more from posture and capture discipline than from anything else.")
            ]
        default:
            return []
        }
    }

    func combinedFrontProfile() -> [String: ScanJSONValue] {
        result?.payload.frontProfile ?? [:]
    }

    func combinedSideProfile() -> [String: ScanJSONValue] {
        result?.payload.sideProfile ?? [:]
    }

    func flatten(
        _ values: [String: ScanJSONValue],
        prefix: String = ""
    ) -> [(key: String, value: ScanJSONValue)] {
        values.flatMap { key, value in
            let composedKey = prefix.isEmpty ? key : "\(prefix).\(key)"

            if let object = value.objectValue {
                return flatten(object, prefix: composedKey)
            }

            return [(key: composedKey, value: value)]
        }
    }

    func makeTraitRow(key: String, value: ScanJSONValue) -> ScanTraitRowModel? {
        let normalizedLabel = PersistedScanRecord.normalizedLabel(for: key.components(separatedBy: ".").last ?? key)
        let displayValue = value.displayString ?? qualitativeLabel(for: (result?.overallScore ?? 72) - 1)

        let explanation: String
        if let object = value.objectValue {
            explanation = object["description"]?.stringValue
                ?? object["why"]?.stringValue
                ?? object["notes"]?.stringValue
                ?? "AIScend is reading this feature as part of the wider facial presentation, not in isolation."
        } else {
            explanation = "AIScend is reading this feature as part of the wider facial presentation, not in isolation."
        }

        return trait(label: normalizedLabel, value: displayValue, explanation: explanation)
    }

    func deduplicated(_ rows: [ScanTraitRowModel]) -> [ScanTraitRowModel] {
        var seen = Set<String>()
        var unique: [ScanTraitRowModel] = []

        for row in rows {
            if seen.insert(row.id).inserted {
                unique.append(row)
            }
        }

        return unique
    }
}

struct ResultsMetricCardModel: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let value: String
    let detail: String
    let symbol: String
    let accent: RoutineAccent
}

struct ResultsCompletionCardModel: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let detail: String
    let symbol: String
    let accent: RoutineAccent
}
