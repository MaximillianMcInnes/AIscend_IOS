//
//  SideProfileResultsPage.swift
//  AIscend
//

import SwiftUI

struct SideProfileResultsPage: View {
    @ObservedObject var viewModel: ScanResultsViewModel
    let pageIndex: Int
    let onShare: () -> Void
    let onContinue: () -> Void
    let onUpgrade: () -> Void

    var body: some View {
        FeatureResultsPage(
            pageIndex: pageIndex,
            totalPages: viewModel.pageCount,
            title: viewModel.title(for: .sideProfile),
            subtitle: viewModel.subtitle(for: .sideProfile),
            badge: "Premium",
            traits: viewModel.sectionTraits(for: .sideProfile),
            showsInlineUpsell: false,
            onShare: onShare,
            onContinue: onContinue,
            onUpgrade: onUpgrade
        )
    }
}
