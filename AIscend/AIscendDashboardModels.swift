//
//  AIscendDashboardModels.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import Foundation

enum DashboardSectionID: Hashable {
    case analytics
    case insights
    case routine
    case scans
    case premium
}

enum DashboardQuickAction: String, CaseIterable, Identifiable {
    case advisor
    case progress
    case routine
    case insights
    case archive
    case refine

    var id: String { rawValue }

    var title: String {
        switch self {
        case .advisor:
            "Advisor"
        case .progress:
            "Progress"
        case .routine:
            "Routine"
        case .insights:
            "Signals"
        case .archive:
            "Archive"
        case .refine:
            "Refine"
        }
    }

    var detail: String {
        switch self {
        case .advisor:
            "AI strategy"
        case .progress:
            "Trend view"
        case .routine:
            "Today"
        case .insights:
            "AI read"
        case .archive:
            "Scan log"
        case .refine:
            "Recalibrate"
        }
    }

    var symbol: String {
        switch self {
        case .advisor:
            "message.fill"
        case .progress:
            "chart.line.uptrend.xyaxis"
        case .routine:
            "square.grid.2x2.fill"
        case .insights:
            "sparkles"
        case .archive:
            "tray.full.fill"
        case .refine:
            "slider.horizontal.3"
        }
    }

    var accent: RoutineAccent {
        switch self {
        case .advisor, .archive:
            .dawn
        case .progress, .insights:
            .sky
        case .routine, .refine:
            .mint
        }
    }
}

struct DashboardTrendPoint: Identifiable {
    let id = UUID()
    let label: String
    let score: Double
}

struct DashboardMetricModel: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let detail: String
    let symbol: String
    let accent: RoutineAccent
}

struct DashboardInsightModel: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let symbol: String
    let accent: RoutineAccent
}

struct DashboardScanPreviewModel: Identifiable {
    let id = UUID()
    let title: String
    let dateLabel: String
    let scoreLabel: String
    let deltaLabel: String
    let captureLabel: String
    let symbol: String
}

struct DashboardSnapshot {
    let score: Int
    let tier: String
    let percentile: Int
    let delta: Double
    let headerSubtitle: String
    let heroStatement: String
    let trendPoints: [DashboardTrendPoint]
    let metrics: [DashboardMetricModel]
    let insights: [DashboardInsightModel]
    let scans: [DashboardScanPreviewModel]
    let streakDays: Int

    static func live(from model: AppModel, now: Date = .now) -> DashboardSnapshot {
        let selectedGoals = model.analysisGoals.isEmpty ? [.overallAttractiveness, .symmetry] : model.analysisGoals
        let primaryGoal = selectedGoals.first ?? .overallAttractiveness
        let secondaryGoal = selectedGoals.dropFirst().first ?? .skin
        let score = derivedScore(from: model, goals: selectedGoals)
        let delta = derivedDelta(score: score, progress: model.progress, goalCount: selectedGoals.count)
        let percentile = derivedPercentile(for: score)
        let streak = max(4, 5 + model.profile.anchors.count + Int(model.progress * 6))
        let points = derivedTrendPoints(score: score, focus: model.profile.focusTrack, now: now)

        return DashboardSnapshot(
            score: score,
            tier: tierTitle(for: score),
            percentile: percentile,
            delta: delta,
            headerSubtitle: headerLine(from: model, primaryGoal: primaryGoal),
            heroStatement: heroLine(from: model, primaryGoal: primaryGoal),
            trendPoints: points,
            metrics: [
                DashboardMetricModel(
                    title: "Routine adherence",
                    value: model.progressLabel,
                    detail: "Completion across today's operating sequence.",
                    symbol: "checkmark.seal.fill",
                    accent: .sky
                ),
                DashboardMetricModel(
                    title: "Monthly shift",
                    value: formattedSigned(delta),
                    detail: "Movement since the last calibrated baseline.",
                    symbol: "arrow.up.right",
                    accent: .dawn
                ),
                DashboardMetricModel(
                    title: "Highest leverage",
                    value: primaryGoal.shortTitle,
                    detail: "The most influential area in the current read.",
                    symbol: primaryGoal.symbol,
                    accent: .mint
                ),
                DashboardMetricModel(
                    title: "Scan cadence",
                    value: "\(max(3, model.profile.anchors.count + selectedGoals.count)) / mo",
                    detail: "Projected baseline frequency at the current tempo.",
                    symbol: "viewfinder.circle.fill",
                    accent: .dawn
                )
            ],
            insights: [
                primaryInsight(for: primaryGoal),
                routineInsight(for: model),
                secondaryInsight(for: secondaryGoal, focus: model.profile.focusTrack)
            ],
            scans: derivedScans(from: points, score: score, delta: delta, now: now),
            streakDays: streak
        )
    }

