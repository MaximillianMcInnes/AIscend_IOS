//
//  GlowUpComparisonEngine.swift
//  AIscend
//

import Foundation

enum GlowUpComparisonEngine {
    static func timeline(from records: [PersistedScanRecord]) -> [GlowUpTimelineScan] {
        records
            .filter(\.isDisplayable)
            .map(makeTimelineScan(from:))
            .sorted { $0.date > $1.date }
    }

    static func comparison(
        from records: [PersistedScanRecord],
        range: GlowUpComparisonRange,
        calendar: Calendar = .current
    ) -> GlowUpComparison? {
        let scans = timeline(from: records)
        guard scans.count >= 2, let latest = scans.first else {
            return nil
        }

        let baseline: GlowUpTimelineScan?
        switch range {
        case .latestPrevious:
            baseline = scans.dropFirst().first
        case .thirtyDays, .ninetyDays:
            if let days = range.lookbackDays,
               let startDate = calendar.date(byAdding: .day, value: -days, to: latest.date)
            {
                let window = scans.filter { $0.date >= startDate }
                baseline = window.count >= 2 ? window.last : scans.dropFirst().first
            } else {
                baseline = scans.dropFirst().first
            }
        case .allTime:
            baseline = scans.last
        }

        guard let baseline else {
            return nil
        }

        let metricDeltas = GlowUpMetricID.allCases.map { metric in
            delta(for: metric, baseline: baseline.record, latest: latest.record)
        }
        let overallDelta = pairedDelta(previous: baseline.score, latest: latest.score)
        let summary = makeSummary(overallDelta: overallDelta, metricDeltas: metricDeltas)

        return GlowUpComparison(
            latest: latest,
            baseline: baseline,
            metricDeltas: metricDeltas,
            overallDelta: overallDelta,
            summary: summary
        )
    }

    static func makeTimelineScan(from record: PersistedScanRecord) -> GlowUpTimelineScan {
        let date = record.savedAt ?? .distantPast
        return GlowUpTimelineScan(
            id: archiveIdentifier(for: record),
            date: date,
            score: sanitizedScore(record.payload.scores.overall ?? record.payload.scores.potential),
            tier: record.tierTitle,
            frontImageRawValue: record.meta.frontUrl,
            sideImageRawValue: record.meta.sideUrl,
            record: record
        )
    }

    private static func delta(
        for metricID: GlowUpMetricID,
        baseline: PersistedScanRecord,
        latest: PersistedScanRecord
    ) -> GlowUpMetricDelta {
        let previous = snapshot(for: metricID, in: baseline)
        let current = snapshot(for: metricID, in: latest)
        let delta = pairedDelta(previous: previous.value, latest: current.value)
        let state = state(for: delta)

        return GlowUpMetricDelta(
            metricID: metricID,
            title: metricID.title,
            symbol: metricID.symbol,
            previousValue: previous.value,
            latestValue: current.value,
            delta: delta,
            state: state,
            narrative: narrative(for: metricID, state: state, delta: delta, latestQualitativeValue: current.qualitativeValue)
        )
    }

    private static func snapshot(for metricID: GlowUpMetricID, in record: PersistedScanRecord) -> GlowUpMetricSnapshot {
        let value: Double?
        let qualitative: String?

        switch metricID {
        case .skinClarity:
            value = record.payload.scores.skin
                ?? nestedNumber(in: record.payload.frontProfile, keys: ["skin", "skin_clarity", "skin_quality", "complexion"])
            qualitative = nestedString(in: record.payload.frontProfile, keys: ["skin", "skin_clarity", "skin_quality", "complexion"])
        case .jawVisibility:
            value = record.payload.scores.jaw
                ?? nestedNumber(in: record.payload.frontProfile, keys: ["jaw", "jaw_definition", "jaw_visibility", "lower_third"])
            qualitative = nestedString(in: record.payload.frontProfile, keys: ["jaw", "jaw_definition", "jaw_visibility", "lower_third"])
        case .eyeArea:
            value = record.payload.scores.eyes
                ?? nestedNumber(in: record.payload.frontProfile, keys: ["eyes", "eye_area", "orbital_support", "canthal_tilt"])
            qualitative = nestedString(in: record.payload.frontProfile, keys: ["eyes", "eye_area", "orbital_support", "canthal_tilt"])
        case .facialHarmony:
            value = nestedNumber(in: record.payload.frontProfile, keys: ["facial_harmony", "harmony", "facial_balance"])
                ?? record.payload.scores.overall
            qualitative = nestedString(in: record.payload.frontProfile, keys: ["facial_harmony", "harmony", "facial_balance"])
        case .symmetry:
            value = nestedNumber(in: record.payload.frontProfile, keys: ["symmetry", "symmetry_read", "facial_symmetry"])
            qualitative = nestedString(in: record.payload.frontProfile, keys: ["symmetry", "symmetry_read", "facial_symmetry"])
        case .postureSideProfile:
            value = record.payload.scores.side
                ?? nestedNumber(in: record.payload.sideProfile, keys: ["side_profile", "profile_projection", "neckline_posture", "facial_convexity"])
            qualitative = nestedString(in: record.payload.sideProfile, keys: ["side_profile", "profile_projection", "neckline_posture", "facial_convexity"])
        }

        return GlowUpMetricSnapshot(
            id: metricID,
            title: metricID.title,
            value: sanitizedScore(value),
            qualitativeValue: qualitative
        )
    }

