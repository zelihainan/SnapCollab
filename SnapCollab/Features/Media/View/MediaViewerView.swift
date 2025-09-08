import SwiftUI
import Photos
import Foundation

struct MediaViewerView: View {
    @ObservedObject var vm: MediaViewModel
    let item: MediaItem
    let onClose: () -> Void

    @State private var uiImage: UIImage?
    @State private var isSharing = false
    @State private var shareURL: URL?
    @State private var scale: CGFloat = 1.0
    @State private var loadFailed = false
    @State private var toastMessage: ToastMessage?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Ana görsel
            Group {
                if let uiImage {
                    ZoomableImage(image: Image(uiImage: uiImage), scale: $scale)
                        .animation(.easeInOut(duration: 0.3), value: uiImage != nil)
                } else if loadFailed {
                    errorPlaceholder
                } else {
                    loadingPlaceholder
                }
            }

            // Üst toolbar
            VStack {
                HStack(spacing: 20) {
                    Button { onClose() } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Circle().fill(.black.opacity(0.5)))
                    }
                    
                    Spacer()
                    
                    // Butonları sadece image yüklendiğinde göster
                    if uiImage != nil {
                        Button {
                            Task { await saveToPhotos() }
                        } label: {
                            Image(systemName: "square.and.arrow.down")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(Circle().fill(.black.opacity(0.5)))
                        }
                        
                        Button {
                            Task { await share() }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(Circle().fill(.black.opacity(0.5)))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                Spacer()
            }
            
            // Toast mesajı
            if let toast = toastMessage {
                VStack {
                    Spacer()
                    
                    HStack {
                        Image(systemName: toast.isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundColor(toast.isSuccess ? .green : .red)
                        
                        Text(toast.message)
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(.black.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(toast.isSuccess ? .green : .red, lineWidth: 1)
                            )
                    )
                    .padding(.bottom, 50)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: toastMessage != nil)
            }
        }
        .onAppear {
            print("DEBUG: MediaViewerView appeared")
            loadImageOnAppear()
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 120 { onClose() }
                }
        )
        .sheet(isPresented: $isSharing) {
            if let shareURL { ActivityView(activityItems: [shareURL]) }
        }
    }
    
    private func loadImageOnAppear() {
        // Eğer zaten yüklenmişse tekrar yükleme
        guard uiImage == nil else { return }
        
        Task { @MainActor in
            print("DEBUG: Starting image load task")
            isLoading = true
            loadFailed = false
            
            do {
                print("DEBUG: Getting URL for path: \(item.thumbPath ?? item.path)")
                
                guard let url = await vm.imageURL(for: item) else {
                    print("DEBUG: Failed to get URL")
                    loadFailed = true
                    isLoading = false
                    return
                }
                
                print("DEBUG: Got URL: \(url)")
                
                let (data, response) = try await URLSession.shared.data(from: url)
                
                print("DEBUG: Downloaded data size: \(data.count) bytes")
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("DEBUG: HTTP Status: \(httpResponse.statusCode)")
                }
                
                guard let img = UIImage(data: data) else {
                    print("DEBUG: Failed to create UIImage from data")
                    loadFailed = true
                    isLoading = false
                    return
                }
                
                print("DEBUG: Successfully created UIImage, setting to state")
                
                // Ana thread'de state güncelle
                uiImage = img
                isLoading = false
                
                print("DEBUG: State updated - uiImage is now set")
                
            } catch {
                print("DEBUG: Image load error: \(error)")
                loadFailed = true
                isLoading = false
            }
        }
    }
    
    private var loadingPlaceholder: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)
            
            Text("Fotoğraf yükleniyor...")
                .foregroundColor(.white.opacity(0.8))
                .font(.caption)
        }
    }

    private var errorPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(.white)
            Text("Görsel yüklenemedi")
                .foregroundStyle(.white.opacity(0.8))
            Button("Tekrar Dene") {
                loadImageOnAppear()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func saveToPhotos() async {
        guard let uiImage else {
            showToast("Görsel henüz yüklenmedi", isSuccess: false)
            return
        }
        
        // İzin durumunu kontrol et
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized, .limited:
            await performSave(image: uiImage)
            
        case .denied, .restricted:
            showToast("Fotoğraf izni reddedildi", isSuccess: false)
            
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            if newStatus == .authorized || newStatus == .limited {
                await performSave(image: uiImage)
            } else {
                showToast("Fotoğraf izni gerekli", isSuccess: false)
            }
            
        @unknown default:
            showToast("Bilinmeyen hata", isSuccess: false)
        }
    }
    
    private func performSave(image: UIImage) async {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            
            showToast("Fotoğraf galeriye kaydedildi", isSuccess: true)
            
        } catch {
            print("Photo save error: \(error)")
            showToast("Kaydetme hatası", isSuccess: false)
        }
    }

    private func share() async {
        guard let uiImage, let data = uiImage.jpegData(compressionQuality: 0.95) else { return }
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        do {
            try data.write(to: tmp)
            shareURL = tmp
            isSharing = true
        } catch {
            print("share write error:", error)
            showToast("Paylaşım hatası", isSuccess: false)
        }
    }
    
    @MainActor
    private func showToast(_ message: String, isSuccess: Bool) {
        toastMessage = ToastMessage(message: message, isSuccess: isSuccess)
        
        // 2 saniye sonra kaldır
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation {
                toastMessage = nil
            }
        }
    }
}

struct ToastMessage: Identifiable {
    let id = UUID()
    let message: String
    let isSuccess: Bool
}

struct ZoomableImage: View {
    let image: Image
    @Binding var scale: CGFloat
    
    var body: some View {
        image
            .resizable()
            .scaledToFit()
            .scaleEffect(scale)
            .gesture(
                MagnificationGesture()
                    .onChanged { scale = max(1, $0) }
                    .onEnded { _ in withAnimation { scale = max(1, scale) } }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
