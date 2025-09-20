//
//  AlbumRepository.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import UIKit

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
                print("🔍 AlbumRepo: No UID found")
                continuation.finish()
                return
            }
            
            print("🔍 AlbumRepo: Starting observation for UID: \(uid)")
            
            let listener = service.myAlbumsQuery(uid: uid)
                .addSnapshotListener { snap, err in
                    if let err = err {
                        print("❌ ALBUM LIST ERROR:", err)
                        return
                    }
                    
                    let documents = snap?.documents ?? []
                    print("🔍 AlbumRepo: Got \(documents.count) documents from Firestore")
                    
                    // Her document'ı ayrı ayrı kontrol et
                    for (index, doc) in documents.enumerated() {
                        print("🔍 Document \(index): \(doc.documentID)")
                        print("🔍 Document data: \(doc.data())")
                        
                        do {
                            let album = try doc.data(as: Album.self)
                            print("🔍 Successfully parsed album: \(album.title)")
                            print("🔍 Album members: \(album.members)")
                            print("🔍 Current user in members: \(album.members.contains(uid))")
                        } catch {
                            print("❌ Failed to parse album \(doc.documentID): \(error)")
                        }
                    }
                    
                    let list = documents.compactMap { doc -> Album? in
                        do {
                            return try doc.data(as: Album.self)
                        } catch {
                            print("❌ Parse error for \(doc.documentID): \(error)")
                            return nil
                        }
                    }
                    
                    print("🔍 AlbumRepo: Yielding \(list.count) albums")
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
        
    func getAlbum(by id: String) async throws -> Album? {
        return try await service.getAlbum(id: id)
    }
}

