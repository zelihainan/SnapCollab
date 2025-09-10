import SwiftUI
import Photos

struct MediaViewerView: View {
    @ObservedObject var vm: MediaViewModel
    let initialItem: MediaItem
    let onClose: () -> Void

    @State private var currentIndex: Int = 0
    @State private var loadedImages: [String: UIImage] = [:]
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var scale: CGFloat = 1.0
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @State private var offset: CGSize = .zero
    @State private var showUI = true
    @State private var uiTimer: Timer?

    private var currentItem: MediaItem {
        guard currentIndex < vm.items.count else { return initialItem }
        return vm.items[currentIndex]
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Main Image Pager
            TabView(selection: $currentIndex) {
                ForEach(Array(vm.items.enumerated()), id: \.element.id) { index, item in
                    MediaImageView(
                        vm: vm,
                        item: item,
                        loadedImages: $loadedImages,
                        scale: $scale
                    )
                    .tag(index)
                    .onTapGesture {
                        toggleUI()
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onAppear {
                // Find initial item index
                if let index = vm.items.firstIndex(where: { $0.id == initialItem.id }) {
                    currentIndex = index
                }
                loadCurrentImage()
            }
            .onChange(of: currentIndex) { _ in
                resetZoom()
                loadCurrentImage()
                preloadAdjacentImages()
            }

            // Top UI Bar
            if showUI {
                VStack {
                    // Top bar
                    HStack {
                        closeButton
                        
                        Spacer()
                        
                        // Image counter with modern design
                        HStack(spacing: 4) {
                            Image(systemName: "photo")
                                .font(.caption)
                            Text("\(currentIndex + 1) of \(vm.items.count)")
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
                        
                        Spacer()
                        
                        // Action buttons with modern glass effect
                        if loadedImages[currentItem.id ?? ""] != nil {
                            HStack(spacing: 8) {
                                // More menu
                                Menu {
                                    
                                    Button(action: shareImageDirectly) {
                                        Label("Paylaş", systemImage: "square.and.arrow.up")
                                    }
                                    
                                    if canDeletePhoto {
                                        Divider()
                                        Button(role: .destructive, action: { showDeleteAlert = true }) {
                                            Label("Sil", systemImage: "trash")
                                        }
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
                                
                                // Download
                                Button(action: saveToPhotos) {
                                    Image(systemName: "arrow.down.to.line")
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
                            .disabled(isDeleting)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Bottom UI Bar
            if showUI && vm.items.count > 1 {
                VStack {
                    Spacer()
                    
                    // Thumbnail strip
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 8) {
                                ForEach(Array(vm.items.enumerated()), id: \.element.id) { index, item in
                                    ThumbnailView(vm: vm, item: item, isSelected: index == currentIndex)
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                currentIndex = index
                                            }
                                        }
                                        .id(index)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .onChange(of: currentIndex) { newIndex in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(newIndex, anchor: .center)
                            }
                        }
                    }
                    .frame(height: 70)
                    .background(
                        Rectangle()
                            .fill(.black.opacity(0.8))
                            .blur(radius: 10)
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            // Toast
            if showToast, let message = toastMessage {
                toastView(message)
            }
        }
        .gesture(
            // Close gesture - swipe down from center
            DragGesture()
                .onChanged { value in
                    if value.startLocation.y < UIScreen.main.bounds.height * 0.3 &&
                       value.translation.height > 50 {
                        offset = value.translation
                    }
                }
                .onEnded { value in
                    if offset.height > 100 && !isDeleting {
                        onClose()
                    } else {
                        withAnimation(.spring()) {
                            offset = .zero
                        }
                    }
                }
        )
        .offset(y: offset.height * 0.5)
        .opacity(1 - abs(offset.height) / 500.0)
        .alert("Fotoğrafı Sil", isPresented: $showDeleteAlert) {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                Task { await deletePhoto() }
            }
        } message: {
            Text("Bu fotoğrafı kalıcı olarak silmek istediğinizden emin misiniz?")
        }
        .disabled(isDeleting)
        .overlay {
            if isDeleting {
                Color.black.opacity(0.6)
                    .overlay {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            Text("Fotoğraf siliniyor...")
                                .foregroundStyle(.white)
                                .font(.caption)
                        }
                    }
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            startUITimer()
        }
        .onDisappear {
            stopUITimer()
        }
    }
    
    // MARK: - UI Components
    
    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.title2)
                .foregroundColor(.white)
                .padding(10)
                .background(Circle().fill(.black.opacity(0.6)))
        }
        .disabled(isDeleting)
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Delete button - only for uploader
            if canDeletePhoto {
                Button(action: { showDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .font(.title2)
                        .foregroundColor(.red)
                        .padding(10)
                        .background(Circle().fill(.black.opacity(0.6)))
                }
                .disabled(isDeleting)
            }
            
            Button(action: saveToPhotos) {
                Image(systemName: "square.and.arrow.down")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Circle().fill(.black.opacity(0.6)))
            }
            .disabled(isDeleting)
            
            Button(action: shareImageDirectly) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Circle().fill(.black.opacity(0.6)))
            }
            .disabled(isDeleting)
        }
    }
    
    // MARK: - Helper Methods
    
    private var canDeletePhoto: Bool {
        guard let currentUID = vm.auth.uid else { return false }
        return currentItem.uploaderId == currentUID
    }
    
    private func toggleUI() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showUI.toggle()
        }
        
        if showUI {
            startUITimer()
        } else {
            stopUITimer()
        }
    }
    
    private func startUITimer() {
        stopUITimer()
        uiTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showUI = false
            }
        }
    }
    
