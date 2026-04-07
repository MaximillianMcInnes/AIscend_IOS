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
    static func configure() {
        #if canImport(FirebaseCore)
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            #if DEBUG
            print("Firebase skipped: add GoogleService-Info.plist to the AIscend target.")
            #endif
            return
        }

        FirebaseApp.configure()
        #else
        #if DEBUG
        print("Firebase skipped: FirebaseCore is not linked yet.")
        #endif
        #endif
    }
}
