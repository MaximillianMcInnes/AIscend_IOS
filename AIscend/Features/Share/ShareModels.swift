//
//  ShareModels.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import Foundation

enum AIScendShareContentType: String, CaseIterable, Identifiable, Hashable, Sendable {
    case scanResult
    case placement
    case traitHighlight
    case streakMilestone
    case badgeUnlock
    case routineProgress

    var id: String { rawValue }
}

enum AIScendShareTemplate: String, CaseIterable, Identifiable, Hashable, Sendable {
    case obsidian
    case precision
    case signal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .obsidian:
            "Obsidian"
        case .precision:
            "Precision"
        case .signal:
            "Signal"
        }
    }

    var subtitle: String {
        switch self {
        case .obsidian:
            "Cinematic score-first flex"
        case .precision:
            "Sharper status-card layout"
        case .signal:
            "Minimal premium story card"
        }
    }
}

enum AIScendSharePrivacyMode: String, CaseIterable, Identifiable, Hashable, Sendable {
    case privateMode
    case minimal
    case named

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privateMode:
            "Private"
        case .minimal:
            "Minimal"
        case .named:
            "Named"
        }
    }

    var subtitle: String {
        switch self {
        case .privateMode:
            "Hide identity, keep the flex"
        case .minimal:
            "Hide identity and soften details"
        case .named:
            "Include your account signature"
        }
    }

    var showsIdentity: Bool {
        self == .named
    }

    var redactsSecondaryMetrics: Bool {
        self == .minimal
    }
}

struct AIScendShareMetric: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let value: String
    let detail: String

    init(
        id: String,
        title: String,
        value: String,
        detail: String
    ) {
        self.id = id
        self.title = title
        self.value = value
        self.detail = detail
    }
}

struct AIScendSharePayload: Identifiable, Hashable, Sendable {
    let id: String
    let contentType: AIScendShareContentType
    let eyebrow: String
    let title: String
    let subtitle: String
    let heroValue: String
    let heroSuffix: String?
    let heroRedaction: String?
    let supportingLine: String
    let callout: String?
    let footer: String
    let symbol: String
    let accent: RoutineAccent
    let identityLine: String?
    let metrics: [AIScendShareMetric]
    let recommendedTemplate: AIScendShareTemplate
    let availableTemplates: [AIScendShareTemplate]
    let shareCaption: String

    func displayedHeroValue(for privacy: AIScendSharePrivacyMode) -> String {
        if privacy == .minimal, let heroRedaction, !heroRedaction.isEmpty {
            return heroRedaction
        }

        return heroValue
    }

    func displayedHeroSuffix(for privacy: AIScendSharePrivacyMode) -> String? {
        if privacy == .minimal, heroRedaction != nil {
            return nil
        }

        return heroSuffix
    }

    func displayedIdentity(for privacy: AIScendSharePrivacyMode) -> String? {
        guard privacy.showsIdentity else {
            return nil
        }

        return identityLine
    }

    func displayedMetrics(for privacy: AIScendSharePrivacyMode) -> [AIScendShareMetric] {
        if privacy.redactsSecondaryMetrics {
            return Array(metrics.prefix(2))
        }

        return metrics
    }
}

extension AIScendSharePayload {
    static func identityLine(displayName: String? = nil, email: String? = nil) -> String? {
        let cleanedName = displayName?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let cleanedName, !cleanedName.isEmpty {
            return cleanedName
        }

        let cleanedEmail = email?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if let cleanedEmail, !cleanedEmail.isEmpty {
            return cleanedEmail
        }

        return nil
    }

    static func scanResult(
        from record: PersistedScanRecord,
        identityLine: String? = nil
    ) -> AIScendSharePayload {
        let overall = ScanJSONValue.formatted(number: record.overallScore.rounded())
        let potential = ScanJSONValue.formatted(number: record.potentialScore.rounded())

        return AIScendSharePayload(
            id: "scan-result-\(record.saveFingerprint)",
            contentType: .scanResult,
            eyebrow: "Scan Result",
            title: "\(record.tierTitle) read",
            subtitle: record.headline,
            heroValue: overall,
            heroSuffix: "/100",
            heroRedaction: record.tierTitle,
            supportingLine: "Top \(record.percentile)% placement",
            callout: record.accessLevel == .premium ? "Full report active" : "Preview report active",
            footer: "AIScend // Private analysis",
            symbol: "sparkles.rectangle.stack.fill",
            accent: .sky,
            identityLine: identityLine,
            metrics: [
                AIScendShareMetric(
                    id: "placement",
                    title: "Placement",
                    value: "Top \(record.percentile)%",
                    detail: "Current standing"
                ),
                AIScendShareMetric(
                    id: "potential",
                    title: "Potential",
                    value: potential,
                    detail: "Visible upside"
                ),
                AIScendShareMetric(
                    id: "tier",
                    title: "Class",
                    value: record.tierTitle,
                    detail: "AIScend band"
                ),
                AIScendShareMetric(
                    id: "access",
                    title: "Layer",
                    value: record.accessLevel == .premium ? "Premium" : "Preview",
                    detail: "Report depth"
                )
            ],
            recommendedTemplate: .obsidian,
            availableTemplates: [.obsidian, .precision, .signal],
            shareCaption: "AIScend read: \(record.tierTitle), top \(record.percentile)% placement, \(overall)/100 overall."
        )
    }

