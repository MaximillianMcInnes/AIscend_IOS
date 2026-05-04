//
//  ResultsAuroraPanel.swift
//  AIscend
//

import SwiftUI

struct ResultsAuroraPanel<Content: View>: View {
    enum Intensity: Equatable {
        case standard
        case hero
        case quiet
    }

    let intensity: Intensity
    let cornerRadius: CGFloat
    private let content: Content

    init(
        intensity: Intensity = .standard,
        cornerRadius: CGFloat = 30,
        @ViewBuilder content: () -> Content
    ) {
        self.intensity = intensity
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AIscendTheme.Spacing.mediumLarge)
            .background(panelBackground)
            .clipShape(shape)
            .overlay(shape.stroke(borderGradient, lineWidth: 1))
            .shadow(color: Color.black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: 16)
            .shadow(color: glowColor, radius: glowRadius, x: 0, y: 0)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    private var shadowOpacity: Double {
        switch intensity {
        case .hero:
            0.34
        case .standard:
            0.26
        case .quiet:
            0.18
        }
    }

    private var shadowRadius: CGFloat {
        switch intensity {
        case .hero:
            28
        case .standard:
            22
        case .quiet:
            16
        }
    }

    private var glowRadius: CGFloat {
        switch intensity {
        case .hero:
            30
        case .standard:
            20
        case .quiet:
            10
        }
    }

    private var glowColor: Color {
        switch intensity {
        case .hero:
            AIscendTheme.Colors.accentGlow.opacity(0.18)
        case .standard:
            AIscendTheme.Colors.accentPrimary.opacity(0.10)
        case .quiet:
            .clear
        }
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.16),
                AIscendTheme.Colors.accentGlow.opacity(intensity == .quiet ? 0.12 : 0.28),
                Color.white.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var panelBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.white.opacity(intensity == .hero ? 0.065 : 0.045),
                    AIscendTheme.Colors.surfaceGlass.opacity(intensity == .quiet ? 0.40 : 0.58),
                    Color(hex: "090C14").opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            shape
                .fill(.ultraThinMaterial)
                .opacity(intensity == .quiet ? 0.10 : 0.16)

            if intensity != .quiet {
                Circle()
                    .fill(AIscendTheme.Colors.accentGlow.opacity(intensity == .hero ? 0.18 : 0.12))
                    .frame(width: 220, height: 220)
                    .blur(radius: 34)
                    .offset(x: 140, y: -140)

                Circle()
                    .fill(Color(hex: "E858FF").opacity(intensity == .hero ? 0.09 : 0.055))
                    .frame(width: 170, height: 170)
                    .blur(radius: 28)
                    .offset(x: -124, y: 118)
            }
        }
    }
}
