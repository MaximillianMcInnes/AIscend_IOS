//
//  AppDelegate.swift
//  AIscend
//
//  Created by Codex on 4/7/26.
//

import UIKit
import SuperwallKit
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

final class AppDelegate: NSObject, UIApplicationDelegate {
    private enum SuperwallLaunch {
        static let apiKey = "pk_6750fbulEXt9xHcHcXmQQ"
        static let placement = "campaign_trigger"
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseBootstrapper.configure()
        Superwall.configure(apiKey: SuperwallLaunch.apiKey)

        DispatchQueue.main.async {
            Superwall.shared.register(placement: SuperwallLaunch.placement)
        }

        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        #if canImport(GoogleSignIn)
        return GIDSignIn.sharedInstance.handle(url)
        #else
        return false
        #endif
    }
}
