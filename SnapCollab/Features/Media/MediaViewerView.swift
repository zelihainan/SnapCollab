import SwiftUI
import Photos
import AVKit
import AVFoundation

struct MediaViewerView: View {
    @ObservedObject var vm: MediaViewModel
    let initialItem: MediaItem
    let onClose: () -> Void

    @State private var currentIndex = 0
    @State private var loadedImages: [String: UIImage] = [:]
    @State private var showUI = true
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var players: [String: AVPlayer] = [:]
    @State private var currentPlayingId: String?
    @State private var muteStates: [String: Bool] = [:]

    private let thumbnailBarHeight: CGFloat = 86
    private let uploaderBarHeight: CGFloat = 60 // Yeni uploader bar height
    private let controlsGapAboveThumbs: CGFloat = 22
    private let soundIconExtraTop: CGFloat = 18

    private var items: [MediaItem] { vm.filteredItems }
    private var currentItem: MediaItem {
        guard currentIndex < items.count else { return initialItem }
        return items[currentIndex]
    }
    private var isFavorite: Bool {
        guard let id = currentItem.id else { return false }
        return vm.isFavorite(id)
    }
    private var canDelete: Bool {
        guard let uid = vm.auth.uid else { return false }
        return currentItem.uploaderId == uid
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    ZStack {
                        if item.isVideo {
                            videoPage(for: item)
                        } else {
                            imagePage(for: item)
                        }
                    }
                    .tag(index)
                    .contentShape(Rectangle())
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.25)) { showUI.toggle() } }
                    .onAppear { if item.isVideo { Task { await ensurePlayer(for: item) } } }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            if showUI { topBar }
            if showUI { uploaderInfoBar } // Yeni uploader bilgi barı
            if showUI && items.count > 1 { thumbnailBar }

            if showToast, let msg = toastMessage { toastView(msg) }
        }
        .alert("Medyayı Sil", isPresented: $showDeleteAlert) {
            Button("İptal", role: .cancel) {}
            Button("Sil", role: .destructive) { Task { await deleteCurrent() } }
        } message: {
            Text("Bu \(currentItem.isVideo ? "videoyu" : "fotoğrafı") kalıcı olarak silmek istediğinizden emin misiniz?")
        }
        .onAppear {
            if let i = items.firstIndex(where: { $0.id == initialItem.id }) { currentIndex = i }
            loadIfNeeded(currentItem)
        }
        .onDisappear { stopAll() }
        .onChange(of: currentIndex) { _ in
            stopAll()
            loadIfNeeded(currentItem)
        }
    }

    private func imagePage(for item: MediaItem) -> some View {
        let id = item.id ?? ""
        return Group {
            if let img = loadedImages[id] {
                Image(uiImage: img).resizable().scaledToFit()
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .onAppear { Task { await loadImage(item) } }
            }
        }
    }

    private func videoPage(for item: MediaItem) -> some View {
        let id = item.id ?? ""
        let player = players[id]

        return ZStack {
            if let player {
                InlineVideoView(
                    player: player,
                    itemId: id,
                    isMuted: Binding(
                        get: { muteStates[id] ?? false },
                        set: { muteStates[id] = $0; player.isMuted = $0 }
                    ),
                    bottomOverlayPadding: thumbnailBarHeight + controlsGapAboveThumbs + uploaderBarHeight,
                    topRightExtraTop: soundIconExtraTop,
                    autoPlay: true
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                AsyncImageView(pathProvider: { await vm.imageURL(for: item) })
                    .scaledToFit()
            }
        }
    }

    private var topBar: some View {
        VStack {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Circle().fill(.black.opacity(0.6)))
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: currentItem.isVideo ? "video" : "photo").font(.caption)
                    Text("\(currentIndex + 1) of \(items.count)")
                        .font(.caption).fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )

                Spacer()

                HStack(spacing: 8) {
                    Button(action: toggleFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundColor(isFavorite ? .red : .white)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle().fill(.ultraThinMaterial)
                                    .environment(\.colorScheme, .dark)
                            )
                    }

                    Menu {
                        Button("Paylaş", action: shareCurrent)
                        Button("Galeriye Kaydet", action: saveCurrent)
                        if canDelete {
                            Divider()
                            Button("Sil", role: .destructive) { showDeleteAlert = true }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle().fill(.ultraThinMaterial)
                                    .environment(\.colorScheme, .dark)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            Spacer()
        }
    }

    private var uploaderInfoBar: some View {
        VStack {
            Spacer()
            
            UploaderInfoView(item: currentItem, vm: vm)
                .padding(.horizontal, 16)
                .padding(.bottom, thumbnailBarHeight + 8) // Thumbnaillerin hemen üstü
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var thumbnailBar: some View {
        VStack {
            Spacer()
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                        let selected = idx == currentIndex
                        AsyncImageView(pathProvider: { await vm.imageURL(for: item) })
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selected ? Color.white : .clear, lineWidth: 2)
                            )
                            .overlay(alignment: .topTrailing) {
                                if item.isVideo {
                                    Image(systemName: "video.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.white)
                                        .padding(2)
                                        .background(Circle().fill(.black.opacity(0.6)))
                                        .clipShape(Circle())
                                        .padding(2)
                                }
                            }
                            .opacity(selected ? 1 : 0.6)
                            .scaleEffect(selected ? 1.1 : 1.0)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    currentIndex = idx
                                }
                            }
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 70)
            .padding(.bottom, 16)
            .background(Color.black.opacity(0.0001))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // Diğer fonksiyonlar aynı kalıyor...
    private func ensurePlayer(for item: MediaItem) async {
        guard let id = item.id, players[id] == nil else { return }
        guard let url = await vm.videoURL(for: item) else { return }
        await MainActor.run {
            let p = AVPlayer(url: url)
            p.isMuted = muteStates[id] ?? false
            p.pause()
            players[id] = p
            currentPlayingId = id

            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: p.currentItem,
                queue: .main
            ) { _ in
                p.seek(to: .zero)
            }
        }
    }

    private func stopAll() {
        for (_, p) in players { p.pause() }
        players.removeAll()
        currentPlayingId = nil
        NotificationCenter.default.removeObserver(self)
    }

    private func loadIfNeeded(_ item: MediaItem) {
        if !item.isVideo { Task { await loadImage(item) } }
    }

    private func loadImage(_ item: MediaItem) async {
        let id = item.id ?? ""
        guard loadedImages[id] == nil else { return }
        do {
            guard let url = await vm.imageURL(for: item) else { return }
            let (data, _) = try await URLSession.shared.data(from: url)
            if let img = UIImage(data: data) {
                await MainActor.run { loadedImages[id] = img }
            }
        } catch { print("Image load error:", error) }
    }

    private func toggleFavorite() {
        guard let id = currentItem.id else { return }
        vm.toggleFavorite(id)
        showToast(vm.isFavorite(id) ? "Favorilere eklendi" : "Favorilerden çıkarıldı")
    }

    private func deleteCurrent() async {
        isDeleting = true
        do {
            try await vm.deletePhoto(currentItem)
            await MainActor.run {
                showToast("\(currentItem.isVideo ? "Video" : "Fotoğraf") silindi")
                if items.count <= 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { onClose() }
                } else if currentIndex >= items.count {
                    currentIndex = max(0, items.count - 1)
                }
            }
        } catch {
            await MainActor.run { showToast("Silme hatası") }
        }
        isDeleting = false
    }

    private func shareCurrent() { showToast("Paylaşım yakında") }

    private func saveCurrent() {
        currentItem.isVideo ? saveVideo() : saveImage()
    }

    private func saveImage() {
        guard let img = loadedImages[currentItem.id ?? ""] else { showToast("Henüz görsel yüklenmedi"); return }
        Task {
            let st = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            if st == .authorized || st == .limited {
                await performSaveImage(img)
            } else if st == .notDetermined {
                let ns = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                if ns == .authorized || ns == .limited { await performSaveImage(img) }
                else { showToast("Fotoğraf izni gerekli") }
            } else { showToast("Fotoğraf izni reddedildi") }
        }
    }

    private func saveVideo() {
        Task {
            let st = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            if st == .authorized || st == .limited {
                await performSaveVideo()
            } else if st == .notDetermined {
                let ns = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                if ns == .authorized || ns == .limited { await performSaveVideo() }
                else { showToast("Fotoğraf izni gerekli") }
            } else { showToast("Fotoğraf izni reddedildi") }
        }
    }

    private func performSaveImage(_ image: UIImage) async {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            await MainActor.run { showToast("Fotoğraf galeriye kaydedildi") }
        } catch { await MainActor.run { showToast("Kaydetme hatası") } }
    }

    private func performSaveVideo() async {
        do {
            guard let url = await vm.videoURL(for: currentItem) else { showToast("Video URL'si alınamadı"); return }
            let (data, _) = try await URLSession.shared.data(from: url)
            let tmp = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
            try data.write(to: tmp)
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tmp)
            }
            try? FileManager.default.removeItem(at: tmp)
            await MainActor.run { showToast("Video galeriye kaydedildi") }
        } catch { await MainActor.run { showToast("Video kaydetme hatası") } }
    }

    private func toastView(_ message: String) -> some View {
        VStack {
            Spacer()
            Text(message)
                .foregroundColor(.white)
                .padding(.horizontal, 20).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 25).fill(.black.opacity(0.8)))
                .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { showToast = false }
            }
        }
    }

    private func showToast(_ msg: String) {
        toastMessage = msg
        withAnimation(.spring()) { showToast = true }
    }
}

