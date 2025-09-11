//
//  MediaGridContainer.swift
//  SnapCollab
//
//  Video desteği eklendi
//

import SwiftUI
import PhotosUI

struct MediaGridContainer: View {
    @ObservedObject var vm: MediaViewModel
    @ObservedObject var state: MediaGridState
    
    var body: some View {
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
        .toolbar {
            MediaGridToolbarContent(vm: vm, state: state)
        }
        .sheet(isPresented: $state.showMediaPicker) {
            MediaPickerSheet(
                isPresented: $state.showMediaPicker,
                selectedImage: $state.selectedImage,
                selectedVideoURL: $state.selectedVideoURL
            )
        }
        .onChange(of: state.selectedImage) { newImage in
            handleImageSelection(newImage)
        }
        .onChange(of: state.selectedVideoURL) { newVideoURL in
            handleVideoSelection(newVideoURL)
        }
        .fullScreenCover(isPresented: $state.showViewer) {
            state.closeViewer()
        } content: {
            if let selectedItem = state.selectedItem {
                MediaViewerView(vm: vm, initialItem: selectedItem) {
                    state.closeViewer()
                }
            }
        }
        .alert("Medyayı Sil", isPresented: $state.showDeleteAlert) {
            MediaGridDeleteAlert(state: state, vm: vm)
        } message: {
            if let item = state.itemToDelete {
                Text("Bu \(item.isVideo ? "videoyu" : "fotoğrafı") kalıcı olarak silmek istediğinizden emin misiniz?")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleImageSelection(_ image: UIImage?) {
        guard let image = image else { return }
        
        vm.pickedImage = image
        Task {
            await vm.uploadPicked()
        }
        
        // Reset selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            state.resetMediaSelection()
        }
    }
    
    private func handleVideoSelection(_ videoURL: URL?) {
        guard let videoURL = videoURL else { return }
        
        vm.pickedVideoURL = videoURL
        Task {
            await vm.uploadPicked()
        }
        
        // Reset selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            state.resetMediaSelection()
        }
    }
}

// MARK: - Scroll View Component
struct MediaGridScrollView: View {
    @ObservedObject var vm: MediaViewModel
    @ObservedObject var state: MediaGridState
    let geometry: GeometryProxy
    
    var body: some View {
        ScrollView {
            regularGrid
        }
        .refreshable {
            await refreshData()
        }
    }
    
    private var regularGrid: some View {
        let sortedItems = vm.sortedItems(by: .newest)
        
        return PinterestGrid(
            items: sortedItems,
            spacing: 8,
            columns: 2,
            containerWidth: geometry.size.width
        ) { item in
            EnhancedMediaGridCard(
                vm: vm,
                item: item,
                onTap: {
                    state.openViewer(with: item)
                },
                onDelete: { item in
                    state.showDeleteConfirmation(for: item)
                }
            )
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }
    
    private func refreshData() async {
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
}

// MARK: - Delete Alert Component
struct MediaGridDeleteAlert: View {
    @ObservedObject var state: MediaGridState
    @ObservedObject var vm: MediaViewModel
    
    var body: some View {
        Group {
            Button("İptal", role: .cancel) {
                state.cancelDelete()
            }
            
            Button("Sil", role: .destructive) {
                if let item = state.itemToDelete {
                    Task {
                        do {
                            try await vm.deletePhoto(item)
                        } catch {
                            print("Delete error: \(error)")
                        }
                        state.cancelDelete()
                    }
                }
            }
        }
    }
}
