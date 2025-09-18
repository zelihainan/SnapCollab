//
//  MediaPickerSheet.swift
//  SnapCollab
//

import SwiftUI
import PhotosUI

struct MediaPickerSheet: View {
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?
    @Binding var selectedVideoURL: URL?
    @Binding var selectedPhotos: [PhotosPickerItem]

    let currentFilter: MediaViewModel.MediaFilter
    
    @State private var showImagePicker = false
    @State private var showVideoPicker = false
    @State private var showCameraPicker = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var cameraSourceType: UIImagePickerController.SourceType = .camera
    @State private var isBulkMode = false

    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: iconForFilter)
                        .font(.system(size: 60))
                        .foregroundStyle(colorForFilter)
                    
                    Text(titleForFilter)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(subtitleForFilter)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                if currentFilter == .all || currentFilter == .photos {
                    VStack(spacing: 16) {
                        Text("Yükleme Modu")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 12) {
                            ModeSelectionButton(
                                title: "Tekli",
                                subtitle: "Bir fotoğraf",
                                icon: "photo",
                                isSelected: !isBulkMode,
                                action: { isBulkMode = false }
                            )
                            
                            ModeSelectionButton(
                                title: "Çoklu",
                                subtitle: "Birden fazla",
                                icon: "photo.stack",
                                isSelected: isBulkMode,
                                action: { isBulkMode = true }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                VStack(spacing: 16) {
                    switch currentFilter {
                    case .all:
                        allFilterOptions
                    case .photos:
                        photoFilterOptions
                    case .videos:
                        videoFilterOptions
                    case .favorites:
                        EmptyView()
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle(titleForFilter)
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
            ImagePicker(selectedImage: $selectedImage, sourceType: cameraSourceType)
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
        .sheet(isPresented: $showCameraPicker) {
            CameraPicker(
                selectedImage: $selectedImage,
                selectedVideoURL: $selectedVideoURL,
                sourceType: cameraSourceType
            )
            .onDisappear {
                if selectedImage != nil || selectedVideoURL != nil {
                    isPresented = false
                }
            }
        }
    }
        
    @ViewBuilder
    private var allFilterOptions: some View {
        if isBulkMode {
            PhotosPicker(
                selection: $selectedPhotos,
                maxSelectionCount: 30,
                matching: .images
            ) {
                MediaOptionButton(
                    icon: "photo.stack.fill",
                    title: "Çoklu Fotoğraf Seç",
                    subtitle: "En fazla 30 fotoğraf seçin",
                    color: .blue
                )
            }
        } else {
            PhotosPicker(
                selection: $pickerItem,
                matching: .any(of: [.images, .videos])
            ) {
                MediaOptionButton(
                    icon: "photo.on.rectangle.angled",
                    title: "Galeriden Seç",
                    subtitle: "Fotoğraf veya video seçin",
                    color: .blue
                )
            }
        }
        
        Button(action: {
            showCameraPicker = true
        }) {
            MediaOptionButton(
                icon: "camera",
                title: "Çek",
                subtitle: "Fotoğraf çek veya video kaydet",
                color: .green
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
        private var photoFilterOptions: some View {
            if isBulkMode {
                // Çoklu fotoğraf seçimi
                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: 30,
                    matching: .images
                ) {
                    MediaOptionButton(
                        icon: "photo.stack.fill",
                        title: "Çoklu Fotoğraf Seç",
                        subtitle: "En fazla 30 fotoğraf seçin",
                        color: .blue
                    )
                }
            } else {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    MediaOptionButton(
                        icon: "photo",
                        title: "Galeriden Fotoğraf Seç",
                        subtitle: "Galeriden fotoğraf seçin",
                        color: .blue
                    )
                }
            }
                
            Button(action: {
                cameraSourceType = .camera
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
        }
        
        @ViewBuilder
        private var videoFilterOptions: some View {
            Button(action: {
                showVideoPicker = true
            }) {
                MediaOptionButton(
                    icon: "video",
                    title: "Galeriden Video Seç",
                    subtitle: "Galeriden video seçin",
                    color: .purple
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                cameraSourceType = .camera
                showCameraPicker = true
            }) {
                MediaOptionButton(
                    icon: "video.badge.plus",
                    title: "Video Çek",
                    subtitle: "Kamera ile video kaydedin",
                    color: .red
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        
    private var iconForFilter: String {
        switch currentFilter {
        case .all: return "plus.circle.fill"
        case .photos: return "photo.circle.fill"
        case .videos: return "video.circle.fill"
        case .favorites: return "heart.circle.fill"
        }
    }
    
    private var colorForFilter: Color {
        switch currentFilter {
        case .all: return .blue
        case .photos: return .blue
        case .videos: return .purple
        case .favorites: return .red
        }
    }
    
    private var titleForFilter: String {
        switch currentFilter {
        case .all: return "İçerik Ekle"
        case .photos: return "Fotoğraf Ekle"
        case .videos: return "Video Ekle"
        case .favorites: return "Favori Ekle"
        }
    }
    
    private var subtitleForFilter: String {
        switch currentFilter {
        case .all: return "Albüme fotoğraf veya video ekleyin"
        case .photos: return "Albüme fotoğraf ekleyin"
        case .videos: return "Albüme video ekleyin"
        case .favorites: return "Favorilere öğe ekleyin"
        }
    }
    
    private func handlePhotosPickerItem(_ pickerItem: PhotosPickerItem?) {
        guard let pickerItem = pickerItem else { return }
        
        Task {
            if let videoTransfer = try? await pickerItem.loadTransferable(type: VideoTransferable.self) {
                await MainActor.run {
                    selectedVideoURL = videoTransfer.url
                    isPresented = false
                }
            } else if let data = try? await pickerItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = image
                    isPresented = false
                }
            }
        }
    }
}

struct ModeSelectionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .medium)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? .blue.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .blue : .clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct VideoCameraPicker: UIViewControllerRepresentable {
    @Binding var selectedVideoURL: URL?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.mediaTypes = ["public.movie"]
        picker.allowsEditing = false
        picker.videoQuality = .typeHigh
        picker.videoMaximumDuration = 300
        picker.cameraCaptureMode = .video
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoCameraPicker
        
        init(_ parent: VideoCameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            
            // Sadece video kontrolü
            if let videoURL = info[.mediaURL] as? URL {
                parent.selectedVideoURL = videoURL
                print("Video captured: \(videoURL.absoluteString)")
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var selectedVideoURL: URL?
    @Environment(\.dismiss) var dismiss
    
    var sourceType: UIImagePickerController.SourceType = .camera
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.mediaTypes = ["public.image", "public.movie"]
        picker.allowsEditing = false
        picker.videoMaximumDuration = 300
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        
        init(_ parent: CameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            
            if let videoURL = info[.mediaURL] as? URL {
                parent.selectedVideoURL = videoURL
            }
            else if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct VideoTransferable: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            
            try FileManager.default.copyItem(at: received.file, to: tempURL)
            return VideoTransferable(url: tempURL)
        }
    }
}

struct MediaOptionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
            }
            
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
}
