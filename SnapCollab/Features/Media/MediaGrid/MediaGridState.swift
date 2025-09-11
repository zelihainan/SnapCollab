//
//  MediaGridState.swift
//  SnapCollab
//
//  Video desteği eklendi
//

import SwiftUI
import PhotosUI

@MainActor
final class MediaGridState: ObservableObject {
    // MARK: - Media Picker
    @Published var showMediaPicker = false
    @Published var selectedImage: UIImage?
    @Published var selectedVideoURL: URL?
    
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
    
    // MARK: - Media Picker Methods
    
    func resetMediaSelection() {
        selectedImage = nil
        selectedVideoURL = nil
        showMediaPicker = false
    }
}
