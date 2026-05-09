//
//  EntryNotificationsOnboardingPage.swift
//  AIscend
//

import SwiftUI
import UIKit
import UserNotifications

struct EntryNotificationsOnboardingPage: View {
    @Environment(\.openURL) private var openURL
    @Binding var draft: EntryOnboardingDraft
    @State private var isRequestingPermission = false

    var body: some View {
        EntryOnboardingPageContainer(
            title: "Turn on progress nudges?",
            subtitle: "AIScend can remind you at the right moments, without crowding your day.",
            usesTypewriterSubtitle: false
        ) {
            VStack(spacing: 26) {
                notificationVisual

                VStack(spacing: 14) {
                    Button {
                        requestNotifications()
                    } label: {
                        HStack(spacing: 14) {
                            if isRequestingPermission {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "bell.badge.fill")
                                    .font(.system(size: 22, weight: .bold))
                            }

                            Text(notificationButtonTitle)
                                .font(.system(size: 20, weight: .heavy, design: .rounded))

                            Spacer()
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 26)
                        .frame(maxWidth: .infinity)
                        .frame(height: 70)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(EntryOnboardingStyle.primaryGradient)
                                .shadow(
                                    color: EntryOnboardingStyle.purple.opacity(0.36),
                                    radius: 26,
                                    x: 0,
                                    y: 14
                                )
                        )
                    }
                    .buttonStyle(EntryOnboardingTactileButtonStyle())
                    .disabled(isRequestingPermission)

                    Button {
                        EntryOnboardingHaptics.tap()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            draft.notificationChoice = .skipped
                        }
                    } label: {
                        Text(draft.notificationChoice == .skipped ? "Skipped for now" : "Not now")
                            .font(.system(size: 19, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(Color.white.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Color.white.opacity(draft.notificationChoice == .skipped ? 0.22 : 0.08), lineWidth: 1)
                            )
                    }
                    .buttonStyle(EntryOnboardingTactileButtonStyle())
                }
            }
            .padding(.top, 28)
            .task {
                await refreshNotificationChoice()
            }
        }
    }

    private var notificationButtonTitle: String {
        switch draft.notificationChoice {
        case .allowed:
            "Notifications on"
        case .denied:
            "Open notifications in Settings"
        case .skipped:
            "Enable instead"
        case nil:
            "Enable notifications"
        }
    }

    private var notificationVisual: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white.opacity(0.055))
                .frame(height: 228)
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(EntryOnboardingStyle.purple.opacity(0.18))
                        .frame(width: 104, height: 104)

                    Image(systemName: "bell.and.waves.left.and.right.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(EntryOnboardingStyle.purpleSoft)
                        .symbolEffect(.pulse, options: .repeating, value: draft.notificationChoice == nil)
                }

                Text("Daily check-ins, scan reminders, and streak saves.")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.74))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
        }
    }

    private func requestNotifications() {
        guard !isRequestingPermission else {
            return
        }

        if draft.notificationChoice == .denied, let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            EntryOnboardingHaptics.tap()
            openURL(settingsURL)
            return
        }

        EntryOnboardingHaptics.advance()

        Task {
            await requestNotificationPermission()
        }
    }

    @MainActor
    private func refreshNotificationChoice() async {
        let settings = await notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                draft.notificationChoice = .allowed
            }
        case .denied:
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                draft.notificationChoice = .denied
            }
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    @MainActor
    private func requestNotificationPermission() async {
        isRequestingPermission = true
        defer { isRequestingPermission = false }

        let settings = await notificationSettings()
        let granted: Bool

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            granted = true
        case .denied:
            granted = false
        case .notDetermined:
            granted = await askForNotificationAuthorization()
        @unknown default:
            granted = false
        }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            draft.notificationChoice = granted ? .allowed : .denied
        }

        granted ? EntryOnboardingHaptics.success() : EntryOnboardingHaptics.warning()
    }

    private func notificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    private func askForNotificationAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }
}

#Preview {
    EntryNotificationsOnboardingPage(draft: .constant(EntryOnboardingDraft()))
        .background(Color.black)
}
