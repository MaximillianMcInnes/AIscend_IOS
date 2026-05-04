//
//  PreviousScanCard.swift
//  AIscend
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct PreviousScanCard: View {
    let record: PersistedScanRecord
    let isBest: Bool
    let isLatest: Bool
    let onTap: () -> Void

    private var clampedScore: Double {
        let score = record.overallScore
        guard score.isFinite else {
            return 0
        }

        return min(max(score, 0), 100)
    }

    private var scoreText: String {
        "\(Int(clampedScore.rounded()))"
    }

    private var tierText: String {
        nonEmpty(record.tierTitle) ?? "Analysis"
    }

    private var percentileText: String {
        let percentile = min(max(record.percentile, 1), 100)
        return "Top \(percentile)%"
    }

    private var dateText: String {
        guard let savedAt = record.savedAt else {
            return "Saved scan"
        }

        return savedAt.formatted(date: .abbreviated, time: .shortened)
    }

    private var accessText: String {
        switch record.accessLevel {
        case .free:
            return "Free"
        case .premium:
            return "Premium"
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                PreviousScanCardPhotoPair(
                    frontRawValue: record.meta.frontUrl,
                    sideRawValue: record.meta.sideUrl
                )

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                    brandStrip
                    scoreSection
                }

                bottomRow
            }
            .padding(AIscendTheme.Spacing.mediumLarge)
            .background(cardBackground)
            .clipShape(cardShape)
            .overlay(cardShape.stroke(borderGradient, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.30), radius: 24, x: 0, y: 16)
            .shadow(color: glowColor, radius: isBest || isLatest ? 28 : 18, x: 0, y: 0)
            .contentShape(cardShape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open previous scan, score \(scoreText), \(dateText)")
    }

    private var brandStrip: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            Circle()
                .fill(AIscendTheme.Colors.accentGlow)
                .frame(width: 7, height: 7)
                .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.90), radius: 8, x: 0, y: 0)

            Text("AIScend")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

            Spacer(minLength: AIscendTheme.Spacing.small)

            Text("Archived result")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
        }
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.accentGlow.opacity(0.18),
                            Color(hex: "E858FF").opacity(0.08),
                            Color.white.opacity(0.035)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private var scoreSection: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            HStack(alignment: .bottom, spacing: AIscendTheme.Spacing.medium) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                    Text("Overall score")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(scoreText)
                            .font(.system(size: 54, weight: .bold, design: .default))
                            .foregroundStyle(AIscendTheme.Colors.textPrimary)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.76)

                        Text("/ 100")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                    }
                }

                Spacer(minLength: AIscendTheme.Spacing.small)

                VStack(alignment: .trailing, spacing: AIscendTheme.Spacing.xxSmall) {
                    Text(tierText)
                        .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.accentGlow)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(percentileText)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.08))

                    Capsule(style: .continuous)
                        .fill(scoreGradient)
                        .frame(width: max(geometry.size.width * (clampedScore / 100), 8))
                        .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.40), radius: 12, x: 0, y: 0)
                }
            }
            .frame(height: 9)
        }
    }

    private var bottomRow: some View {
        HStack(alignment: .center, spacing: AIscendTheme.Spacing.small) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                Text(dateText)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                HStack(spacing: AIscendTheme.Spacing.xSmall) {
                    PreviousScanCardBadge(title: accessText)

                    if isBest {
                        PreviousScanCardBadge(
                            title: "Best",
                            symbol: "trophy.fill",
                            tint: AIscendTheme.Colors.accentAmber
                        )
                    }

                    if isLatest {
                        PreviousScanCardBadge(
                            title: "Latest",
                            symbol: "clock.fill",
                            tint: AIscendTheme.Colors.accentGlow
                        )
                    }
                }
            }

            Spacer(minLength: AIscendTheme.Spacing.small)

            HStack(spacing: 7) {
                Text("Open")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(AIscendTheme.Colors.textPrimary)
            .padding(.horizontal, AIscendTheme.Spacing.small)
            .padding(.vertical, 9)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        }
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
    }

    private var scoreGradient: LinearGradient {
        LinearGradient(
            colors: [
                AIscendTheme.Colors.accentGlow,
                AIscendTheme.Colors.accentPrimary,
                Color(hex: "E858FF")
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var glowColor: Color {
        if isBest {
            return AIscendTheme.Colors.accentAmber.opacity(0.18)
        }

        if isLatest {
            return AIscendTheme.Colors.accentGlow.opacity(0.20)
        }

        return AIscendTheme.Colors.accentPrimary.opacity(0.10)
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.16),
                isBest ? AIscendTheme.Colors.accentAmber.opacity(0.38) : AIscendTheme.Colors.accentGlow.opacity(isLatest ? 0.36 : 0.18),
                Color.white.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.055),
                    AIscendTheme.Colors.surfaceGlass.opacity(0.54),
                    Color(hex: "080B12").opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            cardShape
                .fill(.ultraThinMaterial)
                .opacity(0.14)

            Circle()
                .fill(AIscendTheme.Colors.accentGlow.opacity(0.16))
                .frame(width: 220, height: 220)
                .blur(radius: 36)
                .offset(x: 150, y: -145)

            Circle()
                .fill(Color(hex: "E858FF").opacity(0.08))
                .frame(width: 180, height: 180)
                .blur(radius: 30)
                .offset(x: -130, y: 125)
        }
    }

    private func nonEmpty(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private struct PreviousScanCardPhotoPair: View {
    let frontRawValue: String?
    let sideRawValue: String?

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            PreviousScanCardPhotoTile(title: "Front", rawValue: frontRawValue)
            PreviousScanCardPhotoTile(title: "Side", rawValue: sideRawValue)
        }
    }
}