    private static func nestedNumber(in object: [String: ScanJSONValue], keys: [String]) -> Double? {
        for key in keys {
            if let direct = object[key]?.numberValue {
                return direct
            }

            if let nested = object[key]?.objectValue {
                for nestedKey in ["score", "value", "rating"] {
                    if let value = nested[nestedKey]?.numberValue {
                        return value
                    }
                }
            }
        }

        return nil
    }

    private static func nestedString(in object: [String: ScanJSONValue], keys: [String]) -> String? {
        for key in keys {
            if let direct = object[key]?.displayString {
                return direct
            }

            if let nested = object[key]?.objectValue {
                for nestedKey in ["value", "label", "rating", "status", "description"] {
                    if let value = nested[nestedKey]?.displayString {
                        return value
                    }
                }
            }
        }

        return nil
    }

    private static func pairedDelta(previous: Double?, latest: Double?) -> Double? {
        guard let previous, let latest, previous.isFinite, latest.isFinite else {
            return nil
        }

        return latest - previous
    }

    private static func state(for delta: Double?) -> GlowUpDeltaState {
        guard let delta else {
            return .insufficientData
        }

        if delta >= 1 {
            return .improved
        }

        if delta <= -1 {
            return .declined
        }

        return .stable
    }

    private static func narrative(
        for metricID: GlowUpMetricID,
        state: GlowUpDeltaState,
        delta: Double?,
        latestQualitativeValue: String?
    ) -> String {
        if let delta {
            let magnitude = String(format: "%.1f", abs(delta))
            switch state {
            case .improved:
                return "\(metricID.title) appears up \(magnitude) pts versus the comparison scan, based on available scan data."
            case .declined:
                return "\(metricID.title) may be reading \(magnitude) pts lower. Treat this as a signal to review lighting, recovery, grooming, and consistency."
            case .stable:
                return "\(metricID.title) is essentially stable between these scans, which can be useful when routine inputs are consistent."
            case .insufficientData:
                break
            }
        }

        if let latestQualitativeValue {
            return "Latest scan note: \(latestQualitativeValue). Numeric movement is limited for this area."
        }

        return "AIScend does not have enough consistent signal to compare this area yet."
    }

    private static func makeSummary(
        overallDelta: Double?,
        metricDeltas: [GlowUpMetricDelta]
    ) -> GlowUpProgressSummary {
        let numericDeltas = metricDeltas.compactMap { item -> (GlowUpMetricDelta, Double)? in
            guard let delta = item.delta else { return nil }
            return (item, delta)
        }

        let best = numericDeltas.max { lhs, rhs in lhs.1 < rhs.1 }?.0
        let attention = numericDeltas.min { lhs, rhs in lhs.1 < rhs.1 }?.0

        let trend: String
        if let overallDelta {
            if overallDelta >= 1 {
                trend = "Latest scan appears to be trending upward by \(String(format: "%.1f", overallDelta)) pts."
            } else if overallDelta <= -1 {
                trend = "Latest scan is reading \(String(format: "%.1f", abs(overallDelta))) pts lower than the comparison scan."
            } else {
                trend = "Overall read is stable across the selected comparison."
            }
        } else {
            trend = "Overall trend needs another consistent scan to read cleanly."
        }

        return GlowUpProgressSummary(
            overallTrend: trend,
            bestImprovedArea: best?.title ?? "No clear leader yet",
            areaNeedingAttention: attention?.title ?? "No clear weak point yet",
            consistencyNote: "Compare scans taken under similar lighting, angle, sleep, and grooming conditions for the cleanest read."
        )
    }

    private static func sanitizedScore(_ score: Double?) -> Double? {
        guard let score, score.isFinite else {
            return nil
        }

        return min(max(score, 0), 100)
    }

    private static func archiveIdentifier(for record: PersistedScanRecord) -> String {
        if let scanID = record.meta.scanId?.trimmedNonEmpty {
            return scanID
        }

        return record.archiveFingerprint
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

