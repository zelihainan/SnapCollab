//
//  MediaRepository.swift - Toplu Bildirim Entegrasyonu
//  SnapCollab

import FirebaseFirestore
import UIKit
import AVFoundation

final class MediaRepository {
    private let service: MediaProviding
    let storage: ImageCaching
    let auth: AuthRepository

    init(service: MediaProviding, storage: ImageCaching, auth: AuthRepository) {
        self.service = service
        self.storage = storage
        self.auth = auth
    }

    func observe(albumId: String) -> AsyncStream<[MediaItem]> {
        AsyncStream { continuation in
            let l = service.mediaQuery(albumId: albumId).addSnapshotListener { snap, _ in
                let list = snap?.documents.compactMap { try? $0.data(as: MediaItem.self) } ?? []
                continuation.yield(list)
            }
            continuation.onTermination = { _ in l.remove() }
        }
    }
    
    // MARK: - Temel Upload Metotları (Bildirim Olmadan)
    func upload(image: UIImage, albumId: String) async throws {
        guard let uid = auth.uid else { return }
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }

        let mediaId = UUID().uuidString
        let path = "albums/\(albumId)/\(mediaId)/original.jpg"
        print("UPLOAD start →", path)

        try await storage.put(data: data, to: path)
        print("STORAGE OK")

        let item = MediaItem(id: nil, path: path, thumbPath: nil,
                             type: "image", uploaderId: uid, createdAt: .now)
        let docId = try await service.createMedia(albumId: albumId, item: item)
        print("FIRESTORE OK → media doc:", docId)
    }
    
    func uploadVideo(from videoURL: URL, albumId: String) async throws {
        guard let uid = auth.uid else {
            throw MediaError.notAuthenticated
        }
        
        print("VIDEO UPLOAD start → \(videoURL)")
        
        let mediaId = UUID().uuidString
        let videoPath = "albums/\(albumId)/\(mediaId)/video.mp4"
        let thumbPath = "albums/\(albumId)/\(mediaId)/thumb.jpg"
        
        guard videoURL.startAccessingSecurityScopedResource() else {
            throw MediaError.uploadError
        }
        defer { videoURL.stopAccessingSecurityScopedResource() }
        
        let videoData = try Data(contentsOf: videoURL)
        print("Video data size: \(videoData.count) bytes")
        
        let maxVideoSize = 50 * 1024 * 1024 // 50MB
        guard videoData.count <= maxVideoSize else {
            throw MediaError.fileTooLarge
        }
        
        guard isValidVideoFormat(data: videoData) else {
            throw MediaError.unsupportedFileType
        }
        
        let thumbnailImage = try await generateThumbnail(from: videoURL)
        guard let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.8) else {
            throw MediaError.uploadError
        }
        
        try await storage.put(data: videoData, to: videoPath)
        try await storage.put(data: thumbnailData, to: thumbPath)
        
        print("VIDEO & THUMBNAIL STORAGE OK")
        
        let item = MediaItem(
            id: nil,
            path: videoPath,
            thumbPath: thumbPath,
            type: "video",
            uploaderId: uid,
            createdAt: .now
        )
        
        let docId = try await service.createMedia(albumId: albumId, item: item)
        print("FIRESTORE OK → video doc:", docId)
    }
}

// MARK: - Toplu Bildirim ile Upload İşlemleri
extension MediaRepository {
    
    /// TEK FOTOĞRAF YÜKLEME - Toplu bildirim sistemi ile
    func uploadWithBatchNotification(image: UIImage, albumId: String, notificationRepo: NotificationRepository) async throws {
        // Önce fotoğrafı yükle
        try await upload(image: image, albumId: albumId)
        
        // Sonra batch bildirim gönder
        await sendBatchPhotoNotification(albumId: albumId, notificationRepo: notificationRepo)
    }
    
    /// TEK VIDEO YÜKLEME - Toplu bildirim sistemi ile
    func uploadVideoWithBatchNotification(from videoURL: URL, albumId: String, notificationRepo: NotificationRepository) async throws {
        // Önce videoyu yükle
        try await uploadVideo(from: videoURL, albumId: albumId)
        
        // Sonra batch bildirim gönder
        await sendBatchVideoNotification(albumId: albumId, notificationRepo: notificationRepo)
    }
    
    /// ÇOKLU FOTOĞRAF YÜKLEME - Toplu bildirim sistemi ile
    func uploadMultipleImagesWithBatchNotification(images: [UIImage], albumId: String, notificationRepo: NotificationRepository) async throws {
        print("🔄 Starting batch upload of \(images.count) images")
        
        // Tüm fotoğrafları yükle
        for (index, image) in images.enumerated() {
            print("📸 Uploading image \(index + 1)/\(images.count)")
            try await upload(image: image, albumId: albumId)
            
            // Her fotoğraf için batch notification ekle
            await sendBatchPhotoNotification(albumId: albumId, notificationRepo: notificationRepo)
        }
        
        print("✅ Completed batch upload of \(images.count) images")
    }
    
