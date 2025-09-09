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
    private let auth: AuthRepository

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
}
