//
//  MediaViewModel.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import SwiftUI

@MainActor
final class MediaViewModel: ObservableObject {
    @Published var items: [MediaItem] = []
    @Published var isPicking = false
    @Published var pickedImage: UIImage?

    private let repo: MediaRepository
    private let albumId: String
    let auth: AuthRepository
    init(repo: MediaRepository, albumId: String) {
        self.repo = repo
        self.albumId = albumId
        self.auth = repo.auth
    }

    func start() {
        Task {
            for await list in repo.observe(albumId: albumId) {
                self.items = list
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
    }
}
// MARK: - Date Grouping Extension
extension MediaViewModel {
    var groupedByDate: [(key: String, value: [MediaItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: items) { item in
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
    
    // Fotoğraf istatistikleri
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

