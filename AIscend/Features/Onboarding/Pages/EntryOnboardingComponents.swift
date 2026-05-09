//
//  EntryOnboardingComponents.swift
//  AIscend
//

import SwiftUI

#if os(iOS)
import UIKit
#endif

enum EntryOnboardingStyle {
    static let purple = Color(hex: "9B4DFF")
    static let purpleSoft = Color(hex: "B273FF")
    static let purpleDeep = Color(hex: "6D2BED")
    static let panel = Color.white.opacity(0.075)
    static let panelStrong = Color(hex: "171717")
    static let mutedText = Color.white.opacity(0.58)

    static let primaryGradient = LinearGradient(
        colors: [purple, purpleSoft],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let disabledGradient = LinearGradient(
        colors: [Color.white.opacity(0.14), Color.white.opacity(0.10)],
        startPoint: .leading,
        endPoint: .trailing
    )
}

enum EntryNotificationChoice: Equatable {
    case allowed
    case denied
    case skipped
}

enum EntryCelebrityPreference: String, CaseIterable, Identifiable, Hashable {
    case chico
    case jordanBarrett
    case zayn
    case henryCavill
    case michaelBJordan
    case timothee
    case davidGandy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chico:
            "Chico"
        case .jordanBarrett:
            "Jordan Barrett"
        case .zayn:
            "Zayn"
        case .henryCavill:
            "Henry Cavill"
        case .michaelBJordan:
            "Michael B. Jordan"
        case .timothee:
            "Timothee"
        case .davidGandy:
            "David Gandy"
        }
    }

    var initials: String {
        switch self {
        case .chico:
            "C"
        case .jordanBarrett:
            "JB"
        case .zayn:
            "Z"
        case .henryCavill:
            "HC"
        case .michaelBJordan:
            "MB"
        case .timothee:
            "T"
        case .davidGandy:
            "DG"
        }
    }

    var portraitURL: URL? {
        let fileName: String

        switch self {
        case .chico:
            fileName = "Francisco Lachowski 2011.jpg"
        case .jordanBarrett:
            fileName = "Jordan-barrett-mbfw-march-2022-fashion-week-berlin.jpg"
        case .zayn:
            fileName = "Zayn Malik Glasgow 1.jpg"
        case .henryCavill:
            fileName = "Henry Cavill by Gage Skidmore.jpg"
        case .michaelBJordan:
            fileName = "Michael B. Jordan by Gage Skidmore.jpg"
        case .timothee:
            fileName = "Timoth\u{00E9}e Chalamet Berlinale 2017.jpg"
        case .davidGandy:
            fileName = "David Gandy 2017.jpg"
        }

        let encodedFileName = fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? fileName
        return URL(string: "https://commons.wikimedia.org/wiki/Special:FilePath/\(encodedFileName)?width=420")
    }
}

enum EntryOnboardingHaptics {
    static func tap() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        #endif
    }

    static func advance() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.72)
        #endif
    }

    static func stage() {
        #if os(iOS)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    static func selection() {
        #if os(iOS)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    static func typewriterTick() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.35)
        #endif
    }

    static func success() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    static func warning() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }
}

struct EntryOnboardingPrimaryButtonLabel: View {
    let title: String
    let isActive: Bool
    let progress: Double

    @State private var shimmer = false
    @State private var breathes = false

    var body: some View {
        Text(title)
            .font(.system(size: 21, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                Capsule(style: .continuous)
                    .fill(isActive ? EntryOnboardingStyle.primaryGradient : EntryOnboardingStyle.disabledGradient)
                    .shadow(
                        color: EntryOnboardingStyle.purple.opacity(isActive ? 0.30 + 0.32 * progress : 0),
                        radius: isActive ? (breathes ? 34 : 22) : 0,
                        x: 0,
                        y: 12
                    )
            )
            .overlay {
                if isActive {
                    GeometryReader { geometry in
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        Color.white.opacity(0.34),
                                        .clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 86)
                            .rotationEffect(.degrees(18))
                            .offset(x: shimmer ? geometry.size.width + 90 : -120)
                            .blur(radius: 1)
                    }
                    .clipShape(Capsule(style: .continuous))
                    .allowsHitTesting(false)
                }
            }
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(isActive ? 0.18 : 0.04), lineWidth: 1)
            )
            .scaleEffect(isActive && breathes ? 1.012 : 1)
            .animation(.smooth(duration: 0.22), value: isActive)
            .onAppear {
                shimmer = false
                breathes = false

                withAnimation(.linear(duration: 1.55).repeatForever(autoreverses: false)) {
                    shimmer = true
                }

                withAnimation(.easeInOut(duration: 1.45).repeatForever(autoreverses: true)) {
                    breathes = true
                }
            }
    }
}

struct EntryOnboardingTactileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(.smooth(duration: 0.16), value: configuration.isPressed)
    }
}

struct EntryOnboardingBackdrop: View {
    @State private var isBreathing = false

