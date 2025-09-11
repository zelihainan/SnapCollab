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
    func migrateOldAlbums() async {
        print("Migrating old albums...")
        
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
                    print("Adding updatedAt to album: \(document.documentID)")
                }
                
                // inviteCode yoksa ekle
                if data["inviteCode"] == nil {
                    let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
                    let code = String((0..<6).map { _ in characters.randomElement()! })
                    data["inviteCode"] = code
                    needsUpdate = true
                    print("Adding inviteCode (\(code)) to album: \(document.documentID)")
                }
                
                // Güncelleme gerekiyorsa kaydet
                if needsUpdate {
                    try await document.reference.updateData(data)
                    print("Updated album: \(document.documentID)")
                }
            }
            
            print("Migration completed!")
            
        } catch {
            print("Migration error: \(error)")
        }
    }
}

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
    

    /// Albüm adını güncelleme - sadece sahip yapabilir
    func updateAlbumTitle(_ albumId: String, newTitle: String) async throws {
        guard let uid = auth.uid else {
            throw AlbumError.notAuthenticated
        }
        
        // Albümü al ve yetki kontrol et
        guard var album = try await getAlbum(by: albumId) else {
            throw AlbumError.albumNotFound
        }
        
        // Sadece sahip değiştirebilir
        if !album.isOwner(uid) {
            throw AlbumError.onlyOwnerCanEdit
        }
        
        // Başlığı güncelle
        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw AlbumError.invalidTitle
        }
        
        album.title = trimmedTitle
        album.updatedAt = .now
        
        // Mevcut updateAlbum metodunu kullan
        try await updateAlbum(album)
        print("AlbumRepo: Album title updated to: \(trimmedTitle)")
    }

    /// Albümü tamamen silme - sadece sahip yapabilir
    func deleteAlbum(_ albumId: String) async throws {
        guard let uid = auth.uid else {
            throw AlbumError.notAuthenticated
        }
        
        // Albümü al ve yetki kontrol et
        guard let album = try await getAlbum(by: albumId) else {
            throw AlbumError.albumNotFound
        }
        
        // Sadece sahip silebilir
        if !album.isOwner(uid) {
            throw AlbumError.onlyOwnerCanDelete
        }
        
        // TODO: Albümdeki tüm fotoğrafları da sil (Firebase Storage'dan)
        // Şimdilik sadece Firestore'dan sil
        try await service.deleteAlbum(id: albumId)
        print("AlbumRepo: Album deleted: \(album.title)")
    }
}

extension AlbumRepository {
    
    /// Albümden üye çıkarma - sadece albüm sahibi yapabilir
    func removeMemberFromAlbum(_ albumId: String, memberUID: String) async throws {
        guard let currentUID = auth.uid else {
            throw AlbumError.notAuthenticated
        }
        
        // Albümü al ve yetki kontrol et
        guard var album = try await getAlbum(by: albumId) else {
            throw AlbumError.albumNotFound
        }
        
        // Sadece sahip üye çıkarabilir
        if !album.isOwner(currentUID) {
            throw AlbumError.onlyOwnerCanEdit
        }
        
        // Sahip kendini çıkaramaz
        if album.isOwner(memberUID) {
            throw AlbumError.cannotRemoveOwner
        }
        
        // Üye kontrol et
        if !album.isMember(memberUID) {
            throw AlbumError.notMember
        }
        
        // Üyeyi çıkar
        album.removeMember(memberUID)
        
        // Güncelle
        try await updateAlbum(album)
        print("AlbumRepo: Member \(memberUID) removed from album: \(album.title)")
    }
    
    /// Albüm üyelerinin User bilgilerini getir
    func getAlbumMembers(_ albumId: String) async throws -> [User] {
        guard let album = try await getAlbum(by: albumId) else {
            throw AlbumError.albumNotFound
        }
        
        let userService = FirestoreUserService()
        var members: [User] = []
        
        for memberUID in album.members {
            do {
                if let user = try await userService.getUser(uid: memberUID) {
                    members.append(user)
                } else {
                    // Kullanıcı bulunamadıysa placeholder oluştur
                    let placeholderUser = User(uid: memberUID, email: "Bilinmeyen kullanıcı", displayName: "Silinmiş hesap")
                    members.append(placeholderUser)
                }
            } catch {
                print("Error loading user \(memberUID): \(error)")
                // Hata durumunda placeholder ekle
                let placeholderUser = User(uid: memberUID, email: "Bilinmeyen kullanıcı", displayName: "Silinmiş hesap")
                members.append(placeholderUser)
            }
        }
        
        return members
    }
    
    /// Belirli bir üyenin albümü görme yetkisi var mı kontrol et
    func canViewAlbum(_ albumId: String, userUID: String) async throws -> Bool {
        guard let album = try await getAlbum(by: albumId) else {
            return false
        }
        
        return album.isMember(userUID)
    }
    
