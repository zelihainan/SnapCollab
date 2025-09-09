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
    let auth: AuthRepository
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
// AlbumRepository.swift dosyasına eklenecek extension

extension AlbumRepository {
    
    // MARK: - Join Album Methods
    
    /// Davet kodu ile albüm bulma
    func getAlbumByInviteCode(_ inviteCode: String) async throws -> Album? {
        print("AlbumRepo: Getting album by invite code: \(inviteCode)")
        return try await service.getAlbumByInviteCode(inviteCode)
    }
    
    /// Albümü güncelleme (üye ekleme/çıkarma için)
    func updateAlbum(_ album: Album) async throws {
        print("AlbumRepo: Updating album: \(album.title)")
        try await service.updateAlbum(album)
    }
    
    /// Kullanıcıyı albüme ekleme
    func joinAlbum(inviteCode: String) async throws -> Album {
        guard let uid = auth.uid else {
            throw AlbumError.notAuthenticated
        }
        
        print("AlbumRepo: User \(uid) joining album with code: \(inviteCode)")
        
        // Albümü bul
        guard var album = try await getAlbumByInviteCode(inviteCode) else {
            throw AlbumError.albumNotFound
        }
        
        // Zaten üye mi kontrol et
        if album.isMember(uid) {
            throw AlbumError.alreadyMember
        }
        
        // Üye ekle ve güncelle
        album.addMember(uid)
        try await updateAlbum(album)
        
        print("AlbumRepo: Successfully joined album: \(album.title)")
        return album
    }
    
    /// Kullanıcıyı albümden çıkarma
    func leaveAlbum(_ albumId: String) async throws {
        guard let uid = auth.uid else {
            throw AlbumError.notAuthenticated
        }
        
        guard var album = try await getAlbum(by: albumId) else {
            throw AlbumError.albumNotFound
        }
        
        // Sahip çıkamaz
        if album.isOwner(uid) {
            throw AlbumError.ownerCannotLeave
        }
        
        // Üye değilse hata
        if !album.isMember(uid) {
            throw AlbumError.notMember
        }
        
        // Üyeyi çıkar
        album.removeMember(uid)
        try await updateAlbum(album)
        
        print("AlbumRepo: User left album: \(album.title)")
    }
    
    /// Kullanıcının üyesi olduğu albümleri getir (artık güncelleme ile birlikte)
    func getMyAlbumsWithUpdatedInfo() async throws -> [Album] {
        guard let uid = auth.uid else { return [] }
        
        // Basit query ile albümleri çek
        let snapshot = try await Firestore.firestore()
            .collection("albums")
            .whereField("members", arrayContains: uid)
            .order(by: "updatedAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: Album.self) }
    }
}

// MARK: - Album Error Enum

enum AlbumError: LocalizedError {
    case notAuthenticated
    case albumNotFound
    case alreadyMember
    case notMember
    case ownerCannotLeave
    case invalidInviteCode
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Giriş yapmanız gerekiyor"
        case .albumNotFound:
            return "Albüm bulunamadı"
        case .alreadyMember:
            return "Bu albümün zaten üyesisiniz"
        case .notMember:
            return "Bu albümün üyesi değilsiniz"
        case .ownerCannotLeave:
            return "Albüm sahibi albümü terk edemez"
        case .invalidInviteCode:
            return "Geçersiz davet kodu"
        }
    }
}