    static func placement(
        from record: PersistedScanRecord,
        identityLine: String? = nil
    ) -> AIScendSharePayload {
        AIScendSharePayload(
            id: "placement-\(record.saveFingerprint)",
            contentType: .placement,
            eyebrow: "Placement",
            title: "Current position",
            subtitle: record.placementNarrative,
            heroValue: "\(record.percentile)",
            heroSuffix: "% top",
            heroRedaction: record.tierTitle,
            supportingLine: "\(record.tierTitle) tier with visible upside still open",
            callout: "AIScend contextualises the read, not just the score",
            footer: "AIScend // Quiet leverage compounds",
            symbol: "scope",
            accent: .dawn,
            identityLine: identityLine,
            metrics: [
                AIScendShareMetric(
                    id: "tier",
                    title: "Class",
                    value: record.tierTitle,
                    detail: "Current band"
                ),
                AIScendShareMetric(
                    id: "overall",
                    title: "Overall",
                    value: ScanJSONValue.formatted(number: record.overallScore.rounded()),
                    detail: "Global read"
                ),
                AIScendShareMetric(
                    id: "upside",
                    title: "Upside",
                    value: ScanJSONValue.formatted(number: (record.potentialScore - record.overallScore).rounded()),
                    detail: "Still available"
                )
            ],
            recommendedTemplate: .precision,
            availableTemplates: [.precision, .obsidian, .signal],
            shareCaption: "AIScend placement: top \(record.percentile)% in the \(record.tierTitle) band."
        )
    }

    static func traitHighlight(
        sectionTitle: String,
        trait: ScanTraitRowModel,
        record: PersistedScanRecord?,
        identityLine: String? = nil
    ) -> AIScendSharePayload {
        AIScendSharePayload(
            id: "trait-\(sectionTitle.lowercased())-\(trait.id)",
            contentType: .traitHighlight,
            eyebrow: sectionTitle,
            title: trait.label,
            subtitle: trait.explanation,
            heroValue: trait.value,
            heroSuffix: nil,
            heroRedaction: sectionTitle,
            supportingLine: trait.locked ? "Premium insight preview" : "Highlighted from the current AIScend read",
            callout: record.map { "\($0.tierTitle) tier // top \($0.percentile)%" },
            footer: "AIScend // Feature highlight",
            symbol: "eye.fill",
            accent: trait.locked ? .dawn : .mint,
            identityLine: identityLine,
            metrics: [
                AIScendShareMetric(
                    id: "section",
                    title: "Section",
                    value: sectionTitle,
                    detail: "Current focus"
                ),
                AIScendShareMetric(
                    id: "access",
                    title: "Access",
                    value: trait.locked ? "Premium" : "Visible",
                    detail: "Insight state"
                ),
                AIScendShareMetric(
                    id: "overall",
                    title: "Result",
                    value: record.map { ScanJSONValue.formatted(number: $0.overallScore.rounded()) } ?? "--",
                    detail: "Overall read"
                )
            ],
            recommendedTemplate: .signal,
            availableTemplates: [.signal, .precision, .obsidian],
            shareCaption: "AIScend highlight: \(trait.label) is reading \(trait.value.lowercased())."
        )
    }

