//
//  MediaGridEmptyState.swift
//  SnapCollab
//
//

import SwiftUI

struct MediaGridEmptyState: View {
    let currentFilter: MediaViewModel.MediaFilter
    let favoritesCount: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(color)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if shouldShowFavoritesTip {
                favoritesTipView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    
    private var favoritesTipView: some View {
        VStack(spacing: 12) {
            Text("İpucu")
                .font(.headline)
                .foregroundStyle(.blue)
            
            Text("Fotoğrafları favorilere eklemek için kalp simgesine dokunun")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 16)
    }
        
    private var shouldShowFavoritesTip: Bool {
        currentFilter == .favorites && favoritesCount == 0
    }
    
    private var icon: String {
        switch currentFilter {
        case .all: return "photo.stack"
        case .photos: return "photo"
        case .videos: return "video"
        case .favorites: return "heart"
        }
    }
    
    private var color: Color {
        switch currentFilter {
        case .all: return .blue
        case .photos: return .blue
        case .videos: return .green
        case .favorites: return .red
        }
    }
    
    private var title: String {
        switch currentFilter {
        case .all: return "Henüz içerik yok"
        case .photos: return "Henüz fotoğraf yok"
        case .videos: return "Henüz video yok"
        case .favorites: return "Henüz favori yok"
        }
    }
    
    private var message: String {
        switch currentFilter {
        case .all: return "Bu albüme henüz fotoğraf veya video eklenmemiş. Sağ üstteki '+' butonuna tıklayarak içerik ekleyebilirsiniz."
        case .photos: return "Bu albümde henüz fotoğraf bulunmuyor. Sağ üstteki '+' butonuna tıklayarak fotoğraf ekleyebilirsiniz."
        case .videos: return "Bu albümde henüz video bulunmuyor. Video yükleme özelliği yakında eklenecek."
        case .favorites: return "Henüz hiçbir fotoğrafı favorilere eklememişsiniz. Fotoğraflarda kalp simgesine tıklayarak favori ekleyebilirsiniz."
        }
    }
}
