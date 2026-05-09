//
//  EntryRatingOnboardingPage.swift
//  AIscend
//

import SwiftUI

struct EntryRatingOnboardingPage: View {
    @Binding var rating: Int
    @Binding var showsRatingPrompt: Bool
    @State private var ratingContentVisible = false

    private let testimonials = [
        RatingTestimonial(
            name: "Gabriel D.",
            stars: 5,
            quote: "The private analysis and habit tracker feel genuinely useful."
        ),
        RatingTestimonial(
            name: "Alex M.",
            stars: 5,
            quote: "Clean, direct, and much calmer than guessing from random photos."
        ),
        RatingTestimonial(
            name: "Sam R.",
            stars: 5,
            quote: "The progress structure makes the whole routine easier to trust."
        )
    ]

    var body: some View {
        EntryOnboardingPageContainer(
            title: "Leave a rating",
            subtitle: "This helps us deliver more of what you need.",
            usesTypewriterSubtitle: false
        ) {
            VStack(spacing: 22) {
                ForEach(Array(testimonials.enumerated()), id: \.element.id) { index, testimonial in
                    testimonialCard(testimonial)
                        .opacity(ratingContentVisible ? 1 : 0)
                        .offset(y: ratingContentVisible ? 0 : 24)
                        .animation(
                            .smooth(duration: 0.34).delay(Double(index) * 0.06),
                            value: ratingContentVisible
                        )
                }

                Button {
                    EntryOnboardingHaptics.tap()
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                        showsRatingPrompt = true
                    }
                } label: {
                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: rating >= index ? "star.fill" : "star")
                                .font(.system(size: 22, weight: .bold))
                        }

                        Text(rating == 0 ? "Rate AIScend" : "Thanks for rating")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(EntryOnboardingStyle.purpleSoft)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        Capsule(style: .continuous)
                            .fill(EntryOnboardingStyle.purple.opacity(0.12))
                    )
                }
                .buttonStyle(EntryOnboardingTactileButtonStyle())
                .opacity(ratingContentVisible ? 1 : 0)
                .offset(y: ratingContentVisible ? 0 : 24)
                .animation(.smooth(duration: 0.34).delay(0.22), value: ratingContentVisible)
            }
            .padding(.top, 44)
            .onAppear {
                ratingContentVisible = false
                withAnimation(.smooth(duration: 0.1)) {
                    ratingContentVisible = true
                }
            }
        }
    }

    private func testimonialCard(_ testimonial: RatingTestimonial) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
                Circle()
                    .fill(EntryOnboardingStyle.primaryGradient)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(String(testimonial.name.prefix(1)))
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    )

                Text(testimonial.name)
                    .font(.system(size: 23, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                HStack(spacing: 3) {
                    ForEach(0..<testimonial.stars, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(EntryOnboardingStyle.purple)
                    }
                }
            }

            Text(testimonial.quote)
                .font(.system(size: 21, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.76))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(26)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}

private struct RatingTestimonial: Identifiable {
    let id = UUID()
    let name: String
    let stars: Int
    let quote: String
}

struct EntryRatingPrompt: View {
    @Binding var rating: Int
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.46)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(EntryOnboardingStyle.primaryGradient)
                    .frame(width: 86, height: 86)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .shadow(color: EntryOnboardingStyle.purple.opacity(0.42), radius: 18, x: 0, y: 12)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Enjoying AIScend?")
                        .font(.system(size: 25, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Tap a star to rate the onboarding experience.")
                        .font(.system(size: 21, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.58))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .frame(height: 1)

                HStack {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            EntryOnboardingHaptics.success()
                            rating = star
                            onDismiss()
                        } label: {
                            Image(systemName: rating >= star ? "star.fill" : "star")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(Color(hex: "4EA1FF"))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(EntryOnboardingTactileButtonStyle())
                        .accessibilityLabel("\(star) star rating")
                    }
                }

                Button {
                    EntryOnboardingHaptics.tap()
                    onDismiss()
                } label: {
                    Text("Not Now")
                        .font(.system(size: 25, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 68)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.white.opacity(0.12))
                        )
                }
                .buttonStyle(EntryOnboardingTactileButtonStyle())
            }
            .padding(34)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(Color.black.opacity(0.44))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .padding(.horizontal, 34)
        }
    }
}

#Preview {
    EntryRatingOnboardingPage(rating: .constant(0), showsRatingPrompt: .constant(false))
        .background(Color.black)
}
