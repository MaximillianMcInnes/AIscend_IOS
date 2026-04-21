//
//  DashboardView.swift
//  AIscend
//

import SwiftUI

struct DashboardView: View {
    @Bindable var model: AppModel

    var onBeginCapture: () -> Void = {}

    private let horizontalPadding: CGFloat = 20

    var body: some View {
        GeometryReader { proxy in
            let contentWidth = proxy.size.width - (horizontalPadding * 2)

            ZStack(alignment: .top) {
                AIscendBackdrop()
                DashboardAmbientLayer()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {

                        header(width: contentWidth)
                        scoreCard(width: contentWidth)
                        progressCard(width: contentWidth)
                        photoCard(width: contentWidth)

                    }
                    .frame(width: contentWidth, alignment: .leading)
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }
                .frame(width: proxy.size.width, alignment: .leading)
            }
        }
    }
}

private struct Card<Content: View>: View {
    let width: CGFloat
    let content: Content

    init(width: CGFloat, @ViewBuilder content: () -> Content) {
        self.width = width
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(width: width, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.04))
            )
    }
}

//


struct GlassCard<Content: View>: View {
    var style: AIscendPanelStyle = .standard
    @ViewBuilder let content: Content

    init(
        style: AIscendPanelStyle = .standard,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AIscendTheme.Spacing.large)
            .background(style.fill)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.22), radius: 18, x: 0, y: 10)
    }
}

private extension DashboardView {

    func header(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Dashboard")
                .font(.largeTitle.bold())

            Text("Welcome back")
                .foregroundStyle(.secondary)
        }
        .frame(width: width, alignment: .leading)
    }

    func scoreCard(width: CGFloat) -> some View {
        Card(width: width) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Score")
                    .foregroundStyle(.secondary)

                Text("67")
                    .font(.largeTitle.bold())

                Text("Improving steadily")
                    .foregroundStyle(.secondary)
            }
        }
    }

    func progressCard(width: CGFloat) -> some View {
        Card(width: width) {
            VStack(alignment: .leading, spacing: 12) {

                Text("Progress")
                    .font(.headline)

                Rectangle()
                    .fill(Color.purple.opacity(0.3))
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    func photoCard(width: CGFloat) -> some View {
        Card(width: width) {
            VStack(alignment: .leading, spacing: 12) {

                Text("Daily Scan")
                    .font(.headline)

                Text("Capture today's baseline")
                    .foregroundStyle(.secondary)

                Button(action: onBeginCapture) {
                    Text("Start Scan")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
