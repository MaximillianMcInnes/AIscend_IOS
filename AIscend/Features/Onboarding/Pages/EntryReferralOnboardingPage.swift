//
//  EntryReferralOnboardingPage.swift
//  AIscend
//

import SwiftUI

struct EntryReferralOnboardingPage: View {
    @Binding var draft: EntryOnboardingDraft
    @FocusState private var isReferralFocused: Bool

    var body: some View {
        EntryOnboardingPageContainer(
            title: "Got a referral code?",
            subtitle: "Optional. This is the final step before sign in."
        ) {
            VStack(alignment: .leading, spacing: 22) {
                TextField("Referral code", text: $draft.referralCode)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($isReferralFocused)
                    .padding(.horizontal, 28)
                    .frame(height: 82)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(EntryOnboardingStyle.panelStrong)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                isReferralFocused ? EntryOnboardingStyle.purpleSoft : Color.white.opacity(0.10),
                                lineWidth: isReferralFocused ? 2 : 1
                            )
                    )
                    .shadow(
                        color: EntryOnboardingStyle.purple.opacity(isReferralFocused ? 0.22 : 0),
                        radius: 24,
                        x: 0,
                        y: 14
                    )
                    .onChange(of: draft.referralCode) { _, newValue in
                        let cleaned = newValue
                            .uppercased()
                            .filter { $0.isLetter || $0.isNumber || $0 == "-" }

                        if cleaned != newValue {
                            draft.referralCode = cleaned
                        }

                        EntryOnboardingHaptics.selection()
                    }

                Text("You can leave this blank and continue.")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(EntryOnboardingStyle.mutedText)
                    .padding(.horizontal, 4)
            }
            .padding(.top, 30)
        }
    }
}

#Preview {
    EntryReferralOnboardingPage(draft: .constant(EntryOnboardingDraft()))
        .background(Color.black)
}
