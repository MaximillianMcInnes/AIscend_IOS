//
//  EntryHeightWeightOnboardingPage.swift
//  AIscend
//

import SwiftUI

struct EntryHeightWeightOnboardingPage: View {
    @Binding var draft: EntryOnboardingDraft
    @State private var controlsVisible = false

    private let feetRange = Array(3...7)
    private let inchesRange = Array(0...11)
    private let poundsRange = Array(80...300)
    private let centimetersRange = Array(120...220)
    private let kilogramsRange = Array(35...160)

    var body: some View {
        EntryOnboardingPageContainer(
            title: "Height & weight",
            subtitle: "This will be used to predict your height potential and create your custom plan.",
            usesTypewriterSubtitle: false
        ) {
            VStack(spacing: 24) {
                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 12) {
                        Text("Height")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        heightPickers
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 14)
                    .padding(.bottom, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(EntryOnboardingStyle.panelStrong)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 12) {
                        Text("Weight")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        weightPicker
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 14)
                    .padding(.bottom, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(EntryOnboardingStyle.panelStrong)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 286)
                .overlay(alignment: .center) {
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.10))
                            .frame(maxWidth: .infinity)

                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.10))
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 8)
                    .frame(height: 58)
                    .offset(y: 23)
                    .allowsHitTesting(false)
                }

                measurementToggle
            }
            .padding(.top, 24)
            .opacity(controlsVisible ? 1 : 0)
            .offset(y: controlsVisible ? 0 : 18)
            .animation(.spring(response: 0.44, dampingFraction: 0.84), value: controlsVisible)
            .onAppear {
                controlsVisible = false
                withAnimation(.smooth(duration: 0.12)) {
                    controlsVisible = true
                }
            }
        }
    }

    @ViewBuilder
    private var heightPickers: some View {
        if draft.usesMetricMeasurements {
            Picker("Height centimeters", selection: $draft.heightCentimeters) {
                ForEach(centimetersRange, id: \.self) { centimeters in
                    Text("\(centimeters) cm")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .tag(centimeters)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 202)
            .clipped()
            .onChange(of: draft.heightCentimeters) { _, _ in
                EntryOnboardingHaptics.selection()
            }
        } else {
            HStack(spacing: 8) {
                Picker("Feet", selection: $draft.heightFeet) {
                    ForEach(feetRange, id: \.self) { feet in
                        Text("\(feet) ft")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .tag(feet)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 202)
                .clipped()
                .onChange(of: draft.heightFeet) { _, _ in
                    EntryOnboardingHaptics.selection()
                }

                Picker("Inches", selection: $draft.heightInches) {
                    ForEach(inchesRange, id: \.self) { inches in
                        Text("\(inches) in")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .tag(inches)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 202)
                .clipped()
                .onChange(of: draft.heightInches) { _, _ in
                    EntryOnboardingHaptics.selection()
                }
            }
        }
    }

    @ViewBuilder
    private var weightPicker: some View {
        if draft.usesMetricMeasurements {
            Picker("Weight kilograms", selection: $draft.weightKilograms) {
                ForEach(kilogramsRange, id: \.self) { kilograms in
                    Text("\(kilograms) kg")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .tag(kilograms)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 202)
            .clipped()
            .onChange(of: draft.weightKilograms) { _, _ in
                EntryOnboardingHaptics.selection()
            }
        } else {
            Picker("Weight pounds", selection: $draft.weightPounds) {
                ForEach(poundsRange, id: \.self) { pounds in
                    Text("\(pounds) lb")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .tag(pounds)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 202)
            .clipped()
            .onChange(of: draft.weightPounds) { _, _ in
                EntryOnboardingHaptics.selection()
            }
        }
    }

    private var measurementToggle: some View {
        HStack(spacing: 22) {
            Text("Imperial")
                .font(.system(size: 19, weight: .heavy, design: .rounded))
                .foregroundStyle(draft.usesMetricMeasurements ? Color.white.opacity(0.42) : .white)

            Button {
                EntryOnboardingHaptics.tap()
                withAnimation(.smooth(duration: 0.22)) {
                    draft.usesMetricMeasurements.toggle()
                    syncMeasurementValues()
                }
            } label: {
                ZStack(alignment: draft.usesMetricMeasurements ? .trailing : .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.42))
                        .frame(width: 76, height: 42)

                    Circle()
                        .fill(.white)
                        .frame(width: 34, height: 34)
                        .padding(4)
                }
            }
            .buttonStyle(EntryOnboardingTactileButtonStyle())
            .accessibilityLabel("Measurement system")

            Text("Metric")
                .font(.system(size: 19, weight: .heavy, design: .rounded))
                .foregroundStyle(draft.usesMetricMeasurements ? .white : Color.white.opacity(0.42))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.07))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func syncMeasurementValues() {
        if draft.usesMetricMeasurements {
            let totalInches = draft.heightFeet * 12 + draft.heightInches
            draft.heightCentimeters = Int((Double(totalInches) * 2.54).rounded())
            draft.weightKilograms = Int((Double(draft.weightPounds) * 0.453592).rounded())
        } else {
            let totalInches = Int((Double(draft.heightCentimeters) / 2.54).rounded())
            draft.heightFeet = max(3, min(7, totalInches / 12))
            draft.heightInches = max(0, min(11, totalInches % 12))
            draft.weightPounds = Int((Double(draft.weightKilograms) * 2.20462).rounded())
        }
    }
}

#Preview {
    EntryHeightWeightOnboardingPage(draft: .constant(EntryOnboardingDraft()))
        .background(Color.black)
}
