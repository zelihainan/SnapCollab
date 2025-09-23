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
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    // Sistem dark mode'unu override etmek için
    var colorScheme: ColorScheme? {
        switch colorSchemePreference {
        case .system:
            return nil // Sistem ayarını takip et ama custom dark colors kullan
        case .light:
            return .light
        case .elevatedDark:
            return .dark // SwiftUI'ya dark diyoruz ama custom colors kullanacağız
        }
    }
    
    // Elevated dark mode için custom renkler
    var backgroundColor: Color {
        switch colorSchemePreference {
        case .light, .system:
            return Color(.systemBackground)
        case .elevatedDark:
            return Color(.systemGray5) // Elevated dark background
        }
    }
    
    var secondaryBackgroundColor: Color {
        switch colorSchemePreference {
        case .light, .system:
            return Color(.secondarySystemBackground)
        case .elevatedDark:
            return Color(.systemGray4) // Elevated secondary background
        }
    }
    
    var cardBackgroundColor: Color {
        switch colorSchemePreference {
        case .light, .system:
            return Color(.systemBackground)
        case .elevatedDark:
            return Color(.systemGray4) // Cards için elevated renk
        }
    }
    
    var textColor: Color {
        switch colorSchemePreference {
        case .light, .system:
            return Color(.label)
        case .elevatedDark:
            return Color(.label) // Otomatik beyaz/siyah
        }
    }
    
    var secondaryTextColor: Color {
        switch colorSchemePreference {
        case .light, .system:
            return Color(.secondaryLabel)
        case .elevatedDark:
            return Color(.secondaryLabel)
        }
    }
    
    private init() {
        let savedPreference = UserDefaults.standard.string(forKey: "preferredColorScheme") ?? "system"
        if savedPreference == "dark" {
            self.colorSchemePreference = .elevatedDark
        } else {
            self.colorSchemePreference = AppColorSchemePreference(rawValue: savedPreference) ?? .system
        }
    }
    
    func setColorScheme(_ preference: AppColorSchemePreference) {
        colorSchemePreference = preference
    }
}

enum AppColorSchemePreference: String, CaseIterable {
    case system = "system"
    case light = "light"
    case elevatedDark = "elevatedDark"
    
    var displayName: String {
        switch self {
        case .system: return "Sistem"
        case .light: return "Açık"
        case .elevatedDark: return "Koyu"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .elevatedDark: return .dark
        }
    }
    
    var iconName: String {
        switch self {
        case .system: return "gear"
        case .light: return "sun.max"
        case .elevatedDark: return "moon"
        }
    }
}

