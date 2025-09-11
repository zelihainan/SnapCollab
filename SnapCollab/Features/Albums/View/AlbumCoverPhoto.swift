//
//  AlbumCoverPhoto.swift
//  SnapCollab
//
//  Albüm kapak fotoğrafı bileşeni
//

import SwiftUI

struct AlbumCoverPhoto: View {
    let album: Album
    let albumRepo: AlbumRepository
    let size: CGFloat
    let showEditButton: Bool
    
    @State private var coverImageURL: URL?
    @State private var isLoadingCover = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showActionSheet = false
    @State private var isUpdating = false
    @State private var errorMessage: String?
    
    private var isOwner: Bool {
        album.isOwner(albumRepo.auth.uid ?? "")
    }
    
    init(album: Album, albumRepo: AlbumRepository, size: CGFloat = 44, showEditButton: Bool = false) {
        self.album = album
        self.albumRepo = albumRepo
        self.size = size
        self.showEditButton = showEditButton
    }
    
    var body: some View {
        ZStack {
            // Main Cover Photo
            Group {
                if let coverURL = coverImageURL {
                    AsyncImage(url: coverURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        if isLoadingCover {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else {
                            defaultIcon
                        }
                    }
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.gray.opacity(0.2), lineWidth: 1))
                } else {
                    defaultIcon
                }
            }
            
            // Edit Button Overlay
            if showEditButton && isOwner {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showActionSheet = true
                        }) {
                            Image(systemName: "camera.circle.fill")
                                .font(.system(size: size * 0.25))
                                .foregroundStyle(.white)
                                .background(
                                    Circle()
                                        .fill(.blue)
                                        .frame(width: size * 0.35, height: size * 0.35)
                                )
                        }
                        .offset(x: -size * 0.05, y: -size * 0.05)
                    }
                }
            }
            
            // Loading Overlay
            if isUpdating {
                Circle()
                    .fill(.black.opacity(0.4))
                    .frame(width: size, height: size)
                    .overlay {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.6)
                    }
            }
        }
        .onAppear {
            loadCoverImage()
        }
        .onChange(of: album.coverImagePath) { _ in
            loadCoverImage()
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                Task { await updateCoverImage(image) }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
        .confirmationDialog("Kapak Fotoğrafı", isPresented: $showActionSheet) {
            Button("Fotoğraf Seç") {
                showImagePicker = true
            }
            
            if album.hasCoverImage {
                Button("Kapak Fotoğrafını Kaldır", role: .destructive) {
                    Task { await removeCoverImage() }
                }
            }
            
            Button("İptal", role: .cancel) { }
        }
    }
    
    private var defaultIcon: some View {
        Circle()
            .fill(.blue.gradient)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "photo.on.rectangle.angled")
                    .foregroundStyle(.white)
                    .font(.system(size: size * 0.4))
            }
    }
    
    // MARK: - Methods
    
    private func loadCoverImage() {
        guard let albumId = album.id else { return }
        
        isLoadingCover = true
        
        Task {
            do {
                let url = try await albumRepo.getCoverImageURL(albumId)
                await MainActor.run {
                    coverImageURL = url
                    isLoadingCover = false
                }
            } catch {
                await MainActor.run {
                    coverImageURL = nil
                    isLoadingCover = false
                }
                print("Failed to load cover image: \(error)")
            }
        }
    }
    
    private func updateCoverImage(_ image: UIImage) async {
        guard let albumId = album.id else { return }
        
        isUpdating = true
        errorMessage = nil
        
        do {
            try await albumRepo.updateCoverImage(albumId, coverImage: image)
            await MainActor.run {
                // Yeni URL'yi yükle
                loadCoverImage()
                selectedImage = nil
            }
        } catch {
            await MainActor.run {
                errorMessage = "Kapak fotoğrafı güncellenirken hata: \(error.localizedDescription)"
                selectedImage = nil
            }
        }
        
        isUpdating = false
    }
    
    private func removeCoverImage() async {
        guard let albumId = album.id else { return }
        
        isUpdating = true
        errorMessage = nil
        
        do {
            try await albumRepo.removeCoverImage(albumId)
            await MainActor.run {
                coverImageURL = nil
            }
        } catch {
            await MainActor.run {
                errorMessage = "Kapak fotoğrafı silinirken hata: \(error.localizedDescription)"
            }
        }
        
        isUpdating = false
    }
}

// MARK: - Preview
#Preview {
    let mockAlbum = Album(title: "Test Album", ownerId: "test-uid")
    let mockAuthRepo = AuthRepository(
        service: FirebaseAuthService(),
        userService: FirestoreUserService()
    )
    let mockAlbumRepo = AlbumRepository(
        service: FirestoreAlbumService(),
        auth: mockAuthRepo,
        userService: FirestoreUserService()
    )
    
    VStack(spacing: 20) {
        AlbumCoverPhoto(album: mockAlbum, albumRepo: mockAlbumRepo, size: 60)
        AlbumCoverPhoto(album: mockAlbum, albumRepo: mockAlbumRepo, size: 100, showEditButton: true)
    }
    .padding()
}
