// Core/Utils/ZipManager.swift

import Foundation
import UIKit
import ZIPFoundation
import UniformTypeIdentifiers

class ZipManager {
    static let shared = ZipManager()
    
    func createZipArchive(
        albumTitle: String,
        mediaItems: [MediaItem],
        mediaRepo: MediaRepository,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws -> URL {
        
        let fm = FileManager.default
        let tempDirectory = fm.temporaryDirectory
        
        let safeTitle = albumTitle
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: #"[^\w\-.]"#, with: "_", options: .regularExpression)
        
        let zipFileName = "\(safeTitle)_\(Int(Date().timeIntervalSince1970)).zip"
        let zipURL = tempDirectory.appendingPathComponent(zipFileName)
        
        let workingDir = tempDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fm.createDirectory(at: workingDir, withIntermediateDirectories: true)
        
        // Albüm bilgi dosyası
        let albumInfo = """
        Albüm: \(albumTitle)
        Toplam Medya: \(mediaItems.count)
        Dışa Aktarma Tarihi: \(Date().formatted(date: .numeric, time: .shortened))
        
        Bu ZIP dosyası SnapCollab uygulaması ile oluşturulmuştur.
        """
        try albumInfo.write(to: workingDir.appendingPathComponent("Album_Bilgisi.txt"), atomically: true, encoding: .utf8)
        
        let total = max(mediaItems.count, 1)
        for (i, item) in mediaItems.enumerated() {
            await MainActor.run {
                progressHandler(Double(i) / Double(total), "İndiriliyor: \(i + 1)/\(total)")
            }
            do {
                let downloadURL = try await mediaRepo.downloadURL(for: item.path)
                let (data, _) = try await URLSession.shared.data(from: downloadURL)
                
                let fileExt = item.isVideo ? "mp4" : "jpg"
                let ts = item.createdAt.formatted(date: .abbreviated, time: .omitted)
                let name = "\(ts)_\(String(format: "%03d", i + 1)).\(fileExt)"
                try data.write(to: workingDir.appendingPathComponent(name), options: .atomic)
            } catch {
                print("Download failed for \(item.id ?? "unknown"): \(error)")
            }
        }
        
        await MainActor.run { progressHandler(0.9, "ZIP oluşturuluyor…") }
        

        if fm.fileExists(atPath: zipURL.path) { try? fm.removeItem(at: zipURL) }
        
        let progress = Progress(totalUnitCount: 100)
        try fm.zipItem(
            at: workingDir,
            to: zipURL,
            shouldKeepParent: false,
            compressionMethod: .deflate,
            progress: progress
        )
        
        // Temizlik
        try? fm.removeItem(at: workingDir)
        
        await MainActor.run { progressHandler(1.0, "ZIP dosyası hazır!") }
        return zipURL
    }
}
