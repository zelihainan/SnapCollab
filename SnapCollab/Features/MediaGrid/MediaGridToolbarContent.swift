//
//  MediaGridToolbarContent.swift
//  SnapCollab

import SwiftUI
import PhotosUI

struct MediaGridToolbarContent: ToolbarContent {
    @ObservedObject var vm: MediaViewModel
    @ObservedObject var state: MediaGridState
    
    var body: some ToolbarContent {
        if vm.isSelectionMode {
            // Seçim modu toolbar'ı
            ToolbarItem(placement: .navigationBarLeading) {
                Button("İptal") {
                    vm.toggleSelectionMode()
                }
                .foregroundStyle(.red)
            }
            
            ToolbarItem(placement: .principal) {
                Text("\(vm.selectedItemsCount) seçili")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    selectionModeMenuItems
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                }
                .disabled(vm.selectedItemsCount == 0)
            }
        } else {
            // Normal mod toolbar'ı
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Seçim modu butonu
                    Button(action: {
                        vm.toggleSelectionMode()
                    }) {
                        Image(systemName: "checkmark.circle")
                            .font(.title2)
                    }
                    .opacity(vm.filteredItems.isEmpty ? 0 : 1)
                    
                    // Ekleme butonu
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
        }
    }
    
    @ViewBuilder
    private var selectionModeMenuItems: some View {
        if vm.selectedItemsCount > 0 {
            Button(action: {
                vm.selectAllVisibleItems()
            }) {
                Label("Tümünü Seç", systemImage: "checkmark.square")
            }
            
            Divider()
            
            Button(action: {
                vm.addSelectedToFavorites()
            }) {
                Label("Favorilere Ekle", systemImage: "heart")
            }
            
            if vm.currentFilter == .favorites {
                Button(action: {
                    vm.removeSelectedFromFavorites()
                }) {
                    Label("Favorilerden Çıkar", systemImage: "heart.slash")
                }
            }
            
            Divider()
            
            if vm.canDeleteSelected {
                Button(role: .destructive, action: {
                    state.showBulkDeleteAlert = true
                }) {
                    Label("Sil (\(vm.selectedItemsCount))", systemImage: "trash")
                }
            }
        } else {
            Button(action: {
                vm.selectAllVisibleItems()
            }) {
                Label("Tümünü Seç", systemImage: "checkmark.square")
            }
        }
    }
        
    private var shouldShowAddButton: Bool {
        vm.currentFilter != .favorites
    }
}
