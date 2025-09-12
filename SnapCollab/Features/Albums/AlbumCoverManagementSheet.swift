//
//  AlbumCoverManagementSheet.swift
//  SnapCollab
//
//

import SwiftUI

struct AlbumCoverManagementSheet: View {
    let album: Album
    let albumRepo: AlbumRepository
    @Environment(\.dismiss) var dismiss
    
    @State private var showImagePicker = false
    @State private var showCameraPicker = false
    @State private var selectedImage: UIImage?
    @State private var isUpdating = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var coverImageURL: URL?
    @State private var isLoadingCover = false
    
    private var isOwner: Bool {
        album.isOwner(albumRepo.auth.uid ?? "")
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        ZStack {
                            if let coverURL = coverImageURL {
                                AsyncImage(url: coverURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    if isLoadingCover {
                                        ProgressView()
                                            .scaleEffect(1.2)
                                    } else {
                                        defaultCoverView
                                    }
                                }
                                .frame(width: 150, height: 150)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.gray.opacity(0.2), lineWidth: 2))
                            } else {
                                defaultCoverView
                            }
                            
                            if isUpdating {
                                Circle()
                                    .fill(.black.opacity(0.6))
                                    .frame(width: 150, height: 150)
                                    .overlay {
                                        VStack(spacing: 8) {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(1.2)
                                            Text("Güncelleniyor...")
                                                .foregroundStyle(.white)
                                                .font(.caption)
                                        }
                                    }
                            }
                        }
                    }
                    
                    VStack(spacing: 16) {
                        Text("Kapak Fotoğrafını Değiştir")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            CoverActionButton(
                                icon: "photo",
                                title: "Galeriden Seç",
                                subtitle: "Galeriden fotoğraf seçin",
                                color: .blue
                            ) {
                                showImagePicker = true
                            }
                            
                            CoverActionButton(
                                icon: "camera",
                                title: "Fotoğraf Çek",
                                subtitle: "Kamera ile fotoğraf çekin",
                                color: .green
                            ) {
                                showCameraPicker = true
                            }
                            
                            if album.hasCoverImage {
                                CoverActionButton(
                                    icon: "trash",
                                    title: "Kapak Fotoğrafını Kaldır",
                                    subtitle: "Varsayılan ikona dön",
                                    color: .red
                                ) {
                                    Task { await removeCoverImage() }
                                }
                            }
                        }
                    }
                    .disabled(isUpdating)
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    if showSuccess {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Kapak fotoğrafı güncellendi!")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
            .navigationTitle("Kapak Fotoğrafı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showCameraPicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                Task { await updateCoverImage(image) }
            }
        }
        .onAppear {
            loadCoverImage()
        }
        .onChange(of: showSuccess) { success in
            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSuccess = false
                }
            }
        }
    }
    
    private var defaultCoverView: some View {
        Circle()
            .fill(.blue.gradient)
            .frame(width: 150, height: 150)
            .overlay {
                Image(systemName: "photo.on.rectangle.angled")
                    .foregroundStyle(.white)
                    .font(.system(size: 60))
            }
    }
        
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
                loadCoverImage()
                selectedImage = nil
                showSuccess = true
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
                showSuccess = true
            }
        } catch {
            await MainActor.run {
                errorMessage = "Kapak fotoğrafı silinirken hata: \(error.localizedDescription)"
            }
        }
        
        isUpdating = false
    }
}

struct CoverActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

