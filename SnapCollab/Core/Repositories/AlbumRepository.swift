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
    private let userService: UserProviding
    
    init(service: AlbumProviding, auth: AuthRepository, userService: UserProviding) {
        self.service = service
        self.auth = auth
        self.userService = userService
    }

    func observeMyAlbums() -> AsyncStream<[Album]> {
        AsyncStream { continuation in
            guard let uid = auth.uid else {
                continuation.finish()
                return
            }
            
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
        let album = Album(title: title, ownerId: uid)
        _ = try await service.createAlbum(album)
    }
    
    // MARK: - Basit Üyelik Metodları (Gelişmiş özellikler sonra eklenecek)
    
    func getAlbum(by id: String) async throws -> Album? {
        return try await service.getAlbum(id: id)
    }
    
}
// AlbumRepository.swift dosyasının sonuna ekle

extension AlbumRepository {
    // GEÇİCİ: Eski albümleri güncelle
    func migrateOldAlbums() async {
        print("🔄 Migrating old albums...")
        
        guard let uid = auth.uid else { return }
        
        do {
            // Basit query ile eski albümleri çek
            let snapshot = try await Firestore.firestore()
                .collection("albums")
                .whereField("members", arrayContains: uid)
                .getDocuments()
            
            for document in snapshot.documents {
                var data = document.data()
                var needsUpdate = false
                
                // updatedAt yoksa ekle
                if data["updatedAt"] == nil {
                    data["updatedAt"] = Timestamp()
                    needsUpdate = true
                    print("➕ Adding updatedAt to album: \(document.documentID)")
                }
                
                // inviteCode yoksa ekle
                if data["inviteCode"] == nil {
                    let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
                    let code = String((0..<6).map { _ in characters.randomElement()! })
                    data["inviteCode"] = code
                    needsUpdate = true
                    print("➕ Adding inviteCode (\(code)) to album: \(document.documentID)")
                }
                
                // Güncelleme gerekiyorsa kaydet
                if needsUpdate {
                    try await document.reference.updateData(data)
                    print("✅ Updated album: \(document.documentID)")
                }
            }
            
            print("🎉 Migration completed!")
            
        } catch {
            print("❌ Migration error: \(error)")
        }
    }
}
