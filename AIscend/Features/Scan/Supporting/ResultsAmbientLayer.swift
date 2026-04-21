//
//  ResultsAmbientLayer.swift
//  AIscend
//

import SwiftUI

struct ResultsAmbientLayer: View {
    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    AIscendTheme.Colors.accentGlow.opacity(0.18),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 12,
                endRadius: 320
            )
            .offset(x: 140, y: -160)

            RadialGradient(
                colors: [
                    Color.white.opacity(0.05),
                    .clear
                ],
                center: .topLeading,
                startRadius: 10,
                endRadius: 220
            )
            .offset(x: -150, y: -180)

            RadialGradient(
                colors: [
                    AIscendTheme.Colors.accentPrimary.opacity(0.12),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 300
            )
            .offset(x: -120, y: 260)
        }
        .ignoresSafeArea()
    }
}