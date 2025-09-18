//
//  BulkDownloadSheet.swift
//  SnapCollab
//
//  Toplu indirme işlemi için sheet

import SwiftUI
import Photos
import UIKit

struct BulkDownloadSheet: View {
    let selectedItems: [MediaItem]
    let mediaRepo: MediaRepository
    @Environment(\.dismiss) var dismiss
    
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0.0
    @State private var downloadStatus = ""
    @State private var downloadedCount = 0
    @State private var totalCount = 0
    @State private var showPermissionAlert = false
    @State private var downloadError: String?
    @State private var downloadComplete = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.green.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        if downloadComplete {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.green)
                        } else if isDownloading {
                            ZStack {
                                Circle()
                                    .stroke(.green.opacity(0.3), lineWidth: 6)
                                    .frame(width: 60, height: 60)
                                
                                Circle()
                                    .trim(from: 0, to: downloadProgress)
                                    .stroke(.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: 60, height: 60)
                                    .animation(.easeInOut, value: downloadProgress)
                                
                                Text("\(Int(downloadProgress * 100))%")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)
                            }
                        } else {
                            Image(systemName: "arrow.down.to.line.alt")
                                .font(.system(size: 50))
                                .foregroundStyle(.green)
                        }
                    }
                    
                    Text(downloadComplete ? "İndirme Tamamlandı" : "Galeriye İndir")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if isDownloading {
                        Text(downloadStatus)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    } else if !downloadComplete {
                        Text("\(selectedItems.count) öğe cihazınızın galerisine indirilecek")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 20)
                
                // Progress Info
                if isDownloading || downloadComplete {
                    VStack(spacing: 12) {
                        if totalCount > 0 {
                            Text("\(downloadedCount) / \(totalCount)")
                                .font(.headline)
                                .foregroundStyle(.green)
                        }
                        
                        if downloadProgress > 0 && downloadProgress < 1.0 {
                            ProgressView(value: downloadProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                                .frame(height: 8)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Download Details
                if !isDownloading && !downloadComplete {
                    VStack(spacing: 16) {
                        Text("İndirilecek Öğeler")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        let photoCount = selectedItems.filter { $0.type == "image" }.count
                        let videoCount = selectedItems.filter { $0.type == "video" }.count
                        
                        VStack(spacing: 12) {
                            if photoCount > 0 {
                                DownloadInfoRow(
                                    icon: "photo",
                                    title: "Fotoğraflar",
                                    count: photoCount,
                                    color: .blue
                                )
                            }
                            
                            if videoCount > 0 {
                                DownloadInfoRow(
                                    icon: "video",
                                    title: "Videolar",
                                    count: videoCount,
                                    color: .purple
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Error Message
                if let error = downloadError {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.orange.opacity(0.1))
                    )
                    .padding(.horizontal, 20)
                }
                
                // Action Buttons
                VStack(spacing: 16) {
                    if downloadComplete {
                        Button("Tamamla") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    } else if isDownloading {
                        Button("İptal Et") {
                            // İndirme iptali (implement edilebilir)
                            isDownloading = false
                        }
                        .foregroundStyle(.red)
                    } else {
                        Button("İndirmeyi Başlat") {
                            Task { await startDownload() }
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .disabled(selectedItems.isEmpty)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle("Toplu İndirme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .disabled(isDownloading)
                }
            }
        }
        .alert("Fotoğraf İzni Gerekli", isPresented: $showPermissionAlert) {
            Button("Ayarlara Git") {
                openPhotoSettings()
            }
            Button("İptal", role: .cancel) { }
        } message: {
            Text("Fotoğrafları galeriye kaydetmek için Ayarlar > SnapCollab > Fotoğraflar'dan izin verin")
        }
    }
    
    private func startDownload() async {
        // İzin kontrolü
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .denied || status == .restricted {
            await MainActor.run {
                showPermissionAlert = true
            }
            return
        } else if status == .notDetermined {
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            if newStatus != .authorized && newStatus != .limited {
                await MainActor.run {
                    showPermissionAlert = true
                }
                return
            }
        }
        
        await MainActor.run {
            isDownloading = true
            downloadProgress = 0.0
            downloadedCount = 0
            totalCount = selectedItems.count
            downloadError = nil
            downloadStatus = "İndirme başlıyor..."
        }
        
        // Her öğeyi indir
        for (index, item) in selectedItems.enumerated() {
            do {
                await updateProgress(Double(index) / Double(totalCount), status: "İndiriliyor: \(index + 1)/\(totalCount)")
                
                if item.type == "image" {
                    try await downloadImage(item)
                } else if item.type == "video" {
                    try await downloadVideo(item)
                }
                
                await MainActor.run {
                    downloadedCount = index + 1
                }
                
                // Her 3 dosyada bir kısa bekleme (system'e nefes aldır)
                if (index + 1) % 3 == 0 {
                    try await Task.sleep(nanoseconds: 300_000_000) // 0.3 saniye
                }
                
            } catch {
                print("Download error for item \(item.id ?? ""): \(error)")
                // Hata olsa da devam et
            }
        }
        
        await MainActor.run {
            downloadProgress = 1.0
            downloadStatus = "\(downloadedCount) öğe başarıyla indirildi!"
            downloadComplete = true
            isDownloading = false
        }
    }
    
    private func updateProgress(_ progress: Double, status: String) async {
        await MainActor.run {
            downloadProgress = progress
            downloadStatus = status
        }
    }
    
    private func downloadImage(_ item: MediaItem) async throws {
        do {
            let imageURL = try await mediaRepo.downloadURL(for: item.path)
            let (data, _) = try await URLSession.shared.data(from: imageURL)
            
            guard let image = UIImage(data: data) else {
                throw DownloadError.invalidImageData
            }
            
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
        } catch {
            throw DownloadError.urlNotFound
        }
    }
    
    private func downloadVideo(_ item: MediaItem) async throws {
        do {
            let videoURL = try await mediaRepo.downloadURL(for: item.path)
            let (data, _) = try await URLSession.shared.data(from: videoURL)
            
            // Geçici dosya oluştur
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mp4")
            
            try data.write(to: tempURL)
            
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL)
            }
            
            // Geçici dosyayı sil
            try? FileManager.default.removeItem(at: tempURL)
        } catch {
            throw DownloadError.urlNotFound
        }
    }
    
    private func openPhotoSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

struct DownloadInfoRow: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text("\(count) öğe")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("\(count)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

enum DownloadError: LocalizedError {
    case urlNotFound
    case invalidImageData
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .urlNotFound:
            return "Dosya URL'si bulunamadı"
        case .invalidImageData:
            return "Geçersiz görsel verisi"
        case .permissionDenied:
            return "Fotoğraf erişim izni reddedildi"
        }
    }
}
