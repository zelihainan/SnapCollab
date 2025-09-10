//
//  MediaGridToolbarContent.swift
//  SnapCollab
//
//  Toolbar content for MediaGrid
//

import SwiftUI
import PhotosUI

struct MediaGridToolbarContent: ToolbarContent {
    @ObservedObject var vm: MediaViewModel
    @ObservedObject var state: MediaGridState
    
    var body: some ToolbarContent {
        // Leading toolbar items
        ToolbarItem(placement: .navigationBarLeading) {
            if state.isSelecting {
                selectionModeToolbar
            } else {
                normalModeToolbar
            }
        }
        
        // Trailing toolbar items
        ToolbarItem(placement: .navigationBarTrailing) {
            if !state.isSelecting {
                trailingToolbarItems
            }
        }
    }
    
    // MARK: - Selection Mode Toolbar
    
    private var selectionModeToolbar: some View {
        HStack(spacing: 16) {
            Button("İptal") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    state.resetSelection()
                }
            }
            
            Button(selectAllButtonTitle) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    if state.selectedItems.count == vm.filteredItems.count {
                        state.deselectAll()
                    } else {
                        state.selectAll(items: vm.filteredItems)
                    }
                }
            }
            .disabled(vm.filteredItems.isEmpty)
        }
    }
    
    // MARK: - Normal Mode Toolbar
    
    private var normalModeToolbar: some View {
        Button("Seç") {
            withAnimation(.easeInOut(duration: 0.3)) {
                state.isSelecting = true
            }
        }
        .disabled(vm.filteredItems.isEmpty)
    }
    
    // MARK: - Trailing Toolbar Items
    
    private var trailingToolbarItems: some View {
        HStack(spacing: 12) {
            MediaGridSortMenu(currentSort: $state.currentSort)
            
            if shouldShowAddButton {
                PhotosPicker(selection: $state.pickerItem, matching: .images) {
                    Image(systemName: "plus")
                        .font(.title2)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var selectAllButtonTitle: String {
        state.selectedItems.count == vm.filteredItems.count ? "Hiçbirini Seç" : "Tümünü Seç"
    }
    
    private var shouldShowAddButton: Bool {
        vm.currentFilter != .favorites
    }
}

// MARK: - Sort Menu Component
struct MediaGridSortMenu: View {
    @Binding var currentSort: MediaViewModel.SortType
    
    var body: some View {
        Menu {
            Picker("Sıralama", selection: $currentSort) {
                sortOption(icon: "clock.arrow.2.circlepath", title: "En Yeni", type: .newest)
                sortOption(icon: "clock", title: "En Eski", type: .oldest)
                sortOption(icon: "person", title: "Yükleyiciye Göre", type: .uploader)
                sortOption(icon: "heart.fill", title: "Favoriler Önce", type: .favorites)
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.body)
        }
    }
    
    private func sortOption(icon: String, title: String, type: MediaViewModel.SortType) -> some View {
        HStack {
            Image(systemName: icon)
            Text(title)
        }.tag(type)
    }
}