// Yeni UploaderInfoView komponenti
struct UploaderInfoView: View {
    let item: MediaItem
    let vm: MediaViewModel
    
    @State private var uploaderUser: User?
    @State private var isLoading = true
    
    var body: some View {
        HStack(spacing: 12) {
            // Profil fotoğrafı
            Group {
                if let user = uploaderUser, let photoURL = user.photoURL, !photoURL.isEmpty {
                    AsyncImage(url: URL(string: photoURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else {
                            defaultAvatar
                        }
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
                } else {
                    defaultAvatar
                }
            }
            
            // Kullanıcı adı ve "ekledi" yazısı
            VStack(alignment: .leading, spacing: 2) {
                if let user = uploaderUser {
                    Text(user.displayName ?? user.email)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                } else {
                    if isLoading {
                        Text("Yükleniyor...")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    } else {
                        Text("Bilinmeyen kullanıcı")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                
                HStack(spacing: 4) {
                    
                    Text(timeAgoText)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .onAppear {
            loadUploaderInfo()
        }
        .onChange(of: item.uploaderId) { _ in
            loadUploaderInfo()
        }
    }
    
    private var defaultAvatar: some View {
        Circle()
            .fill(.white.opacity(0.2))
            .frame(width: 32, height: 32)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.7))
            }
    }
    
    private var timeAgoText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.localizedString(for: item.createdAt, relativeTo: Date())
    }
    
    private func loadUploaderInfo() {
        isLoading = true
        
        // Önce cache'ten kontrol et
        if let cachedUser = vm.getUser(for: item.uploaderId) {
            uploaderUser = cachedUser
            isLoading = false
            return
        }
        
        // Cache'te yoksa Firestore'dan yükle
        Task {
            do {
                let userService = FirestoreUserService()
                let user = try await userService.getUser(uid: item.uploaderId)
                
                await MainActor.run {
                    uploaderUser = user
                    isLoading = false
                    
                    // Cache'e ekle
                    vm.cacheUser(user, for: item.uploaderId)
                }
            } catch {
                await MainActor.run {
                    uploaderUser = nil
                    isLoading = false
                }
                print("Error loading uploader info: \(error)")
            }
        }
    }
}

private struct InlineVideoView: View {
    let player: AVPlayer
    let itemId: String
    @Binding var isMuted: Bool

    let bottomOverlayPadding: CGFloat
    let topRightExtraTop: CGFloat
    let autoPlay: Bool

    @State private var isPlaying = false
    @State private var current: Double = 0
    @State private var duration: Double = 0
    @State private var showControls = true
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            PlayerViewRepresentable(player: player)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    if isPlaying {
                        player.pause()
                    } else {
                        player.play()
                    }
                    showControlsTemporarily()
                }

            if showControls {
                VStack {
                    // Ses butonu - sağ üst köşe
                    HStack {
                        Spacer()
                        Button {
                            isMuted.toggle()
                            player.isMuted = isMuted
                            showControlsTemporarily()
                        } label: {
                            Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(.black.opacity(0.6)))
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 50 + topRightExtraTop)
                    }

                    Spacer()

                    // Minimal video kontrolleri - alt kısımda
                    VStack(spacing: 6) {
                        // Progress bar - daha ince
                        HStack(spacing: 8) {
                            Text(format(current))
                                .font(.caption2)
                                .foregroundColor(.white)
                                .monospacedDigit()
                            
                            Slider(value: $current, in: 0...max(duration, 1), onEditingChanged: { editing in
                                if !editing {
                                    player.seek(to: CMTime(seconds: current, preferredTimescale: 600))
                                }
                            })
                            .accentColor(.white)
                            
                            Text(format(duration))
                                .font(.caption2)
                                .foregroundColor(.white)
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 20)

                        // Play/Pause butonu - daha küçük
                        HStack {
                            Spacer()
                            Button {
                                if isPlaying { player.pause() } else { player.play() }
                                showControlsTemporarily()
                            } label: {
                                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 32)) // Daha küçük
                                    .foregroundColor(.white)
                                    .background(Circle().fill(.black.opacity(0.3)))
                            }
                            Spacer()
                        }
                        .padding(.bottom, 8)
                    }
                    .padding(.bottom, bottomOverlayPadding)
                    .background(
                        LinearGradient(colors: [.clear, .black.opacity(0.6)], // Daha hafif gradient
                                       startPoint: .top, endPoint: .bottom)
                            .frame(height: 100) // Daha küçük gradient area
                    )
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            setupObservers()
            if autoPlay {
                // Kısa bir gecikme sonra otomatik başlat
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    player.play()
                }
            }
            showControlsTemporarily()
            player.isMuted = isMuted
        }
        .onDisappear {
            timer?.invalidate()
            player.pause() // View'dan çıkarken durdur
        }
    }

    private func setupObservers() {
        if let item = player.currentItem {
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item, queue: .main
            ) { _ in
                player.seek(to: .zero)
                isPlaying = false
                // Otomatik tekrar oynatma için
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    player.play()
                }
            }
        }
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
                                       queue: .main) { t in
            current = t.seconds
            isPlaying = player.rate > 0
            if let it = player.currentItem { duration = it.duration.seconds }
        }
    }

    private func showControlsTemporarily() {
        withAnimation { showControls = true }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in // Daha kısa süre
            withAnimation { showControls = false }
        }
    }

    private func format(_ s: Double) -> String {
        guard s.isFinite else { return "0:00" }
        let i = Int(s), m = i / 60, r = i % 60
        return String(format: "%d:%02d", m, r)
    }
}

private struct PlayerViewRepresentable: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerView {
        let v = PlayerView()
        v.playerLayer.player = player
        v.playerLayer.videoGravity = .resizeAspect
        return v
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.playerLayer.player = player
        uiView.playerLayer.videoGravity = .resizeAspect
    }

    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
        override func layoutSubviews() {
            super.layoutSubviews()
        }
    }
}