// MARK: - Migration Extensions
extension AlbumRepository {
    func migrateOldAlbums() async {
        print("Migrating old albums...")
        
        guard let uid = auth.uid else { return }
        
        do {
            let snapshot = try await Firestore.firestore()
                .collection("albums")
                .whereField("members", arrayContains: uid)
                .getDocuments()
            
            for document in snapshot.documents {
                var data = document.data()
                var needsUpdate = false
                
                if data["updatedAt"] == nil {
                    data["updatedAt"] = Timestamp()
                    needsUpdate = true
                    print("Adding updatedAt to album: \(document.documentID)")
                }
                
                if data["inviteCode"] == nil {
                    let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
                    let code = String((0..<6).map { _ in characters.randomElement()! })
                    data["inviteCode"] = code
                    needsUpdate = true
                    print("Adding inviteCode (\(code)) to album: \(document.documentID)")
                }
                
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
    
    func migrateCoverImageSupport() async {
        print("Migrating albums for cover image support...")
        
        guard let uid = auth.uid else { return }
        
        do {
            let snapshot = try await Firestore.firestore()
                .collection("albums")
                .whereField("members", arrayContains: uid)
                .getDocuments()
            
            for document in snapshot.documents {
                var data = document.data()
                var needsUpdate = false
                
                if data["coverImagePath"] == nil {
                    data["coverImagePath"] = NSNull()
                    needsUpdate = true
                    print("Adding coverImagePath field to album: \(document.documentID)")
                }
                
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
                
                if data["updatedAt"] == nil {
                    data["updatedAt"] = Timestamp()
                    needsUpdate = true
                    print("Adding updatedAt to album: \(document.documentID)")
                }
                
                if data["inviteCode"] == nil {
                    let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
                    let code = String((0..<6).map { _ in characters.randomElement()! })
                    data["inviteCode"] = code
                    needsUpdate = true
                    print("Adding inviteCode (\(code)) to album: \(document.documentID)")
                }
                
                if data["coverImagePath"] == nil {
                    data["coverImagePath"] = NSNull()
                    needsUpdate = true
                    print("Adding coverImagePath field to album: \(document.documentID)")
                }
                
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

// MARK: - Owner Transfer & Pinning
extension AlbumRepository {
    
    // MARK: - Owner Transfer
    func transferOwnership(_ albumId: String, to newOwnerId: String, notificationRepo: NotificationRepository? = nil) async throws {
        guard let currentUID = auth.uid else {
            throw AlbumError.notAuthenticated
        }
        
        guard var album = try await getAlbum(by: albumId) else {
            throw AlbumError.albumNotFound
        }
        
        // Sadece mevcut owner transfer yapabilir
        if !album.isOwner(currentUID) {
            throw AlbumError.onlyOwnerCanEdit
        }
        
        // Yeni owner albüm üyesi olmalı
        if !album.isMember(newOwnerId) {
            throw AlbumError.notMember
        }
        
        // Owner kendine transfer edemez
        if currentUID == newOwnerId {
            throw AlbumError.cannotTransferToSelf
        }
        
        let oldOwnerId = album.ownerId
        album.transferOwnership(to: newOwnerId)
        
        try await updateAlbum(album)
        
        // Bildirim gönder
        if let notificationRepo = notificationRepo,
           let currentUser = auth.currentUser {
            await notificationRepo.notifyOwnershipTransferred(
                fromUser: currentUser,
                toUserId: newOwnerId,
                album: album,
                oldOwnerId: oldOwnerId
            )
        }
        
        print("AlbumRepo: Ownership transferred from \(oldOwnerId) to \(newOwnerId) for album: \(album.title)")
    }
    
    // MARK: - Pinleme Özelliği
    func toggleAlbumPin(_ albumId: String) async throws {
        guard let uid = auth.uid else {
            throw AlbumError.notAuthenticated
        }
        
        guard let album = try await getAlbum(by: albumId) else {
            throw AlbumError.albumNotFound
        }
        
        if !album.isMember(uid) {
            throw AlbumError.notMember
        }
        
        // Pinleme bilgisi user-specific olarak UserDefaults'ta saklanacak
        let key = "pinned_albums_\(uid)"
        var pinnedAlbums = UserDefaults.standard.stringArray(forKey: key) ?? []
        
        if pinnedAlbums.contains(albumId) {
            pinnedAlbums.removeAll { $0 == albumId }
        } else {
            pinnedAlbums.append(albumId)
        }
        
        UserDefaults.standard.set(pinnedAlbums, forKey: key)
        
        print("AlbumRepo: Album \(albumId) pin status toggled for user \(uid)")
    }
    
    func getPinnedAlbums() -> [String] {
        guard let uid = auth.uid else { return [] }
        let key = "pinned_albums_\(uid)"
        return UserDefaults.standard.stringArray(forKey: key) ?? []
    }
    
    func isAlbumPinned(_ albumId: String) -> Bool {
        let pinnedAlbums = getPinnedAlbums()
        return pinnedAlbums.contains(albumId)
    }
    
    func sortAlbumsWithPinned(_ albums: [Album]) -> [Album] {
        let pinnedAlbumIds = Set(getPinnedAlbums())
        
        let pinnedAlbums = albums.filter { album in
            guard let id = album.id else { return false }
            return pinnedAlbumIds.contains(id)
        }.sorted { $0.updatedAt > $1.updatedAt }
        
        let unpinnedAlbums = albums.filter { album in
            guard let id = album.id else { return false }
            return !pinnedAlbumIds.contains(id)
        }.sorted { $0.updatedAt > $1.updatedAt }
        
        return pinnedAlbums + unpinnedAlbums
    }
}

// MARK: - Album Management
extension AlbumRepository {
    
    func getAlbumByInviteCode(_ inviteCode: String) async throws -> Album? {
        print("AlbumRepo: Getting album by invite code: \(inviteCode)")
        return try await service.getAlbumByInviteCode(inviteCode)
    }
    
    func updateAlbum(_ album: Album) async throws {
        print("AlbumRepo: Updating album: \(album.title)")
        try await service.updateAlbum(album)
    }
    
    func joinAlbum(inviteCode: String) async throws -> Album {
        guard let uid = auth.uid else {
            throw AlbumError.notAuthenticated
        }
        
        print("AlbumRepo: User \(uid) joining album with code: \(inviteCode)")
        
        guard var album = try await getAlbumByInviteCode(inviteCode) else {
            throw AlbumError.albumNotFound
        }
        
        if album.isMember(uid) {
            throw AlbumError.alreadyMember
        }
        
        album.addMember(uid)
        try await updateAlbum(album)
        
        print("AlbumRepo: Successfully joined album: \(album.title)")
        return album
    }
    
    func leaveAlbum(_ albumId: String) async throws {
        guard let uid = auth.uid else {
            throw AlbumError.notAuthenticated
        }
        
        guard var album = try await getAlbum(by: albumId) else {
            throw AlbumError.albumNotFound
        }
        
        if album.isOwner(uid) {
            throw AlbumError.ownerCannotLeave
        }
        
        if !album.isMember(uid) {
            throw AlbumError.notMember
        }
        
        album.removeMember(uid)
        try await updateAlbum(album)
        
        print("AlbumRepo: User left album: \(album.title)")
    }
    
    func getMyAlbumsWithUpdatedInfo() async throws -> [Album] {
        guard let uid = auth.uid else { return [] }
        
        let snapshot = try await Firestore.firestore()
            .collection("albums")
            .whereField("members", arrayContains: uid)
            .order(by: "updatedAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: Album.self) }
    }
    
    func updateAlbumTitle(_ albumId: String, newTitle: String) async throws {
        guard let uid = auth.uid else {
            throw AlbumError.notAuthenticated
        }
        
        guard var album = try await getAlbum(by: albumId) else {
            throw AlbumError.albumNotFound
        }
        
        if !album.isOwner(uid) {
            throw AlbumError.onlyOwnerCanEdit
        }
        
        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw AlbumError.invalidTitle
        }
        
        album.title = trimmedTitle
        album.updatedAt = .now
        
        try await updateAlbum(album)
        print("AlbumRepo: Album title updated to: \(trimmedTitle)")
    }

    func deleteAlbum(_ albumId: String) async throws {
        guard let uid = auth.uid else {
            throw AlbumError.notAuthenticated
        }
        
        guard let album = try await getAlbum(by: albumId) else {
            throw AlbumError.albumNotFound
        }
        
        if !album.isOwner(uid) {
            throw AlbumError.onlyOwnerCanDelete
        }

        try await service.deleteAlbum(id: albumId)
        print("AlbumRepo: Album deleted: \(album.title)")
    }
}

// MARK: - Member Management
extension AlbumRepository {
    
    func removeMemberFromAlbum(_ albumId: String, memberUID: String) async throws {
        guard let currentUID = auth.uid else {
            throw AlbumError.notAuthenticated
        }
        
        guard var album = try await getAlbum(by: albumId) else {
            throw AlbumError.albumNotFound
        }
        
        if !album.isOwner(currentUID) {
            throw AlbumError.onlyOwnerCanEdit
        }
        
        if album.isOwner(memberUID) {
            throw AlbumError.cannotRemoveOwner
        }
        
        if !album.isMember(memberUID) {
            throw AlbumError.notMember
        }
        
        album.removeMember(memberUID)
        
        try await updateAlbum(album)
        print("AlbumRepo: Member \(memberUID) removed from album: \(album.title)")
    }
    
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
                    let placeholderUser = User(uid: memberUID, email: "Bilinmeyen kullanıcı", displayName: "Silinmiş hesap")
                    members.append(placeholderUser)
                }
            } catch {
                print("Error loading user \(memberUID): \(error)")
                let placeholderUser = User(uid: memberUID, email: "Bilinmeyen kullanıcı", displayName: "Silinmiş hesap")
                members.append(placeholderUser)
            }
        }
        
        return members
    }
    
    func canViewAlbum(_ albumId: String, userUID: String) async throws -> Bool {
        guard let album = try await getAlbum(by: albumId) else {
            return false
        }
        
        return album.isMember(userUID)
    }
    
    func getAlbumStats(_ albumId: String) async throws -> AlbumStats {
        guard let album = try await getAlbum(by: albumId) else {
            throw AlbumError.albumNotFound
        }
        
        return AlbumStats(
            memberCount: album.members.count,
            createdDate: album.createdAt,
            lastUpdated: album.updatedAt
        )
    }
}

// MARK: - Cover Image Management
extension AlbumRepository {
    
    func updateCoverImage(_ albumId: String, coverImage: UIImage) async throws {
        guard let uid = auth.uid else {
            throw AlbumError.notAuthenticated
        }
        
        guard var album = try await getAlbum(by: albumId) else {
            throw AlbumError.albumNotFound
        }
        
        if !album.isOwner(uid) {
            throw AlbumError.onlyOwnerCanEdit
        }
        
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
            }
        }
        
        let newCoverPath = try await uploadCoverImage(coverImage, albumId: albumId)
        
        album.updateCoverImage(newCoverPath)
        try await updateAlbum(album)
        
        print("AlbumRepo: Cover image updated successfully")
    }
    
    func removeCoverImage(_ albumId: String) async throws {
        guard let uid = auth.uid else {
            throw AlbumError.notAuthenticated
        }
        
        guard var album = try await getAlbum(by: albumId) else {
            throw AlbumError.albumNotFound
        }
        
        if !album.isOwner(uid) {
            throw AlbumError.onlyOwnerCanEdit
        }
        
        guard let coverPath = album.coverImagePath else {
            throw AlbumError.noCoverImageToDelete
        }
        
        let mediaRepo = MediaRepository(
            service: FirestoreMediaService(),
            storage: FirebaseStorageService(),
            auth: auth
        )
        try await mediaRepo.storage.delete(path: coverPath)
        
        album.updateCoverImage(nil)
        try await updateAlbum(album)
        
        print("AlbumRepo: Cover image removed successfully")
    }
    
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
    
    private func uploadCoverImage(_ image: UIImage, albumId: String) async throws -> String {
        let optimizedImage = await optimizeForCover(image)
        
        guard let imageData = optimizedImage.jpegData(compressionQuality: 0.8) else {
            throw AlbumError.imageProcessingFailed
        }
        
        let fileName = "cover_\(Date().timeIntervalSince1970).jpg"
        let storagePath = "albums/\(albumId)/cover/\(fileName)"
        
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

// MARK: - Notification Extensions
extension AlbumRepository {
    
    func joinAlbumWithNotification(inviteCode: String, notificationRepo: NotificationRepository) async throws -> Album {
        guard let uid = auth.uid,
              let currentUser = auth.currentUser else {
            throw AlbumError.notAuthenticated
        }
        
        print("AlbumRepo: User \(uid) joining album with code: \(inviteCode)")
        
        guard var album = try await getAlbumByInviteCode(inviteCode) else {
            throw AlbumError.albumNotFound
        }
        
        if album.isMember(uid) {
            throw AlbumError.alreadyMember
        }
        
        album.addMember(uid)
        try await updateAlbum(album)
        
        let otherMemberIds = album.members.filter { $0 != uid }
        if !otherMemberIds.isEmpty {
            await notificationRepo.notifyMemberJoined(
                newUser: currentUser,
                toUserIds: otherMemberIds,
                album: album
            )
        }
        
        print("AlbumRepo: Successfully joined album with notification: \(album.title)")
        return album
    }
    
    func updateAlbumTitleWithNotification(_ albumId: String, newTitle: String, notificationRepo: NotificationRepository) async throws {
        guard let uid = auth.uid,
              let currentUser = auth.currentUser else {
            throw AlbumError.notAuthenticated
        }
        
        guard var album = try await getAlbum(by: albumId) else {
            throw AlbumError.albumNotFound
        }
        
        if !album.isOwner(uid) {
            throw AlbumError.onlyOwnerCanEdit
        }
        
        let oldTitle = album.title
        
        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw AlbumError.invalidTitle
        }
        
        album.title = trimmedTitle
        album.updatedAt = .now
        
        try await updateAlbum(album)
        
        let otherMemberIds = album.members.filter { $0 != uid }
        if !otherMemberIds.isEmpty {
            await notificationRepo.notifyAlbumUpdated(
                fromUser: currentUser,
                toUserIds: otherMemberIds,
                album: album,
                changeType: "adını \"\(oldTitle)\" yerine \"\(trimmedTitle)\" olarak değiştirdi"
            )
        }
        
        print("AlbumRepo: Album title updated with notification to: \(trimmedTitle)")
    }
    
    func updateCoverImageWithNotification(_ albumId: String, coverImage: UIImage, notificationRepo: NotificationRepository) async throws {
        guard let uid = auth.uid,
              let currentUser = auth.currentUser else {
            throw AlbumError.notAuthenticated
        }
        
        try await updateCoverImage(albumId, coverImage: coverImage)
        
        guard let album = try await getAlbum(by: albumId) else { return }
        
        // Diğer üyelere bildirim gönder
        let otherMemberIds = album.members.filter { $0 != uid }
        if !otherMemberIds.isEmpty {
            await notificationRepo.notifyAlbumUpdated(
                fromUser: currentUser,
                toUserIds: otherMemberIds,
                album: album,
                changeType: "kapak fotoğrafını değiştirdi"
            )
        }
    }
}

// MARK: - Supporting Types
struct AlbumStats {
    let memberCount: Int
    let createdDate: Date
    let lastUpdated: Date
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
    case noCoverImageToDelete
    case imageProcessingFailed
    case cannotTransferToSelf
    case ownershipTransferFailed
    
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
        case .noCoverImageToDelete:
            return "Silinecek kapak fotoğrafı yok"
        case .imageProcessingFailed:
            return "Görüntü işleme hatası"
        case .cannotTransferToSelf:
            return "Kendinize owner transfer yapamazsınız"
        case .ownershipTransferFailed:
            return "Owner transfer işlemi başarısız"
        }
    }
}
