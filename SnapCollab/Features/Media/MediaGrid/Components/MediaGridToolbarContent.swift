//
//  MediaGridToolbarContent.swift
//  SnapCollab
//
//

import SwiftUI
import PhotosUI

struct MediaGridToolbarContent: ToolbarContent {
    @ObservedObject var vm: MediaViewModel
    @ObservedObject var state: MediaGridState
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if shouldShowAddButton {
                Button(action: {
                    state.showMediaPicker = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var shouldShowAddButton: Bool {
        // Favorites filtresi dışında her yerde göster
        vm.currentFilter != .favorites
    }
}
