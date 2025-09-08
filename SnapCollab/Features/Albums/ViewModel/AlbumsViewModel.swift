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
        Task {
            for await list in repo.observeMyAlbums() {
                self.albums = list
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
