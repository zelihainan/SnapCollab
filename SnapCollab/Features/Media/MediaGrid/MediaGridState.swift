//
//  MediaGridState.swift
//  SnapCollab
//
//  Simplified state management for MediaGrid - no selection mode
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
    
    // MARK: - Delete
    @Published var showDeleteAlert = false
    @Published var itemToDelete: MediaItem?
    
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
}
