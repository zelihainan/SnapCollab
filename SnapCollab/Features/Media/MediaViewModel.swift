//
//  MediaViewModel.swift - Direkt İndirme ve Düzeltilmiş Silme İzinleri
//  SnapCollab
//

import SwiftUI
import Foundation
import AVKit
import PhotosUI
import Photos

@MainActor
final class MediaViewModel: ObservableObject {
    @Published var items: [MediaItem] = []
    @Published var filteredItems: [MediaItem] = []
    @Published var isPicking = false
    @Published var pickedImage: UIImage?
    @Published var pickedVideoURL: URL?
    @Published var currentFilter: MediaFilter = .all
    @Published var favorites: Set<String> = []
    @Published var favoriteAnimations: [String: Bool] = [:]
    
    // Toplu işlemler için yeni özellikler
    @Published var isSelectionMode = false
    @Published var selectedItems: Set<String> = []
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var uploadStatus = ""
    @Published var uploadedCount = 0
    @Published var totalUploadCount = 0
    
    // Çoklu seçim için
    @Published var selectedPhotos: [PhotosPickerItem] = []
    @Published var isProcessingBulkUpload = false
    @Published var bulkUploadProgress: Double = 0.0
    
    // Direkt indirme için
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var downloadStatus = ""
    
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
    private let notificationRepo: NotificationRepository?
    
    private var userCache: [String: User] = [:]
    
    init(repo: MediaRepository, albumId: String, notificationRepo: NotificationRepository? = nil) {
        self.repo = repo
        self.albumId = albumId
        self.auth = repo.auth
        self.notificationRepo = notificationRepo
        
        loadFavorites()
    }
    
    // MARK: - Toplu İşlem Fonksiyonları
    
    func toggleSelectionMode() {
        isSelectionMode.toggle()
        if !isSelectionMode {
            selectedItems.removeAll()
        }
    }
    
    func toggleItemSelection(_ itemId: String) {
        if selectedItems.contains(itemId) {
            selectedItems.remove(itemId)
        } else {
            selectedItems.insert(itemId)
        }
    }
    
    func selectAllVisibleItems() {
        selectedItems = Set(filteredItems.compactMap { $0.id })
    }
    
    func clearSelection() {
        selectedItems.removeAll()
    }
    
    var selectedItemsCount: Int {
        selectedItems.count
    }
    
    // Silme iznini düzelt - sadece kendi yüklediği dosyaları silebilsin
    var canDeleteSelected: Bool {
        guard let currentUserId = auth.uid, selectedItemsCount > 0 else { return false }
        let selectedMediaItems = filteredItems.filter { selectedItems.contains($0.id ?? "") }
        // Tüm seçili öğelerin uploaderId'sini kontrol et
        return !selectedMediaItems.isEmpty && selectedMediaItems.allSatisfy { $0.uploaderId == currentUserId }
    }
    
    // MARK: - Direkt İndirme İşlemi
    
