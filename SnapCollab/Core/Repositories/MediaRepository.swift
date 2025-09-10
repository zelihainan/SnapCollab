//
//  MediaRepository.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import FirebaseFirestore
import UIKit

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

    func downloadURL(for path: String) async throws -> URL {
        try await storage.url(for: path)
    }
    
    func updateMedia(albumId: String, item: MediaItem) async throws {
        guard let itemId = item.id else { return }
        try await service.updateMedia(albumId: albumId, itemId: itemId, item: item)
    }
    
}

extension MediaRepository {
    
    /// Medya dosyasını sil - sadece yükleyen kişi veya albüm sahibi silebilir
    func deleteMedia(albumId: String, item: MediaItem) async throws {
        guard let uid = auth.uid else {
            throw MediaError.notAuthenticated
        }
        
        guard let itemId = item.id else {
            throw MediaError.invalidMediaItem
        }
        
        // Yetki kontrolü - ya uploader ya da album owner olmalı
        let isUploader = item.uploaderId == uid
        
        // Albüm bilgisini al ve owner kontrolü yap
        // Bu kısımda AlbumRepository'ye erişim gerekiyor
        // Şimdilik basit tutuyoruz - sadece uploader silebilir
        if !isUploader {
            // TODO: Album owner kontrolü eklenecek
            throw MediaError.noPermissionToDelete
        }
        
        do {
            // Önce Firestore'dan sil
            try await service.deleteMedia(albumId: albumId, itemId: itemId)
            print("MediaRepo: Deleted from Firestore: \(itemId)")
            
            // Sonra Storage'dan sil
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
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Giriş yapmanız gerekiyor"
        case .invalidMediaItem:
            return "Geçersiz medya dosyası"
        case .noPermissionToDelete:
            return "Bu fotoğrafı silme yetkiniz yok"
        case .deleteError:
            return "Fotoğraf silinirken hata oluştu"
        case .uploadError:
            return "Fotoğraf yüklenirken hata oluştu"
        }
    }
}