    /// Albümün istatistiklerini getir
    func getAlbumStats(_ albumId: String) async throws -> AlbumStats {
        guard let album = try await getAlbum(by: albumId) else {
            throw AlbumError.albumNotFound
        }
        
        // Medya sayısını hesapla (MediaRepository kullanarak)
        // Bu kısım isteğe bağlı - şimdilik basit tutuyoruz
        
        return AlbumStats(
            memberCount: album.members.count,
            createdDate: album.createdAt,
            lastUpdated: album.updatedAt
        )
    }
}
extension AlbumRepository {
    
    // MARK: - Cover Image Management
    
    /// Albüm kapak fotoğrafını güncelle
    func updateCoverImage(_ albumId: String, coverImage: UIImage) async throws {
        guard let uid = auth.uid else {
            throw AlbumError.notAuthenticated
        }
        
        // Albümü al ve yetki kontrol et
        guard var album = try await getAlbum(by: albumId) else {
            throw AlbumError.albumNotFound
        }
        
        // Sadece sahip kapak fotoğrafını değiştirebilir
        if !album.isOwner(uid) {
            throw AlbumError.onlyOwnerCanEdit
        }
        
        // Eski kapak fotoğrafını sil (varsa)
        if let oldCoverPath = album.coverImagePath {
            do {
                let mediaRepo = MediaRepository(
                    service: FirestoreMediaService(),
                    storage: FirebaseStorageService(),
                    auth: auth
                )
                try await mediaRepo.storage.delete(path: oldCoverPath)
                print("AlbumRepo: Old cover image deleted: \(oldCoverPath)")
            } catch {
                print("AlbumRepo: Failed to delete old cover image: \(error)")
                // Devam et - yeni fotoğraf yüklenebilir
            }
        }
        
        // Yeni kapak fotoğrafını yükle
        let newCoverPath = try await uploadCoverImage(coverImage, albumId: albumId)
        
        // Albümü güncelle
        album.updateCoverImage(newCoverPath)
        try await updateAlbum(album)
        
        print("AlbumRepo: Cover image updated successfully")
    }
    
    /// Albüm kapak fotoğrafını sil
    func removeCoverImage(_ albumId: String) async throws {
        guard let uid = auth.uid else {
            throw AlbumError.notAuthenticated
        }
        
        // Albümü al ve yetki kontrol et
        guard var album = try await getAlbum(by: albumId) else {
            throw AlbumError.albumNotFound
        }
        
        // Sadece sahip kapak fotoğrafını silebilir
        if !album.isOwner(uid) {
            throw AlbumError.onlyOwnerCanEdit
        }
        
        // Kapak fotoğrafı var mı kontrol et
        guard let coverPath = album.coverImagePath else {
            throw AlbumError.noCoverImageToDelete
        }
        
        // Storage'dan sil
        let mediaRepo = MediaRepository(
            service: FirestoreMediaService(),
            storage: FirebaseStorageService(),
            auth: auth
        )
        try await mediaRepo.storage.delete(path: coverPath)
        
        // Albümden kaldır
        album.updateCoverImage(nil)
        try await updateAlbum(album)
        
        print("AlbumRepo: Cover image removed successfully")
    }
    
    /// Kapak fotoğrafı URL'sini al
    func getCoverImageURL(_ albumId: String) async throws -> URL? {
        guard let album = try await getAlbum(by: albumId),
              let coverPath = album.coverImagePath else {
            return nil
        }
        
        let mediaRepo = MediaRepository(
            service: FirestoreMediaService(),
            storage: FirebaseStorageService(),
            auth: auth
        )
        
        return try await mediaRepo.storage.url(for: coverPath)
    }
    
    // MARK: - Private Helper Methods
    
    private func uploadCoverImage(_ image: UIImage, albumId: String) async throws -> String {
        // Resmi optimize et (512x512, dairesel gösterim için kare olmalı)
        let optimizedImage = await optimizeForCover(image)
        
        guard let imageData = optimizedImage.jpegData(compressionQuality: 0.8) else {
            throw AlbumError.imageProcessingFailed
        }
        
        // Storage path oluştur
        let fileName = "cover_\(Date().timeIntervalSince1970).jpg"
        let storagePath = "albums/\(albumId)/cover/\(fileName)"
        
        // Storage'a yükle
        let mediaRepo = MediaRepository(
            service: FirestoreMediaService(),
            storage: FirebaseStorageService(),
            auth: auth
        )
        try await mediaRepo.storage.put(data: imageData, to: storagePath)
        
        print("AlbumRepo: Cover image uploaded to: \(storagePath)")
        return storagePath
    }
    
    private func optimizeForCover(_ image: UIImage) async -> UIImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let targetSize = CGSize(width: 512, height: 512)
                
                UIGraphicsBeginImageContextWithOptions(targetSize, false, 0)
                
