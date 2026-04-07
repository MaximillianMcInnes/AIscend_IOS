//
//  ContentView.swift
//  AIscend
//
//  Created by user294334 on 4/7/26.
//

import SwiftUI

struct ContentView: View {
    @State private var model: AppModel = AppModel()

    var body: some View {
        Group {
            if model.hasCompletedOnboarding {
                RoutineDashboardView(model: model)
            } else {
                OnboardingView(model: model)
            }
        }
        .animation(.smooth(duration: 0.35), value: model.hasCompletedOnboarding)
    }
}

#Preview {
    ContentView()
}
