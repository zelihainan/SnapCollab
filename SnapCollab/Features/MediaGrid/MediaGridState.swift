
//  MediaGridState.swift - Toplu İşlemler İçin Güncellenmiş
//  SnapCollab
//

import SwiftUI
import PhotosUI

@MainActor
final class MediaGridState: ObservableObject {
    @Published var showMediaPicker = false
    @Published var selectedImage: UIImage?
    @Published var selectedVideoURL: URL?
    @Published var selectedPhotos: [PhotosPickerItem] = [] // Yeni: Çoklu fotoğraf
    @Published var selectedItem: MediaItem?
    @Published var showViewer = false
    @Published var showDeleteAlert = false
    @Published var itemToDelete: MediaItem?
    @Published var showBulkDeleteAlert = false // Yeni: Toplu silme alert'i
    @Published var showBulkUploadProgress = false // Yeni: Çoklu yükleme progress'i
    
    
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
        
    func showDeleteConfirmation(for item: MediaItem) {
        itemToDelete = item
        showDeleteAlert = true
    }
    
    func cancelDelete() {
        itemToDelete = nil
        showDeleteAlert = false
    }
    
    func cancelBulkDelete() {
        showBulkDeleteAlert = false
    }
        
    func resetMediaSelection() {
        selectedImage = nil
        selectedVideoURL = nil
        selectedPhotos = []
        showMediaPicker = false
    }
}