    /// KARMA MEDYA YÜKLEME - Toplu bildirim sistemi ile
    func uploadMixedMediaWithBatchNotification(
        images: [UIImage],
        videoURLs: [URL],
        albumId: String,
        notificationRepo: NotificationRepository
    ) async throws {
        print("🔄 Starting mixed media upload - \(images.count) images, \(videoURLs.count) videos")
        
        // Tüm fotoğrafları yükle
        for (index, image) in images.enumerated() {
            print("📸 Uploading image \(index + 1)/\(images.count)")
            try await upload(image: image, albumId: albumId)
            await sendBatchPhotoNotification(albumId: albumId, notificationRepo: notificationRepo)
        }
        
        // Tüm videoları yükle
        for (index, videoURL) in videoURLs.enumerated() {
            print("🎥 Uploading video \(index + 1)/\(videoURLs.count)")
            try await uploadVideo(from: videoURL, albumId: albumId)
            await sendBatchVideoNotification(albumId: albumId, notificationRepo: notificationRepo)
        }
        
        print("✅ Completed mixed media upload")
    }
    
    // MARK: - Batch Notification Helper Metotları
    
    private func sendBatchPhotoNotification(albumId: String, notificationRepo: NotificationRepository) async {
        guard let currentUser = auth.currentUser else {
            print("❌ No current user for photo notification")
            return
        }
        
        do {
            // Albüm bilgilerini al
            let db = Firestore.firestore()
            let doc = try await db.collection("albums").document(albumId).getDocument()
            guard let album = try? doc.data(as: Album.self) else {
                print("❌ Could not fetch album for photo notification")
                return
            }
            
            // Diğer üyeleri bul
            let otherMemberIds = album.members.filter { $0 != currentUser.uid }
            
            if !otherMemberIds.isEmpty {
                print("📸 Sending batch photo notification to \(otherMemberIds.count) members")
                await notificationRepo.notifyPhotoAddedBatch(
                    fromUser: currentUser,
                    toUserIds: otherMemberIds,
                    album: album
                )
            } else {
                print("📸 No other members to notify for photo")
            }
        } catch {
            print("❌ Failed to send batch photo notification: \(error)")
        }
    }
    
    private func sendBatchVideoNotification(albumId: String, notificationRepo: NotificationRepository) async {
        guard let currentUser = auth.currentUser else {
            print("❌ No current user for video notification")
            return
        }
        
        do {
            // Albüm bilgilerini al
            let db = Firestore.firestore()
            let doc = try await db.collection("albums").document(albumId).getDocument()
            guard let album = try? doc.data(as: Album.self) else {
                print("❌ Could not fetch album for video notification")
                return
            }
            
            // Diğer üyeleri bul
            let otherMemberIds = album.members.filter { $0 != currentUser.uid }
            
            if !otherMemberIds.isEmpty {
                print("🎥 Sending batch video notification to \(otherMemberIds.count) members")
                await notificationRepo.notifyVideoAddedBatch(
                    fromUser: currentUser,
                    toUserIds: otherMemberIds,
                    album: album
                )
            } else {
                print("🎥 No other members to notify for video")
            }
        } catch {
            print("❌ Failed to send batch video notification: \(error)")
        }
    }
}

// MARK: - Legacy Anında Bildirim Sistemi (Eski Uyumluluk)
extension MediaRepository {
    
    /// Legacy - Tek seferlik fotoğraf bildirimi (eski kod uyumluluğu için)
    func uploadWithNotification(image: UIImage, albumId: String, notificationRepo: NotificationRepository) async throws {
        try await upload(image: image, albumId: albumId)
        await sendInstantPhotoNotification(albumId: albumId, notificationRepo: notificationRepo)
    }
    
    /// Legacy - Tek seferlik video bildirimi (eski kod uyumluluğu için)
    func uploadVideoWithNotification(from videoURL: URL, albumId: String, notificationRepo: NotificationRepository) async throws {
        try await uploadVideo(from: videoURL, albumId: albumId)
        await sendInstantVideoNotification(albumId: albumId, notificationRepo: notificationRepo)
    }
    
    // MARK: - Legacy Instant Notification Helpers
    
    private func sendInstantPhotoNotification(albumId: String, notificationRepo: NotificationRepository) async {
        guard let currentUser = auth.currentUser else { return }
        
        do {
            let db = Firestore.firestore()
            let doc = try await db.collection("albums").document(albumId).getDocument()
            guard let album = try? doc.data(as: Album.self) else { return }
            
            let otherMemberIds = album.members.filter { $0 != currentUser.uid }
            
            if !otherMemberIds.isEmpty {
                await notificationRepo.notifyPhotoAdded(
                    fromUser: currentUser,
                    toUserIds: otherMemberIds,
                    album: album
                )
            }
        } catch {
            print("Failed to send instant photo notification: \(error)")
        }
    }
    
