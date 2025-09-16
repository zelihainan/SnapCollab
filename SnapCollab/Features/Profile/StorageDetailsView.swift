//
//  StorageDetailsView.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 16.09.2025.
//

import SwiftUI
import Foundation

struct StorageDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var storageManager = StorageManager.shared
    @State private var storageBreakdown: StorageBreakdown?
    @State private var isCalculating = false
    
    var body: some View {
        NavigationView {
            List {
                // Genel Bilgiler
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Toplam Kullanım")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            if isCalculating {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Hesaplanıyor...")
                                        .foregroundStyle(.secondary)
                                        .font(.subheadline)
                                }
                            } else {
                                Text(storageManager.formatStorageSize(storageManager.totalStorageUsed))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.blue)
                            }
                        }
                        
                        Spacer()
                        
                        Button("Yenile") {
                            refreshStorage()
                        }
                        .buttonStyle(.bordered)
                        .disabled(isCalculating)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Genel Bilgiler")
                }
                
                // Depolama Dağılımı
                if let breakdown = storageBreakdown {
                    Section {
                        StorageItemRow(
                            title: "Önbellek Dosyaları",
                            subtitle: "Geçici dosyalar ve thumbnails",
                            size: breakdown.cacheSize,
                            color: .orange,
                            icon: "arrow.down.circle"
                        )
                        
                        StorageItemRow(
                            title: "Uygulama Verileri",
                            subtitle: "Ayarlar ve kullanıcı tercihleri",
                            size: breakdown.documentsSize,
                            color: .blue,
                            icon: "doc.circle"
                        )
                        
                        StorageItemRow(
                            title: "Kullanıcı Ayarları",
                            subtitle: "Uygulama yapılandırması",
                            size: breakdown.userDefaultsSize,
                            color: .green,
                            icon: "gear.circle"
                        )
                        
                        StorageItemRow(
                            title: "Favoriler",
                            subtitle: "Favori medya listesi",
                            size: breakdown.favoritesSize,
                            color: .red,
                            icon: "heart.circle"
                        )
                        
                    } header: {
                        Text("Depolama Dağılımı")
                    } footer: {
                        Text("Önbellek dosyaları güvenle silinebilir")
                    }
                }
                
                // Temizleme Seçenekleri
                Section {
                    Button(action: clearCache) {
                        HStack {
                            Image(systemName: "trash.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.orange)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Önbelleği Temizle")
                                    .foregroundStyle(.primary)
                                Text("Geçici dosyaları sil")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if storageBreakdown?.cacheSize ?? 0 > 0 {
                                Text(storageManager.formatStorageSize(storageBreakdown?.cacheSize ?? 0))
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                } header: {
                    Text("Temizleme")
                }
                
                // Sistem Bilgileri
                Section {
                    InfoRow(title: "Cihaz Modeli", value: UIDevice.current.model)
                    InfoRow(title: "iOS Sürümü", value: UIDevice.current.systemVersion)
                    InfoRow(title: "Uygulama Sürümü", value: Bundle.main.appVersion)
                    InfoRow(title: "Build Numarası", value: Bundle.main.buildNumber)
                    
                } header: {
                    Text("Sistem Bilgileri")
                }
            }
            .navigationTitle("Depolama Detayları")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
        .onAppear {
            calculateDetailedStorage()
        }
    }
    
    private func refreshStorage() {
        Task {
            await storageManager.calculateStorageUsage()
            calculateDetailedStorage()
        }
    }
    
    private func calculateDetailedStorage() {
        isCalculating = true
        
        Task {
            let breakdown = await StorageCalculator.calculateBreakdown()
            
            await MainActor.run {
                self.storageBreakdown = breakdown
                self.isCalculating = false
            }
        }
    }
    
    private func clearCache() {
        Task {
            do {
                try await storageManager.clearCache()
                calculateDetailedStorage()
            } catch {
                print("Cache clear error: \(error)")
            }
        }
    }
}

// MARK: - Storage Item Row
struct StorageItemRow: View {
    let title: String
    let subtitle: String
    let size: Int64
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(StorageManager.shared.formatStorageSize(size))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(color)
                
                if size > 0 {
                    ProgressView(value: Double(size), total: Double(StorageManager.shared.totalStorageUsed))
                        .progressViewStyle(LinearProgressViewStyle(tint: color))
                        .frame(width: 60)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text(value)
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
    }
}

// MARK: - Storage Breakdown Model
struct StorageBreakdown {
    let cacheSize: Int64
    let documentsSize: Int64
    let userDefaultsSize: Int64
    let favoritesSize: Int64
    
    var totalSize: Int64 {
        cacheSize + documentsSize + userDefaultsSize + favoritesSize
    }
}

// MARK: - Storage Calculator
struct StorageCalculator {
    static func calculateBreakdown() async -> StorageBreakdown {
        var cacheSize: Int64 = 0
        var documentsSize: Int64 = 0
        var userDefaultsSize: Int64 = 0
        var favoritesSize: Int64 = 0
        
        // Cache directory
        if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            cacheSize = await calculateDirectorySize(url: cacheURL)
        }
        
        // Documents directory
        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            documentsSize = await calculateDirectorySize(url: documentsURL)
        }
        
        // UserDefaults size
        userDefaultsSize = await calculateUserDefaultsSize()
        
        // Favorites size (estimate based on stored favorites)
        favoritesSize = await calculateFavoritesSize()
        
        return StorageBreakdown(
            cacheSize: cacheSize,
            documentsSize: documentsSize,
            userDefaultsSize: userDefaultsSize,
            favoritesSize: favoritesSize
        )
    }
    
    private static func calculateDirectorySize(url: URL) async -> Int64 {
        var totalSize: Int64 = 0
        
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                if let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
            } catch {
                continue
            }
        }
        
        return totalSize
    }
    
    private static func calculateUserDefaultsSize() async -> Int64 {
        let userDefaults = UserDefaults.standard
        let dict = userDefaults.dictionaryRepresentation()
        
        do {
            let data = try PropertyListSerialization.data(
                fromPropertyList: dict,
                format: .binary,
                options: 0
            )
            return Int64(data.count)
        } catch {
            return 0
        }
    }
    
    private static func calculateFavoritesSize() async -> Int64 {
        // Estimate favorites storage size
        let userDefaults = UserDefaults.standard
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        var favoritesSize: Int64 = 0
        for key in allKeys {
            if key.contains("favorites_") {
                if let data = userDefaults.data(forKey: key) {
                    favoritesSize += Int64(data.count)
                }
            }
        }
        
        return favoritesSize
    }
}

// MARK: - Bundle Extensions
extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var appName: String {
        return infoDictionary?["CFBundleDisplayName"] as? String ??
               infoDictionary?["CFBundleName"] as? String ?? "SnapCollab"
    }
    
    var bundleID: String {
        return bundleIdentifier ?? "com.zelihainan.SnapCollab"
    }
    
    var fullVersionString: String {
        return "\(appVersion) (\(buildNumber))"
    }
    
    var copyright: String {
        return infoDictionary?["NSHumanReadableCopyright"] as? String ?? "© 2025 SnapCollab"
    }
}
