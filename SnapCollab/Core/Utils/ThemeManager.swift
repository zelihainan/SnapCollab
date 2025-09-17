//
//  ThemeManager.swift 
//  SnapCollab
//

import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var colorSchemePreference: AppColorSchemePreference {
        didSet {
            UserDefaults.standard.set(colorSchemePreference.rawValue, forKey: "preferredColorScheme")
            // Ana thread'de UI güncellemesi için trigger
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    var colorScheme: ColorScheme? {
        switch colorSchemePreference {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    private init() {
        let savedPreference = UserDefaults.standard.string(forKey: "preferredColorScheme") ?? "system"
        self.colorSchemePreference = AppColorSchemePreference(rawValue: savedPreference) ?? .system
    }
    
    func setColorScheme(_ preference: AppColorSchemePreference) {
        colorSchemePreference = preference
    }
}

enum AppColorSchemePreference: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "Sistem"
        case .light: return "Açık"
        case .dark: return "Koyu"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    var iconName: String {
        switch self {
        case .system: return "gear"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}
