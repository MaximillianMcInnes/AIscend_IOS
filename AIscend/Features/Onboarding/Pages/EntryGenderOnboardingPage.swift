//
//  EntryGenderOnboardingPage.swift
//  AIscend
//

import SwiftUI

struct EntryGenderOnboardingPage: View {
    @Binding var draft: EntryOnboardingDraft
    let onSelection: () -> Void
    @State private var optionsVisible = false

    init(draft: Binding<EntryOnboardingDraft>, onSelection: @escaping () -> Void = {}) {
        _draft = draft
        self.onSelection = onSelection
    }

    var body: some View {
        EntryOnboardingPageContainer(
            title: "Select your profile",
            subtitle: "This helps AIScend tune your analysis context and create a more relevant plan.",
            usesTypewriterSubtitle: false
        ) {
            VStack(spacing: 14) {
                ForEach(Array(EntryOnboardingGender.allCases.enumerated()), id: \.element.id) { index, gender in
                    EntryOnboardingOptionRow(
                        title: gender.rawValue,
                        isSelected: draft.gender == gender
                    ) {
                        withAnimation(.smooth(duration: 0.22)) {
                            draft.gender = gender
                        }
                        onSelection()
                    }
                    .opacity(optionsVisible ? 1 : 0)
                    .offset(y: optionsVisible ? 0 : 22)
                    .animation(
                        .smooth(duration: 0.34).delay(Double(index) * 0.055),
                        value: optionsVisible
                    )
                }
            }
            .onAppear {
                optionsVisible = false
                withAnimation(.smooth(duration: 0.1)) {
                    optionsVisible = true
                }
            }
        }
    }
}

#Preview {
    EntryGenderOnboardingPage(draft: .constant(EntryOnboardingDraft()))
        .background(Color.black)
}