    private func sendInstantVideoNotification(albumId: String, notificationRepo: NotificationRepository) async {
        guard let currentUser = auth.currentUser else { return }
        
        do {
            let db = Firestore.firestore()
            let doc = try await db.collection("albums").document(albumId).getDocument()
            guard let album = try? doc.data(as: Album.self) else { return }
            
            let otherMemberIds = album.members.filter { $0 != currentUser.uid }
            
            if !otherMemberIds.isEmpty {
                await notificationRepo.notifyVideoAdded(
                    fromUser: currentUser,
                    toUserIds: otherMemberIds,
                    album: album
                )
            }
        } catch {
            print("Failed to send instant video notification: \(error)")
        }
    }
}

// MARK: - Diğer MediaRepository Metotları (Değişiklik Yok)
extension MediaRepository {
    
    func downloadURL(for path: String) async throws -> URL {
        try await storage.url(for: path)
    }
    
    func updateMedia(albumId: String, item: MediaItem) async throws {
        guard let itemId = item.id else { return }
        try await service.updateMedia(albumId: albumId, itemId: itemId, item: item)
    }
    
    func deleteMedia(albumId: String, item: MediaItem) async throws {
        guard let uid = auth.uid else {
            throw MediaError.notAuthenticated
        }
        
        guard let itemId = item.id else {
            throw MediaError.invalidMediaItem
        }
        
        let isUploader = item.uploaderId == uid
        
        if !isUploader {
            throw MediaError.noPermissionToDelete
        }
        
        do {
            try await service.deleteMedia(albumId: albumId, itemId: itemId)
            print("MediaRepo: Deleted from Firestore: \(itemId)")
            
            try await storage.delete(path: item.path)
            print("MediaRepo: Deleted from Storage: \(item.path)")
            
            if let thumbPath = item.thumbPath {
                try await storage.delete(path: thumbPath)
                print("MediaRepo: Deleted thumbnail: \(thumbPath)")
            }
            
        } catch {
            print("MediaRepo: Delete error: \(error)")
            throw MediaError.deleteError
        }
    }
    
    // MARK: - Video Processing Helpers
    
    private func isValidVideoFormat(data: Data) -> Bool {
        let mp4Headers: [[UInt8]] = [
            [0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70],
            [0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70],
            [0x00, 0x00, 0x00, 0x1C, 0x66, 0x74, 0x79, 0x70]
        ]
        
        guard data.count >= 8 else { return false }
        
        let headerBytes = Array(data.prefix(8))
        
        for header in mp4Headers {
            if headerBytes.starts(with: header) {
                return true
            }
        }
        
        if headerBytes.count >= 4 {
            let qtHeader = Array(headerBytes[4..<8])
            if qtHeader == [0x66, 0x74, 0x79, 0x70] {
                return true
            }
        }
        
        return false
    }
    
    private func generateThumbnail(from videoURL: URL) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let asset = AVAsset(url: videoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.maximumSize = CGSize(width: 400, height: 400)
            
            let times = [
                CMTime(seconds: 1, preferredTimescale: 600),
                CMTime(seconds: 0.5, preferredTimescale: 600),
                CMTime(seconds: 0.1, preferredTimescale: 600)
            ]
            
            var attemptCount = 0
            
            func tryNextTime() {
                guard attemptCount < times.count else {
                    continuation.resume(throwing: MediaError.uploadError)
                    return
                }
                
                let time = times[attemptCount]
                attemptCount += 1
                
                imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, result, error in
                    if let cgImage = cgImage {
                        let uiImage = UIImage(cgImage: cgImage)
                        continuation.resume(returning: uiImage)
                    } else {
                        print("Thumbnail generation failed at time \(time.seconds), trying next...")
                        tryNextTime()
                    }
                }
            }
            
            tryNextTime()
        }
    }
}

enum MediaError: LocalizedError {
    case notAuthenticated
    case invalidMediaItem
    case noPermissionToDelete
    case deleteError
    case uploadError
    case unsupportedFileType
    case fileTooLarge
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Giriş yapmanız gerekiyor"
        case .invalidMediaItem:
            return "Geçersiz medya dosyası"
        case .noPermissionToDelete:
            return "Bu medyayı silme yetkiniz yok"
        case .deleteError:
            return "Medya silinirken hata oluştu"
        case .uploadError:
            return "Medya yüklenirken hata oluştu"
        case .unsupportedFileType:
            return "Desteklenmeyen dosya türü"
        case .fileTooLarge:
            return "Dosya boyutu çok büyük (maksimum 50MB)"
        }
    }
}
