//
//  StreakHubView.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import SwiftUI

struct StreakHubView: View {
    @ObservedObject var dailyCheckInStore: DailyCheckInStore
    @ObservedObject var badgeManager: BadgeManager
    @ObservedObject var notificationManager: NotificationManager

    let onOpenCheckIn: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        StreaksView(
            dailyCheckInStore: dailyCheckInStore,
            badgeManager: badgeManager,
            notificationManager: notificationManager,
            onOpenCheckIn: onOpenCheckIn,
            onDismiss: onDismiss
        )
    }
}
