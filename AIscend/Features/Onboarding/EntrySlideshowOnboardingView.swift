//
//  EntrySlideshowOnboardingView.swift
//  AIscend
//

import SwiftUI

private struct EntrySlideshowPage: Identifiable {
    let id: Int
    let imageName: String
    let title: String
    let subtitle: String
}

struct EntrySlideshowOnboardingView: View {
    @Bindable var model: AppModel
    @State private var selection = 0

    private let pages: [EntrySlideshowPage] = [
        EntrySlideshowPage(
            id: 0,
            imageName: "onboarding-slide-1",
            title: "Predict your score",
            subtitle: "Input your details to discover your facial potential"
        ),
        EntrySlideshowPage(
            id: 1,
            imageName: "onboarding-slide-2",
            title: "Track your changes",
            subtitle: "Watch every scan turn into a clear progress update"
        ),
        EntrySlideshowPage(
            id: 2,
            imageName: "onboarding-slide-3",
            title: "Find your best angles",
            subtitle: "Use front and side reads to understand what stands out"
        ),
        EntrySlideshowPage(
            id: 3,
            imageName: "onboarding-slide-4",
            title: "Build your routine",
            subtitle: "Turn your scan into practical daily improvements"
        ),
        EntrySlideshowPage(
            id: 4,
            imageName: "onboarding-slide-5",
            title: "Start your ascent",
            subtitle: "Sign in once and keep your results in one place"
        )
    ]

    var body: some View {
        GeometryReader { geometry in
            let metrics = EntrySlideshowMetrics(size: geometry.size, safeAreaInsets: geometry.safeAreaInsets)

            ZStack(alignment: .top) {
                purpleBackground

                VStack(spacing: 0) {
                    TabView(selection: $selection) {
                        ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                            phoneStage(page: page, metrics: metrics)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: metrics.stageHeight)
                    .clipped()

                    Spacer(minLength: metrics.bottomHeight - metrics.panelOverlap)
                }

                languagePill(metrics: metrics)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, metrics.sideInset)
                    .padding(.top, metrics.languageTop)

                bottomPanel(metrics: metrics)
                    .frame(height: metrics.bottomHeight)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var currentPage: EntrySlideshowPage {
        pages[min(selection, pages.count - 1)]
    }

    private var isLastPage: Bool {
        selection == pages.count - 1
    }

    private var purpleBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.18, green: 0.02, blue: 0.48),
                Color(red: 0.37, green: 0.10, blue: 0.68),
                Color(red: 0.63, green: 0.37, blue: 0.90)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func languagePill(metrics: EntrySlideshowMetrics) -> some View {
        HStack(spacing: 14) {
            Text("🇺🇸")
                .font(.system(size: metrics.languageFontSize))

            Text("EN")
                .font(.system(size: metrics.languageFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, metrics.languageHorizontalPadding)
        .frame(height: metrics.languageHeight)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.09))
        )
    }

    private func phoneStage(page: EntrySlideshowPage, metrics: EntrySlideshowMetrics) -> some View {
        ZStack {
            phoneMock(page: page, metrics: metrics)
                .frame(width: metrics.phoneWidth)
                .offset(y: metrics.phoneYOffset)

            Text("Monthly update")
                .font(.system(size: metrics.calloutFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, metrics.calloutHorizontalPadding)
                .frame(height: metrics.calloutHeight)
                .frame(maxWidth: metrics.calloutMaxWidth)
                .background(
                    Capsule(style: .continuous)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 0)
                )
                .overlay(Capsule(style: .continuous).stroke(Color.black.opacity(0.18), lineWidth: metrics.calloutStrokeWidth))
                .offset(x: -metrics.phoneWidth * 0.36, y: metrics.phoneWidth * 0.52)

            Text("+0.1 inches")
                .font(.system(size: metrics.calloutFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, metrics.calloutHorizontalPadding)
                .frame(height: metrics.calloutHeight)
                .frame(maxWidth: metrics.calloutMaxWidth)
                .background(
                    Capsule(style: .continuous)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 0)
                )
                .overlay(Capsule(style: .continuous).stroke(Color.black.opacity(0.18), lineWidth: metrics.calloutStrokeWidth))
                .offset(x: metrics.phoneWidth * 0.44, y: metrics.phoneWidth * 0.34)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func phoneMock(page: EntrySlideshowPage, metrics: EntrySlideshowMetrics) -> some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: metrics.phoneCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: metrics.phoneCornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: metrics.phoneBorderWidth)
                )

