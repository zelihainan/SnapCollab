//
//  SnapCollabApp.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
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
        }
    }
}

