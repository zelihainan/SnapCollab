//
//  AlbumDetailViewWrapper.swift
//  SnapCollab
//
//

import SwiftUI

struct AlbumDetailViewWrapper: View {
    let albumId: String
    let di: DIContainer
    
    @State private var album: Album?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if let album = album {
                AlbumDetailView(album: album, di: di)
            } else if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Albüm yükleniyor...")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundStyle(.orange)
                    
                    Text("Albüm Yüklenemedi")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(error)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Tekrar Dene") {
                        loadAlbum()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .onAppear {
            loadAlbum()
        }
    }
    
    private func loadAlbum() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                print("AlbumDetailWrapper: Loading album: \(albumId)")
                let loadedAlbum = try await di.albumRepo.getAlbum(by: albumId)
                
                await MainActor.run {
                    if let loadedAlbum = loadedAlbum {
                        album = loadedAlbum
                        print("AlbumDetailWrapper: Album loaded successfully: \(loadedAlbum.title)")
                    } else {
                        errorMessage = "Albüm bulunamadı"
                        print("AlbumDetailWrapper: Album not found")
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Albüm yüklenirken hata: \(error.localizedDescription)"
                    isLoading = false
                    print("AlbumDetailWrapper: Error loading album: \(error)")
                }
            }
        }
    }
}
