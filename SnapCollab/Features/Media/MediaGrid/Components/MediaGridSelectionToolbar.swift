//
//  MediaGridSelectionToolbar.swift
//  SnapCollab
//
//  Selection toolbar component for MediaGrid
//

import SwiftUI

struct MediaGridSelectionToolbar: View {
    @ObservedObject var state: MediaGridState
    @ObservedObject var vm: MediaViewModel
    
    var body: some View {
        HStack {
            Text("\(state.selectedItems.count) öğe seçildi")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            if !state.selectedItems.isEmpty {
                selectionStatsView
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Private Views
    
    private var selectionStatsView: some View {
        HStack(spacing: 4) {
            let stats = state.getSelectionStats(vm: vm)
            
            if stats.favoriteCount > 0 {
                favoriteStatsView(count: stats.favoriteCount)
            }
            
            if stats.nonFavoriteCount > 0 {
                if stats.favoriteCount > 0 {
                    separatorView
                }
                nonFavoriteStatsView(count: stats.nonFavoriteCount)
            }
        }
        .font(.caption)
    }
    
    private func favoriteStatsView(count: Int) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "heart.fill")
                .foregroundStyle(.red)
            Text("\(count)")
                .foregroundStyle(.red)
        }
    }
    
    private func nonFavoriteStatsView(count: Int) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "heart")
                .foregroundStyle(.secondary)
            Text("\(count)")
                .foregroundStyle(.secondary)
        }
    }
    
    private var separatorView: some View {
        Text("•")
            .foregroundStyle(.secondary)
    }
}