            RoundedRectangle(cornerRadius: metrics.phoneCornerRadius - 5, style: .continuous)
                .fill(Color.black)
                .padding(metrics.phoneInset)

            VStack(alignment: .leading, spacing: metrics.phoneContentSpacing) {
                phoneTopBar(metrics: metrics)

                HStack(spacing: metrics.phoneContentSpacing) {
                    miniMetric(title: "Current", value: "71", highlighted: false, metrics: metrics)
                    miniMetric(title: "Predicted", value: "83", highlighted: true, metrics: metrics)
                }

                Text("Optimize up to 12 points 📈")
                    .font(.system(size: metrics.phoneBodyFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity)
                    .frame(height: metrics.phoneStripHeight)
                    .background(RoundedRectangle(cornerRadius: metrics.phoneCardRadius).fill(Color.white.opacity(0.10)))

                slideImagePlaceholder(page: page, metrics: metrics)

                Text("Stronger than 76.7% of your age 🌎")
                    .font(.system(size: metrics.phoneBodyFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .frame(height: metrics.phoneStripHeight)
                    .background(RoundedRectangle(cornerRadius: metrics.phoneCardRadius).fill(Color(red: 0.39, green: 0.20, blue: 0.65).opacity(0.42)))

                HStack(spacing: metrics.phoneContentSpacing) {
                    miniStat(title: "Dream score odds", value: "68%", metrics: metrics)
                    miniStat(title: "Growth complete", value: "89.8%", metrics: metrics)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, metrics.phoneHorizontalPadding)
            .padding(.top, metrics.phoneTopPadding)
            .padding(.bottom, metrics.phoneHorizontalPadding)

            RoundedRectangle(cornerRadius: metrics.notchHeight * 0.5, style: .continuous)
                .fill(Color.black)
                .frame(width: metrics.notchWidth, height: metrics.notchHeight)
                .padding(.top, metrics.phoneInset + 4)
        }
        .aspectRatio(0.53, contentMode: .fit)
        .shadow(color: Color.black.opacity(0.24), radius: 26, x: 0, y: 18)
    }

    private func phoneTopBar(metrics: EntrySlideshowMetrics) -> some View {
        HStack {
            Text("Last report")
                .font(.system(size: metrics.phoneTitleFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            Image(systemName: "gearshape.fill")
                .font(.system(size: metrics.phoneIconFontSize, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: metrics.phoneIconSize, height: metrics.phoneIconSize)
                .background(Circle().fill(Color.white.opacity(0.12)))
        }
    }

    private func slideImagePlaceholder(page: EntrySlideshowPage, metrics: EntrySlideshowMetrics) -> some View {
        ZStack {
            if UIImage(named: page.imageName) != nil {
                Image(page.imageName)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.07))

                Path { path in
                    path.move(to: CGPoint(x: 20, y: 132))
                    path.addCurve(to: CGPoint(x: 145, y: 96), control1: CGPoint(x: 56, y: 124), control2: CGPoint(x: 88, y: 108))
                    path.addCurve(to: CGPoint(x: 270, y: 66), control1: CGPoint(x: 190, y: 82), control2: CGPoint(x: 218, y: 70))
                    path.addLine(to: CGPoint(x: 330, y: 66))
                }
                .stroke(Color(red: 0.58, green: 0.27, blue: 0.96), style: StrokeStyle(lineWidth: 4, lineCap: .round))

                Circle()
                    .stroke(.white, lineWidth: 6)
                    .fill(Color(red: 0.58, green: 0.27, blue: 0.96))
                    .frame(width: 34, height: 34)
                    .offset(x: -8, y: 8)
            }
        }
        .frame(height: metrics.chartHeight)
        .clipShape(RoundedRectangle(cornerRadius: metrics.phoneCardRadius, style: .continuous))
    }

    private func miniMetric(title: String, value: String, highlighted: Bool = false, metrics: EntrySlideshowMetrics) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: metrics.phoneSmallFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(1)

            Text(value)
                .font(.system(size: metrics.phoneMetricFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(metrics.phoneCardPadding)
        .frame(height: metrics.metricCardHeight)
        .background(
            RoundedRectangle(cornerRadius: metrics.phoneCardRadius, style: .continuous)
                .fill(highlighted ? Color(red: 0.56, green: 0.30, blue: 0.91) : Color.white.opacity(0.10))
        )
    }

    private func miniStat(title: String, value: String, metrics: EntrySlideshowMetrics) -> some View {
        VStack(spacing: metrics.miniStatSpacing) {
            Text(title)
                .font(.system(size: metrics.phoneTinyFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.64))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(value)
                .font(.system(size: metrics.phoneStatFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.86))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Capsule(style: .continuous)
                .fill(Color(red: 0.62, green: 0.34, blue: 0.95).opacity(0.86))
                .frame(height: metrics.statBarHeight)
        }
        .frame(maxWidth: .infinity)
        .padding(metrics.phoneCardPadding)
        .frame(height: metrics.statCardHeight)
        .background(
            RoundedRectangle(cornerRadius: metrics.phoneCardRadius, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }

    private func bottomPanel(metrics: EntrySlideshowMetrics) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: metrics.panelSectionSpacing) {
                VStack(spacing: metrics.textSpacing) {
                    Text(currentPage.title)
                        .font(.system(size: metrics.titleFontSize, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.58)
                        .allowsTightening(true)

                    Text(currentPage.subtitle)
                        .font(.system(size: metrics.subtitleFontSize, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .lineSpacing(metrics.subtitleLineSpacing)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                        .padding(.horizontal, metrics.subtitleHorizontalPadding)
                }

                pageDots(metrics: metrics)

                Button(action: handlePrimaryAction) {
                    Text("Let’s start")
                        .font(.system(size: metrics.buttonFontSize, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: metrics.buttonHeight)
                        .background(
                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.56, green: 0.29, blue: 0.91),
                                            Color(red: 0.68, green: 0.43, blue: 0.98)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color(red: 0.55, green: 0.24, blue: 0.93).opacity(0.36), radius: 28, x: 0, y: 14)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, metrics.buttonTopPadding)

                Button(action: finishOnboarding) {
                    Text("You already have an account?")
                        .font(.system(size: metrics.accountFontSize, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.84))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, metrics.sideInset)
            .padding(.top, metrics.panelTopPadding)
            .padding(.bottom, metrics.panelBottomPadding)
            .frame(maxWidth: .infinity)
            .frame(height: metrics.bottomHeight)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: metrics.panelCornerRadius,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: metrics.panelCornerRadius,
                    style: .continuous
                )
                .fill(Color.black)
            )
        }
    }

    private func pageDots(metrics: EntrySlideshowMetrics) -> some View {
        HStack(spacing: metrics.dotSpacing) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index == selection ? Color(red: 0.58, green: 0.27, blue: 0.96) : Color.white.opacity(0.18))
                    .frame(width: index == selection ? metrics.activeDotWidth : metrics.dotSize, height: metrics.dotSize)
                    .animation(.smooth(duration: 0.22), value: selection)
            }
        }
    }

    private func handlePrimaryAction() {
        guard selection != 0, !isLastPage else {
            finishIntro()
            return
        }

        withAnimation(.smooth(duration: 0.28)) {
            selection += 1
        }
    }

    private func finishOnboarding() {
        withAnimation(.smooth(duration: 0.35)) {
            model.completeEntryOnboarding()
        }
    }

    private func finishIntro() {
        withAnimation(.smooth(duration: 0.35)) {
            model.completeEntryIntro()
        }
    }
}

#Preview {
    EntrySlideshowOnboardingView(model: AppModel())
}

private struct EntrySlideshowMetrics {
    let size: CGSize
    let safeAreaInsets: EdgeInsets

