//
//  AlbumsViewModel.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import Foundation

@MainActor
final class AlbumsViewModel: ObservableObject {
    @Published var albums: [Album] = []
    @Published var newTitle = ""
    @Published var showCreate = false

    private let repo: AlbumRepository
    init(repo: AlbumRepository) { self.repo = repo }

    func start() {
        print("🔍 AlbumsVM: start() called")
        print("🔍 AlbumsVM: Current auth state: \(repo.auth.isSignedIn)")
        print("🔍 AlbumsVM: Current UID: \(repo.auth.uid ?? "nil")")
        
        Task {
            print("🔍 AlbumsVM: Starting AsyncStream")
            for await albums in repo.observeMyAlbums() {
                print("🔍 AlbumsVM: Received \(albums.count) albums from repo")
                await MainActor.run {
                    self.albums = albums
                    print("🔍 AlbumsVM: Updated UI with \(albums.count) albums")
                }
            }
        }
    }

    func create() async {
        let t = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        try? await repo.create(title: t)
        newTitle = ""
        showCreate = false
    }
    
}
