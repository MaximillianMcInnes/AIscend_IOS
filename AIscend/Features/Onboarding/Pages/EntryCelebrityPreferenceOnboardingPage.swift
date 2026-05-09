//
//  EntryCelebrityPreferenceOnboardingPage.swift
//  AIscend
//

import SwiftUI

struct EntryCelebrityPreferenceOnboardingPage: View {
    @Binding var draft: EntryOnboardingDraft

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        EntryOnboardingPageContainer(
            title: "Whose look do you rate?",
            subtitle: "Choose the references you like most. AIScend uses this to understand your taste, not to copy anyone.",
            usesTypewriterSubtitle: false
        ) {
            VStack(spacing: 12) {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(EntryCelebrityPreference.allCases) { preference in
                        celebrityTile(preference)
                    }
                }

                noneTile
            }
            .padding(.top, 12)
        }
    }

    private func celebrityTile(_ preference: EntryCelebrityPreference) -> some View {
        let isSelected = draft.celebrityPreferences.contains(preference)

        return Button {
            EntryOnboardingHaptics.selection()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                draft.skippedCelebrityPreferences = false

                if isSelected {
                    draft.celebrityPreferences.remove(preference)
                } else {
                    draft.celebrityPreferences.insert(preference)
                }
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                portrait(for: preference)
                    .frame(maxWidth: .infinity)
                    .frame(height: 238)
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(preference.title)
                                .font(.system(size: 20, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .minimumScaleFactor(0.72)

                            HStack(spacing: 7) {
                                Image(systemName: isSelected ? "heart.fill" : "heart")
                                    .font(.system(size: 13, weight: .bold))

                                Text(isSelected ? "Selected" : "Tap to choose")
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                            }
                            .foregroundStyle(isSelected ? EntryOnboardingStyle.purpleSoft : Color.white.opacity(0.80))
                        }
                        .padding(16)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                isSelected ? EntryOnboardingStyle.purpleSoft.opacity(0.86) : Color.white.opacity(0.10),
                                lineWidth: isSelected ? 2 : 1
                            )
                    }

                Image(systemName: isSelected ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isSelected ? .white : Color.white.opacity(0.72))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.black.opacity(isSelected ? 0.58 : 0.42)))
                    .padding(12)
            }
        }
        .buttonStyle(EntryOnboardingTactileButtonStyle())
    }

    private func portrait(for preference: EntryCelebrityPreference) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    EntryOnboardingStyle.purple.opacity(0.36),
                    Color.white.opacity(0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            AsyncImage(url: preference.portraitURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failure:
                    fallbackPortrait(for: preference)
                case .empty:
                    ProgressView()
                        .tint(.white)
                @unknown default:
                    fallbackPortrait(for: preference)
                }
            }

            LinearGradient(
                colors: [
                    Color.black.opacity(0.02),
                    Color.black.opacity(0.18),
                    Color.black.opacity(0.76)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            LinearGradient(
                colors: [
                    EntryOnboardingStyle.purple.opacity(0.12),
                    .clear
                ],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
        }
        .clipped()
    }

    private func fallbackPortrait(for preference: EntryCelebrityPreference) -> some View {
        Text(preference.initials)
            .font(.system(size: 27, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noneTile: some View {
        Button {
            EntryOnboardingHaptics.tap()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                draft.celebrityPreferences.removeAll()
                draft.skippedCelebrityPreferences = true
            }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: draft.skippedCelebrityPreferences ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(draft.skippedCelebrityPreferences ? EntryOnboardingStyle.purpleSoft : Color.white.opacity(0.36))

                Text("None of these")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .frame(height: 68)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(draft.skippedCelebrityPreferences ? EntryOnboardingStyle.purple.opacity(0.16) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(draft.skippedCelebrityPreferences ? EntryOnboardingStyle.purpleSoft.opacity(0.72) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(EntryOnboardingTactileButtonStyle())
    }
}

#Preview {
    EntryCelebrityPreferenceOnboardingPage(draft: .constant(EntryOnboardingDraft()))
        .background(Color.black)
}
