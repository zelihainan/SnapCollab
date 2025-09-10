//
//  MediaGridContainer.swift
//  SnapCollab
//
//  Main container for MediaGrid
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
                VStack(spacing: 0) {
                    if state.isSelecting {
                        MediaGridSelectionToolbar(state: state, vm: vm)
                    }
                    
                    MediaGridScrollView(vm: vm, state: state, geometry: geometry)
                    
                    if state.isSelecting {
                        VStack {
                            Spacer()
                            MediaGridBatchActions(vm: vm, state: state)
                                .padding(.bottom, 20)
                        }
                        .transition(.move(edge: .bottom))
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(state.isSelecting)
        .toolbar {
            MediaGridToolbarContent(vm: vm, state: state)
        }
        .onChange(of: state.pickerItem) { newValue in
            handleImagePicker(newValue)
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
        .alert("Fotoğrafı Sil", isPresented: $state.showDeleteAlert) {
            MediaGridDeleteAlert(state: state, vm: vm)
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleImagePicker(_ pickerItem: PhotosPickerItem?) {
        guard let pickerItem = pickerItem else { return }
        
        Task {
            if let data = try? await pickerItem.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                vm.pickedImage = img
                await vm.uploadPicked()
            }
            await MainActor.run {
                state.pickerItem = nil
            }
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
            if state.isSelecting {
                selectableGrid
            } else {
                regularGrid
            }
        }
        .refreshable {
            await refreshData()
        }
    }
    
    private var regularGrid: some View {
        let sortedItems = vm.sortedItems(by: state.currentSort)
        
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
    
    private var selectableGrid: some View {
        let sortedItems = vm.sortedItems(by: state.currentSort)
        
        return PinterestGrid(
            items: sortedItems,
            spacing: 8,
            columns: 2,
            containerWidth: geometry.size.width
        ) { item in
            SelectableMediaCard(
                vm: vm,
                item: item,
                isSelected: state.isSelected(item.id ?? ""),
                onSelection: { itemId in
                    state.toggleSelection(for: itemId)
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
