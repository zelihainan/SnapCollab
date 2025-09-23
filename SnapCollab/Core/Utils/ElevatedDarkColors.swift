//
//  ElevatedDarkColors.swift
//  SnapCollab
//

import SwiftUI
import UIKit

extension Color {
    // Elevated Dark Mode renkleri
    static let elevatedBackground = Color(UIColor.systemGray6)      // En açık gri
    static let elevatedSecondary = Color(UIColor.systemGray5)       // Biraz daha koyu
    static let elevatedTertiary = Color(UIColor.systemGray4)        // Orta gri
    static let elevatedCard = Color(UIColor.systemGray4)            // Card background
    static let elevatedOverlay = Color(UIColor.systemGray3)         // Overlay renkler
}

// Custom modifier elevated dark mode için
struct ElevatedDarkStyle: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .background(themeManager.backgroundColor)
            .foregroundStyle(themeManager.textColor)
    }
}

extension View {
    func elevatedDarkStyle() -> some View {
        modifier(ElevatedDarkStyle())
    }
}
