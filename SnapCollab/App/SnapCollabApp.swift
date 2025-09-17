//
//  SnapCollabApp.swift
//  SnapCollab
//

import SwiftUI
import FirebaseCore

@main
struct SnapCollabApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var themeManager = ThemeManager.shared

    init() {
        FirebaseApp.configure()
        setupSoftDarkColors()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(themeManager)
                .environment(\.di, DIContainer.bootstrap())
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
    
    private func setupSoftDarkColors() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
            if #available(iOS 15.0, *) {
            appearance.backgroundColor = UIColor.systemGray6
        }
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        
        if #available(iOS 15.0, *) {
            tabAppearance.backgroundColor = UIColor.systemGray6
        }
        
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}