    static let preview = DashboardSnapshot(
        score: 72,
        tier: "Prime",
        percentile: 11,
        delta: 3.2,
        headerSubtitle: "Your next upgrade starts with consistency.",
        heroStatement: "Jaw definition and skin consistency are currently driving the strongest return.",
        trendPoints: [
            DashboardTrendPoint(label: "May", score: 58),
            DashboardTrendPoint(label: "Jun", score: 61),
            DashboardTrendPoint(label: "Jul", score: 63),
            DashboardTrendPoint(label: "Aug", score: 66),
            DashboardTrendPoint(label: "Sep", score: 69),
            DashboardTrendPoint(label: "Now", score: 72)
        ],
        metrics: [
            DashboardMetricModel(title: "Routine adherence", value: "68%", detail: "Completion across today's operating sequence.", symbol: "checkmark.seal.fill", accent: .sky),
            DashboardMetricModel(title: "Monthly shift", value: "+3.2", detail: "Movement since the last calibrated baseline.", symbol: "arrow.up.right", accent: .dawn),
            DashboardMetricModel(title: "Highest leverage", value: "Jawline", detail: "The most influential area in the current read.", symbol: "triangle.bottomhalf.filled", accent: .mint),
            DashboardMetricModel(title: "Scan cadence", value: "4 / mo", detail: "Projected baseline frequency at the current tempo.", symbol: "viewfinder.circle.fill", accent: .dawn)
        ],
        insights: [
            DashboardInsightModel(title: "Jaw definition is still the clearest lever", detail: "Lower-face structure is currently shaping first impression more than any other variable.", symbol: "triangle.bottomhalf.filled", accent: .sky),
            DashboardInsightModel(title: "Routine adherence is now visible in the read", detail: "Consistency is doing more work than intensity. Keep the cadence clean.", symbol: "checkmark.seal.fill", accent: .mint),
            DashboardInsightModel(title: "Hair framing is amplifying overall balance", detail: "Presentation shifts are making the face read more structured before fine-detail improvements.", symbol: "scissors", accent: .dawn)
        ],
        scans: [
            DashboardScanPreviewModel(title: "Latest baseline", dateLabel: "08 Apr", scoreLabel: "72", deltaLabel: "+1.8", captureLabel: "Controlled lighting", symbol: "camera.aperture"),
            DashboardScanPreviewModel(title: "Three weeks ago", dateLabel: "19 Mar", scoreLabel: "69", deltaLabel: "+2.4", captureLabel: "Front + profile", symbol: "viewfinder"),
            DashboardScanPreviewModel(title: "First quarter marker", dateLabel: "24 Feb", scoreLabel: "65", deltaLabel: "+1.6", captureLabel: "Neutral capture", symbol: "sparkles")
        ],
        streakDays: 12
    )
}

private extension DashboardSnapshot {
    static func derivedScore(from model: AppModel, goals: [AnalysisGoal]) -> Int {
        let goalWeight = goals.count * 3
        let anchorWeight = model.profile.anchors.count * 2
        let focusWeight: Int

        switch model.profile.focusTrack {
        case .momentum:
            focusWeight = 2
        case .mastery:
            focusWeight = 4
        case .balance:
            focusWeight = 3
        }

        let raw = 58 + goalWeight + anchorWeight + focusWeight + Int(model.progress * 14)
        return max(52, min(91, raw))
    }

    static func derivedDelta(score: Int, progress: Double, goalCount: Int) -> Double {
        let raw = 1.1 + Double(goalCount) * 0.55 + progress * 2.8 + Double(score - 60) * 0.025
        return (raw * 10).rounded() / 10
    }

    static func derivedPercentile(for score: Int) -> Int {
        max(4, 29 - Int(Double(score - 56) * 0.62))
    }

    static func tierTitle(for score: Int) -> String {
        switch score {
        case ..<62:
            "Foundation"
        case ..<70:
            "Ascent"
        case ..<80:
            "Prime"
        default:
            "Sovereign"
        }
    }

    static func headerLine(from model: AppModel, primaryGoal: AnalysisGoal) -> String {
        if model.nextOpenStep != nil {
            return "Your next upgrade starts with consistency."
        }

        return "\(primaryGoal.shortTitle) is stabilising. Measured gains are beginning to compound."
    }

    static func heroLine(from model: AppModel, primaryGoal: AnalysisGoal) -> String {
        let secondaryText: String
        switch primaryGoal {
        case .jawline:
            secondaryText = "Lower-face definition remains the most influential variable in the current read."
        case .skin:
            secondaryText = "Surface quality is now shaping the overall presentation more than isolated changes."
        case .eyes:
            secondaryText = "Eye-area sharpness is controlling how awake and composed the face reads."
        case .hair:
            secondaryText = "Hair framing is affecting balance and perceived structure more than expected."
        case .symmetry:
            secondaryText = "Balance and alignment remain the cleanest route to a stronger overall impression."
        case .overallAttractiveness:
            secondaryText = "Global presentation is being lifted most by consistency, not scattered changes."
        }

        if let nextStep = model.nextOpenStep {
            return "\(secondaryText) Next move: \(nextStep.title.lowercased())."
        }

        return secondaryText
    }

