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
            // Seçim modu toolbar'ı - iPhone Galerisi gibi
            ToolbarItem(placement: .principal) {
                Text(vm.selectedItemsCount == 0 ? "Öğe Seç" : "\(vm.selectedItemsCount) Seçili")
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
                    // Seçim modu butonu - sadece fotoğraf varsa göster
                    if !vm.filteredItems.isEmpty {
                        Button("Seç") {
                            vm.toggleSelectionMode()
                        }
                        .foregroundStyle(.blue)
                    }
                    
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
            
            Button(action: {
                state.showBulkDownloadSheet = true
            }) {
                Label("Galeriye Kaydet", systemImage: "arrow.down.to.line")
            }
            
            if vm.canDeleteSelected {
                Divider()
                
                Button(role: .destructive, action: {
                    state.showBulkDeleteAlert = true
                }) {
                    Label("Sil", systemImage: "trash")
                }
            }
        }
    }
        
    private var shouldShowAddButton: Bool {
        vm.currentFilter != .favorites
    }
}
