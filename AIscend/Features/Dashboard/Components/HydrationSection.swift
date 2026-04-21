//
//  HydrationSection.swift
//  AIscend
//

import SwiftUI

struct HydrationSection: View {
    @ObservedObject var hydrationStore: HydrationTrackingStore
    @ObservedObject var electrolyteStore: ElectrolyteTrackingStore

    let onOpenHydration: () -> Void
    let onOpenChat: (String) -> Void

    var body: some View {
        HydrationDashboardCard(
            store: hydrationStore,
            electrolyteStore: electrolyteStore,
            onOpenHydration: onOpenHydration,
            onOpenChat: onOpenChat
        )
        .frame(maxWidth: .infinity)
    }
}