    var body: some View {
        ZStack {
            Color.black

            RadialGradient(
                colors: [
                    EntryOnboardingStyle.purple.opacity(0.18),
                    .clear
                ],
                center: .bottom,
                startRadius: 8,
                endRadius: 460
            )
            .offset(y: 260)
            .scaleEffect(isBreathing ? 1.12 : 0.96)
            .opacity(isBreathing ? 1 : 0.72)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.015),
                    .clear,
                    EntryOnboardingStyle.purple.opacity(0.035)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 4.2).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
    }
}

struct EntryOnboardingPageContainer<Content: View>: View {
    let title: String
    let subtitle: String?
    let usesTypewriterSubtitle: Bool
    @ViewBuilder let content: Content
    @State private var reveal = false

    init(
        title: String,
        subtitle: String?,
        usesTypewriterSubtitle: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.usesTypewriterSubtitle = usesTypewriterSubtitle
        self.content = content()
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(title)
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.82)
                        .opacity(reveal ? 1 : 0)
                        .offset(y: reveal ? 0 : 16)

                    if let subtitle {
                        subtitleText(subtitle)
                        .opacity(reveal ? 1 : 0)
                        .offset(y: reveal ? 0 : 18)
                    }
                }
                .padding(.top, 14)

                content
                    .opacity(reveal ? 1 : 0)
                    .offset(y: reveal ? 0 : 24)
                    .scaleEffect(reveal ? 1 : 0.98, anchor: .top)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 22)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear {
            reveal = false
            withAnimation(.spring(response: 0.54, dampingFraction: 0.86).delay(0.08)) {
                reveal = true
            }
        }
    }

    @ViewBuilder
    private func subtitleText(_ subtitle: String) -> some View {
        if usesTypewriterSubtitle {
            EntryTypewriterText(
                text: subtitle,
                isActive: reveal,
                font: .system(size: 18, weight: .semibold, design: .rounded),
                color: EntryOnboardingStyle.mutedText
            )
        } else {
            Text(subtitle)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(EntryOnboardingStyle.mutedText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct EntryTypewriterText: View {
    let text: String
    let isActive: Bool
    let font: Font
    let color: Color

    @State private var visibleCount = 0
    @State private var typingTask: Task<Void, Never>?

    var body: some View {
        Text(String(text.prefix(visibleCount)))
            .font(font)
            .foregroundStyle(color)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(text)
            .onAppear {
                startTypingIfNeeded()
            }
            .onChange(of: isActive) { _, _ in
                startTypingIfNeeded()
            }
            .onChange(of: text) { _, _ in
                startTypingIfNeeded(force: true)
            }
            .onDisappear {
                typingTask?.cancel()
                typingTask = nil
            }
    }

    private func startTypingIfNeeded(force: Bool = false) {
        guard isActive else {
            visibleCount = 0
            return
        }

        guard force || visibleCount == 0 else {
            return
        }

        typingTask?.cancel()
        visibleCount = 0
        let characters = Array(text)

        typingTask = Task {
            for index in characters.indices {
                guard !Task.isCancelled else {
                    return
                }

                try? await Task.sleep(nanoseconds: 18_000_000)

                await MainActor.run {
                    visibleCount = index + 1
                    if index.isMultiple(of: 4) || characters[index] == "." || characters[index] == "&" {
                        EntryOnboardingHaptics.typewriterTick()
                    }
                }
            }
        }
    }
}

struct EntryOnboardingOptionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            EntryOnboardingHaptics.selection()
            action()
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? EntryOnboardingStyle.purpleSoft : Color.white.opacity(0.34), lineWidth: 3)
                        .frame(width: 28, height: 28)

                    if isSelected {
                        Circle()
                            .fill(EntryOnboardingStyle.purpleSoft)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding(.horizontal, 30)
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? EntryOnboardingStyle.purple.opacity(0.18) : EntryOnboardingStyle.panelStrong)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? EntryOnboardingStyle.purple.opacity(0.62) : Color.white.opacity(0.025), lineWidth: 1)
            )
        }
        .buttonStyle(EntryOnboardingTactileButtonStyle())
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isSelected)
    }
}

struct EntryOnboardingPillRow: View {
    let symbol: String
    let text: AttributedString

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(EntryOnboardingStyle.purple)
                .frame(width: 44, height: 44)

            Text(text)
                .font(.system(size: 23, weight: .bold, design: .rounded))
                .foregroundStyle(EntryOnboardingStyle.purple)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 26)
        .frame(minHeight: 76)
        .background(
            Capsule(style: .continuous)
                .fill(EntryOnboardingStyle.purple.opacity(0.12))
        )
    }
}

extension AttributedString {
    static func onboardingText(_ base: String, highlights: [String] = []) -> AttributedString {
        var attributed = AttributedString(base)
        attributed.foregroundColor = .white

        for highlight in highlights {
            if let range = attributed.range(of: highlight) {
                attributed[range].foregroundColor = EntryOnboardingStyle.purple
                attributed[range].font = .system(size: 25, weight: .heavy, design: .rounded)
            }
        }

        return attributed
    }
}
