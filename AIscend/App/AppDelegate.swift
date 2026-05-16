//
//  AppDelegate.swift
//  AIscend
//
//  Created by Codex on 4/7/26.
//

import UIKit
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseBootstrapper.configure()
        AIScendSuperwallAnalytics.configureFromBundle()
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        #if canImport(SuperwallKit)
        if AIScendSuperwallDeepLinkHandler.handle(url) {
            return true
        }
        #endif

        #if canImport(GoogleSignIn)
        return GIDSignIn.sharedInstance.handle(url)
        #else
        return false
        #endif
    }
}
