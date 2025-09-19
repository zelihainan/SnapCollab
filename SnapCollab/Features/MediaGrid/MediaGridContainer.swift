import SwiftUI
import PhotosUI

struct MediaGridContainer: View {
    @ObservedObject var vm: MediaViewModel
    @ObservedObject var state: MediaGridState
    
    var body: some View {
        ZStack {
            mainContent
            if vm.isProcessingBulkUpload { bulkUploadProgressOverlay }
        }
        .toolbar { MediaGridToolbarContent(vm: vm, state: state) }
        .sheet(isPresented: $state.showMediaPicker) { mediaPicker }
        .onChange(of: state.selectedImage, perform: handleImageSelection(_:))
        .onChange(of: state.selectedVideoURL, perform: handleVideoSelection(_:))
        .onChange(of: state.selectedPhotos, perform: handleBulkPhotoSelection(_:))
        .fullScreenCover(isPresented: $state.showViewer, onDismiss: { state.closeViewer() }) {
            if let selectedItem = state.selectedItem {
                MediaViewerView(vm: vm, initialItem: selectedItem) {
                    state.closeViewer()
                }
            }
        }
        .alert("Medyayı Sil", isPresented: $state.showDeleteAlert) {
            Button("Vazgeç", role: .cancel) { state.itemToDelete = nil }
            Button("Sil", role: .destructive) {
                if let item = state.itemToDelete {
                    Task { try? await vm.deletePhoto(item) }
                }
                state.itemToDelete = nil
            }
        } message: {
            if let item = state.itemToDelete {
                Text("Bu \(item.isVideo ? "videoyu" : "fotoğrafı") kalıcı olarak silmek istediğinizden emin misiniz?")
            }
        }
        .alert("Seçili Öğeleri Sil", isPresented: $state.showBulkDeleteAlert) {
            Button("Vazgeç", role: .cancel) { }
            Button("Sil", role: .destructive) {
                Task { try? await vm.deleteSelectedItems() }
            }
        } message: {
            Text("\(vm.selectedItemsCount) öğeyi kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.")
        }
        .onChange(of: vm.selectedItems) { selectedItems in
            // Hiç seçim kalmadığında otomatik çıkış
            if selectedItems.isEmpty && vm.isSelectionMode {
                withAnimation(.easeInOut(duration: 0.3)) {
                    vm.isSelectionMode = false
                }
            }
        }
    }

    // MARK: - Pieces split out to reduce type-checking load
    @ViewBuilder
    private var mainContent: some View {
        GeometryReader { geometry in
            if vm.filteredItems.isEmpty {
                MediaGridEmptyState(
                    currentFilter: vm.currentFilter,
                    favoritesCount: vm.favoritesCount
                )
            } else {
                MediaGridScrollView(vm: vm, state: state, geometry: geometry)
            }
        }
    }

    @ViewBuilder
    private var mediaPicker: some View {
        MediaPickerSheet(
            isPresented: $state.showMediaPicker,
            selectedImage: $state.selectedImage,
            selectedVideoURL: $state.selectedVideoURL,
            selectedPhotos: $state.selectedPhotos,
            currentFilter: vm.currentFilter
        )
    }

    // MARK: - Bulk upload overlay
    private var bulkUploadProgressOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.3), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    Circle()
                        .trim(from: 0, to: vm.bulkUploadProgress)
                        .stroke(.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 80, height: 80)
                        .animation(.easeInOut, value: vm.bulkUploadProgress)
                    Text("\(Int(vm.bulkUploadProgress * 100))%")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                VStack(spacing: 8) {
                    Text("Fotoğraflar Yükleniyor")
                        .font(.title2).fontWeight(.semibold)
                        .foregroundStyle(.white)
                    Text(vm.uploadStatus)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    if vm.totalUploadCount > 0 {
                        Text("\(vm.uploadedCount) / \(vm.totalUploadCount)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Handlers
    private func handleImageSelection(_ image: UIImage?) {
        guard let image = image else { return }
        vm.pickedImage = image
        Task { await vm.uploadPicked() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { state.resetMediaSelection() }
    }

    private func handleVideoSelection(_ videoURL: URL?) {
        guard let videoURL = videoURL else { return }
        vm.pickedVideoURL = videoURL
        Task { await vm.uploadPicked() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { state.resetMediaSelection() }
    }

    private func handleBulkPhotoSelection(_ photos: [PhotosPickerItem]) {
        guard !photos.isEmpty else { return }
        vm.selectedPhotos = photos
        Task { await vm.processBulkPhotoUpload() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { state.resetMediaSelection() }
    }
}
