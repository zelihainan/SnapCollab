//
//  EnhancedMediaGridCard.swift
//  SnapCollab
//
//

import SwiftUI

struct EnhancedMediaGridCard: View {
    @ObservedObject var vm: MediaViewModel
    let item: MediaItem
    let onTap: () -> Void
    let onDelete: ((MediaItem) -> Void)?
    
    @State private var showHeartParticles = false
    @State private var heartScale: CGFloat = 1.0
    
    private var isFavorite: Bool {
        guard let itemId = item.id else { return false }
        return vm.isFavorite(itemId)
    }
    
    private var isAnimating: Bool {
        guard let itemId = item.id else { return false }
        return vm.isAnimating(itemId)
    }
    
    private var canDelete: Bool {
        return item.uploaderId == vm.auth.uid
    }
    
    var body: some View {
        ZStack {
            if item.isVideo {
                AsyncImageView(pathProvider: { await vm.imageURL(for: item) })
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
                    .overlay(
                        VStack {
                            Spacer()
                            
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.white)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.6))
                                            .frame(width: 36, height: 36)
                                    )
                                
                                Spacer()
                            }
                            .padding(8)
                        }
                    )
                    .onTapGesture {
                        onTap()
                    }
                    .onTapGesture(count: 2) {
                        doubleTapToFavorite()
                    }
                    .contextMenu {
                        contextMenuItems
                    }
            } else {
                AsyncImageView(pathProvider: { await vm.imageURL(for: item) })
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
                    .onTapGesture {
                        onTap()
                    }
                    .onTapGesture(count: 2) {
                        doubleTapToFavorite()
                    }
                    .contextMenu {
                        contextMenuItems
                    }
            }
                VStack {
                HStack {
                    Spacer()
                    
                    Button(action: toggleFavorite) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .environment(\.colorScheme, .light)
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(isFavorite ? Color.red : Color.white)
                                .scaleEffect(heartScale)
                                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isFavorite)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(isAnimating ? 1.3 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isAnimating)
                }
                Spacer()
            }
            .padding(8)
            
            if showHeartParticles {
                HeartParticlesView()
                    .allowsHitTesting(false)
            }
            
            if isAnimating && isFavorite {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(Color.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 4)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isAnimating)
            }
        }
        .hoverEffect(.lift)
        .onChange(of: isFavorite) { newValue in
            if newValue {
                triggerHeartAnimation()
            }
        }
    }
        
    @ViewBuilder
    private var contextMenuItems: some View {
        Button(action: toggleFavorite) {
            Label(isFavorite ? "Favorilerden Çıkar" : "Favorilere Ekle",
                  systemImage: isFavorite ? "heart.slash" : "heart.fill")
        }
        
        Button(action: shareMedia) {
            Label("Paylaş", systemImage: "square.and.arrow.up")
        }
        
        if !item.isVideo {
            Button(action: saveToPhotos) {
                Label("Galeriye Kaydet", systemImage: "arrow.down.to.line")
            }
        }
        
        if canDelete {
            Divider()
            Button(role: .destructive, action: { onDelete?(item) }) {
                Label("Sil", systemImage: "trash")
            }
        }
    }
   
    private func toggleFavorite() {
        guard let itemId = item.id else { return }
        vm.toggleFavorite(itemId)
        triggerHeartAnimation()
    }
    
    private func doubleTapToFavorite() {
        guard let itemId = item.id else { return }
        if !isFavorite {
            vm.toggleFavorite(itemId)
            triggerHeartAnimation()
        }
    }
    
    private func triggerHeartAnimation() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            heartScale = 1.3
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                heartScale = 1.0
            }
        }
        
        if isFavorite {
            showHeartParticles = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showHeartParticles = false
            }
        }
    }
    
    private func shareMedia() {
        print("Share media: \(item.id ?? "")")
        // TODO: Media paylaşma implementasyonu
    }
    
    private func saveToPhotos() {
        print("Save to photos: \(item.id ?? "")")
        // TODO: Fotoğraf galeriye kaydetme implementasyonu
    }
}
