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
        setupElevatedDarkColors()
        setupWindowBackground()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(themeManager)
                .environment(\.di, DIContainer.bootstrap())
                .preferredColorScheme(themeManager.colorScheme)
                .background(themeManager.backgroundColor.ignoresSafeArea())
        }
    }
    
    private func setupWindowBackground() {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            for window in windowScene.windows {
                // Elevated dark için window background
                if ThemeManager.shared.colorSchemePreference == .elevatedDark {
                    window.backgroundColor = UIColor.systemGray6
                } else {
                    window.backgroundColor = UIColor.systemBackground
                }
            }
        }
    }
    
    private func setupElevatedDarkColors() {
        let lightAppearance = UINavigationBarAppearance()
        lightAppearance.configureWithOpaqueBackground()
        lightAppearance.backgroundColor = UIColor.systemBackground
        
        let darkAppearance = UINavigationBarAppearance()
        darkAppearance.configureWithOpaqueBackground()
        darkAppearance.backgroundColor = UIColor.systemGray5 // Elevated dark
        
        UINavigationBar.appearance().standardAppearance = lightAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = lightAppearance
        
        // Dark mode'da elevated renkleri kullan
        if #available(iOS 15.0, *) {
            UINavigationBar.appearance(for: UITraitCollection(userInterfaceStyle: .dark)).standardAppearance = darkAppearance
            UINavigationBar.appearance(for: UITraitCollection(userInterfaceStyle: .dark)).scrollEdgeAppearance = darkAppearance
        }
        
        let lightTabAppearance = UITabBarAppearance()
        lightTabAppearance.configureWithOpaqueBackground()
        lightTabAppearance.backgroundColor = UIColor.systemBackground
        
        let darkTabAppearance = UITabBarAppearance()
        darkTabAppearance.configureWithOpaqueBackground()
        darkTabAppearance.backgroundColor = UIColor.systemGray5 // Elevated dark
        
        UITabBar.appearance().standardAppearance = lightTabAppearance
        UITabBar.appearance().scrollEdgeAppearance = lightTabAppearance
        
        if #available(iOS 15.0, *) {
            UITabBar.appearance(for: UITraitCollection(userInterfaceStyle: .dark)).standardAppearance = darkTabAppearance
            UITabBar.appearance(for: UITraitCollection(userInterfaceStyle: .dark)).scrollEdgeAppearance = darkTabAppearance
        }
    }
}
