//
//  FirestoreMediaService.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import FirebaseFirestore

final class FirestoreMediaService: MediaProviding {
    private let db = Firestore.firestore()

    func mediaQuery(albumId: String) -> Query {
        db.collection("albums").document(albumId)
          .collection("media")
          .order(by: "createdAt", descending: true)
    }

    func createMedia(albumId: String, item: MediaItem) async throws -> String {
        let ref = db.collection("albums").document(albumId).collection("media").document()
        var copy = item
        copy.id = ref.documentID
        try ref.setData(from: copy)
        return ref.documentID
    }
}
