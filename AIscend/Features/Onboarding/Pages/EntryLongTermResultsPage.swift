//
//  EntryLongTermResultsPage.swift
//  AIscend
//

import SwiftUI

struct EntryLongTermResultsPage: View {
    var body: some View {
        EntryOnboardingPageContainer(
            title: "Your attractiveness curve should be visible",
            subtitle: "Consistent photos and tiny daily actions make progress easier to see instead of guess."
        ) {
            ResultsChartCard()
                .padding(.top, 26)
        }
    }
}

private struct ResultsChartCard: View {
    @State private var drawProgress = false
    @State private var pointPulse = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Attractiveness curve")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            GeometryReader { geometry in
                ZStack {
                    VStack(spacing: 0) {
                        ForEach(0..<4, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.white.opacity(0.10))
                                .frame(height: 1)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .padding(.horizontal, 8)

                    CurvePath(yOffset: 34, endLift: 0.42)
                        .trim(from: 0, to: drawProgress ? 1 : 0)
                        .stroke(Color(hex: "FF553E"), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                        .shadow(color: Color(hex: "FF553E").opacity(0.28), radius: 10, x: 0, y: 0)

                    CurvePath(yOffset: 0, endLift: 0.78)
                        .trim(from: 0, to: drawProgress ? 1 : 0)
                        .stroke(EntryOnboardingStyle.purpleSoft, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                        .shadow(color: EntryOnboardingStyle.purpleSoft.opacity(0.52), radius: 16, x: 0, y: 0)
                        .animation(.easeInOut(duration: 1.05).delay(0.18), value: drawProgress)

                    chartPoint(
                        color: EntryOnboardingStyle.purple,
                        position: CGPoint(x: 26, y: geometry.size.height * 0.76)
                    )

                    chartPoint(
                        color: EntryOnboardingStyle.purpleSoft,
                        position: CGPoint(x: geometry.size.width - 26, y: geometry.size.height * 0.15)
                    )
                    .opacity(drawProgress ? 1 : 0)
                    .scaleEffect(drawProgress ? 1 : 0.72)
                    .animation(.spring(response: 0.42, dampingFraction: 0.72).delay(0.9), value: drawProgress)
                }
            }
            .frame(height: 218)

            HStack(spacing: 18) {
                legend(color: Color(hex: "FF553E"), title: "Untracked")
                legend(color: EntryOnboardingStyle.purpleSoft, title: "AIScend plan")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.045))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .onAppear {
            drawProgress = false
            pointPulse = false

            withAnimation(.easeInOut(duration: 0.95)) {
                drawProgress = true
            }

            withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true).delay(0.7)) {
                pointPulse = true
            }
        }
    }

    private func chartPoint(color: Color, position: CGPoint) -> some View {
        Circle()
            .fill(color)
            .frame(width: 22, height: 22)
            .overlay(Circle().stroke(.white, lineWidth: 4))
            .shadow(color: color.opacity(pointPulse ? 0.75 : 0.34), radius: pointPulse ? 18 : 8, x: 0, y: 0)
            .scaleEffect(pointPulse ? 1.08 : 0.94)
            .position(position)
    }

    private func legend(color: Color, title: String) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 14, height: 14)

            Text(title)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
        }
    }
}

private struct CurvePath: Shape {
    let yOffset: CGFloat
    let endLift: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let start = CGPoint(x: rect.minX + 20, y: rect.height * 0.76)
        let end = CGPoint(x: rect.maxX - 20, y: rect.height * (0.92 - endLift) + yOffset)

        path.move(to: start)
        path.addCurve(
            to: end,
            control1: CGPoint(x: rect.width * 0.32, y: rect.height * 0.55),
            control2: CGPoint(x: rect.width * 0.60, y: rect.height * (0.28 + yOffset / 260))
        )

        return path
    }
}

#Preview {
    EntryLongTermResultsPage()
        .background(Color.black)
}
