//
//  DataExportView.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 16.09.2025.


import SwiftUI
import Foundation

struct DataExportView: View {
    let authRepo: AuthRepository
    @Environment(\.dismiss) var dismiss
    
    @State private var isExporting = false
    @State private var exportProgress: Double = 0.0
    @State private var exportStatus = "Hazırlanıyor..."
    @State private var exportedData: UserExportData?
    @State private var showShareSheet = false
    @State private var exportError: String?
    @State private var exportComplete = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.purple.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        if exportComplete {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.green)
                        } else if isExporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                                .scaleEffect(1.5)
                        } else {
                            Image(systemName: "square.and.arrow.down.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.purple)
                        }
                    }
                    
                    Text(exportComplete ? "Export Tamamlandı" : "Verilerimi İndir")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if exportComplete {
                        Text("Tüm verileriniz başarıyla export edildi")
                            .font(.body)
                            .foregroundStyle(.green)
                            .multilineTextAlignment(.center)
                    } else if isExporting {
                        Text("Verileriniz export ediliyor, lütfen bekleyin...")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("SnapCollab hesabınızdaki tüm verilerinizi JSON formatında indirebilirsiniz")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 20)
                
                // Progress Section
                if isExporting || exportComplete {
                    VStack(spacing: 16) {
                        ProgressView(value: exportProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                            .frame(height: 8)
                            .background(Color(.systemGray5))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        
                        HStack {
                            Text(exportStatus)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(exportProgress * 100))%")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.purple)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Export Details
                if !isExporting && !exportComplete {
                    VStack(spacing: 16) {
                        Text("İndirilecek Veriler")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            ExportDataItem(
                                icon: "person.circle",
                                title: "Profil Bilgileri",
                                description: "Ad, e-posta, kayıt tarihi"
                            )
                            
                            ExportDataItem(
                                icon: "photo.stack",
                                title: "Albüm Verileri",
                                description: "Oluşturduğunuz ve katıldığınız albümler"
                            )
                            
                            ExportDataItem(
                                icon: "heart",
                                title: "Favoriler",
                                description: "Favori olarak işaretlediğiniz medyalar"
                            )
                            
                            ExportDataItem(
                                icon: "gear",
                                title: "Uygulama Ayarları",
                                description: "Tema, yazı boyutu ve tercihler"
                            )
                            
                            ExportDataItem(
                                icon: "bell",
                                title: "Bildirim Geçmişi",
                                description: "Son 30 günün bildirim kayıtları"
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Error Message
                if let error = exportError {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.red.opacity(0.1))
                    )
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    if exportComplete {
                        VStack(spacing: 12) {
                            Button("Dosyayı Paylaş") {
                                showShareSheet = true
                            }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                            
                            Button("Tekrar Export Et") {
                                resetExport()
                            }
                            .foregroundStyle(.blue)
                        }
                    } else if isExporting {
                        Button("İptal Et") {
                            cancelExport()
                        }
                        .foregroundStyle(.red)
                    } else {
                        Button("Export Başlat") {
                            startExport()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .disabled(authRepo.currentUser == nil)
                    }
                    
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Veri Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let data = exportedData {
                ShareExportedDataView(exportData: data)
            }
        }
    }
    
    private func startExport() {
        guard let user = authRepo.currentUser else {
            exportError = "Kullanıcı bilgisi bulunamadı"
            return
        }
        
        isExporting = true
        exportError = nil
        exportProgress = 0.0
        
        Task {
            await performExport(for: user)
        }
    }
    
    private func performExport(for user: User) async {
        do {
            // Step 1: Collect user data
            await updateProgress(0.2, status: "Profil bilgileri toplanıyor...")
            let userData = await collectUserData(user)
            
            // Step 2: Collect albums
            await updateProgress(0.4, status: "Albüm verileri toplanıyor...")
            let albumsData = await collectAlbumsData(user.uid)
            
            // Step 3: Collect favorites
            await updateProgress(0.6, status: "Favoriler toplanıyor...")
            let favoritesData = await collectFavoritesData(user.uid)
            
            // Step 4: Collect settings
            await updateProgress(0.8, status: "Uygulama ayarları toplanıyor...")
            let settingsData = await collectSettingsData()
            
            // Step 5: Create export data
            await updateProgress(1.0, status: "Export tamamlanıyor...")
            
            let exportData = UserExportData(
                user: userData,
                albums: albumsData,
                favorites: favoritesData,
                settings: settingsData,
                exportDate: Date(),
                appVersion: Bundle.main.appVersion
            )
            
            await MainActor.run {
                self.exportedData = exportData
                self.exportComplete = true
                self.isExporting = false
                self.exportStatus = "Export tamamlandı!"
            }
            
        } catch {
            await MainActor.run {
                self.exportError = "Export hatası: \(error.localizedDescription)"
                self.isExporting = false
            }
        }
    }
    
    private func updateProgress(_ progress: Double, status: String) async {
        await MainActor.run {
            self.exportProgress = progress
            self.exportStatus = status
        }
        
        // Simulate some processing time
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
    
    private func collectUserData(_ user: User) async -> ExportedUser {
        return ExportedUser(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
            photoURL: user.photoURL,
            createdAt: user.createdAt
        )
    }
    
    private func collectAlbumsData(_ userId: String) async -> [ExportedAlbum] {
        // In real app, you'd fetch from your repository
        // For now, return mock data
        return []
    }
    
    private func collectFavoritesData(_ userId: String) async -> [String] {
        let userDefaults = UserDefaults.standard
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        var allFavorites: [String] = []
        for key in allKeys {
            if key.contains("favorites_") && key.contains(userId) {
                if let data = userDefaults.data(forKey: key),
                   let favorites = try? JSONDecoder().decode(Set<String>.self, from: data) {
                    allFavorites.append(contentsOf: favorites)
                }
            }
        }
        
        return allFavorites
    }
    
    private func collectSettingsData() async -> ExportedSettings {
        let userDefaults = UserDefaults.standard
        
        return ExportedSettings(
            fontSizePreference: userDefaults.string(forKey: "fontSizePreference") ?? "medium",
            preferredColorScheme: userDefaults.string(forKey: "preferredColorScheme") ?? "system",
            notificationsEnabled: userDefaults.bool(forKey: "notificationsEnabled"),
            photoNotificationsEnabled: userDefaults.bool(forKey: "photoNotificationsEnabled"),
            videoNotificationsEnabled: userDefaults.bool(forKey: "videoNotificationsEnabled")
        )
    }
    
    private func cancelExport() {
        isExporting = false
        exportProgress = 0.0
        exportStatus = "Export iptal edildi"
        exportError = nil
    }
    
    private func resetExport() {
        exportComplete = false
        exportedData = nil
        exportProgress = 0.0
        exportStatus = "Hazırlanıyor..."
        exportError = nil
    }
}

// MARK: - Export Data Item
struct ExportDataItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.purple)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Share Exported Data View
struct ShareExportedDataView: View {
    let exportData: UserExportData
    @Environment(\.dismiss) var dismiss
    @State private var shareURL: URL?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export dosyanız hazır!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let url = shareURL {
                    ActivityView(activityItems: [url])
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ProgressView("Dosya hazırlanıyor...")
                }
            }
            .navigationTitle("Paylaş")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
        .onAppear {
            createShareableFile()
        }
    }
    
    private func createShareableFile() {
        Task {
            do {
                let jsonData = try JSONEncoder().encode(exportData)
                let fileName = "SnapCollab_Export_\(Date().formatted(date: .abbreviated, time: .omitted)).json"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                
                try jsonData.write(to: tempURL)
                
                await MainActor.run {
                    shareURL = tempURL
                }
            } catch {
                print("Error creating shareable file: \(error)")
            }
        }
    }
}

// MARK: - Export Data Models
struct UserExportData: Codable {
    let user: ExportedUser
    let albums: [ExportedAlbum]
    let favorites: [String]
    let settings: ExportedSettings
    let exportDate: Date
    let appVersion: String
}

struct ExportedUser: Codable {
    let uid: String
    let email: String
    let displayName: String?
    let photoURL: String?
    let createdAt: Date
}

struct ExportedAlbum: Codable {
    let id: String
    let title: String
    let ownerId: String
    let memberCount: Int
    let createdAt: Date
    let isOwner: Bool
}

struct ExportedSettings: Codable {
    let fontSizePreference: String
    let preferredColorScheme: String
    let notificationsEnabled: Bool
    let photoNotificationsEnabled: Bool
    let videoNotificationsEnabled: Bool
}
