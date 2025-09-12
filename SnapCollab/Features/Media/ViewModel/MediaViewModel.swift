//
//  MediaViewModel.swift
//  SnapCollab
//
//  Video desteği eklendi
//

import SwiftUI
import Foundation
import AVKit

@MainActor
final class MediaViewModel: ObservableObject {
    @Published var items: [MediaItem] = []
    @Published var filteredItems: [MediaItem] = []
    @Published var isPicking = false
    @Published var pickedImage: UIImage?
    @Published var pickedVideoURL: URL? // Video URL'si için eklendi
    @Published var currentFilter: MediaFilter = .all
    @Published var favorites: Set<String> = []
    @Published var favoriteAnimations: [String: Bool] = [:]
    
    enum MediaFilter {
        case all
        case photos
        case videos
        case favorites
    }
    
    enum SortType: Hashable {
        case newest
        case oldest
        case uploader
        case favorites
    }
    
    let repo: MediaRepository
    private let albumId: String
    let auth: AuthRepository
    
    // MARK: - User Cache
    private var userCache: [String: User] = [:]
    
    init(repo: MediaRepository, albumId: String) {
        self.repo = repo
        self.albumId = albumId
        self.auth = repo.auth
        
        // Load favorites from UserDefaults
        loadFavorites()
    }
    
    func start() {
        Task {
            for await list in repo.observe(albumId: albumId) {
                self.items = list
                self.applyFilter()
                await preloadUserInfo(for: list)
            }
        }
    }
    
    // MARK: - Upload Methods
    
    func uploadPicked() async {
        // Önce fotoğraf varsa onu yükle
        if let image = pickedImage {
            await uploadPickedImage(image)
        }
        
        // Sonra video varsa onu yükle
        if let videoURL = pickedVideoURL {
            await uploadPickedVideo(videoURL)
        }
    }
    
    private func uploadPickedImage(_ image: UIImage) async {
        do {
            try await repo.upload(image: image, albumId: albumId)
            pickedImage = nil
            print("Image upload successful")
        } catch {
            print("Image upload error:", error)
        }
    }
    
    private func uploadPickedVideo(_ videoURL: URL) async {
        do {
            try await repo.uploadVideo(from: videoURL, albumId: albumId)
            pickedVideoURL = nil
            print("Video upload successful")
        } catch {
            print("Video upload error:", error)
        }
    }
    
    func imageURL(for item: MediaItem) async -> URL? {
        do {
            // Video için thumbnail kullan, fotoğraf için orijinal
            let pathToUse = item.isVideo ? (item.thumbPath ?? item.path) : item.path
            return try await repo.downloadURL(for: pathToUse)
        } catch {
            return nil
        }
    }
    
    // MediaViewModel.swift içindeki video URL metodunu güncelleyin

    // MediaViewModel.swift dosyasına eklenecek/güncellenecek metodlar:

    // MediaViewModel.swift içindeki videoURL metodunu bu şekilde güncelleyin:

    // MediaViewModel.swift - videoURL metodunu basitleştirin:

    // Video için orijinal URL'yi al (oynatma için)
    func videoURL(for item: MediaItem) async -> URL? {
        guard item.isVideo else {
            print("MediaVM: Item is not a video: \(item.type)")
            return nil
        }
        
        print("MediaVM: Getting video URL for path: \(item.path)")
        
        do {
            let url = try await repo.downloadURL(for: item.path)
            print("MediaVM: Successfully got video URL: \(url.absoluteString)")
            
            // Content-type kontrolü kaldırıldı - QuickTime dosyaları da desteklenmeli
            return url
            
        } catch {
            print("MediaVM: Error getting video URL: \(error)")
            return nil
        }
    }
    

    func debugVideoURL(for item: MediaItem) async {
        guard item.isVideo else { return }
        
        do {
            let url = try await repo.downloadURL(for: item.path)
            print("🎬 DEBUG Video URL: \(url.absoluteString)")
            
            let asset = AVAsset(url: url)
            let playable = try await asset.load(.isPlayable)
            let duration = try await asset.load(.duration)
            
            print("🎬 DEBUG Video playable: \(playable)")
            print("🎬 DEBUG Video duration: \(duration.seconds) seconds")
            
            if playable && duration.seconds > 0 {
                print("🎬 DEBUG Video seems valid!")
            } else {
                print("🎬 DEBUG Video has issues")
            }
            
        } catch {
            print("🎬 DEBUG Video test failed: \(error)")
        }
    }
    
    func deletePhoto(_ item: MediaItem) async throws {
        try await repo.deleteMedia(albumId: albumId, item: item)
        print("MediaVM: Media deleted successfully")
        
        // Remove from favorites if it was favorited
        if let itemId = item.id {
            removeFavorite(itemId)
        }
    }
    
    // MARK: - Filtering Methods
    
    func setFilter(_ filter: MediaFilter) {
        currentFilter = filter
        applyFilter()
    }
    
    private func applyFilter() {
        switch currentFilter {
        case .all:
            filteredItems = items
        case .photos:
            filteredItems = items.filter { $0.type == "image" }
        case .videos:
            filteredItems = items.filter { $0.type == "video" }
        case .favorites:
            filteredItems = items.filter { item in
                guard let itemId = item.id else { return false }
                return favorites.contains(itemId)
            }
        }
    }
    
    // MARK: - Favorites Management
    
    func toggleFavorite(_ itemId: String) {
        if favorites.contains(itemId) {
            removeFavorite(itemId)
        } else {
            addFavorite(itemId)
        }
    }
    
