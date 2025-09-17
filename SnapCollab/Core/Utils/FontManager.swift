//
//  FontManager.swift
//  SnapCollab
//

import SwiftUI
import Combine

class FontManager: ObservableObject {
    static let shared = FontManager()
    
    @Published var fontSizePreference: FontSizePreference {
        didSet {
            UserDefaults.standard.fontSizePreference = fontSizePreference
            objectWillChange.send()
        }
    }
    
    private init() {
        self.fontSizePreference = UserDefaults.standard.fontSizePreference
    }
    
    func scaledFont(_ font: Font) -> Font {
        switch font {
        case .largeTitle:
            return .system(size: 34 * fontSizePreference.scale, weight: .regular)
        case .title:
            return .system(size: 28 * fontSizePreference.scale, weight: .regular)
        case .title2:
            return .system(size: 22 * fontSizePreference.scale, weight: .regular)
        case .title3:
            return .system(size: 20 * fontSizePreference.scale, weight: .regular)
        case .headline:
            return .system(size: 17 * fontSizePreference.scale, weight: .semibold)
        case .body:
            return .system(size: 17 * fontSizePreference.scale, weight: .regular)
        case .callout:
            return .system(size: 16 * fontSizePreference.scale, weight: .regular)
        case .subheadline:
            return .system(size: 15 * fontSizePreference.scale, weight: .regular)
        case .footnote:
            return .system(size: 13 * fontSizePreference.scale, weight: .regular)
        case .caption:
            return .system(size: 12 * fontSizePreference.scale, weight: .regular)
        case .caption2:
            return .system(size: 11 * fontSizePreference.scale, weight: .regular)
        default:
            return font
        }
    }
    
    func scaledSize(_ size: CGFloat) -> CGFloat {
        return size * fontSizePreference.scale
    }
    
    func setFontSize(_ preference: FontSizePreference) {
        fontSizePreference = preference
    }
}

extension Font {
    static func scaledSystem(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        return .system(size: FontManager.shared.scaledSize(size), weight: weight, design: design)
    }
    
    func scaled() -> Font {
        return FontManager.shared.scaledFont(self)
    }
}

struct ScaledFont: ViewModifier {
    @EnvironmentObject var fontManager: FontManager
    let font: Font
    
    func body(content: Content) -> some View {
        content
            .font(fontManager.scaledFont(font))
    }
}

extension View {
    func scaledFont(_ font: Font) -> some View {
        modifier(ScaledFont(font: font))
    }
}

extension Text {
    func scaledFont(_ font: Font) -> Text {
        self.font(FontManager.shared.scaledFont(font))
    }
}
