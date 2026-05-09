//
//  ChartSection.swift
//  AIscend
//

import Charts
import SwiftUI

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

struct DashboardScanTrendPoint: Identifiable {
    let id = UUID()
    let label: String
    let actual: Double?
    let predicted: Double?
}

struct DashboardScanTrendModel {
    let points: [DashboardScanTrendPoint]
    let scanCount: Int
    let latestScore: Double

    var bestScore: Double {
        points.compactMap(\.actual).max() ?? latestScore
    }

    var highlightedPoint: DashboardScanTrendPoint {
        points.last(where: { $0.actual != nil })
            ?? points.first(where: { $0.predicted != nil })
            ?? DashboardScanTrendPoint(label: "Now", actual: latestScore, predicted: nil)
    }

    var highlightedScore: Double {
        highlightedPoint.actual ?? highlightedPoint.predicted ?? latestScore
    }

    var predictedScore: Double {
        points.last(where: { $0.predicted != nil })?.predicted
            ?? highlightedScore
    }

    static func fallback(from snapshot: DashboardSnapshot) -> DashboardScanTrendModel {
        let actualPoints = snapshot.trendPoints.map {
            DashboardScanTrendPoint(label: $0.label, actual: $0.score, predicted: nil)
        }
        let latestScore = Double(snapshot.score)
        let target = min(95, latestScore + max(4, snapshot.delta * 1.45))
        let forecastLabels = ["+1m", "+2m", "+3m", "+4m", "+5m", "+6m"]
        let forecastPoints = forecastLabels.enumerated().map { index, label in
            let progress = Double(index + 1) / Double(forecastLabels.count)
            let eased = 1 - pow(1 - progress, 1.45)
            return DashboardScanTrendPoint(
                label: label,
                actual: nil,
                predicted: latestScore + (target - latestScore) * eased
            )
        }

        return DashboardScanTrendModel(
            points: actualPoints + forecastPoints,
            scanCount: snapshot.scans.count,
            latestScore: latestScore
        )
    }
}

enum DashboardScanTrendPhase {
    case idle
    case loading
    case loaded(DashboardScanTrendModel)
    case empty
    case failed(String)
}

@MainActor
final class DashboardScanTrendStore: ObservableObject {
    @Published private(set) var phase: DashboardScanTrendPhase = .idle

    #if canImport(FirebaseFirestore)
    private let firestore: Firestore
    #endif

    init() {
        #if canImport(FirebaseFirestore)
        self.firestore = Firestore.firestore()
        #endif
    }

    func loadScans(for user: SessionUser?) async {
        guard let user else {
            phase = .empty
            return
        }

        phase = .loading

        do {
            #if canImport(FirebaseFirestore)
            let scans = try await fetchScanPoints(for: user)
            guard let model = DashboardScanTrendBuilder.model(from: scans) else {
                phase = .empty
                return
            }
            phase = .loaded(model)
            #else
            phase = .empty
            #endif
        } catch {
            let message = (error as NSError).localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            phase = .failed(message.isEmpty ? "AIScend could not load your scan trend right now." : message)
        }
    }

    #if canImport(FirebaseFirestore)
    private func fetchScanPoints(for user: SessionUser) async throws -> [DashboardRawScanPoint] {
        var documentsByID: [String: QueryDocumentSnapshot] = [:]

        let uidSnapshot = try await firestore
            .collection("Scans")
            .whereField("ownerUid", isEqualTo: user.id)
            .getDocuments()

        for document in uidSnapshot.documents {
            documentsByID[document.documentID] = document
        }

        if let email = user.email?.trimmingCharacters(in: .whitespacesAndNewlines),
           !email.isEmpty
        {
            let emailCandidates = Set([email, email.lowercased()])
            for emailCandidate in emailCandidates {
                let emailSnapshot = try await firestore
                    .collection("Scans")
                    .whereField("email", isEqualTo: emailCandidate)
                    .getDocuments()

                for document in emailSnapshot.documents {
                    documentsByID[document.documentID] = document
                }
            }
        }

        let rawDocuments = Array(documentsByID.values)
        let today = Date()

        return rawDocuments.enumerated().compactMap { index, document in
            let object = document.data()
            guard let score = DashboardScanTrendBuilder.score(from: object) else {
                return nil
            }

            let date = DashboardScanTrendBuilder.date(from: object)
                ?? Calendar.current.date(
                    byAdding: .day,
                    value: -(rawDocuments.count - 1 - index) * 7,
                    to: today
                )
                ?? today

            return DashboardRawScanPoint(date: date, score: score)
        }
        .sorted { $0.date < $1.date }
    }
    #endif
}

private struct DashboardRawScanPoint {
    let date: Date
    let score: Double
}

