//
//  EyesResultsPage.swift
//  AIscend
//

import SwiftUI

struct EyesResultsPage: View {
    @ObservedObject var viewModel: ScanResultsViewModel
    let pageIndex: Int
    let onShare: () -> Void
    let onContinue: () -> Void
    let onUpgrade: () -> Void

    var body: some View {
        FeatureResultsPage(
            pageIndex: pageIndex,
            totalPages: viewModel.pageCount,
            title: viewModel.title(for: .eyes),
            subtitle: viewModel.subtitle(for: .eyes),
            badge: viewModel.isPremium ? nil : "Preview",
            traits: viewModel.sectionTraits(for: .eyes),
            showsInlineUpsell: !viewModel.isPremium,
            onShare: onShare,
            onContinue: onContinue,
            onUpgrade: onUpgrade
        )
    }
}
