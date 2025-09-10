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
