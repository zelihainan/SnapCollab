//
//  MediaProviding.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import FirebaseFirestore

protocol MediaProviding {
    func mediaQuery(albumId: String) -> Query
    func createMedia(albumId: String, item: MediaItem) async throws -> String
    func updateMedia(albumId: String, itemId: String, item: MediaItem) async throws
    func deleteMedia(albumId: String, itemId: String) async throws  // ← Bu satırı ekle
}

protocol ImageCaching {
    func url(for storagePath: String) async throws -> URL
    func put(data: Data, to storagePath: String) async throws
    func delete(path: String) async throws  // ← Bu satırı da ekle
}
