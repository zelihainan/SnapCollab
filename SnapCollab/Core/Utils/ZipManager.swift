//
//  ZipManager.swift
//  SnapCollab
//

import Foundation
import ZIPFoundation

final class ZipManager {
    static let shared = ZipManager()
    private init() {}

    enum ZipError: LocalizedError {
        case creationFailed
        case noMediaFound
        case workingDir
        case cancelled

        var errorDescription: String? {
            switch self {
            case .creationFailed: return "ZIP dosyası oluşturulamadı."
            case .noMediaFound:   return "Paylaşılacak medya bulunamadı."
            case .workingDir:     return "Geçici klasör oluşturulamadı."
            case .cancelled:      return "İşlem iptal edildi."
            }
        }
    }

    /// Albüm için ZIP arşivi üretir.
    /// - Parameter progressHandler: MainActor’da çağrılır.
    func createZipArchive(
        albumTitle: String,
        mediaItems: [MediaItem],
        mediaRepo: MediaRepository,
        progressHandler: @MainActor @escaping (Double, String) -> Void
    ) async throws -> URL {

        guard !mediaItems.isEmpty else { throw ZipError.noMediaFound }

        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory

        let safeTitle = albumTitle
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: #"[^\w\-.]"#, with: "_", options: .regularExpression)

        let zipURL = tempDir.appendingPathComponent("\(safeTitle)_\(Int(Date().timeIntervalSince1970)).zip")

        // Çalışma klasörü
        let workingDir = tempDir.appendingPathComponent(UUID().uuidString, isDirectory: true)
        do {
            try fm.createDirectory(at: workingDir, withIntermediateDirectories: true)
        } catch {
            throw ZipError.workingDir
        }

        // Albüm bilgi dosyası
        let info = """
        Albüm: \(albumTitle)
        Toplam Medya: \(mediaItems.count)
        Dışa Aktarma: \(Date().formatted(date: .numeric, time: .shortened))

        Bu ZIP dosyası SnapCollab tarafından oluşturulmuştur.
        """
        try info.write(to: workingDir.appendingPathComponent("Album_Bilgisi.txt"), atomically: true, encoding: .utf8)

        // Medyaları indir
        let total = mediaItems.count
        for (i, item) in mediaItems.enumerated() {
            try Task.checkCancellation()
            await progressHandler(Double(i) / Double(max(total, 1)), "İndiriliyor: \(i + 1)/\(total)")

            let downloadURL = try await mediaRepo.downloadURL(for: item.path)
            try Task.checkCancellation()

            // Bu çağrı iptal edilirse CancellationError propagate olur
            let (data, _) = try await URLSession.shared.data(from: downloadURL)
            try Task.checkCancellation()

            let ext = item.isVideo ? "mp4" : "jpg"
            let ts  = item.createdAt.formatted(date: .abbreviated, time: .omitted)
            let name = "\(ts)_\(String(format: "%03d", i + 1)).\(ext)"
            try data.write(to: workingDir.appendingPathComponent(name), options: .atomic)
        }

        await progressHandler(0.9, "ZIP hazırlanıyor…")
        try Task.checkCancellation()

        // ZipFoundation ile sıkıştır
        if fm.fileExists(atPath: zipURL.path) { try? fm.removeItem(at: zipURL) }

        // zipItem senkron çalışır; başlamadan önce iptal kontrolü yaptık.
        try fm.zipItem(
            at: workingDir,
            to: zipURL,
            shouldKeepParent: false,
            compressionMethod: .deflate,
            progress: nil
        )

        // Temizlik
        try? fm.removeItem(at: workingDir)

        await progressHandler(1.0, "ZIP hazır")
        return zipURL
    }
}
