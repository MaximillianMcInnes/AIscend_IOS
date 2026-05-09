//
//  EntryNameOnboardingPage.swift
//  AIscend
//

import SwiftUI

struct EntryNameOnboardingPage: View {
    @Binding var draft: EntryOnboardingDraft
    @FocusState private var isNameFocused: Bool

    var body: some View {
        EntryOnboardingPageContainer(
            title: "What should we call you?",
            subtitle: "Your plan feels sharper when the experience speaks to you directly."
        ) {
            VStack(alignment: .leading, spacing: 22) {
                TextField("Your name", text: $draft.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($isNameFocused)
                    .padding(.horizontal, 28)
                    .frame(height: 82)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(EntryOnboardingStyle.panelStrong)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                isNameFocused ? EntryOnboardingStyle.purpleSoft : Color.white.opacity(0.10),
                                lineWidth: isNameFocused ? 2 : 1
                            )
                    )
                    .shadow(
                        color: EntryOnboardingStyle.purple.opacity(isNameFocused ? 0.24 : 0),
                        radius: 24,
                        x: 0,
                        y: 14
                    )
                    .onChange(of: draft.name) { _, _ in
                        EntryOnboardingHaptics.selection()
                    }

                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(EntryOnboardingStyle.purpleSoft)

                    Text("This stays private inside AIScend.")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(EntryOnboardingStyle.mutedText)
                }
                .padding(.horizontal, 4)
            }
            .padding(.top, 46)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                isNameFocused = true
            }
        }
    }
}

#Preview {
    EntryNameOnboardingPage(draft: .constant(EntryOnboardingDraft()))
        .background(Color.black)
}