                // Görüntüyü kare olarak crop et
                let imageSize = image.size
                let cropSize = min(imageSize.width, imageSize.height)
                let cropOrigin = CGPoint(
                    x: (imageSize.width - cropSize) / 2,
                    y: (imageSize.height - cropSize) / 2
                )
                
                let cropRect = CGRect(origin: cropOrigin, size: CGSize(width: cropSize, height: cropSize))
                
                if let croppedCGImage = image.cgImage?.cropping(to: cropRect) {
                    let croppedImage = UIImage(cgImage: croppedCGImage)
                    croppedImage.draw(in: CGRect(origin: .zero, size: targetSize))
                }
                
                let optimizedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                continuation.resume(returning: optimizedImage ?? image)
            }
        }
    }
}

//
//  AlbumRepository.swift - Migration Extension
//  SnapCollab
//
//  Migration for cover image support
//

extension AlbumRepository {
    
    /// Eski albümleri yeni cover image field'ı ile güncelle
    func migrateCoverImageSupport() async {
        print("Migrating albums for cover image support...")
        
        guard let uid = auth.uid else { return }
        
        do {
            // Tüm albümleri çek
            let snapshot = try await Firestore.firestore()
                .collection("albums")
                .whereField("members", arrayContains: uid)
                .getDocuments()
            
            for document in snapshot.documents {
                var data = document.data()
                var needsUpdate = false
                
                // coverImagePath yoksa null olarak ekle
                if data["coverImagePath"] == nil {
                    data["coverImagePath"] = NSNull()
                    needsUpdate = true
                    print("Adding coverImagePath field to album: \(document.documentID)")
                }
                
                // Güncelleme gerekiyorsa kaydet
                if needsUpdate {
                    try await document.reference.updateData(data)
                    print("Updated album for cover image support: \(document.documentID)")
                }
            }
            
            print("Cover image migration completed!")
            
        } catch {
            print("Cover image migration error: \(error)")
        }
    }
    
    /// Gelişmiş migration - hem eski hem yeni alanları kontrol et
    func migrateAllAlbumFields() async {
        print("Running complete album migration...")
        
        guard let uid = auth.uid else { return }
        
        do {
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
                    print("Adding updatedAt to album: \(document.documentID)")
                }
                
                // inviteCode yoksa ekle
                if data["inviteCode"] == nil {
                    let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
                    let code = String((0..<6).map { _ in characters.randomElement()! })
                    data["inviteCode"] = code
                    needsUpdate = true
                    print("Adding inviteCode (\(code)) to album: \(document.documentID)")
                }
                
                // coverImagePath yoksa null olarak ekle
                if data["coverImagePath"] == nil {
                    data["coverImagePath"] = NSNull()
                    needsUpdate = true
                    print("Adding coverImagePath field to album: \(document.documentID)")
                }
                
                // Güncelleme gerekiyorsa kaydet
                if needsUpdate {
                    try await document.reference.updateData(data)
                    print("Updated album: \(document.documentID)")
                }
            }
            
            print("Complete album migration finished!")
            
        } catch {
            print("Complete migration error: \(error)")
        }
    }
}

// MARK: - Album Stats Model
struct AlbumStats {
    let memberCount: Int
    let createdDate: Date
    let lastUpdated: Date
    // İleride eklenebilecek diğer istatistikler:
    // let mediaCount: Int
    // let totalSize: Int64
    // let lastPhotoDate: Date?
}

enum AlbumError: LocalizedError {
    case notAuthenticated
    case albumNotFound
    case alreadyMember
    case notMember
    case ownerCannotLeave
    case invalidInviteCode
    case onlyOwnerCanEdit
    case onlyOwnerCanDelete
    case invalidTitle
    case deleteError
    case cannotRemoveOwner
    case noCoverImageToDelete        // Yeni: Silinecek kapak fotoğrafı yok
    case imageProcessingFailed       // Yeni: Görüntü işleme hatası
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Giriş yapmanız gerekiyor"
        case .albumNotFound:
            return "Albüm bulunamadı"
        case .cannotRemoveOwner:
            return "Albüm sahibi çıkarılamaz"
        case .alreadyMember:
            return "Bu albümün zaten üyesisiniz"
        case .notMember:
            return "Bu albümün üyesi değilsiniz"
        case .ownerCannotLeave:
            return "Albüm sahibi albümü terk edemez"
        case .invalidInviteCode:
            return "Geçersiz davet kodu"
        case .onlyOwnerCanEdit:
            return "Sadece albüm sahibi düzenleyebilir"
        case .onlyOwnerCanDelete:
            return "Sadece albüm sahibi silebilir"
        case .invalidTitle:
            return "Geçerli bir başlık giriniz"
        case .deleteError:
            return "Albüm silinirken hata oluştu"
        case .noCoverImageToDelete:      // Yeni case
            return "Silinecek kapak fotoğrafı yok"
        case .imageProcessingFailed:     // Yeni case
            return "Görüntü işleme hatası"
        }
    }
}
