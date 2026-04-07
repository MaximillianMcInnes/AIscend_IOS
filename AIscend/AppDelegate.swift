//
//  AppDelegate.swift
//  AIscend
//
//  Created by Codex on 4/7/26.
//

import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseBootstrapper.configure()
        return true
    }
}