    static func streakMilestone(
        snapshot: StreakSnapshot,
        identityLine: String? = nil
    ) -> AIScendSharePayload {
        AIScendSharePayload(
            id: "streak-\(snapshot.currentStreak)-\(snapshot.totalCheckIns)",
            contentType: .streakMilestone,
            eyebrow: "Consistency",
            title: "Chain protected",
            subtitle: snapshot.motivationalLine,
            heroValue: "\(max(snapshot.currentStreak, 0))",
            heroSuffix: "days",
            heroRedaction: snapshot.currentStreak >= 7 ? "Locked In" : "Consistent",
            supportingLine: "\(snapshot.totalCheckIns) check-ins logged so far",
            callout: snapshot.checkedInToday ? "Today's accountability is closed" : "Today's check-in is still open",
            footer: "AIScend // Discipline compounds",
            symbol: "flame.fill",
            accent: .mint,
            identityLine: identityLine,
            metrics: [
                AIScendShareMetric(
                    id: "best",
                    title: "Best",
                    value: "\(snapshot.bestStreak)d",
                    detail: "Record run"
                ),
                AIScendShareMetric(
                    id: "next",
                    title: "Next",
                    value: "\(snapshot.nextMilestone)d",
                    detail: "Milestone"
                ),
                AIScendShareMetric(
                    id: "today",
                    title: "Today",
                    value: snapshot.checkedInToday ? "Locked" : "Open",
                    detail: "Status"
                )
            ],
            recommendedTemplate: .signal,
            availableTemplates: [.signal, .obsidian, .precision],
            shareCaption: "AIScend streak: \(snapshot.currentStreak) days and still climbing."
        )
    }

    static func badgeUnlock(
        badge: AIScendBadge,
        totalBadges: Int,
        currentStreak: Int,
        identityLine: String? = nil
    ) -> AIScendSharePayload {
        AIScendSharePayload(
            id: "badge-\(badge.id.rawValue)-\(totalBadges)-\(currentStreak)",
            contentType: .badgeUnlock,
            eyebrow: "Badge Unlock",
            title: badge.title,
            subtitle: badge.detail,
            heroValue: "Unlocked",
            heroSuffix: nil,
            heroRedaction: "Status",
            supportingLine: "\(totalBadges) AIScend markers earned",
            callout: currentStreak > 0 ? "\(currentStreak)-day streak currently active" : nil,
            footer: "AIScend // Quiet status markers",
            symbol: badge.symbol,
            accent: badge.accent,
            identityLine: identityLine,
            metrics: [
                AIScendShareMetric(
                    id: "badge",
                    title: "Marker",
                    value: badge.title,
                    detail: "Unlocked now"
                ),
                AIScendShareMetric(
                    id: "vault",
                    title: "Vault",
                    value: "\(totalBadges)",
                    detail: "Earned total"
                ),
                AIScendShareMetric(
                    id: "streak",
                    title: "Streak",
                    value: currentStreak > 0 ? "\(currentStreak)d" : "--",
                    detail: "Current run"
                )
            ],
            recommendedTemplate: .precision,
            availableTemplates: [.precision, .signal, .obsidian],
            shareCaption: "AIScend badge unlocked: \(badge.title)."
        )
    }

    static func routineProgress(
        progress: Double,
        streakDays: Int,
        nextStep: RoutineStep?,
        identityLine: String? = nil
    ) -> AIScendSharePayload {
        let progressPercent = max(0, min(Int((progress * 100).rounded()), 100))

        return AIScendSharePayload(
            id: "routine-\(progressPercent)-\(streakDays)-\(nextStep?.id ?? "none")",
            contentType: .routineProgress,
            eyebrow: "Routine Progress",
            title: "Execution stays visible",
            subtitle: nextStep?.detail ?? "Today's operating layer is moving cleanly enough to keep compounding.",
            heroValue: "\(progressPercent)",
            heroSuffix: "%",
            heroRedaction: streakDays >= 7 ? "Locked In" : "In Motion",
            supportingLine: nextStep.map { "Next move: \($0.title)" } ?? "Today's routine is fully closed",
            callout: streakDays > 0 ? "\(streakDays)-day control streak active" : "Resetting today's cadence",
            footer: "AIScend // Routine before noise",
            symbol: "checkmark.seal.fill",
            accent: .sky,
            identityLine: identityLine,
            metrics: [
                AIScendShareMetric(
                    id: "streak",
                    title: "Streak",
                    value: "\(max(streakDays, 0))d",
                    detail: "Current run"
                ),
                AIScendShareMetric(
                    id: "next-step",
                    title: "Next",
                    value: nextStep?.title ?? "Closed",
                    detail: "Highest leverage move"
                ),
                AIScendShareMetric(
                    id: "system",
                    title: "System",
                    value: progressPercent >= 70 ? "Controlled" : "Building",
                    detail: "Execution state"
                )
            ],
            recommendedTemplate: .obsidian,
            availableTemplates: [.obsidian, .precision, .signal],
            shareCaption: "AIScend routine progress: \(progressPercent)% complete with a \(streakDays)-day streak."
        )
    }
}