    static func derivedTrendPoints(score: Int, focus: FocusTrack, now: Date) -> [DashboardTrendPoint] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        let offsets: [Double]
        switch focus {
        case .momentum:
            offsets = [-11, -8.5, -6.3, -4.4, -2.4, 0]
        case .mastery:
            offsets = [-9.5, -7.8, -5.9, -4.3, -2.9, 0]
        case .balance:
            offsets = [-8.6, -7.1, -5.8, -4.1, -2.3, 0]
        }

        return offsets.enumerated().map { index, offset in
            let date = Calendar.current.date(byAdding: .month, value: index - 5, to: now) ?? now
            let label = index == offsets.count - 1 ? "Now" : formatter.string(from: date)
            let value = max(48, min(94, Double(score) + offset))
            return DashboardTrendPoint(label: label, score: value)
        }
    }

    static func derivedScans(from points: [DashboardTrendPoint], score: Int, delta: Double, now: Date) -> [DashboardScanPreviewModel] {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"

        let dates = [
            now,
            Calendar.current.date(byAdding: .day, value: -20, to: now) ?? now,
            Calendar.current.date(byAdding: .day, value: -43, to: now) ?? now
        ]
        let titles = ["Latest baseline", "Three weeks ago", "First quarter marker"]
        let captureLabels = ["Controlled lighting", "Front + profile", "Neutral capture"]
        let symbols = ["camera.aperture", "viewfinder", "sparkles"]
        let values = [
            score,
            Int((points.dropLast().last?.score ?? Double(score - 3)).rounded()),
            Int((points.dropLast(2).last?.score ?? Double(score - 6)).rounded())
        ]
        let deltas = [delta, max(delta - 0.8, 0.9), max(delta - 1.4, 0.6)]

        return zip(zip(zip(titles, dates), zip(values, deltas)), zip(captureLabels, symbols)).map { payload, meta in
            let titleAndDate = payload.0
            let scoreAndDelta = payload.1
            return DashboardScanPreviewModel(
                title: titleAndDate.0,
                dateLabel: formatter.string(from: titleAndDate.1),
                scoreLabel: "\(scoreAndDelta.0)",
                deltaLabel: formattedSigned(scoreAndDelta.1),
                captureLabel: meta.0,
                symbol: meta.1
            )
        }
    }

    static func primaryInsight(for goal: AnalysisGoal) -> DashboardInsightModel {
        switch goal {
        case .jawline:
            DashboardInsightModel(
                title: "Jaw definition is still the clearest lever",
                detail: "Lower-face structure is currently shaping first impression more than any other variable.",
                symbol: goal.symbol,
                accent: .sky
            )
        case .skin:
            DashboardInsightModel(
                title: "Skin consistency is doing visible work",
                detail: "Surface quality is lifting the total read faster than more dramatic interventions.",
                symbol: goal.symbol,
                accent: .mint
            )
        case .eyes:
            DashboardInsightModel(
                title: "Eye support is controlling perceived sharpness",
                detail: "Sleep, hydration, and brow discipline are still disproportionately influential.",
                symbol: goal.symbol,
                accent: .sky
            )
        case .hair:
            DashboardInsightModel(
                title: "Hair framing is amplifying balance",
                detail: "Shape and density perception are supporting the face before finer-detail work lands.",
                symbol: goal.symbol,
                accent: .dawn
            )
        case .symmetry:
            DashboardInsightModel(
                title: "Symmetry is quietly multiplying the gain",
                detail: "Angles, posture, and clean captures are making the overall read feel more ordered.",
                symbol: goal.symbol,
                accent: .mint
            )
        case .overallAttractiveness:
            DashboardInsightModel(
                title: "Global presentation is lifting",
                detail: "The total facial read is being improved most by consistency rather than isolated tweaks.",
                symbol: goal.symbol,
                accent: .sky
            )
        }
    }

    static func routineInsight(for model: AppModel) -> DashboardInsightModel {
        let detail: String
        if model.progress >= 0.66 {
            detail = "Daily discipline is now visible in the read. Maintain the current cadence."
        } else if model.progress >= 0.33 {
            detail = "Consistency is starting to register, but the operating rhythm still has space to tighten."
        } else {
            detail = "The system is set correctly. The next gain depends on repeatable execution, not more inputs."
        }

        return DashboardInsightModel(
            title: "Routine adherence is shaping the outcome",
            detail: detail,
            symbol: "checkmark.seal.fill",
            accent: .mint
        )
    }

    static func secondaryInsight(for goal: AnalysisGoal, focus: FocusTrack) -> DashboardInsightModel {
        let detail: String

        switch focus {
        case .momentum:
            detail = "\(goal.shortTitle) is most likely to respond to fast, visible consistency over the next cycle."
        case .mastery:
            detail = "\(goal.shortTitle) is improving more through quieter, higher-quality repetition than brute force."
        case .balance:
            detail = "\(goal.shortTitle) is benefiting from lower noise, steadier sleep, and cleaner daily structure."
        }

        return DashboardInsightModel(
            title: "\(goal.title) remains strategically important",
            detail: detail,
            symbol: goal.symbol,
            accent: .dawn
        )
    }

    static func formattedSigned(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", value))"
    }
}
