//
//  EntryHabitImpactOnboardingPage.swift
//  AIscend
//

import SwiftUI

struct EntryHabitImpactOnboardingPage: View {
    var body: some View {
        EntryOnboardingPageContainer(
            title: "Lifestyle impact is the part you can control",
            subtitle: "AIScend separates fixed signals from daily choices so the next action is obvious."
        ) {
            VStack(alignment: .leading, spacing: 48) {
                HabitImpactCard()

                Text(
                    .onboardingText(
                        "Daily choices can unlock the visible wins your scans keep missing.",
                        highlights: ["Daily choices", "visible wins"]
                    )
                )
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 28)
        }
    }
}

private struct HabitImpactCard: View {
    @State private var animate = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Label("Lifestyle Impact", systemImage: "bolt.heart.fill")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Text("20%")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(EntryOnboardingStyle.purpleSoft)
                    .contentTransition(.numericText())
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.08))

                    Capsule(style: .continuous)
                        .fill(EntryOnboardingStyle.primaryGradient)
                        .frame(width: geometry.size.width * (animate ? 0.20 : 0.04))
                        .shadow(color: EntryOnboardingStyle.purpleSoft.opacity(0.50), radius: 18, x: 0, y: 0)

                    Text("repeatable habits")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.leading, 18)
                }
            }
            .frame(height: 50)

            VStack(spacing: 12) {
                impactRow(symbol: "drop.fill", title: "Hydration", value: 0.74)
                impactRow(symbol: "face.smiling.inverse", title: "Grooming", value: 0.64)
                impactRow(symbol: "figure.walk", title: "Posture", value: 0.58)
            }
        }
        .padding(24)
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
            withAnimation(.spring(response: 0.72, dampingFraction: 0.78).delay(0.12)) {
                animate = true
            }
        }
    }

    private func impactRow(symbol: String, title: String, value: CGFloat) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(EntryOnboardingStyle.purpleSoft)
                .frame(width: 30, height: 30)
                .background(Circle().fill(EntryOnboardingStyle.purple.opacity(0.14)))

            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 82, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.08))

                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.42))
                        .frame(width: geometry.size.width * (animate ? value : 0.10))
                }
            }
            .frame(height: 10)
        }
    }
}

#Preview {
    EntryHabitImpactOnboardingPage()
        .background(Color.black)
}
