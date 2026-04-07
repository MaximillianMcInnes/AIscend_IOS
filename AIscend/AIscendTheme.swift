//
//  AIscendTheme.swift
//  AIscend
//
//  Created by Codex on 4/7/26.
//

import SwiftUI

enum AIscendTheme {
    static let midnight = Color(red: 0.05, green: 0.08, blue: 0.18)
    static let storm = Color(red: 0.12, green: 0.25, blue: 0.41)
    static let sky = Color(red: 0.25, green: 0.66, blue: 0.77)
    static let mint = Color(red: 0.54, green: 0.86, blue: 0.79)
    static let sunrise = Color(red: 1.00, green: 0.77, blue: 0.41)
    static let coral = Color(red: 0.98, green: 0.57, blue: 0.42)
    static let mist = Color(red: 0.93, green: 0.97, blue: 0.99)
    static let secondaryText = Color.white.opacity(0.72)
}

extension RoutineAccent {
    var tint: Color {
        switch self {
        case .dawn:
            AIscendTheme.sunrise
        case .sky:
            AIscendTheme.sky
        case .mint:
            AIscendTheme.mint
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .dawn:
            LinearGradient(
                colors: [AIscendTheme.sunrise, AIscendTheme.coral],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sky:
            LinearGradient(
                colors: [AIscendTheme.sky, Color(red: 0.38, green: 0.80, blue: 0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .mint:
            LinearGradient(
                colors: [AIscendTheme.mint, Color(red: 0.39, green: 0.74, blue: 0.59)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct AIscendBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AIscendTheme.midnight, AIscendTheme.storm, AIscendTheme.sky],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(AIscendTheme.sunrise.opacity(0.30))
                .frame(width: 260, height: 260)
                .blur(radius: 28)
                .offset(x: 140, y: -220)

            Circle()
                .fill(AIscendTheme.mint.opacity(0.22))
                .frame(width: 300, height: 300)
                .blur(radius: 32)
                .offset(x: -150, y: 260)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.05), .clear, .white.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blendMode(.screen)
        }
        .ignoresSafeArea()
    }
}

struct AIscendCardModifier: ViewModifier {
    let highlighted: Bool

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.white.opacity(highlighted ? 0.18 : 0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(highlighted ? 0.28 : 0.14), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 12)
    }
}

extension View {
    func aiscendCard(highlighted: Bool = false) -> some View {
        modifier(AIscendCardModifier(highlighted: highlighted))
    }
}

struct AIscendCapsule: View {
    let title: String
    let symbol: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(.white.opacity(isActive ? 0.20 : 0.10))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(.white.opacity(isActive ? 0.26 : 0.12), lineWidth: 1)
        )
    }
}
