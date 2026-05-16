//
//  ScanFlowCoordinatorView.swift
//  AIscend
//

import SwiftUI

struct ScanFlowCoordinatorView: View {
    let session: AuthSessionStore
    let isPremium: Bool
    let onOpenRoutine: () -> Void
    let onOpenGlowUpPlan: (PersistedScanRecord) -> Void
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
        isPremium: Bool = false,
        onOpenRoutine: @escaping () -> Void = {},
        onOpenGlowUpPlan: @escaping (PersistedScanRecord) -> Void = { _ in },
        onOpenChat: @escaping () -> Void = {},
        onReturnHome: @escaping () -> Void = {},
        onDismiss: @escaping () -> Void = {}
    ) {
        self.session = session
        self.isPremium = isPremium
        self.onOpenRoutine = onOpenRoutine
        self.onOpenGlowUpPlan = onOpenGlowUpPlan
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
            isPremium: isPremium,
            onOpenRoutine: onOpenRoutine,
            onOpenGlowUpPlan: onOpenGlowUpPlan,
            onOpenChat: onOpenChat,
            onReturnHome: onReturnHome,
            onDismiss: onDismiss
        )
    }
}
