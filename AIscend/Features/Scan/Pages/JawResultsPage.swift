//
//  JawResultsPage.swift
//  AIscend
//

import SwiftUI

struct JawResultsPage: View {
    @ObservedObject var viewModel: ScanResultsViewModel
    let pageIndex: Int
    let onShare: () -> Void
    let onContinue: () -> Void
    let onUpgrade: () -> Void

    var body: some View {
        FeatureResultsPage(
            pageIndex: pageIndex,
            totalPages: viewModel.pageCount,
            title: viewModel.title(for: .jaw),
            subtitle: viewModel.subtitle(for: .jaw),
            badge: "Premium",
            traits: viewModel.sectionTraits(for: .jaw),
            showsInlineUpsell: false,
            onShare: onShare,
            onContinue: onContinue,
            onUpgrade: onUpgrade
        )
    }
}