private struct PreviousScanCardPhotoTile: View {
    let title: String
    let rawValue: String?

    @State private var didRevealImage = false

    private var source: PreviousScanCardImageSource {
        PreviousScanCardImageSource(rawValue: rawValue)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            tilePlaceholder
            imageContent

            LinearGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.56),
                    Color.black.opacity(0.78)
                ],
                startPoint: .center,
                endPoint: .bottom
            )

            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                .padding(AIscendTheme.Spacing.medium)
        }
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .clipShape(tileShape)
        .overlay(tileShape.stroke(Color.white.opacity(0.10), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.24), radius: 16, x: 0, y: 10)
        .onChange(of: rawValue) { _, _ in
            didRevealImage = false
        }
    }

    @ViewBuilder
    private var imageContent: some View {
        #if canImport(UIKit)
        if let image = source.localURL.flatMap({ UIImage(contentsOfFile: $0.path) }) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(didRevealImage ? 1 : 0)
                .scaleEffect(didRevealImage ? 1 : 1.035)
                .blur(radius: didRevealImage ? 0 : 10)
                .onAppear(perform: revealImageIfNeeded)
        } else if let remoteURL = source.remoteURL {
            remoteImage(remoteURL)
        }
        #else
        if let remoteURL = source.remoteURL {
            remoteImage(remoteURL)
        }
        #endif
    }

    private func remoteImage(_ url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(didRevealImage ? 1 : 0)
                    .scaleEffect(didRevealImage ? 1 : 1.035)
                    .blur(radius: didRevealImage ? 0 : 10)
                    .onAppear(perform: revealImageIfNeeded)
            case .empty:
                tilePlaceholder
                    .overlay(PreviousScanCardShimmer(cornerRadius: 24))
            default:
                tilePlaceholder
            }
        }
    }

    private var tilePlaceholder: some View {
        LinearGradient(
            colors: [
                Color(hex: "171B26"),
                Color(hex: "0A0D14")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            ZStack {
                Circle()
                    .fill(AIscendTheme.Colors.accentGlow.opacity(0.15))
                    .frame(width: 94, height: 94)
                    .blur(radius: 18)

                Image(systemName: "person.crop.rectangle")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(AIscendTheme.Colors.textMuted)
            }
        }
    }

    private var tileShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
    }

    private func revealImageIfNeeded() {
        guard !didRevealImage else {
            return
        }

        withAnimation(.easeOut(duration: 0.42)) {
            didRevealImage = true
        }
    }
}

private struct PreviousScanCardBadge: View {
    let title: String
    var symbol: String?
    var tint: Color = AIscendTheme.Colors.accentPrimary

    var body: some View {
        HStack(spacing: 6) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .bold))
            }

            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(tint.opacity(0.16))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(tint.opacity(0.28), lineWidth: 1)
        )
    }
}

private struct PreviousScanCardShimmer: View {
    let cornerRadius: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shimmerX: CGFloat = -1.2

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.05))
            .overlay {
                if !reduceMotion {
                    GeometryReader { geometry in
                        LinearGradient(
                            colors: [
                                .clear,
                                Color.white.opacity(0.16),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 0.68)
                        .offset(x: geometry.size.width * shimmerX)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                }
            }
            .onAppear {
                guard !reduceMotion else {
                    return
                }

                shimmerX = -1.2
                withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: false)) {
                    shimmerX = 1.2
                }
            }
    }
}

private struct PreviousScanCardImageSource {
    let localURL: URL?
    let remoteURL: URL?

    init(rawValue: String?) {
        let trimmedValue = Self.trimmed(rawValue)
        localURL = Self.resolveLocalURL(from: trimmedValue)
        remoteURL = Self.resolveRemoteURL(from: trimmedValue)
    }

    private static func trimmed(_ rawValue: String?) -> String? {
        let value = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines)
        return value?.isEmpty == false ? value : nil
    }

    private static func resolveLocalURL(from rawValue: String?) -> URL? {
        guard let rawValue else {
            return nil
        }

        return candidateLocalURLs(for: rawValue)
            .first(where: { FileManager.default.fileExists(atPath: $0.path) })
    }

    private static func candidateLocalURLs(for rawValue: String) -> [URL] {
        var candidates: [URL] = []

        if rawValue.hasPrefix("/") {
            candidates.append(URL(fileURLWithPath: rawValue))
        }

        if let directURL = URL(string: rawValue), directURL.isFileURL {
            candidates.append(directURL)
        }

        if let decodedValue = rawValue.removingPercentEncoding {
            if decodedValue.hasPrefix("/") {
                candidates.append(URL(fileURLWithPath: decodedValue))
            }

            if let decodedURL = URL(string: decodedValue), decodedURL.isFileURL {
                candidates.append(decodedURL)
            }
        }

        if !rawValue.contains("://"), !rawValue.hasPrefix("/") {
            let directories = [
                FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first,
                FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
                FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first,
                FileManager.default.temporaryDirectory
            ].compactMap { $0 }

            for directory in directories {
                candidates.append(directory.appendingPathComponent(rawValue))
                candidates.append(directory.appendingPathComponent("ScanCaptures", isDirectory: true).appendingPathComponent(rawValue))
            }
        }

        return candidates
    }

    private static func resolveRemoteURL(from rawValue: String?) -> URL? {
        guard let rawValue else {
            return nil
        }

        let candidates = [
            rawValue,
            rawValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            rawValue.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        ]

        for candidate in candidates.compactMap({ $0 }) {
            guard let url = URL(string: candidate),
                  let scheme = url.scheme?.lowercased(),
                  scheme == "http" || scheme == "https"
            else {
                continue
            }

            return url
        }

        return nil
    }
}
