//
//  MediaGridView.swift - Tüm Toplu İşlemler İle Güncellenmiş
//  SnapCollab
//

import SwiftUI

struct MediaGridView: View {
    @ObservedObject var vm: MediaViewModel
    @StateObject private var gridState = MediaGridState()
    @State private var showBulkDownloadSheet = false
    
    var body: some View {
        ZStack {
            MediaGridContainer(vm: vm, state: gridState)
            
            // Seçim modu için floating action button
            if vm.isSelectionMode && vm.selectedItemsCount > 0 {
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        FloatingActionMenu(
                            selectedCount: vm.selectedItemsCount,
                            canDelete: vm.canDeleteSelected,
                            onFavoriteAdd: {
                                vm.addSelectedToFavorites()
                            },
                            onFavoriteRemove: {
                                vm.removeSelectedFromFavorites()
                            },
                            onDownload: {
                                showBulkDownloadSheet = true
                            },
                            onDelete: {
                                gridState.showBulkDeleteAlert = true
                            },
                            currentFilter: vm.currentFilter
                        )
                        .padding(.trailing, 20)
                        .padding(.bottom, 100) // Tab bar için boşluk
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.isSelectionMode)
            }
        }
        .task {
            vm.start()
        }
        .sheet(isPresented: $showBulkDownloadSheet) {
            BulkDownloadSheet(
                selectedItems: vm.filteredItems.filter { vm.selectedItems.contains($0.id ?? "") },
                mediaRepo: vm.repo
            )
        }
    }
}

struct FloatingActionMenu: View {
    let selectedCount: Int
    let canDelete: Bool
    let onFavoriteAdd: () -> Void
    let onFavoriteRemove: () -> Void
    let onDownload: () -> Void
    let onDelete: () -> Void
    let currentFilter: MediaViewModel.MediaFilter
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 16) {
            if isExpanded {
                // Action buttons
                VStack(spacing: 12) {
                    // Favorilere ekle/çıkar
                    if currentFilter == .favorites {
                        FloatingActionButton(
                            icon: "heart.slash.fill",
                            title: "Favorilerden Çıkar",
                            color: .orange,
                            action: onFavoriteRemove
                        )
                    } else {
                        FloatingActionButton(
                            icon: "heart.fill",
                            title: "Favorilere Ekle",
                            color: .red,
                            action: onFavoriteAdd
                        )
                    }
                    
                    // İndir
                    FloatingActionButton(
                        icon: "arrow.down.to.line",
                        title: "Galeriye İndir",
                        color: .green,
                        action: onDownload
                    )
                    
                    // Sil (sadece izin varsa)
                    if canDelete {
                        FloatingActionButton(
                            icon: "trash.fill",
                            title: "Sil",
                            color: .red,
                            action: onDelete
                        )
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Ana button
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: isExpanded ? "xmark" : "ellipsis")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    
                    if !isExpanded {
                        Text("\(selectedCount)")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: isExpanded ? 56 : 80, height: 56)
                .background(
                    Capsule()
                        .fill(.blue)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
    }
}

struct FloatingActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(color)
                    .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

//
//  MediaGridScrollView.swift - Son güncelleme
//  SnapCollab
//

struct MediaGridScrollView: View {
    @ObservedObject var vm: MediaViewModel
    @ObservedObject var state: MediaGridState
    let geometry: GeometryProxy
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Seçim modu header'ı
                if vm.isSelectionMode {
                    SelectionModeHeader(vm: vm)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
                
                regularGrid
            }
            .padding(.top, vm.isSelectionMode ? 16 : 8)
        }
        .refreshable {
            await refreshData()
        }
    }
    
    private var regularGrid: some View {
        let sortedItems = vm.sortedItems(by: .newest)
        
        return PinterestGrid(
            items: sortedItems,
            spacing: 8,
            columns: 2,
            containerWidth: geometry.size.width
        ) { item in
            EnhancedMediaGridCard(
                vm: vm,
                item: item,
                onTap: {
                    if !vm.isSelectionMode {
                        state.openViewer(with: item)
                    }
                },
                onDelete: { item in
                    state.showDeleteConfirmation(for: item)
                }
            )
        }
        .padding(.horizontal, 12)
    }
    
    private func refreshData() async {
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
}

struct SelectionModeHeader: View {
    @ObservedObject var vm: MediaViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Seçim Modu")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button("Tümünü Seç") {
                    vm.selectAllVisibleItems()
                }
                .font(.subheadline)
                .foregroundStyle(.blue)
            }
            
            HStack {
                Text("\(vm.selectedItemsCount) öğe seçili")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if vm.selectedItemsCount > 0 {
                    Button("Seçimi Temizle") {
                        vm.clearSelection()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.blue.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.blue.opacity(0.2), lineWidth: 1)
        )
    }
}