    var isCompactHeight: Bool { size.height < 760 }
    var sideInset: CGFloat { size.width < 390 ? 26 : 36 }
    var panelOverlap: CGFloat { 34 }
    var bottomHeight: CGFloat { min(max(size.height * 0.40, isCompactHeight ? 300 : 326), 370) }
    var stageHeight: CGFloat { max(size.height - bottomHeight + panelOverlap, 410) }

    var languageTop: CGFloat { max(safeAreaInsets.top + 8, 18) }
    var languageHeight: CGFloat { isCompactHeight ? 54 : 62 }
    var languageFontSize: CGFloat { isCompactHeight ? 18 : 21 }
    var languageHorizontalPadding: CGFloat { isCompactHeight ? 19 : 23 }

    var phoneAvailableHeight: CGFloat { stageHeight - safeAreaInsets.top - 24 }
    var phoneWidth: CGFloat {
        min(size.width * 0.58, phoneAvailableHeight * 0.53, isCompactHeight ? 218 : 248)
    }
    var phoneYOffset: CGFloat { safeAreaInsets.top + (isCompactHeight ? 18 : 32) }
    var phoneCornerRadius: CGFloat { phoneWidth * 0.13 }
    var phoneBorderWidth: CGFloat { max(phoneWidth * 0.012, 2.5) }
    var phoneInset: CGFloat { max(phoneWidth * 0.018, 5) }
    var notchWidth: CGFloat { phoneWidth * 0.29 }
    var notchHeight: CGFloat { phoneWidth * 0.07 }
    var phoneHorizontalPadding: CGFloat { phoneWidth * 0.068 }
    var phoneTopPadding: CGFloat { phoneWidth * 0.18 }
    var phoneContentSpacing: CGFloat { phoneWidth * 0.028 }
    var phoneCardPadding: CGFloat { phoneWidth * 0.036 }
    var phoneCardRadius: CGFloat { phoneWidth * 0.045 }
    var metricCardHeight: CGFloat { phoneWidth * 0.205 }
    var phoneStripHeight: CGFloat { phoneWidth * 0.125 }
    var chartHeight: CGFloat { phoneWidth * 0.34 }
    var statCardHeight: CGFloat { phoneWidth * 0.20 }
    var miniStatSpacing: CGFloat { phoneWidth * 0.014 }
    var statBarHeight: CGFloat { max(phoneWidth * 0.018, 4) }