    func addFavorite(_ itemId: String) {
        favorites.insert(itemId)
        saveFavorites()
        applyFilter()
    }
    
    func removeFavorite(_ itemId: String) {
        favorites.remove(itemId)
        saveFavorites()
        applyFilter()
    }
    
    func isFavorite(_ itemId: String) -> Bool {
        return favorites.contains(itemId)
    }
    
    private func loadFavorites() {
        guard let uid = auth.uid else { return }
        let key = "favorites_\(albumId)_\(uid)"
        
        if let data = UserDefaults.standard.data(forKey: key),
           let savedFavorites = try? JSONDecoder().decode(Set<String>.self, from: data) {
            favorites = savedFavorites
        }
    }
    
    private func saveFavorites() {
        guard let uid = auth.uid else { return }
        let key = "favorites_\(albumId)_\(uid)"
        
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    // MARK: - User Cache Methods
    
    func getUser(for userId: String) -> User? {
        return userCache[userId]
    }
    
    func cacheUser(_ user: User?, for userId: String) {
        userCache[userId] = user
    }
    
    func clearUserCache() {
        userCache.removeAll()
    }
    
    private func preloadUserInfo(for items: [MediaItem]) async {
        let uniqueUploaderIds = Set(items.map { $0.uploaderId })
        
        for uploaderId in uniqueUploaderIds {
            if userCache[uploaderId] == nil {
                await loadUserInfo(for: uploaderId)
            }
        }
    }
    
    private func loadUserInfo(for userId: String) async {
        guard userCache[userId] == nil else { return }
        
        do {
            let userService = FirestoreUserService()
            let user = try await userService.getUser(uid: userId)
            await MainActor.run {
                userCache[userId] = user
            }
        } catch {
            print("Failed to load user info for \(userId): \(error)")
        }
    }
    
    // MARK: - Media Type Helpers
    
    var photosCount: Int {
        items.filter { $0.type == "image" }.count
    }
    
    var videosCount: Int {
        items.filter { $0.type == "video" }.count
    }
    
    var favoritesCount: Int {
        items.filter { item in
            guard let itemId = item.id else { return false }
            return favorites.contains(itemId)
        }.count
    }
    
    // MARK: - Search and Sort
    
    func searchItems(query: String) -> [MediaItem] {
        guard !query.isEmpty else { return filteredItems }
        
        return filteredItems.filter { item in
            if let user = userCache[item.uploaderId] {
                let userName = user.displayName ?? user.email
                return userName.localizedCaseInsensitiveContains(query)
            }
            return false
        }
    }
    
    func sortedItems(by sortType: SortType) -> [MediaItem] {
        switch sortType {
        case .newest:
            return filteredItems.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            return filteredItems.sorted { $0.createdAt < $1.createdAt }
        case .uploader:
            return filteredItems.sorted { item1, item2 in
                let user1 = userCache[item1.uploaderId]
                let user2 = userCache[item2.uploaderId]
                let name1 = user1?.displayName ?? user1?.email ?? ""
                let name2 = user2?.displayName ?? user2?.email ?? ""
                return name1.localizedCaseInsensitiveCompare(name2) == .orderedAscending
            }
        case .favorites:
            return filteredItems.sorted { item1, item2 in
                let isFavorite1 = favorites.contains(item1.id ?? "")
                let isFavorite2 = favorites.contains(item2.id ?? "")
                
                if isFavorite1 && !isFavorite2 {
                    return true
                } else if !isFavorite1 && isFavorite2 {
                    return false
                } else {
                    return item1.createdAt > item2.createdAt
                }
            }
        }
    }
    
    // MARK: - Animation helpers
    
    func isAnimating(_ itemId: String) -> Bool {
        return favoriteAnimations[itemId] ?? false
    }
    
    func addMultipleToFavorites(_ itemIds: [String]) {
        for itemId in itemIds {
            favorites.insert(itemId)
            favoriteAnimations[itemId] = true
        }
        saveFavorites()
        applyFilter()
        
        for (index, itemId) in itemIds.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1 + 0.3) {
                self.favoriteAnimations[itemId] = false
            }
        }
        
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)
    }
    
    func removeMultipleFromFavorites(_ itemIds: [String]) {
        for itemId in itemIds {
            favorites.remove(itemId)
        }
        saveFavorites()
        applyFilter()
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

extension MediaViewModel {
    
    // Güncellenmiş upload metodları
    func uploadPickedWithNotification(notificationRepo: NotificationRepository) async {
        // Önce fotoğraf varsa onu yükle
        if let image = pickedImage {
            await uploadPickedImageWithNotification(image, notificationRepo: notificationRepo)
        }
        
        // Sonra video varsa onu yükle
        if let videoURL = pickedVideoURL {
            await uploadPickedVideoWithNotification(videoURL, notificationRepo: notificationRepo)
        }
    }
    
    private func uploadPickedImageWithNotification(_ image: UIImage, notificationRepo: NotificationRepository) async {
        do {
            try await repo.uploadWithNotification(image: image, albumId: albumId, notificationRepo: notificationRepo)
            pickedImage = nil
            print("Image upload with notification successful")
        } catch {
            print("Image upload with notification error:", error)
        }
    }
    
    private func uploadPickedVideoWithNotification(_ videoURL: URL, notificationRepo: NotificationRepository) async {
        do {
            try await repo.uploadVideoWithNotification(from: videoURL, albumId: albumId, notificationRepo: notificationRepo)
            pickedVideoURL = nil
            print("Video upload with notification successful")
        } catch {
            print("Video upload with notification error:", error)
        }
    }
}
