//
//  EntryBlindspotsOnboardingPage.swift
//  AIscend
//

import SwiftUI

struct EntryBlindspotsOnboardingPage: View {
    @State private var revealRows = false

    private let rows = [
        ("lighting.max", "Lighting drift", "Same face, different read."),
        ("viewfinder", "Angle changes", "Progress gets hard to compare."),
        ("calendar.badge.clock", "Missed habits", "Small gaps stack quietly."),
        ("sparkles.rectangle.stack", "No structure", "Advice turns into noise.")
    ]

    var body: some View {
        EntryOnboardingPageContainer(
            title: "Untracked progress should not feel messy",
            subtitle: "AIScend keeps the main variables visible so a bad photo day does not blur the whole journey."
        ) {
            VStack(spacing: 14) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    BlindspotSignalRow(
                        symbol: row.0,
                        title: row.1,
                        detail: row.2,
                        isVisible: revealRows
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.44, dampingFraction: 0.82).delay(Double(index) * 0.08), value: revealRows)
                }
            }
            .padding(.top, 26)
            .onAppear {
                revealRows = false
                withAnimation(.spring(response: 0.44, dampingFraction: 0.82).delay(0.12)) {
                    revealRows = true
                }
            }
        }
    }
}

private struct BlindspotSignalRow: View {
    let symbol: String
    let title: String
    let detail: String
    let isVisible: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(EntryOnboardingStyle.primaryGradient)
                        .shadow(color: EntryOnboardingStyle.purple.opacity(isVisible ? 0.32 : 0), radius: 18, x: 0, y: 8)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text(detail)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(EntryOnboardingStyle.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.055))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 16)
    }
}

#Preview {
    EntryBlindspotsOnboardingPage()
        .background(Color.black)
}
