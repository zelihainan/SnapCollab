//
//  AlbumProviding.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import FirebaseFirestore

protocol AlbumProviding {
    func myAlbumsQuery(uid: String) -> Query
    func createAlbum(_ album: Album) async throws -> String
}
