import SwiftUI
import Photos

struct MediaViewerView: View {
    @ObservedObject var vm: MediaViewModel
    let item: MediaItem
    let onClose: () -> Void

    @State private var loadedImage: UIImage?
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var scale: CGFloat = 1.0
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var showDeleteAlert = false  // ← Silme alert'i için
    @State private var isDeleting = false       // ← Silme işlemi için

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Ana içerik
            if isLoading {
                loadingView
            } else if loadFailed {
                errorView
            } else if let image = loadedImage {
                imageView(image)
            } else {
                errorView
            }

            // Toolbar
            VStack {
                HStack {
                    closeButton
                    Spacer()
                    if loadedImage != nil {
                        actionButtons
                    }
                }
                .padding()
                Spacer()
            }
            
            // Toast
            if showToast, let message = toastMessage {
                toastView(message)
            }
        }
        .onAppear {
            print("DEBUG: MediaViewerView appeared for item: \(item.id ?? "unknown")")
            loadImage()
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 100 && !isDeleting {
                        onClose()
                    }
                }
        )
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
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Fotoğraf yükleniyor...")
                .foregroundColor(.white)
                .font(.caption)
        }
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.white)
            
            Text("Fotoğraf yüklenemedi")
                .foregroundColor(.white)
            
            Button("Tekrar Dene") {
                loadImage()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func imageView(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .scaleEffect(scale)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = max(1.0, value)
                    }
                    .onEnded { _ in
                        withAnimation(.spring()) {
                            if scale < 1.2 {
                                scale = 1.0
                            }
                        }
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring()) {
                    scale = scale > 1.0 ? 1.0 : 2.0
                }
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
        .disabled(isDeleting)
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Silme butonu - sadece uploader için
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
    
    // ← Silme yetkisi kontrolü
    private var canDeletePhoto: Bool {
        guard let currentUID = vm.auth.uid else { return false }
        return item.uploaderId == currentUID
    }
    
    // ← Fotoğraf silme metodu
    private func deletePhoto() async {
        isDeleting = true
        
        do {
            try await vm.deletePhoto(item)
            
            await MainActor.run {
                showToastMessage("Fotoğraf silindi")
                // 1 saniye sonra viewer'ı kapat
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    onClose()
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
    
    private func loadImage() {
        print("DEBUG: Starting image load")
        isLoading = true
        loadFailed = false
        
        Task {
            do {
                guard let url = await vm.imageURL(for: item) else {
                    print("DEBUG: Failed to get URL")
                    await MainActor.run {
                        isLoading = false
                        loadFailed = true
                    }
                    return
                }
                
                print("DEBUG: Got URL: \(url)")
                
                let (data, _) = try await URLSession.shared.data(from: url)
                
                guard let image = UIImage(data: data) else {
                    print("DEBUG: Failed to create UIImage")
                    await MainActor.run {
                        isLoading = false
                        loadFailed = true
                    }
                    return
                }
                
                print("DEBUG: Successfully loaded image")
                await MainActor.run {
                    loadedImage = image
                    isLoading = false
                    loadFailed = false
                }
                
            } catch {
                print("DEBUG: Load error: \(error)")
                await MainActor.run {
                    isLoading = false
                    loadFailed = true
                }
            }
        }
    }
    
    private func saveToPhotos() {
        guard let image = loadedImage else {
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
            print("Photo save error: \(error)")
            await MainActor.run {
                showToastMessage("Kaydetme hatası")
            }
        }
    }
    
    private func shareImageDirectly() {
        print("DEBUG: Share button tapped - using UIKit approach")
        
        guard let image = loadedImage else {
            showToastMessage("Henüz görsel yüklenmedi")
            return
        }
        
        // UIKit yaklaşımı - direkt UIActivityViewController göster
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("DEBUG: Could not find root view controller")
            showToastMessage("Paylaşım hatası")
            return
        }
        
        // En üstteki view controller'ı bul
        var topViewController = rootViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        
        print("DEBUG: Found top view controller: \(type(of: topViewController))")
        
        // Zengin içerik için temporary file oluştur
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            showToastMessage("Paylaşım hatası")
            return
        }
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("SnapCollab_Photo_\(Date().timeIntervalSince1970)")
            .appendingPathExtension("jpg")
        
        do {
            try imageData.write(to: tempURL)
            print("DEBUG: Created temp file at: \(tempURL)")
        } catch {
            print("DEBUG: Failed to create temp file: \(error)")
            showToastMessage("Paylaşım hatası")
            return
        }
        
        // Paylaşım içeriği - hem URL hem de image ekle
        let shareText = "SnapCollab'dan paylaşıldı"
        let activityItems: [Any] = [shareText, tempURL, image]
        
        // ActivityViewController oluştur ve hemen göster
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        // iPad için popover ayarları
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topViewController.view
            popover.sourceRect = CGRect(x: topViewController.view.bounds.midX,
                                      y: topViewController.view.bounds.midY,
                                      width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Completion handler
        activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            print("DEBUG: Share completed: \(completed), error: \(error?.localizedDescription ?? "none")")
            
            // Temp file'ı temizle
            try? FileManager.default.removeItem(at: tempURL)
            
            if completed {
                DispatchQueue.main.async {
                    self.showToastMessage("Paylaşım tamamlandı")
                }
            }
        }
        
        // Hemen göster
        topViewController.present(activityVC, animated: true) {
            print("DEBUG: Share sheet presented successfully")
        }
    }
    
    private func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation(.spring()) {
            showToast = true
        }
    }
}