private enum DashboardScanTrendBuilder {
    private static let calendar = Calendar(identifier: .gregorian)

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()

    static func model(from scans: [DashboardRawScanPoint]) -> DashboardScanTrendModel? {
        let sortedScans = scans.sorted { $0.date < $1.date }
        guard sortedScans.count >= 2, let firstScan = sortedScans.first, let lastScan = sortedScans.last else {
            return nil
        }

        let now = Date()
        let nowKey = monthKey(for: now)
        let endKey = yearEndKey(for: now)
        let firstKey = monthKey(for: firstScan.date)
        let monthKeys = keysBetween(startKey: firstKey, endKey: endKey)
        let grouped = Dictionary(grouping: sortedScans, by: { monthKey(for: $0.date) })
        let lastActualKey = monthKey(for: lastScan.date)

        let basePoints = monthKeys.map { key in
            let scores = grouped[key]?.map(\.score) ?? []
            let average = scores.isEmpty ? nil : scores.reduce(0, +) / Double(scores.count)
            return DashboardScanTrendPoint(
                label: monthLabel(from: key),
                actual: key <= nowKey ? average : nil,
                predicted: nil
            )
        }

        guard let lastActualIndex = monthKeys.lastIndex(where: { $0 <= min(nowKey, lastActualKey) && grouped[$0]?.isEmpty == false }) else {
            return nil
        }

        let lastActualValue = grouped[monthKeys[lastActualIndex]]?.map(\.score).average ?? lastScan.score
        let target = computeTarget(from: lastActualValue)
        let stepsToYearEnd = max(0, basePoints.count - 1 - lastActualIndex)
        let forecast = planToTargetSharper(
            start: lastActualValue,
            target: target,
            steps: stepsToYearEnd,
            closeFraction: 0.9,
            alpha: 0.6,
            power: 1.6
        )

        let points = basePoints.enumerated().map { index, point in
            if index < lastActualIndex {
                return point
            }

            if index == lastActualIndex {
                return DashboardScanTrendPoint(
                    label: point.label,
                    actual: point.actual,
                    predicted: applyUplift(lastActualValue, lastActual: lastActualValue, target: target)
                )
            }

            let forecastIndex = index - lastActualIndex - 1
            let rawPrediction = forecast.indices.contains(forecastIndex)
                ? forecast[forecastIndex]
                : lastActualValue

            return DashboardScanTrendPoint(
                label: point.label,
                actual: point.actual,
                predicted: applyUplift(rawPrediction, lastActual: lastActualValue, target: target)
            )
        }

        return DashboardScanTrendModel(
            points: points,
            scanCount: sortedScans.count,
            latestScore: lastActualValue
        )
    }

    static func score(from object: [String: Any]) -> Double? {
        let candidates: [Any?] = [
            object["overallScore"],
            object["overall"],
            object["score"]
        ]

        for candidate in candidates {
            if let number = candidate as? NSNumber {
                return number.doubleValue
            }

            if let value = candidate as? Double {
                return value
            }

            if let value = candidate as? Int {
                return Double(value)
            }

            if let string = candidate as? String, let value = Double(string) {
                return value
            }
        }

        return nil
    }

    static func date(from object: [String: Any]) -> Date? {
        let candidates: [Any?] = [
            object["createdAt"],
            object["savedAt"],
            object["updatedAt"]
        ]

        for candidate in candidates {
            if let date = candidate as? Date {
                return date
            }

            #if canImport(FirebaseFirestore)
            if let timestamp = candidate as? Timestamp {
                return timestamp.dateValue()
            }
            #endif

            if let seconds = candidate as? TimeInterval {
                return Date(timeIntervalSince1970: seconds)
            }

            if let string = candidate as? String {
                if let date = ISO8601DateFormatter().date(from: string) {
                    return date
                }
            }
        }

        return nil
    }

    private static func monthKey(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        let year = components.year ?? 1970
        let month = components.month ?? 1
        return "\(year)-\(String(format: "%02d", month))"
    }

    private static func yearEndKey(for date: Date) -> String {
        let year = calendar.component(.year, from: date)
        return "\(year)-12"
    }

