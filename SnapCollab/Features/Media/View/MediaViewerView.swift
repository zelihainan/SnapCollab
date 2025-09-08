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

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Group {
                if let uiImage {
                    ZoomableImage(image: Image(uiImage: uiImage), scale: $scale)
                } else if loadFailed {
                    errorPlaceholder
                } else {
                    ProgressView().tint(.white)
                        .task { await loadImage() }
                }
            }

            VStack {
                HStack(spacing: 20) {
                    Button { onClose() } label: {
                        Image(systemName: "xmark").font(.title2).foregroundStyle(.white)
                    }
                    Spacer()
                    Button { Task { await saveToPhotos() } } label: {
                        Image(systemName: "square.and.arrow.down").font(.title2).foregroundStyle(.white)
                    }
                    Button { Task { await share() } } label: {
                        Image(systemName: "square.and.arrow.up").font(.title2).foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 16).padding(.top, 12)
                Spacer()
            }
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


    private func loadImage() async {
        do {
            guard let url = await vm.imageURL(for: item) else {
                loadFailed = true; return
            }
            let (data, _) = try await URLSession.shared.data(from: url)
            if let img = UIImage(data: data) {
                await MainActor.run { self.uiImage = img }
            } else {
                await MainActor.run { self.loadFailed = true }
            }
        } catch {
            print("viewer load error:", error)
            await MainActor.run { self.loadFailed = true }
        }
    }

    private var errorPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark").font(.largeTitle).foregroundStyle(.white)
            Text("Görsel yüklenemedi").foregroundStyle(.white.opacity(0.8))
            Button("Kapat") { onClose() }
                .buttonStyle(.borderedProminent)
        }
    }

    private func saveToPhotos() async {
        guard let uiImage else { return }
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .notDetermined {
            _ = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        }
        UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
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
        } catch { print("share write error:", error) }
    }
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
