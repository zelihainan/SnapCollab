//
//  MediaViewModel.swift
//  SnapCollab
//
//  Enhanced with filtering capabilities
//

import SwiftUI

@MainActor
final class MediaViewModel: ObservableObject {
    @Published var items: [MediaItem] = []
    @Published var filteredItems: [MediaItem] = []
    @Published var isPicking = false
    @Published var pickedImage: UIImage?
    @Published var currentFilter: MediaFilter = .all
    @Published var favorites: Set<String> = [] // Favori fotoğraf ID'leri

    enum MediaFilter {
        case all
        case photos
        case videos
        case favorites
    }

    private let repo: MediaRepository
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
                // Yeni gelen fotoğrafların kullanıcı bilgilerini preload et
                await preloadUserInfo(for: list)
            }
        }
    }

    func uploadPicked() async {
        guard let img = pickedImage else { return }
        do {
            try await repo.upload(image: img, albumId: albumId)
            pickedImage = nil
        } catch {
            print("upload error:", error)
        }
    }

    func imageURL(for item: MediaItem) async -> URL? {
        do {
            return try await repo.downloadURL(for: item.thumbPath ?? item.path)
        } catch {
            return nil
        }
    }
    
    func deletePhoto(_ item: MediaItem) async throws {
        try await repo.deleteMedia(albumId: albumId, item: item)
        print("MediaVM: Photo deleted successfully")
        
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
        applyFilter() // Refresh filtered items
    }
    
    func removeFavorite(_ itemId: String) {
        favorites.remove(itemId)
        saveFavorites()
        applyFilter() // Refresh filtered items
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
    
    /// Cache'den kullanıcı bilgisini al
    func getUser(for userId: String) -> User? {
        return userCache[userId]
    }
    
    /// Kullanıcıyı cache'le
    func cacheUser(_ user: User?, for userId: String) {
        userCache[userId] = user
    }
    
    /// Cache'i temizle (memory yönetimi için)
    func clearUserCache() {
        userCache.removeAll()
    }
    
    /// Yeni gelen medya itemların kullanıcı bilgilerini preload et
    private func preloadUserInfo(for items: [MediaItem]) async {
        let uniqueUploaderIds = Set(items.map { $0.uploaderId })
        
        for uploaderId in uniqueUploaderIds {
            // Cache'de yoksa yükle
            if userCache[uploaderId] == nil {
                await loadUserInfo(for: uploaderId)
            }
        }
    }
    
    /// Specific bir kullanıcı ID için bilgiyi yükle ve cache'le
    private func loadUserInfo(for userId: String) async {
        guard userCache[userId] == nil else { return } // Zaten cache'de varsa yükleme
        
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
            // Search by uploader name or date
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
        }
    }
    
    enum SortType {
        case newest
        case oldest
        case uploader
    }
}

// MARK: - Date Grouping Extension
extension MediaViewModel {
    var groupedByDate: [(key: String, value: [MediaItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredItems) { item in
            calendar.dateInterval(of: .day, for: item.createdAt)?.start ?? item.createdAt
        }
        
        return grouped
            .sorted { $0.key > $1.key } // En yeni tarih önce
            .map { (key: formatDate($0.key), value: $0.value.sorted { $0.createdAt > $1.createdAt }) }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Bugün"
        } else if calendar.isDateInYesterday(date) {
            return "Dün"
        } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(date) == true {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            formatter.locale = Locale(identifier: "tr_TR")
            return formatter.string(from: date)
        } else if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMMM EEEE"
            formatter.locale = Locale(identifier: "tr_TR")
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMMM yyyy"
            formatter.locale = Locale(identifier: "tr_TR")
            return formatter.string(from: date)
        }
    }
    
    // Fotoğraf istatistikleri - filteredItems yerine items kullanarak gerçek sayıları göster
    var photoStats: (total: Int, today: Int, thisWeek: Int, thisMonth: Int) {
        let calendar = Calendar.current
        let now = Date()
        
        let today = items.filter { calendar.isDateInToday($0.createdAt) }.count
        
        let thisWeek = items.filter { item in
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else { return false }
            return weekInterval.contains(item.createdAt)
        }.count
        
        let thisMonth = items.filter { item in
            guard let monthInterval = calendar.dateInterval(of: .month, for: now) else { return false }
            return monthInterval.contains(item.createdAt)
        }.count
        
        return (total: items.count, today: today, thisWeek: thisWeek, thisMonth: thisMonth)
    }
}