    private static func monthLabel(from key: String) -> String {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2,
              let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: 1))
        else {
            return key
        }

        return monthFormatter.string(from: date)
    }

    private static func keysBetween(startKey: String, endKey: String) -> [String] {
        var keys: [String] = []
        var current = startKey

        while current <= endKey {
            keys.append(current)
            current = addMonths(to: current, count: 1)
        }

        return keys
    }

    private static func addMonths(to key: String, count: Int) -> String {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2,
              let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: 1)),
              let shifted = calendar.date(byAdding: .month, value: count, to: date)
        else {
            return key
        }

        return monthKey(for: shifted)
    }

    private static func planToTargetSharper(
        start: Double,
        target: Double,
        steps: Int,
        closeFraction: Double,
        alpha: Double,
        power: Double
    ) -> [Double] {
        guard steps > 0 else {
            return []
        }

        let target = max(target, start + 0.1)
        let count = max(1, steps)
        let base = -log(max(0.000001, 1 - closeFraction))
        let curve = base / max(0.000001, Double(count) * alpha)

        return (1...steps).map { step in
            let x = Double(step) / Double(count)
            let u = 1 - pow(1 - x, power)
            return target - (target - start) * exp(-curve * u)
        }
    }

    private static func computeTarget(from lastScore: Double) -> Double {
        let scaled = 85 + (lastScore - 50) * 0.25
        return max(85, min(92, scaled))
    }

    private static func applyUplift(_ value: Double, lastActual: Double, target: Double) -> Double {
        let baseUplift = max(0.75, 0.1 * (target - lastActual))
        return min(95, value + baseUplift)
    }
}

private extension Array where Element == Double {
    var average: Double? {
        isEmpty ? nil : reduce(0, +) / Double(count)
    }
}

struct ChartSection: View {
    let snapshot: DashboardSnapshot
    var trendPhase: DashboardScanTrendPhase = .idle

    @State private var selectedRange: DashboardTrendRange = .yearly

    private var liveTrendModel: DashboardScanTrendModel? {
        if case .loaded(let model) = trendPhase {
            return model
        }

        return nil
    }

    private var chartModel: DashboardScanTrendModel {
        liveTrendModel ?? .fallback(from: snapshot)
    }

    private var isLoading: Bool {
        if case .loading = trendPhase {
            return true
        }

        return false
    }

    private var displayedPoints: [DashboardTrendPlotPoint] {
        let points: [DashboardScanTrendPoint]

        switch selectedRange {
        case .monthly:
            points = monthlyPoints(from: chartModel.points)
        case .yearly:
            points = yearlyPoints(from: chartModel.points)
        }

        return points.enumerated().map { index, point in
            DashboardTrendPlotPoint(index: index, point: point)
        }
    }

    private var displayedHighlight: DashboardTrendPlotPoint {
        displayedPoints.last(where: { $0.point.actual != nil })
            ?? displayedPoints.first(where: { $0.point.predicted != nil })
            ?? DashboardTrendPlotPoint(
                index: 0,
                point: DashboardScanTrendPoint(label: "Now", actual: Double(snapshot.score), predicted: nil)
            )
    }

    private var minTrendValue: Double {
        let values = displayedPoints.flatMap { [$0.point.actual, $0.point.predicted].compactMap { $0 } }
        return max((values.min() ?? Double(snapshot.score)) - 4, 0)
    }

    private var maxTrendValue: Double {
        let values = displayedPoints.flatMap { [$0.point.actual, $0.point.predicted].compactMap { $0 } }
        return values.max() ?? Double(snapshot.score)
    }

