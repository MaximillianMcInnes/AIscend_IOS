//
//  FirebaseBootstrapper.swift
//  AIscend
//
//  Created by Codex on 4/7/26.
//

import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif

enum FirebaseBootstrapper {
    enum State: Equatable {
        case idle
        case ready
        case missingGoogleServiceInfo
        case missingFirebaseCore
    }

    private(set) static var state: State = .idle

    static var isReady: Bool {
        #if canImport(FirebaseCore)
        FirebaseApp.app() != nil || state == .ready
        #else
        false
        #endif
    }

    static var statusMessage: String? {
        switch state {
        case .idle, .ready:
            return nil
        case .missingGoogleServiceInfo:
            return "Add `GoogleService-Info.plist` to `AIscend/Resources/Configuration` so Firebase Auth can finish configuring."
        case .missingFirebaseCore:
            return "FirebaseCore is not linked yet, so authentication is unavailable."
        }
    }

    static func configure() {
        #if canImport(FirebaseCore)
        guard FirebaseApp.app() == nil else {
            state = .ready
            return
        }

        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            state = .missingGoogleServiceInfo
            #if DEBUG
            print("Firebase skipped: add GoogleService-Info.plist to the AIscend target from Resources/Configuration.")
            #endif
            return
        }

        FirebaseApp.configure()
        state = .ready
        #else
        state = .missingFirebaseCore
        #if DEBUG
        print("Firebase skipped: FirebaseCore is not linked yet.")
        #endif
        #endif
    }
}
