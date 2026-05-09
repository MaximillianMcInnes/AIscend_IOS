//
//  EntryAgeOnboardingPage.swift
//  AIscend
//

import SwiftUI

struct EntryAgeOnboardingPage: View {
    @Binding var draft: EntryOnboardingDraft
    @State private var ageContentVisible = false

    private var ageValue: Int {
        Int(draft.age.rounded())
    }

    private var ageLabel: String {
        ageValue >= 65 ? "65+" : "\(ageValue)"
    }

    var body: some View {
        EntryOnboardingPageContainer(
            title: "How old are you?",
            subtitle: "Age helps AIScend tune the tone, timing, and structure of your plan.",
            usesTypewriterSubtitle: false
        ) {
            VStack(spacing: 46) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    EntryOnboardingStyle.purple.opacity(0.30),
                                    EntryOnboardingStyle.purple.opacity(0.08),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 8,
                                endRadius: 170
                            )
                        )
                        .frame(width: 248, height: 248)

                    VStack(spacing: 6) {
                        Text(ageLabel)
                            .font(.system(size: 98, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())

                        Text("years old")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(EntryOnboardingStyle.mutedText)
                    }
                }
                .frame(maxWidth: .infinity)
                .opacity(ageContentVisible ? 1 : 0)
                .offset(
                    x: ageContentVisible ? 0 : -34,
                    y: ageContentVisible ? 0 : 28
                )
                .animation(.smooth(duration: 0.42), value: ageContentVisible)

                VStack(spacing: 18) {
                    Slider(
                        value: $draft.age,
                        in: 13...65,
                        step: 1
                    ) {
                        Text("Age")
                    }
                    .tint(EntryOnboardingStyle.purpleSoft)
                    .onChange(of: draft.age) { _, _ in
                        EntryOnboardingHaptics.selection()
                    }

                    HStack {
                        Text("13")
                        Spacer()
                        Text("65+")
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(EntryOnboardingStyle.mutedText)
                }
                .padding(.horizontal, 28)
                .opacity(ageContentVisible ? 1 : 0)
                .offset(
                    x: ageContentVisible ? 0 : 34,
                    y: ageContentVisible ? 0 : 24
                )
                .animation(.smooth(duration: 0.42).delay(0.08), value: ageContentVisible)
            }
            .padding(.top, 22)
            .onAppear {
                ageContentVisible = false
                withAnimation(.smooth(duration: 0.1)) {
                    ageContentVisible = true
                }
            }
        }
    }
}

#Preview {
    EntryAgeOnboardingPage(draft: .constant(EntryOnboardingDraft(age: 21)))
        .background(Color.black)
}
