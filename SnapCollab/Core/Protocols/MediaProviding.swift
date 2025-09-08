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
}

protocol ImageCaching {
    func url(for storagePath: String) async throws -> URL
    func put(data: Data, to storagePath: String) async throws
}
