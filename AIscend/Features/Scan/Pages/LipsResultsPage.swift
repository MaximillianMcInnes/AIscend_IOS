//
//  LipsResultsPage.swift
//  AIscend
//

import SwiftUI

struct LipsResultsPage: View {
    @ObservedObject var viewModel: ScanResultsViewModel
    let pageIndex: Int
    let onShare: () -> Void
    let onContinue: () -> Void
    let onUpgrade: () -> Void

    var body: some View {
        FeatureResultsPage(
            pageIndex: pageIndex,
            totalPages: viewModel.pageCount,
            title: viewModel.title(for: .lips),
            subtitle: viewModel.subtitle(for: .lips),
            badge: nil,
            traits: viewModel.sectionTraits(for: .lips),
            showsInlineUpsell: false,
            onShare: onShare,
            onContinue: onContinue,
            onUpgrade: onUpgrade
        )
    }
}
