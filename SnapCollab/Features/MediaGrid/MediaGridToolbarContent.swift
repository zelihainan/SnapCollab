//
//  MediaGridToolbarContent.swift
//  SnapCollab

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
        
    private var shouldShowAddButton: Bool {
        vm.currentFilter != .favorites
    }
}
