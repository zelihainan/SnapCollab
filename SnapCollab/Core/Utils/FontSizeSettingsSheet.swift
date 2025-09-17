//
//  FontSizeSettingsSheet.swift
//  SnapCollab

import SwiftUI

struct FontSizeSettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var fontManager: FontManager
    @State private var selectedSize: FontSizePreference
    
    init() {
        _selectedSize = State(initialValue: FontManager.shared.fontSizePreference)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "textformat.size")
                        .font(.system(size: 50))
                        .foregroundStyle(.green)
                    
                    Text("Yazı Boyutu")
                        .scaledFont(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.top, 20)
                
                VStack(spacing: 20) {
                    Text("Önizleme")
                        .scaledFont(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 16) {
                        SampleTextView(
                            fontSize: selectedSize,
                            title: "Albüm Başlığı",
                            subtitle: "Bu bir örnek albüm açıklamasıdır",
                            isSelected: true
                        )
                        
                        SampleTextView(
                            fontSize: selectedSize,
                            title: "Bildirim",
                            subtitle: "Yeni fotoğraf eklendi",
                            isSelected: false
                        )
                    }
                    .padding(.horizontal, 20)
                }
                
                VStack(spacing: 16) {
                    Text("Boyut Seçimi")
                        .scaledFont(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        ForEach(FontSizePreference.allCases, id: \.self) { size in
                            FontSizeOptionCard(
                                size: size,
                                isSelected: selectedSize == size,
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedSize = size
                                    }
                                    
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                                
                VStack(spacing: 10) {
                    Button("Uygula") {
                        fontManager.setFontSize(selectedSize)
                        
                        let notificationFeedback = UINotificationFeedbackGenerator()
                        notificationFeedback.notificationOccurred(.success)
                        
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Yazı Boyutu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}

struct SampleTextView: View {
    let fontSize: FontSizePreference
    let title: String
    let subtitle: String
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(isSelected ? .blue : .gray)
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: isSelected ? "photo.stack.fill" : "bell.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16 * fontSize.scale, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.system(size: 14 * fontSize.scale))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .animation(.easeInOut(duration: 0.2), value: fontSize)
    }
}

struct FontSizeOptionCard: View {
    let size: FontSizePreference
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Text("Aa")
                    .font(.system(size: size.sampleSize, weight: .medium))
                    .foregroundStyle(isSelected ? .blue : .primary)
                
                Text(size.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? .blue.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .blue : .clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum FontSizePreference: String, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extraLarge"
    
    var displayName: String {
        switch self {
        case .small: return "Küçük"
        case .medium: return "Orta"
        case .large: return "Büyük"
        case .extraLarge: return "Çok Büyük"
        }
    }
    
    var scale: CGFloat {
        switch self {
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.1
        case .extraLarge: return 1.2
        }
    }
    
    var sampleSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        case .extraLarge: return 20
        }
    }
}

extension UserDefaults {
    var fontSizePreference: FontSizePreference {
        get {
            if let rawValue = string(forKey: "fontSizePreference"),
               let preference = FontSizePreference(rawValue: rawValue) {
                return preference
            }
            return .medium
        }
        set {
            set(newValue.rawValue, forKey: "fontSizePreference")
        }
    }
}
