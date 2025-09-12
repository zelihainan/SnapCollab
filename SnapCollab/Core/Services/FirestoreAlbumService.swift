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
        return db.collection("albums")
            .whereField("members", arrayContains: uid)
            .order(by: "updatedAt", descending: true)
            .limit(to: 50)
    }

    func createAlbum(_ album: Album) async throws -> String {
        let ref = db.collection("albums").document()
        var albumWithId = album
        albumWithId.id = ref.documentID
        try ref.setData(from: albumWithId)
        return ref.documentID
    }
    
    func getAlbum(id: String) async throws -> Album? {
        let doc = try await db.collection("albums").document(id).getDocument()
        return try doc.data(as: Album.self)
    }
    
    func getAlbumByInviteCode(_ inviteCode: String) async throws -> Album? {
        let query = db.collection("albums")
            .whereField("inviteCode", isEqualTo: inviteCode)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        guard let document = snapshot.documents.first else {
            return nil
        }
        
        return try document.data(as: Album.self)
    }
    
    func updateAlbum(_ album: Album) async throws {
        guard let albumId = album.id else {
            throw NSError(domain: "FirestoreAlbumService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Album ID is missing"])
        }
        
        try db.collection("albums").document(albumId).setData(from: album, merge: true)
    }
    
    func deleteAlbum(id: String) async throws {
        try await db.collection("albums").document(id).delete()
    }
}
