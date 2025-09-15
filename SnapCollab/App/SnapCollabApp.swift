//
//  SnapCollabApp.swift
//  SnapCollab
//
//

import SwiftUI
import FirebaseCore

@main
struct SnapCollabApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var fontManager = FontManager.shared

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(fontManager)
                .environment(\.di, DIContainer.bootstrap())
        }
    }
}