    func downloadSelectedItems() async {
        let itemsToDownload = filteredItems.filter { selectedItems.contains($0.id ?? "") }
        guard !itemsToDownload.isEmpty else { return }
        
        // İzin kontrolü
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .denied || status == .restricted {
            print("Photo library access denied")
            return
        } else if status == .notDetermined {
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            if newStatus != .authorized && newStatus != .limited {
                print("Photo library access denied after request")
                return
            }
        }
        
        isDownloading = true
        downloadProgress = 0.0
        downloadStatus = "İndirme başlıyor..."
        
        var downloadedCount = 0
        let totalCount = itemsToDownload.count
        
        for (index, item) in itemsToDownload.enumerated() {
            do {
                await updateDownloadProgress(Double(index) / Double(totalCount), status: "İndiriliyor: \(index + 1)/\(totalCount)")
                
                if item.type == "image" {
                    try await downloadImage(item)
                } else if item.type == "video" {
                    try await downloadVideo(item)
                }
                
                downloadedCount = index + 1
                
                // Her 3 dosyada bir kısa bekleme
                if (index + 1) % 3 == 0 {
                    try await Task.sleep(nanoseconds: 300_000_000)
                }
                
            } catch {
                print("Download error for item \(item.id ?? ""): \(error)")
            }
        }
        
        downloadProgress = 1.0
        downloadStatus = "\(downloadedCount) öğe başarıyla indirildi!"
        
        // 2 saniye sonra temizle
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isDownloading = false
            self.clearSelection()
            self.isSelectionMode = false
        }
    }
    
    private func updateDownloadProgress(_ progress: Double, status: String) async {
        await MainActor.run {
            downloadProgress = progress
            downloadStatus = status
        }
    }
    
    private func downloadImage(_ item: MediaItem) async throws {
        let imageURL = try await repo.downloadURL(for: item.path)
        let (data, _) = try await URLSession.shared.data(from: imageURL)
        
        guard let image = UIImage(data: data) else {
            throw MediaError.uploadError
        }
        
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
    
    private func downloadVideo(_ item: MediaItem) async throws {
        let videoURL = try await repo.downloadURL(for: item.path)
        let (data, _) = try await URLSession.shared.data(from: videoURL)
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        try data.write(to: tempURL)
        
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL)
        }
        
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    // MARK: - Paylaşım İşlevi
    
    func shareSelectedItems() {
        let itemsToShare = filteredItems.filter { selectedItems.contains($0.id ?? "") }
        
        // Bu işlevi implement etmek için download URL'lerini alıp UIActivityViewController'da paylaşabilirsiniz
        print("Sharing \(itemsToShare.count) items")
        
        Task {
            var urlsToShare: [URL] = []
            
            for item in itemsToShare.prefix(10) { // Maksimum 10 öğe
                do {
                    let url = try await repo.downloadURL(for: item.path)
                    urlsToShare.append(url)
                } catch {
                    print("Error getting URL for sharing: \(error)")
                }
            }
            
            await MainActor.run {
                if !urlsToShare.isEmpty {
                    showShareSheet(with: urlsToShare)
                }
            }
        }
    }
    
    private func showShareSheet(with urls: [URL]) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else { return }
        
        var topViewController = rootViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        
        let activityVC = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topViewController.view
            popover.sourceRect = CGRect(x: topViewController.view.bounds.midX,
                                      y: topViewController.view.bounds.midY,
                                      width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        topViewController.present(activityVC, animated: true)
    }
    
    // MARK: - Çoklu Fotoğraf Yükleme
    
    func processBulkPhotoUpload() async {
        guard !selectedPhotos.isEmpty else { return }
        
        isProcessingBulkUpload = true
        bulkUploadProgress = 0.0
        uploadedCount = 0
        totalUploadCount = selectedPhotos.count
        uploadStatus = "Fotoğraflar hazırlanıyor..."
        
        var processedImages: [UIImage] = []
        
        for (index, photoItem) in selectedPhotos.enumerated() {
            do {
                if let imageData = try await photoItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: imageData) {
                    processedImages.append(image)
                }
                
                await MainActor.run {
                    bulkUploadProgress = Double(index + 1) / Double(selectedPhotos.count * 2)
                    uploadStatus = "Hazırlanıyor: \(index + 1)/\(selectedPhotos.count)"
                }
            } catch {
                print("Error loading photo: \(error)")
            }
        }
        
        for (index, image) in processedImages.enumerated() {
            do {
                if let notificationRepo = notificationRepo {
                    try await repo.uploadWithNotification(image: image, albumId: albumId, notificationRepo: notificationRepo)
                } else {
                    try await repo.upload(image: image, albumId: albumId)
                }
                
                await MainActor.run {
                    uploadedCount = index + 1
                    bulkUploadProgress = 0.5 + (Double(index + 1) / Double(processedImages.count)) * 0.5
                    uploadStatus = "Yükleniyor: \(index + 1)/\(processedImages.count)"
                }
                
                if (index + 1) % 5 == 0 {
                    try await Task.sleep(nanoseconds: 500_000_000)
                }
                
            } catch {
                print("Error uploading photo \(index): \(error)")
            }
        }
        
        await MainActor.run {
            isProcessingBulkUpload = false
            selectedPhotos.removeAll()
            uploadStatus = "\(uploadedCount) fotoğraf başarıyla yüklendi!"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.uploadStatus = ""
            }
        }
    }
    
    // MARK: - Toplu Silme
    
    func deleteSelectedItems() async throws {
        let itemsToDelete = filteredItems.filter { selectedItems.contains($0.id ?? "") }
        
        for item in itemsToDelete {
            do {
                try await repo.deleteMedia(albumId: albumId, item: item)
                
                if let itemId = item.id {
                    removeFavorite(itemId)
                }
            } catch {
                print("Error deleting item \(item.id ?? ""): \(error)")
            }
        }
        
        clearSelection()
        isSelectionMode = false
    }
    
    // MARK: - Mevcut Fonksiyonlar (Değiştirilmeden)
    
    func start() {
        Task {
            for await list in repo.observe(albumId: albumId) {
                self.items = list
                self.applyFilter()
                await preloadUserInfo(for: list)
            }
        }
    }
        
    func uploadPicked() async {
        if let notificationRepo = notificationRepo {
            print("Using notification system for upload")
            await uploadPickedWithNotification(notificationRepo: notificationRepo)
        } else {
            print("Fallback: Using upload without notifications")
            await uploadPickedWithoutNotification()
        }
    }
    
    private func uploadPickedWithNotification(notificationRepo: NotificationRepository) async {
        if let image = pickedImage {
            await uploadPickedImageWithNotification(image, notificationRepo: notificationRepo)
        }
        if let videoURL = pickedVideoURL {
            await uploadPickedVideoWithNotification(videoURL, notificationRepo: notificationRepo)
        }
    }
    
    private func uploadPickedWithoutNotification() async {
        if let image = pickedImage {
            await uploadPickedImage(image)
        }
        if let videoURL = pickedVideoURL {
            await uploadPickedVideo(videoURL)
        }
    }
    
    private func uploadPickedImageWithNotification(_ image: UIImage, notificationRepo: NotificationRepository) async {
        do {
            try await repo.uploadWithNotification(image: image, albumId: albumId, notificationRepo: notificationRepo)
            pickedImage = nil
            print("Image upload with notification successful")
        } catch {
            print("Image upload with notification error:", error)
            await uploadPickedImage(image)
        }
    }
    
    private func uploadPickedVideoWithNotification(_ videoURL: URL, notificationRepo: NotificationRepository) async {
        do {
            try await repo.uploadVideoWithNotification(from: videoURL, albumId: albumId, notificationRepo: notificationRepo)
            pickedVideoURL = nil
            print("Video upload with notification successful")
        } catch {
            print("Video upload with notification error:", error)
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
            let pathToUse = item.isVideo ? (item.thumbPath ?? item.path) : item.path
            return try await repo.downloadURL(for: pathToUse)
        } catch {
            print("Error getting image URL: \(error)")
            return nil
        }
    }
    
    func videoURL(for item: MediaItem) async -> URL? {
        guard item.isVideo else {
            print("Item is not a video: \(item.type)")
            return nil
        }
        
        do {
            let url = try await repo.downloadURL(for: item.path)
            print("Successfully got video URL")
            return url
        } catch {
            print("Error getting video URL: \(error)")
            return nil
        }
    }
        
    func deletePhoto(_ item: MediaItem) async throws {
        try await repo.deleteMedia(albumId: albumId, item: item)
        print("Media deleted successfully")
        
        if let itemId = item.id {
            removeFavorite(itemId)
        }
    }
        
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
