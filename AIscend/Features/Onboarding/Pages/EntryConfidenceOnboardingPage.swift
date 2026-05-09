//
//  EntryConfidenceOnboardingPage.swift
//  AIscend
//

import SwiftUI

struct EntryConfidenceOnboardingPage: View {
    var body: some View {
        EntryOnboardingPageContainer(
            title: "Every check-in makes the plan sharper",
            subtitle: "AIScend turns consistent inputs into clearer next moves, so progress feels less random."
        ) {
            SharpeningSignalCard()
                .padding(.top, 34)
        }
    }
}

private struct SharpeningSignalCard: View {
    @State private var animate = false

    private let steps = [
        ("Photo", "camera.viewfinder", 0.42),
        ("Habit", "checkmark.seal.fill", 0.68),
        ("Plan", "sparkles", 0.90)
    ]

    var body: some View {
        VStack(spacing: 22) {
            HStack(alignment: .bottom, spacing: 14) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    VStack(spacing: 12) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.07))
                                .frame(height: 178)

                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(EntryOnboardingStyle.primaryGradient)
                                .frame(height: animate ? 178 * CGFloat(step.2) : 18)
                                .shadow(color: EntryOnboardingStyle.purpleSoft.opacity(0.36), radius: 16, x: 0, y: 0)
                        }
                        .overlay(alignment: .center) {
                            Image(systemName: step.1)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(Circle().fill(Color.black.opacity(0.34)))
                        }

                        Text(step.0)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .animation(.spring(response: 0.62, dampingFraction: 0.78).delay(Double(index) * 0.12), value: animate)
                }
            }

            Text("The routine improves from real patterns, not one perfect scan.")
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.62))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(26)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.045))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .onAppear {
            animate = false
            withAnimation(.spring(response: 0.62, dampingFraction: 0.78).delay(0.14)) {
                animate = true
            }
        }
    }
}

#Preview {
    EntryConfidenceOnboardingPage()
        .background(Color.black)
}
