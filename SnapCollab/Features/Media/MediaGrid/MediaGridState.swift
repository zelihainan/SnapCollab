//
//  MediaGridState.swift
//  SnapCollab
//
//  State management for MediaGrid
//

import SwiftUI
import PhotosUI

@MainActor
final class MediaGridState: ObservableObject {
    // MARK: - Photo Picker
    @Published var pickerItem: PhotosPickerItem?
    
    // MARK: - Viewer
    @Published var selectedItem: MediaItem?
    @Published var showViewer = false
    
    // MARK: - Selection Mode
    @Published var isSelecting = false
    @Published var selectedItems: Set<String> = []
    
    // MARK: - Sorting
    @Published var currentSort: MediaViewModel.SortType = .newest
    
    // MARK: - Delete
    @Published var showDeleteAlert = false
    @Published var itemToDelete: MediaItem?
    
    // MARK: - Selection Methods
    
    func resetSelection() {
        isSelecting = false
        selectedItems.removeAll()
    }
    
    func toggleSelection(for itemId: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedItems.contains(itemId) {
                selectedItems.remove(itemId)
            } else {
                selectedItems.insert(itemId)
            }
        }
    }
    
    func selectAll(items: [MediaItem]) {
        selectedItems = Set(items.compactMap { $0.id })
    }
    
    func deselectAll() {
        selectedItems.removeAll()
    }
    
    func isSelected(_ itemId: String) -> Bool {
        selectedItems.contains(itemId)
    }
    
    // MARK: - Viewer Methods
    
    func openViewer(with item: MediaItem) {
        selectedItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showViewer = true
        }
    }
    
    func closeViewer() {
        showViewer = false
        selectedItem = nil
    }
    
    // MARK: - Delete Methods
    
    func showDeleteConfirmation(for item: MediaItem) {
        itemToDelete = item
        showDeleteAlert = true
    }
    
    func cancelDelete() {
        itemToDelete = nil
        showDeleteAlert = false
    }
    
    // MARK: - Selection Statistics
    
    func getSelectionStats(vm: MediaViewModel) -> (favoriteCount: Int, nonFavoriteCount: Int) {
        let favoriteCount = selectedItems.filter { vm.isFavorite($0) }.count
        let nonFavoriteCount = selectedItems.count - favoriteCount
        return (favoriteCount, nonFavoriteCount)
    }
}
