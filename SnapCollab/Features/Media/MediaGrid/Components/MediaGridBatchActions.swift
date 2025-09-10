//
//  MediaGridBatchActions.swift
//  SnapCollab
//
//  Batch actions component for MediaGrid selection mode
//

import SwiftUI

struct MediaGridBatchActions: View {
    @ObservedObject var vm: MediaViewModel
    @ObservedObject var state: MediaGridState
    
    var body: some View {
        if !state.selectedItems.isEmpty {
            actionButtonsView
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    // MARK: - Private Views
    
    private var actionButtonsView: some View {
        HStack(spacing: 16) {
            let stats = state.getSelectionStats(vm: vm)
            
            if stats.nonFavoriteCount > 0 {
                addToFavoritesButton(count: stats.nonFavoriteCount)
            }
            
            if stats.favoriteCount > 0 {
                removeFromFavoritesButton(count: stats.favoriteCount)
            }
        }
    }
    
    private func addToFavoritesButton(count: Int) -> some View {
        Button {
            performAddToFavorites()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                Text("Favorile (\(count))")
            }
            .foregroundStyle(.red)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(.red.opacity(0.1)))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func removeFromFavoritesButton(count: Int) -> some View {
        Button {
            performRemoveFromFavorites()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "heart.slash")
                Text("Favoriden Çıkar (\(count))")
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(.secondary.opacity(0.1)))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Actions
    
    private func performAddToFavorites() {
        let itemsToAdd = Array(state.selectedItems.filter { !vm.isFavorite($0) })
        vm.addMultipleToFavorites(itemsToAdd)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            state.resetSelection()
        }
    }
    
    private func performRemoveFromFavorites() {
        let itemsToRemove = Array(state.selectedItems.filter { vm.isFavorite($0) })
        vm.removeMultipleFromFavorites(itemsToRemove)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            state.resetSelection()
        }
    }
}
