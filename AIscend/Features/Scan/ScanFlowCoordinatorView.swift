//
//  ScanFlowCoordinatorView.swift
//  AIscend
//

import SwiftUI

struct ScanFlowCoordinatorView: View {
    let session: AuthSessionStore
    let onOpenRoutine: () -> Void
    let onOpenChat: () -> Void
    let onReturnHome: () -> Void
    let onDismiss: () -> Void

    @ObservedObject private var badgeManager: BadgeManager
    @ObservedObject private var dailyCheckInStore: DailyCheckInStore
    @ObservedObject private var notificationManager: NotificationManager

    init(
        session: AuthSessionStore,
        badgeManager: BadgeManager,
        dailyCheckInStore: DailyCheckInStore,
        notificationManager: NotificationManager,
        onOpenRoutine: @escaping () -> Void = {},
        onOpenChat: @escaping () -> Void = {},
        onReturnHome: @escaping () -> Void = {},
        onDismiss: @escaping () -> Void = {}
    ) {
        self.session = session
        self.onOpenRoutine = onOpenRoutine
        self.onOpenChat = onOpenChat
        self.onReturnHome = onReturnHome
        self.onDismiss = onDismiss
        self._badgeManager = ObservedObject(wrappedValue: badgeManager)
        self._dailyCheckInStore = ObservedObject(wrappedValue: dailyCheckInStore)
        self._notificationManager = ObservedObject(wrappedValue: notificationManager)
    }

    var body: some View {
        ScanCaptureFlowView(
            session: session,
            badgeManager: badgeManager,
            dailyCheckInStore: dailyCheckInStore,
            notificationManager: notificationManager,
            onOpenRoutine: onOpenRoutine,
            onOpenChat: onOpenChat,
            onReturnHome: onReturnHome,
            onDismiss: onDismiss
        )
    }
}
