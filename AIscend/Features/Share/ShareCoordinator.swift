//
//  ShareCoordinator.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import Foundation
import SwiftUI

@MainActor
final class ShareCoordinator: ObservableObject {
    @Published var activePayload: AIScendSharePayload?

    func present(_ payload: AIScendSharePayload) {
        activePayload = payload
    }

    func dismiss() {
        activePayload = nil
    }
}