    var body: some View {
        if isLoading {
            ChartSectionSkeleton()
        } else if case .empty = trendPhase {
            ChartSectionEmptyState()
        } else {
            chartCard
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                    Text(liveTrendModel == nil ? "Score / cycle" : "\(chartModel.scanCount) scans tracked")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                    Text(snapshot.heroStatement)
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: AIscendTheme.Spacing.small)

                currentScorePill
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: AIscendTheme.Spacing.small) {
                    trendRangePicker
                    Spacer(minLength: AIscendTheme.Spacing.small)
                    predictedScoreBlock
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    trendRangePicker
                    predictedScoreBlock
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Chart {
                ForEach(displayedPoints) { plotPoint in
                    if let actual = plotPoint.point.actual {
                        AreaMark(
                            x: .value("Period", plotPoint.index),
                            yStart: .value("Baseline", minTrendValue),
                            yEnd: .value("Score", actual)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.accentPrimary.opacity(0.22),
                                    AIscendTheme.Colors.accentGlow.opacity(0.02)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }

                ForEach(displayedPoints) { plotPoint in
                    if let actual = plotPoint.point.actual {
                        LineMark(
                            x: .value("Period", plotPoint.index),
                            y: .value("Score", actual),
                            series: .value("Series", "Actual")
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(AIscendTheme.Colors.accentGlow)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    }
                }

                ForEach(displayedPoints) { plotPoint in
                    if let predicted = plotPoint.point.predicted {
                        LineMark(
                            x: .value("Period", plotPoint.index),
                            y: .value("Forecast", predicted),
                            series: .value("Series", "Forecast")
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(AIscendTheme.Colors.accentPrimary.opacity(0.62))
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [8, 7]))
                    }
                }

                RuleMark(x: .value("Selected", displayedHighlight.index))
                    .foregroundStyle(AIscendTheme.Colors.textMuted.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

                PointMark(
                    x: .value("Selected", displayedHighlight.index),
                    y: .value("Score", displayedHighlight.score)
                )
                .symbolSize(260)
                .foregroundStyle(AIscendTheme.Colors.accentGlow)

                PointMark(
                    x: .value("Selected", displayedHighlight.index),
                    y: .value("Score", displayedHighlight.score)
                )
                .symbolSize(90)
                .foregroundStyle(Color.white)
            }
            .chartLegend(.hidden)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: displayedPoints.map(\.index)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0))
                    AxisTick(stroke: StrokeStyle(lineWidth: 0))
                    AxisValueLabel {
                        if let index = value.as(Int.self),
                           let label = displayedPoints.first(where: { $0.index == index })?.point.label
                        {
                            Text(label)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(AIscendTheme.Colors.textMuted)
                        }
                    }
                }
            }
            .chartYScale(domain: minTrendValue...(maxTrendValue + 4))
            .frame(maxWidth: .infinity)
            .frame(height: 220)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "151515").opacity(0.98),
                            AIscendTheme.Colors.surfaceMuted.opacity(0.96)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.34), radius: 24, x: 0, y: 16)
    }

    private var currentScorePill: some View {
        Text(String(format: "%.1f", displayedHighlight.score))
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(AIscendTheme.Colors.textPrimary)
            .padding(.horizontal, AIscendTheme.Spacing.small)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(AIscendTheme.Colors.accentPrimary)
            )
    }

    private var trendRangePicker: some View {
        Picker("Trend range", selection: $selectedRange) {
            ForEach(DashboardTrendRange.allCases) { range in
                Text(range.title).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 220)
    }

    private var predictedScoreBlock: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AIscendTheme.Colors.accentPrimary.opacity(0.24))
                    .frame(width: 38, height: 38)

                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AIscendTheme.Colors.accentGlow)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Predicted")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                Text(String(format: "%.1f", chartModel.predictedScore))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
            }
        }
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, AIscendTheme.Spacing.xSmall)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private func monthlyPoints(from points: [DashboardScanTrendPoint]) -> [DashboardScanTrendPoint] {
        guard !points.isEmpty else {
            return []
        }

        let highlightIndex = points.lastIndex(where: { $0.actual != nil })
            ?? points.firstIndex(where: { $0.predicted != nil })
            ?? 0
        let lowerBound = max(0, highlightIndex - 3)
        let upperBound = min(points.count - 1, highlightIndex + 3)

        return Array(points[lowerBound...upperBound])
    }

    private func yearlyPoints(from points: [DashboardScanTrendPoint]) -> [DashboardScanTrendPoint] {
        guard points.count > 12 else {
            return points
        }

        return Array(points.suffix(12))
    }
}

private enum DashboardTrendRange: String, CaseIterable, Identifiable {
    case monthly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .monthly:
            "Monthly"
        case .yearly:
            "Yearly"
        }
    }
}

private struct DashboardTrendPlotPoint: Identifiable {
    let index: Int
    let point: DashboardScanTrendPoint

    var id: String {
        "\(index)-\(point.id)"
    }

    var score: Double {
        point.actual ?? point.predicted ?? 0
    }
}

private struct ChartSectionSkeleton: View {
    @State private var pulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    skeletonBlock(width: 92, height: 12, radius: 6)
                    skeletonBlock(width: 260, height: 22, radius: 8)
                    skeletonBlock(width: 210, height: 18, radius: 8)
                }

                Spacer(minLength: AIscendTheme.Spacing.small)
                skeletonBlock(width: 48, height: 28, radius: 14)
            }

            skeletonBlock(width: nil, height: 220, radius: 22)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "151515").opacity(0.98),
                            AIscendTheme.Colors.surfaceMuted.opacity(0.96)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
        .opacity(pulse ? 0.64 : 0.38)
        .animation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true), value: pulse)
        .onAppear {
            pulse = true
        }
    }

    private func skeletonBlock(width: CGFloat?, height: CGFloat, radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Color.white.opacity(0.12))
            .frame(maxWidth: width == nil ? .infinity : nil)
            .frame(width: width, height: height)
    }
}

private struct ChartSectionEmptyState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            Text("No scans found")
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)

            Text("Capture at least two scans to unlock your live progress trend.")
                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "151515").opacity(0.98),
                            AIscendTheme.Colors.surfaceMuted.opacity(0.96)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.34), radius: 24, x: 0, y: 16)
    }
}
