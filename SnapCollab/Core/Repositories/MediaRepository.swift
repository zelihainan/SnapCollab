//
//  MediaRepository.swift
//  SnapCollab
//
//  Video desteği eklendi
//

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
    
    // MARK: - Image Upload
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
    
    // MARK: - Video Upload
    func uploadVideo(from videoURL: URL, albumId: String) async throws {
        guard let uid = auth.uid else {
            throw MediaError.notAuthenticated
        }
        
        print("VIDEO UPLOAD start → \(videoURL)")
        
        let mediaId = UUID().uuidString
        let videoPath = "albums/\(albumId)/\(mediaId)/video.mp4"
        let thumbPath = "albums/\(albumId)/\(mediaId)/thumb.jpg"
        
        // Video dosyasını Data olarak oku
        let videoData = try Data(contentsOf: videoURL)
        print("Video data size: \(videoData.count) bytes")
        
        // Video thumbnail oluştur
        let thumbnailImage = try await generateThumbnail(from: videoURL)
        guard let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.8) else {
            throw MediaError.uploadError
        }
        
        // Video ve thumbnail'i Storage'a yükle
        try await storage.put(data: videoData, to: videoPath)
        try await storage.put(data: thumbnailData, to: thumbPath)
        
        print("VIDEO & THUMBNAIL STORAGE OK")
        
        // Firestore'a kaydet
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
    
    // MARK: - Thumbnail Generation
    private func generateThumbnail(from videoURL: URL) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let asset = AVAsset(url: videoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.maximumSize = CGSize(width: 300, height: 300)
            
            let time = CMTime(seconds: 1, preferredTimescale: 600)
            
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let cgImage = cgImage else {
                    continuation.resume(throwing: MediaError.uploadError)
                    return
                }
                
                let uiImage = UIImage(cgImage: cgImage)
                continuation.resume(returning: uiImage)
            }
        }
    }

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
        
        // Yetki kontrolü - ya uploader ya da album owner olmalı
        let isUploader = item.uploaderId == uid
        
        if !isUploader {
            // TODO: Album owner kontrolü eklenecek
            throw MediaError.noPermissionToDelete
        }
        
        do {
            // Önce Firestore'dan sil
            try await service.deleteMedia(albumId: albumId, itemId: itemId)
            print("MediaRepo: Deleted from Firestore: \(itemId)")
            
            // Sonra Storage'dan ana dosyayı sil
            try await storage.delete(path: item.path)
            print("MediaRepo: Deleted from Storage: \(item.path)")
            
            // Thumbnail varsa onu da sil
            if let thumbPath = item.thumbPath {
                try await storage.delete(path: thumbPath)
                print("MediaRepo: Deleted thumbnail: \(thumbPath)")
            }
            
        } catch {
            print("MediaRepo: Delete error: \(error)")
            throw MediaError.deleteError
        }
    }
}

// MARK: - Media Error Enum
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
            return "Dosya boyutu çok büyük"
        }
    }
}
