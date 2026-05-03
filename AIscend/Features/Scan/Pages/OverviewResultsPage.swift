//
//  OverviewResultsPage.swift
//  AIscend
//

import SwiftUI

struct OverviewResultsPage: View {
    @ObservedObject var viewModel: ScanResultsViewModel
    let pageIndex: Int
    let onShare: () -> Void
    let onContinue: () -> Void

    var body: some View {
        RatingsResultsPage(
            pageIndex: pageIndex,
            totalPages: viewModel.pageCount,
            title: viewModel.title(for: .overview),
            subtitle: viewModel.subtitle(for: .overview),
            result: viewModel.result,
            scoreCards: viewModel.scoreCards,
            onShare: onShare,
            onContinue: onContinue
        )
    }
}
