//
//  AIscendApp.swift
//  AIscend
//
//  Created by user294334 on 4/7/26.
//

import SwiftUI

@main
struct AIscendApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        AIscendTheme.configureSystemAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