    var phoneTitleFontSize: CGFloat { phoneWidth * 0.064 }
    var phoneBodyFontSize: CGFloat { phoneWidth * 0.038 }
    var phoneSmallFontSize: CGFloat { phoneWidth * 0.03 }
    var phoneTinyFontSize: CGFloat { phoneWidth * 0.024 }
    var phoneMetricFontSize: CGFloat { phoneWidth * 0.082 }
    var phoneStatFontSize: CGFloat { phoneWidth * 0.056 }
    var phoneIconFontSize: CGFloat { phoneWidth * 0.04 }
    var phoneIconSize: CGFloat { phoneWidth * 0.09 }

    var calloutFontSize: CGFloat { isCompactHeight ? 15 : 17 }
    var calloutHeight: CGFloat { isCompactHeight ? 42 : 48 }
    var calloutMaxWidth: CGFloat { size.width * 0.43 }
    var calloutHorizontalPadding: CGFloat { isCompactHeight ? 14 : 18 }
    var calloutStrokeWidth: CGFloat { 2 }

    var panelCornerRadius: CGFloat { size.width < 390 ? 42 : 52 }
    var panelTopPadding: CGFloat { isCompactHeight ? 54 : 66 }
    var panelBottomPadding: CGFloat { max(safeAreaInsets.bottom + 16, 28) }
    var panelSectionSpacing: CGFloat { isCompactHeight ? 18 : 22 }
    var textSpacing: CGFloat { isCompactHeight ? 10 : 14 }
    var titleFontSize: CGFloat { min(size.width * 0.105, isCompactHeight ? 37 : 43) }
    var subtitleFontSize: CGFloat { min(size.width * 0.052, isCompactHeight ? 18 : 21) }
    var subtitleLineSpacing: CGFloat { 4 }
    var subtitleHorizontalPadding: CGFloat { size.width < 390 ? 8 : 16 }
    var dotSpacing: CGFloat { isCompactHeight ? 12 : 14 }
    var dotSize: CGFloat { isCompactHeight ? 12 : 14 }
    var activeDotWidth: CGFloat { isCompactHeight ? 32 : 38 }
    var buttonTopPadding: CGFloat { isCompactHeight ? 8 : 12 }
    var buttonHeight: CGFloat { isCompactHeight ? 62 : 74 }
    var buttonFontSize: CGFloat { isCompactHeight ? 22 : 25 }
    var accountFontSize: CGFloat { isCompactHeight ? 17 : 20 }
}
