//
//  FirestoreAlbumService.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import Foundation
import FirebaseFirestore

final class FirestoreAlbumService: AlbumProviding {
    private let db = Firestore.firestore()

    func myAlbumsQuery(uid: String) -> Query {
        db.collection("albums")
          .whereField("members", arrayContains: uid)
          //.order(by: "createdAt", descending: true)
    }

    func createAlbum(_ album: Album) async throws -> String {
        let ref = db.collection("albums").document()
        try ref.setData(from: album)  // Codable
        return ref.documentID
    }
}
