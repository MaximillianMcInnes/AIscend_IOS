//
//  EntryGoalsSelectionOnboardingPage.swift
//  AIscend
//

import SwiftUI

struct EntryGoalsSelectionOnboardingPage: View {
    @Binding var draft: EntryOnboardingDraft
    @State private var goalsVisible = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        EntryOnboardingPageContainer(
            title: "Choose your goals",
            subtitle: "Pick the areas AIScend should prioritize first. You can choose more than one.",
            usesTypewriterSubtitle: false
        ) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(AnalysisGoal.allCases.enumerated()), id: \.element.id) { index, goal in
                    goalTile(goal)
                        .opacity(goalsVisible ? 1 : 0)
                        .offset(y: goalsVisible ? 0 : 22)
                        .animation(
                            .smooth(duration: 0.34).delay(Double(index) * 0.045),
                            value: goalsVisible
                        )
                }
            }
            .padding(.top, 18)
            .onAppear {
                goalsVisible = false
                withAnimation(.smooth(duration: 0.1)) {
                    goalsVisible = true
                }
            }
        }
    }

    private func goalTile(_ goal: AnalysisGoal) -> some View {
        let isSelected = draft.goals.contains(goal)

        return Button {
            EntryOnboardingHaptics.selection()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                if let index = draft.goals.firstIndex(of: goal) {
                    draft.goals.remove(at: index)
                } else {
                    draft.goals.append(goal)
                    draft.goals.sort { lhs, rhs in
                        let lhsIndex = AnalysisGoal.allCases.firstIndex(of: lhs) ?? 0
                        let rhsIndex = AnalysisGoal.allCases.firstIndex(of: rhs) ?? 0
                        return lhsIndex < rhsIndex
                    }
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: goal.symbol)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(isSelected ? .white : EntryOnboardingStyle.purpleSoft)
                        .frame(width: 42, height: 42)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isSelected ? EntryOnboardingStyle.purple : Color.white.opacity(0.08))
                        )

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(isSelected ? EntryOnboardingStyle.purpleSoft : Color.white.opacity(0.34))
                }

                Text(goal.shortTitle)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.76)

                Text(goal.subtitle)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.54))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 154, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? EntryOnboardingStyle.purple.opacity(0.18) : EntryOnboardingStyle.panelStrong)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? EntryOnboardingStyle.purpleSoft.opacity(0.72) : Color.white.opacity(0.06), lineWidth: 1.3)
            )
        }
        .buttonStyle(EntryOnboardingTactileButtonStyle())
    }
}

#Preview {
    EntryGoalsSelectionOnboardingPage(draft: .constant(EntryOnboardingDraft()))
        .background(Color.black)
}
