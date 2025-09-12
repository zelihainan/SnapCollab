//
//  SnapCollabApp.swift
//  SnapCollab
//
//  Onboarding sistemi eklendi
//

import SwiftUI
import FirebaseCore

@main
struct SnapCollabApp: App {
    @StateObject private var appState = AppState()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environment(\.di, DIContainer.bootstrap())
        }
    }
}
