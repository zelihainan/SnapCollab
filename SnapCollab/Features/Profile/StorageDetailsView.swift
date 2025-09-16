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
    @State private var showClearAlert = false
    @State private var isClearing = false
    
    var body: some View {
        NavigationView {
            List {
                // Header - iCloud Style
                Section {
                    VStack(spacing: 20) {
                        // Storage Circle
                        ZStack {
                            Circle()
                                .stroke(.tertiary, lineWidth: 4)
                                .frame(width: 120, height: 120)
                            
                            Circle()
                                .trim(from: 0, to: usedStoragePercentage)
                                .stroke(.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 120, height: 120)
                                .animation(.easeInOut(duration: 1.0), value: usedStoragePercentage)
                            
                            VStack(spacing: 4) {
                                if isCalculating {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Text(storageManager.formatStorageSize(storageManager.totalStorageUsed))
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                    
                                    Text("Kullanılan")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
                .listRowBackground(Color.clear)
                
                // Storage Breakdown - iCloud Style
                if let breakdown = storageBreakdown {
                    Section {
                        StorageItemRow(
                            title: "Önbellek Dosyaları",
                            subtitle: "Geçici dosyalar ve küçük resimler",
                            size: breakdown.cacheSize,
                            color: .orange,
                            icon: "arrow.clockwise.circle.fill",
                            totalSize: storageManager.totalStorageUsed
                        )
                        
                        StorageItemRow(
                            title: "Uygulama Verileri",
                            subtitle: "Ayarlar ve kullanıcı tercihleri",
                            size: breakdown.documentsSize,
                            color: .blue,
                            icon: "folder.circle.fill",
                            totalSize: storageManager.totalStorageUsed
                        )
                        
                        StorageItemRow(
                            title: "Kullanıcı Ayarları",
                            subtitle: "Uygulama yapılandırması",
                            size: breakdown.userDefaultsSize,
                            color: .green,
                            icon: "gearshape.circle.fill",
                            totalSize: storageManager.totalStorageUsed
                        )
                        
                    } header: {
                        Text("Depolama Ayrıntıları")
                    }
                    
                    // Actions Section
                    Section {
                        Button(action: { showClearAlert = true }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(.red.opacity(0.1))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "trash.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.red)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Önbelleği Temizle")
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    
                                    Text("Geçici dosyaları sil")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if let breakdown = storageBreakdown, breakdown.cacheSize > 0 {
                                    Text(storageManager.formatStorageSize(breakdown.cacheSize))
                                        .font(.subheadline)
                                        .foregroundStyle(.red)
                                        .fontWeight(.medium)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isClearing || (storageBreakdown?.cacheSize ?? 0) == 0)
                        
                    } footer: {
                        Text("Önbellek dosyaları güvenle silinebilir ve uygulama performansını etkilemez")
                    }
                }
            }
            .navigationTitle("Depolama")
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
        .alert("Önbelleği Temizle", isPresented: $showClearAlert) {
            Button("İptal", role: .cancel) { }
            Button("Temizle", role: .destructive) {
                clearCache()
            }
        } message: {
            Text("Önbellek dosyaları temizlenecek. Bu işlem geri alınamaz ve uygulama performansını etkilemez.")
        }
        .overlay {
            if isClearing {
                Color.black.opacity(0.3)
                    .overlay {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            Text("Temizleniyor...")
                                .foregroundStyle(.white)
                                .font(.subheadline)
                        }
                    }
                    .ignoresSafeArea()
            }
        }
    }
    
    private var usedStoragePercentage: CGFloat {
        let total = storageManager.totalStorageUsed
        if total == 0 { return 0.0 }
        // Simulated max capacity for visualization (100 MB)
        let maxCapacity: Int64 = 100 * 1024 * 1024
        return min(CGFloat(total) / CGFloat(maxCapacity), 1.0)
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
        isClearing = true
        
        Task {
            do {
                try await storageManager.clearCache()
                await MainActor.run {
                    calculateDetailedStorage()
                }
            } catch {
                print("Cache clear error: \(error)")
            }
            
            await MainActor.run {
                isClearing = false
            }
        }
    }
}

// MARK: - Storage Item Row - Updated iCloud Style
struct StorageItemRow: View {
    let title: String
    let subtitle: String
    let size: Int64
    let color: Color
    let icon: String
    let totalSize: Int64
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(size == 0 ? "0 KB" : StorageManager.shared.formatStorageSize(size))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(color)
                
                if totalSize > 0 {
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(.systemGray5))
                            .frame(height: 4)
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(color)
                                    .frame(width: size == 0 ? 0 : geometry.size.width * CGFloat(size) / CGFloat(totalSize), height: 4)
                                    .animation(.easeInOut(duration: 0.5), value: size)
                            }
                    }
                    .frame(width: 60, height: 4)
                } else {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 4)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Storage Breakdown Model (Updated)
struct StorageBreakdown {
    let cacheSize: Int64
    let documentsSize: Int64
    let userDefaultsSize: Int64
    
    var totalSize: Int64 {
        cacheSize + documentsSize + userDefaultsSize
    }
}

// MARK: - Storage Calculator (Updated)
struct StorageCalculator {
    static func calculateBreakdown() async -> StorageBreakdown {
        var cacheSize: Int64 = 0
        var documentsSize: Int64 = 0
        var userDefaultsSize: Int64 = 0
        
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
        
        return StorageBreakdown(
            cacheSize: cacheSize,
            documentsSize: documentsSize,
            userDefaultsSize: userDefaultsSize
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
}

// MARK: - Bundle Extensions (Updated)
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