    private func stopUITimer() {
        uiTimer?.invalidate()
        uiTimer = nil
    }
    
    private func resetZoom() {
        withAnimation(.easeInOut(duration: 0.2)) {
            scale = 1.0
        }
    }
    
    private func loadCurrentImage() {
        let itemId = currentItem.id ?? ""
        guard loadedImages[itemId] == nil else { return }
        
        Task {
            await loadImage(for: currentItem)
        }
    }
    
    private func preloadAdjacentImages() {
        // Preload previous image
        if currentIndex > 0 {
            let prevItem = vm.items[currentIndex - 1]
            Task {
                await loadImage(for: prevItem)
            }
        }
        
        // Preload next image
        if currentIndex < vm.items.count - 1 {
            let nextItem = vm.items[currentIndex + 1]
            Task {
                await loadImage(for: nextItem)
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
    
    private func deletePhoto() async {
        isDeleting = true
        
        do {
            try await vm.deletePhoto(currentItem)
            
            await MainActor.run {
                showToastMessage("Fotoğraf silindi")
                
                // If it was the last photo, close viewer
                if vm.items.count <= 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        onClose()
                    }
                } else {
                    // Adjust index if needed
                    if currentIndex >= vm.items.count {
                        currentIndex = vm.items.count - 1
                    }
                }
            }
            
        } catch {
            await MainActor.run {
                let errorMsg = (error as? MediaError)?.errorDescription ?? error.localizedDescription
                showToastMessage("Silme hatası: \(errorMsg)")
            }
        }
        
        isDeleting = false
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
    
    private func saveToPhotos() {
        guard let image = loadedImages[currentItem.id ?? ""] else {
            showToastMessage("Henüz görsel yüklenmedi")
            return
        }
        
        Task {
            let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            
            switch status {
            case .authorized, .limited:
                await performSave(image: image)
                
            case .denied, .restricted:
                showToastMessage("Fotoğraf izni reddedildi")
                
            case .notDetermined:
                let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                if newStatus == .authorized || newStatus == .limited {
                    await performSave(image: image)
                } else {
                    showToastMessage("Fotoğraf izni gerekli")
                }
                
            @unknown default:
                showToastMessage("Bilinmeyen hata")
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
    
    private func shareImageDirectly() {
        guard let image = loadedImages[currentItem.id ?? ""] else {
            showToastMessage("Henüz görsel yüklenmedi")
            return
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            showToastMessage("Paylaşım hatası")
            return
        }
        
        var topViewController = rootViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            showToastMessage("Paylaşım hatası")
            return
        }
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("SnapCollab_Photo_\(Date().timeIntervalSince1970)")
            .appendingPathExtension("jpg")
        
        do {
            try imageData.write(to: tempURL)
        } catch {
            showToastMessage("Paylaşım hatası")
            return
        }
        
        let shareText = "SnapCollab'dan paylaşıldı"
        let activityItems: [Any] = [shareText, tempURL, image]
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topViewController.view
            popover.sourceRect = CGRect(x: topViewController.view.bounds.midX,
                                      y: topViewController.view.bounds.midY,
                                      width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        activityVC.completionWithItemsHandler = { _, completed, _, _ in
            try? FileManager.default.removeItem(at: tempURL)
            if completed {
                DispatchQueue.main.async {
                    self.showToastMessage("Paylaşım tamamlandı")
                }
            }
        }
        
        topViewController.present(activityVC, animated: true)
    }
    
    private func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation(.spring()) {
            showToast = true
        }
    }
}

// MARK: - Media Image View
struct MediaImageView: View {
    @ObservedObject var vm: MediaViewModel
    let item: MediaItem
    @Binding var loadedImages: [String: UIImage]
    @Binding var scale: CGFloat
    
    private var itemId: String { item.id ?? "" }
    
    var body: some View {
        Group {
            if let image = loadedImages[itemId] {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = max(1.0, min(value, 5.0))
                            }
                            .onEnded { _ in
                                withAnimation(.spring()) {
                                    if scale < 1.2 {
                                        scale = 1.0
                                    } else if scale > 3.0 {
                                        scale = 3.0
                                    }
                                }
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring()) {
                            scale = scale > 1.0 ? 1.0 : 2.0
                        }
                    }
            } else {
                loadingPlaceholder
                    .onAppear {
                        Task {
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
                    }
            }
        }
    }
    
    private var loadingPlaceholder: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Yükleniyor...")
                .foregroundColor(.white)
                .font(.caption)
        }
    }
}

// MARK: - Thumbnail View
struct ThumbnailView: View {
    @ObservedObject var vm: MediaViewModel
    let item: MediaItem
    let isSelected: Bool
    
    var body: some View {
        AsyncImageView(pathProvider: { await vm.imageURL(for: item) })
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
            .opacity(isSelected ? 1.0 : 0.6)
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
