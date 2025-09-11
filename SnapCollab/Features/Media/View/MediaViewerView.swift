//
//  MediaViewerView.swift
//  SnapCollab
//
//  Inline video player ile - iPhone Photos tarzı
//

import SwiftUI
import Photos
import AVKit
import AVFoundation

struct MediaViewerView: View {
    @ObservedObject var vm: MediaViewModel
    let initialItem: MediaItem
    let onClose: () -> Void

    @State private var currentIndex: Int = 0
    @State private var loadedImages: [String: UIImage] = [:]
    @State private var showUI = true
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @State private var toastMessage: String?
    @State private var showToast = false
    
    // INLINE VIDEO PLAYER STATE
    @State private var inlineVideoPlayers: [String: AVPlayer] = [:]
    @State private var currentPlayingVideoId: String?

    private var currentItem: MediaItem {
        guard currentIndex < vm.filteredItems.count else { return initialItem }
        return vm.filteredItems[currentIndex]
    }
    
    private var isFavorite: Bool {
        guard let itemId = currentItem.id else { return false }
        return vm.isFavorite(itemId)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Main Content
            mediaContentView
            
            // UI Overlay
            if showUI {
                topUIBar
                if vm.filteredItems.count > 1 {
                    bottomUIBar
                }
            }
            
            // Toast
            if showToast, let message = toastMessage {
                toastView(message)
            }
        }
        .alert("Medyayı Sil", isPresented: $showDeleteAlert) {
            deleteAlertButtons
        } message: {
            Text("Bu \(currentItem.isVideo ? "videoyu" : "fotoğrafı") kalıcı olarak silmek istediğinizden emin misiniz?")
        }
        .onAppear {
            setupInitialState()
        }
        .onDisappear {
            stopAllInlineVideos()
        }
        .onChange(of: currentIndex) { _ in
            loadCurrentMedia()
            stopAllInlineVideos() // Index değişince videoları durdur
        }
    }
    
    // MARK: - UI Components
    
    private var mediaContentView: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(vm.filteredItems.enumerated()), id: \.element.id) { index, item in
                if item.isVideo {
                    videoItemView(item: item, index: index)
                } else {
                    imageItemView(item: item, index: index)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
    
    private func videoItemView(item: MediaItem, index: Int) -> some View {
        ZStack {
            // Video player veya thumbnail
            if let player = getPlayerForItem(item) {
                // Inline video player - iPhone Photos tarzı
                VideoPlayer(player: player)
                    .aspectRatio(contentMode: .fit)
                    .onAppear {
                        print("🎬 Inline VideoPlayer appeared for item: \(item.id ?? "")")
                    }
                    .onDisappear {
                        player.pause()
                        print("🎬 Inline VideoPlayer disappeared")
                    }
            } else {
                // Thumbnail göster + play button
                AsyncImageView(pathProvider: { await vm.imageURL(for: item) })
                    .aspectRatio(contentMode: .fit)
                    .overlay {
                        Button(action: { startInlineVideo(item) }) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(.white)
                                .background(
                                    Circle()
                                        .fill(.black.opacity(0.3))
                                        .frame(width: 100, height: 100)
                                )
                        }
                    }
            }
        }
        .tag(index)
        .onTapGesture { toggleUI() }
    }
    
    private func imageItemView(item: MediaItem, index: Int) -> some View {
        let itemId = item.id ?? ""
        
        return Group {
            if let image = loadedImages[itemId] {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .onAppear {
                        Task { await loadImage(for: item) }
                    }
            }
        }
        .tag(index)
        .onTapGesture { toggleUI() }
    }
    
    private var topUIBar: some View {
        VStack {
            HStack {
                closeButton
                Spacer()
                mediaCounterView
                Spacer()
                actionButtonsView
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            Spacer()
        }
    }
    
    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.title2)
                .foregroundColor(.white)
                .padding(10)
                .background(Circle().fill(.black.opacity(0.6)))
        }
    }
    
    private var mediaCounterView: some View {
        HStack(spacing: 4) {
            Image(systemName: currentItem.isVideo ? "video" : "photo")
                .font(.caption)
            Text("\(currentIndex + 1) of \(vm.filteredItems.count)")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 8) {
            favoriteButton
            moreMenuButton
        }
    }
    
    private var favoriteButton: some View {
        Button(action: toggleFavorite) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.title3)
                .foregroundColor(isFavorite ? .red : .white)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
        }
    }
    
    private var moreMenuButton: some View {
        Menu {
            Button("Paylaş", action: shareMedia)
            if !currentItem.isVideo {
                Button("Galeriye Kaydet", action: saveToPhotos)
            }
            if canDeleteMedia {
                Divider()
                Button("Sil", role: .destructive) { showDeleteAlert = true }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
        }
    }
    
    private var bottomUIBar: some View {
        VStack {
            Spacer()
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(Array(vm.filteredItems.enumerated()), id: \.element.id) { index, item in
                        thumbnailView(for: item, at: index)
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 70)
            .padding(.bottom, 20)
        }
    }
    
    private func thumbnailView(for item: MediaItem, at index: Int) -> some View {
        let isSelected = index == currentIndex
        
        return AsyncImageView(pathProvider: { await vm.imageURL(for: item) })
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
            .overlay(
                videoIndicatorOverlay(for: item)
            )
            .opacity(isSelected ? 1.0 : 0.6)
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentIndex = index
                }
            }
    }
    
    @ViewBuilder
    private func videoIndicatorOverlay(for item: MediaItem) -> some View {
        if item.isVideo {
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "video.fill")
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .background(
                            Circle()
                                .fill(.black.opacity(0.6))
                                .frame(width: 16, height: 16)
                        )
                }
                Spacer()
            }
            .padding(2)
        }
    }
    
    private var deleteAlertButtons: some View {
        Group {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                Task { await deleteMedia() }
            }
        }
    }
    
    // MARK: - Inline Video Methods
    
    private func getPlayerForItem(_ item: MediaItem) -> AVPlayer? {
        guard let itemId = item.id else { return nil }
        return inlineVideoPlayers[itemId]
    }
    
    private func startInlineVideo(_ item: MediaItem) {
        guard item.isVideo, let itemId = item.id else { return }
        
        print("🎬 Starting inline video for item: \(itemId)")
        
        // Diğer videoları durdur
        stopAllInlineVideos()
        
        Task {
            guard let videoURL = await vm.videoURL(for: item) else {
                showToastMessage("Video URL'si alınamadı")
                return
            }
            
            await MainActor.run {
                // Yeni player oluştur
                let player = AVPlayer(url: videoURL)
                inlineVideoPlayers[itemId] = player
                currentPlayingVideoId = itemId
                
                // Auto-play
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    player.play()
                    print("🎬 Inline video started playing")
                }
                
                // Video bitince thumbnail'e dön
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: player.currentItem,
                    queue: .main
                ) { _ in
                    self.stopInlineVideo(itemId)
                }
            }
        }
    }
    
    private func stopInlineVideo(_ itemId: String) {
        print("🎬 Stopping inline video: \(itemId)")
        
        inlineVideoPlayers[itemId]?.pause()
        inlineVideoPlayers.removeValue(forKey: itemId)
        
        if currentPlayingVideoId == itemId {
            currentPlayingVideoId = nil
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    private func stopAllInlineVideos() {
        print("🎬 Stopping all inline videos")
        
        for (itemId, player) in inlineVideoPlayers {
            player.pause()
        }
        inlineVideoPlayers.removeAll()
        currentPlayingVideoId = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Helper Methods
    
    private func setupInitialState() {
        if let index = vm.filteredItems.firstIndex(where: { $0.id == initialItem.id }) {
            currentIndex = index
        }
        loadCurrentMedia()
    }
    
    private var canDeleteMedia: Bool {
        guard let currentUID = vm.auth.uid else { return false }
        return currentItem.uploaderId == currentUID
    }
    
    private func toggleUI() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showUI.toggle()
        }
    }
    
    private func toggleFavorite() {
        guard let itemId = currentItem.id else { return }
        vm.toggleFavorite(itemId)
        let message = vm.isFavorite(itemId) ? "Favorilere eklendi" : "Favorilerden çıkarıldı"
        showToastMessage(message)
    }
    
    private func loadCurrentMedia() {
        if !currentItem.isVideo {
            let itemId = currentItem.id ?? ""
            if loadedImages[itemId] == nil {
                Task { await loadImage(for: currentItem) }
            }
        }
    }
    
    private func loadImage(for item: MediaItem) async {
        let itemId = item.id ?? ""
        guard loadedImages[itemId] == nil else { return }
        
        do {
            guard let url = await vm.imageURL(for: item) else { return }
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { return }
            
            await MainActor.run {
                loadedImages[itemId] = image
            }
        } catch {
            print("Failed to load image: \(error)")
        }
    }
    
    private func deleteMedia() async {
        isDeleting = true
        
        do {
            try await vm.deletePhoto(currentItem)
            
            await MainActor.run {
                showToastMessage("\(currentItem.isVideo ? "Video" : "Fotoğraf") silindi")
                
                if vm.filteredItems.count <= 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        onClose()
                    }
                } else {
                    if currentIndex >= vm.filteredItems.count {
                        currentIndex = vm.filteredItems.count - 1
                    }
                }
            }
        } catch {
            await MainActor.run {
                showToastMessage("Silme hatası")
            }
        }
        
        isDeleting = false
    }
    
    private func shareMedia() {
        showToastMessage("Paylaşım özelliği yakında eklenecek")
    }
    
    private func saveToPhotos() {
        guard !currentItem.isVideo, let image = loadedImages[currentItem.id ?? ""] else {
            showToastMessage("Henüz görsel yüklenmedi")
            return
        }
        
        Task {
            let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            
            if status == .authorized || status == .limited {
                await performSave(image: image)
            } else if status == .notDetermined {
                let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                if newStatus == .authorized || newStatus == .limited {
                    await performSave(image: image)
                } else {
                    showToastMessage("Fotoğraf izni gerekli")
                }
            } else {
                showToastMessage("Fotoğraf izni reddedildi")
            }
        }
    }
    
    private func performSave(image: UIImage) async {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            await MainActor.run {
                showToastMessage("Galeriye kaydedildi")
            }
        } catch {
            await MainActor.run {
                showToastMessage("Kaydetme hatası")
            }
        }
    }
    
    private func toastView(_ message: String) -> some View {
        VStack {
            Spacer()
            
            Text(message)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.black.opacity(0.8))
                )
                .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showToast = false
                }
            }
        }
    }
    
    private func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation(.spring()) {
            showToast = true
        }
    }
}
