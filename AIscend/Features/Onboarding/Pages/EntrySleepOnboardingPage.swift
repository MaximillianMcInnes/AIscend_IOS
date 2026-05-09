//
//  EntrySleepOnboardingPage.swift
//  AIscend
//

import SwiftUI

struct EntrySleepOnboardingPage: View {
    @Binding var draft: EntryOnboardingDraft

    var body: some View {
        EntryOnboardingPageContainer(
            title: "How long do you want to dedicate each day?",
            subtitle: "Pick a daily commitment AIScend can turn into a realistic routine you can actually repeat.",
            usesTypewriterSubtitle: false
        ) {
            VStack(spacing: 30) {
                DedicationDial(minutes: draft.dailyDedicationMinutes)
                    .frame(width: 262, height: 262)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)

                Slider(
                    value: $draft.dailyDedicationMinutes,
                    in: 5...60,
                    step: 5
                ) {
                    Text("Daily dedication")
                }
                .tint(EntryOnboardingStyle.purpleSoft)
                .padding(.horizontal, 38)
                .onChange(of: draft.dailyDedicationMinutes) { _, _ in
                    EntryOnboardingHaptics.selection()
                }

                HStack {
                    Text("5 min")
                    Spacer()
                    Text("60+ min")
                }
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(EntryOnboardingStyle.mutedText)
                .padding(.horizontal, 40)
            }
        }
    }
}

private struct DedicationDial: View {
    let minutes: Double
    @State private var isGlowing = false

    private var dedicationProgress: Double {
        (minutes - 5) / (60 - 5)
    }

    private var dedicationLabel: String {
        let roundedMinutes = Int(minutes.rounded())
        return roundedMinutes >= 60 ? "60+" : "\(roundedMinutes)"
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            EntryOnboardingStyle.purple.opacity(0.12 + dedicationProgress * 0.34),
                            .clear
                        ],
                        center: .center,
                        startRadius: 16,
                        endRadius: 148
                    )
                )
                .scaleEffect(isGlowing ? 1.08 : 0.96)
                .shadow(
                    color: EntryOnboardingStyle.purpleSoft.opacity(0.20 + 0.38 * dedicationProgress),
                    radius: 20 + 22 * dedicationProgress,
                    x: 0,
                    y: 0
                )

            ForEach(0..<54, id: \.self) { tick in
                let tickProgress = Double(tick) / 53
                let isActive = tickProgress <= dedicationProgress

                Capsule(style: .continuous)
                    .fill(isActive ? EntryOnboardingStyle.purpleSoft : Color.white.opacity(0.08))
                    .frame(width: 10, height: isActive ? 40 : 30)
                    .offset(y: -106)
                    .rotationEffect(.degrees(Double(tick) * 360 / 54))
                    .opacity(isActive ? 1 : 0.72)
                    .shadow(color: EntryOnboardingStyle.purple.opacity(isActive ? 0.32 : 0), radius: 8, x: 0, y: 0)
            }

            VStack(spacing: 2) {
                Text(dedicationLabel)
                    .font(.system(size: 62, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                Text("min/day")
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundStyle(EntryOnboardingStyle.purpleSoft)
            }
        }
        .animation(.smooth(duration: 0.24), value: dedicationProgress)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                isGlowing = true
            }
        }
    }
}

#Preview {
    EntrySleepOnboardingPage(draft: .constant(EntryOnboardingDraft(dailyDedicationMinutes: 25)))
        .background(Color.black)
}
