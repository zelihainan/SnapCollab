//
//  MediaGridToolbarContent.swift
//  SnapCollab
//
//  Simplified toolbar content for MediaGrid - only add photo button
//

import SwiftUI
import PhotosUI

struct MediaGridToolbarContent: ToolbarContent {
    @ObservedObject var vm: MediaViewModel
    @ObservedObject var state: MediaGridState
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if shouldShowAddButton {
                PhotosPicker(selection: $state.pickerItem, matching: .images) {
                    Image(systemName: "plus")
                        .font(.title2)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var shouldShowAddButton: Bool {
        vm.currentFilter != .favorites
    }
}
