//
//  AlbumRepository.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class AlbumRepository {
    private let service: AlbumProviding
    private let auth: AuthRepository
    init(service: AlbumProviding, auth: AuthRepository) {
        self.service = service
        self.auth = auth
    }

    func observeMyAlbums() -> AsyncStream<[Album]> {
        AsyncStream { continuation in
            let uid = Auth.auth().currentUser?.uid
            print("DEBUG UID:", uid ?? "nil")
            
            guard let uid = auth.uid else { continuation.finish(); return }
            let listener = service.myAlbumsQuery(uid: uid)
                .addSnapshotListener { snap, err in
                    if let err = err {
                        print("ALBUM LIST ERROR:", err)
                    }
                    let list = snap?.documents.compactMap { try? $0.data(as: Album.self) } ?? []
                    continuation.yield(list)
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }


    func create(title: String) async throws {
        guard let uid = auth.uid else { return }
        let album = Album(id: nil,
                          title: title,
                          ownerId: uid,
                          members: [uid],
                          createdAt: .now)
        _ = try await service.createAlbum(album)
    }
}
