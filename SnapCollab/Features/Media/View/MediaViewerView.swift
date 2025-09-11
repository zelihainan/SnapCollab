//
//  MediaViewerView.swift
//  SnapCollab
//
//  Basitleştirilmiş video desteği (Emergency Player)
//

import SwiftUI
import Photos
import AVKit       // ⬅️ VideoPlayer/AVPlayer için
import UIKit       // ⬅️ UIApplication, UIPasteboard için

struct MediaViewerView: View {
    @ObservedObject var vm: MediaViewModel
    let initialItem: MediaItem
    let onClose: () -> Void

    @State private var currentIndex: Int = 0
    @State private var loadedImages: [String: UIImage] = [:]
    @State private var showUI = true
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @State private var showVideoPlayer = false
    @State private var videoPlayerURL: URL?
    @State private var toastMessage: String?
    @State private var showToast = false

    private var currentItem: MediaItem {
        guard currentIndex < vm.filteredItems.count else { return initialItem }
        return vm.filteredItems[currentIndex]
    }
    
    private var isFavorite: Bool {
        guard let itemId = currentItem.id else { return false }
        return vm.isFavorite(itemId)
    }

    var body: some View {
        let _ = print("🎬 MediaViewer body - showVideoPlayer: \(showVideoPlayer), videoPlayerURL: \(videoPlayerURL?.absoluteString ?? "nil")")
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

        .fullScreenCover(isPresented: $showVideoPlayer) {
            if let videoURL = videoPlayerURL {
                // SEÇENEK 1: Stable Video Player (Temp file kullanır - En güvenilir)
                StableVideoPlayer(videoURL: videoURL) {
                    showVideoPlayer = false
                    videoPlayerURL = nil
                }
                
                // VEYA SEÇENEK 2: WebView Player (Her zaman çalışır)
                /*
                WebViewVideoPlayer(videoURL: videoURL) {
                    showVideoPlayer = false
                    videoPlayerURL = nil
                }
                */
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
        .onChange(of: currentIndex) { _ in
            loadCurrentMedia()
        }
    }
    
    private func videoItemView(item: MediaItem, index: Int) -> some View {
        AsyncImageView(pathProvider: { await vm.imageURL(for: item) })
            .aspectRatio(contentMode: .fit)
            .overlay {
                // Play button - daha büyük ve ortalanmış
                Button(action: { playVideo(item) }) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4)
                }
            }
            .overlay(
                // Video indicator - sol alt köşe
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "video.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(.black.opacity(0.7))
                            )
                        Spacer()
                    }
                    .padding(12)
                }
            )
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
        let hasContent = shouldShowActionButtons()
        
        return Group {
            if hasContent {
                HStack(spacing: 8) {
                    favoriteButton
                    moreMenuButton
                }
            }
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
    
    // MARK: - Helper Methods
    
    private func setupInitialState() {
        if let index = vm.filteredItems.firstIndex(where: { $0.id == initialItem.id }) {
            currentIndex = index
        }
        loadCurrentMedia()
    }
    
    private func shouldShowActionButtons() -> Bool {
        if currentItem.isVideo { return true }
        if currentItem.isImage && loadedImages[currentItem.id ?? ""] != nil { return true }
        return false
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
    
    private func diagnoseVideo(_ item: MediaItem) {
        guard item.isVideo else { return }
        
        print("🔍 VIDEO DIAGNOSIS START")
        print("🔍 Item ID: \(item.id ?? "nil")")
        print("🔍 Item Type: \(item.type)")
        print("🔍 Item Path: \(item.path)")
        print("🔍 Item ThumbPath: \(item.thumbPath ?? "nil")")
        print("🔍 Item Created: \(item.createdAt)")
        
        Task {
            do {
                // 1. Ana video path'ini kontrol et
                print("🔍 Step 1: Getting main video URL...")
                let mainURL = try await vm.repo.downloadURL(for: item.path)
                print("🔍 Main Video URL: \(mainURL.absoluteString)")
                
                // 2. Video URL'sine HEAD request at
                var request = URLRequest(url: mainURL)
                request.httpMethod = "HEAD"
                request.timeoutInterval = 10
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("🔍 Step 2: HEAD Response Status: \(httpResponse.statusCode)")
                    print("🔍 Step 2: Headers: \(httpResponse.allHeaderFields)")
                    
                    if let contentLength = httpResponse.allHeaderFields["Content-Length"] as? String {
                        print("🔍 File Size: \(contentLength) bytes")
                        
                        if let size = Int(contentLength), size < 1000 {
                            print("🔍 WARNING: File is very small (\(size) bytes) - probably corrupted!")
                        }
                    }
                    
                    if let contentType = httpResponse.allHeaderFields["Content-Type"] as? String {
                        print("🔍 Content-Type: \(contentType)")
                    }
                }
                
                // 3. İlk birkaç byte'ı kontrol et (file signature)
                print("🔍 Step 3: Checking file signature...")
                let (data, _) = try await URLSession.shared.data(from: mainURL)
                
                print("🔍 Total file size: \(data.count) bytes")
                
                if data.count >= 12 {
                    let header = Array(data.prefix(12))
                    print("🔍 File header (hex): \(header.map { String(format: "%02X", $0) }.joined(separator: " "))")
                    
                    // MP4 signature kontrol
                    if data.count >= 8 {
                        let signature = Array(data[4..<8])
                        let signatureString = String(bytes: signature, encoding: .ascii) ?? ""
                        print("🔍 File signature: '\(signatureString)'")
                        
                        if signatureString == "ftyp" {
                            print("🔍 ✅ Valid MP4 signature detected")
                        } else {
                            print("🔍 ❌ Invalid MP4 signature - Expected 'ftyp', got '\(signatureString)'")
                        }
                    }
                }
                
                // 4. Thumbnail URL'sini kontrol et
                if let thumbPath = item.thumbPath {
                    print("🔍 Step 4: Checking thumbnail...")
                    let thumbURL = try await vm.repo.downloadURL(for: thumbPath)
                    print("🔍 Thumbnail URL: \(thumbURL.absoluteString)")
                    
                    var thumbRequest = URLRequest(url: thumbURL)
                    thumbRequest.httpMethod = "HEAD"
                    let (_, thumbResponse) = try await URLSession.shared.data(for: thumbRequest)
                    
                    if let httpResponse = thumbResponse as? HTTPURLResponse {
                        print("🔍 Thumbnail Status: \(httpResponse.statusCode)")
                        if let contentType = httpResponse.allHeaderFields["Content-Type"] as? String {
                            print("🔍 Thumbnail Content-Type: \(contentType)")
                        }
                    }
                }
                
                print("🔍 VIDEO DIAGNOSIS COMPLETE")
                
            } catch {
                print("🔍 DIAGNOSIS ERROR: \(error)")
            }
        }
    }

    private func playVideo(_ item: MediaItem) {
        guard item.isVideo else {
            showToastMessage("Bu dosya video değil")
            return
        }
        
        print("🎬 MediaViewer: Playing video for item: \(item.id ?? "")")
        print("🎬 MediaViewer: Current showVideoPlayer state: \(showVideoPlayer)")
        print("🎬 MediaViewer: Current videoPlayerURL: \(videoPlayerURL?.absoluteString ?? "nil")")
        
        Task {
            guard let videoURL = await vm.videoURL(for: item) else {
                await MainActor.run {
                    showToastMessage("Video URL'si alınamadı")
                }
                return
            }
            
            print("🎬 MediaViewer: Got video URL: \(videoURL.absoluteString)")
            
            await MainActor.run {
                print("🎬 MediaViewer: Setting videoPlayerURL and showVideoPlayer to true")
                videoPlayerURL = videoURL
                showVideoPlayer = true
                print("🎬 MediaViewer: After setting - showVideoPlayer: \(showVideoPlayer)")
                print("🎬 MediaViewer: After setting - videoPlayerURL: \(videoPlayerURL?.absoluteString ?? "nil")")
            }
        }
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

// MARK: - Emergency Video View (Safari + Kopyala + Native Player Denemesi)
struct EmergencyVideoView: View {
    let videoURL: URL
    let onClose: () -> Void
    
    @State private var player: AVPlayer
    
    init(videoURL: URL, onClose: @escaping () -> Void) {
        self.videoURL = videoURL
        self.onClose = onClose
        _player = State(initialValue: AVPlayer(url: videoURL))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.blue)
                
                Text("Video Oynatıcı")
                    .font(.title)
                
                Text("Video URL'si:")
                    .font(.headline)
                
                Text(videoURL.absoluteString)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(spacing: 16) {
                    Button("Safari'de Aç") {
                        UIApplication.shared.open(videoURL)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    
                    Button("URL'yi Kopyala") {
                        UIPasteboard.general.string = videoURL.absoluteString
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
                
                // Native iOS VideoPlayer
                VideoPlayer(player: player)
                    .frame(height: 220)
                    .background(Color.black)
                    .cornerRadius(8)
                    .onAppear {
                        // Basit zaman gözlemi + otomatik oynatma
                        _ = player.addPeriodicTimeObserver(
                            forInterval: CMTime(seconds: 1, preferredTimescale: 1),
                            queue: .main
                        ) { time in
                            print("🎬 Player time: \(time.seconds)s")
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            player.play()
                            print("🎬 Player.play() called")
                        }
                    }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Video Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { onClose() }
                }
            }
        }
    }
}
