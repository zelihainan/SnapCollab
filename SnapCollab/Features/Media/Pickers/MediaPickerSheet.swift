//
//  MediaPickerSheet.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 11.09.2025.
//

import SwiftUI
import PhotosUI

struct MediaPickerSheet: View {
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?
    @Binding var selectedVideoURL: URL?
    
    @State private var showImagePicker = false
    @State private var showVideoPicker = false
    @State private var pickerItem: PhotosPickerItem?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    
                    Text("İçerik Ekle")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Albüme fotoğraf veya video ekleyin")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Options
                VStack(spacing: 16) {
                    // Photo from Library
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        MediaOptionButton(
                            icon: "photo",
                            title: "Fotoğraf Seç",
                            subtitle: "Galeriden fotoğraf seçin",
                            color: .blue
                        )
                    }
                    
                    // Photo from Camera
                    Button(action: {
                        showImagePicker = true
                    }) {
                        MediaOptionButton(
                            icon: "camera",
                            title: "Fotoğraf Çek",
                            subtitle: "Kamera ile fotoğraf çekin",
                            color: .green
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Video from Library
                    Button(action: {
                        showVideoPicker = true
                    }) {
                        MediaOptionButton(
                            icon: "video",
                            title: "Video Seç",
                            subtitle: "Galeriden video seçin",
                            color: .purple
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle("İçerik Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("İptal") {
                        isPresented = false
                    }
                }
            }
        }
        .onChange(of: pickerItem) { newValue in
            handlePhotosPickerItem(newValue)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
                .onDisappear {
                    if selectedImage != nil {
                        isPresented = false
                    }
                }
        }
        .sheet(isPresented: $showVideoPicker) {
            VideoPicker(selectedVideoURL: $selectedVideoURL)
                .onDisappear {
                    if selectedVideoURL != nil {
                        isPresented = false
                    }
                }
        }
    }
    
    private func handlePhotosPickerItem(_ pickerItem: PhotosPickerItem?) {
        guard let pickerItem = pickerItem else { return }
        
        Task {
            if let data = try? await pickerItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = image
                    isPresented = false
                }
            }
        }
    }
}

// MARK: - Media Option Button
struct MediaOptionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
            }
            
            // Content
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
            
            // Arrow
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
}
