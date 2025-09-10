//
//  EnhancedMediaGridCard.swift
//  SnapCollab
//
//  Enhanced media card with iPhone-like interactions
//

import SwiftUI

struct EnhancedMediaGridCard: View {
    @ObservedObject var vm: MediaViewModel
    let item: MediaItem
    let onTap: () -> Void
    let onDelete: ((MediaItem) -> Void)?
    
    @State private var uploaderUser: User?
    @State private var isLoadingUser = false
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
        VStack(spacing: 0) {
            // Photo Container
            ZStack {
                // Main Image
                AsyncImageView(pathProvider: { await vm.imageURL(for: item) })
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
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
                
                // Heart Button
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
                                    .foregroundStyle(isFavorite ? .red : .white)
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
                
                // Heart Particles
                if showHeartParticles {
                    HeartParticlesView()
                        .allowsHitTesting(false)
                }
                
                // Double-tap heart overlay
                if isAnimating && isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4)
                        .scaleEffect(isAnimating ? 1.0 : 0.5)
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isAnimating)
                }
            }
            .hoverEffect(.lift)
            
            // User Info Footer
            userInfoFooter
        }
        .onAppear {
            loadUploaderInfo()
        }
        .onChange(of: isFavorite) { newValue in
            if newValue {
                triggerHeartAnimation()
            }
        }
    }
    
    // MARK: - Views
    
    private var userInfoFooter: some View {
        HStack(spacing: 8) {
            // Profile Photo
            if isLoadingUser {
                Circle()
                    .fill(.secondary.opacity(0.3))
                    .frame(width: 24, height: 24)
                    .overlay {
                        ProgressView().scaleEffect(0.6)
                    }
            } else if let photoURL = uploaderUser?.photoURL, !photoURL.isEmpty {
                AsyncImage(url: URL(string: photoURL)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    defaultAvatar
                }
                .frame(width: 24, height: 24)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 0.5))
            } else {
                defaultAvatar
            }
            
            // Name and Time
            VStack(alignment: .leading, spacing: 2) {
                if isLoadingUser {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.secondary.opacity(0.3))
                        .frame(width: 60, height: 10)
                } else {
                    Text(uploaderUser?.displayName ?? "Bilinmeyen Kullanıcı")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                
                Text(timeAgoText(item.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer(minLength: 0)
            
            // Favorite indicator
            if isFavorite {
                Image(systemName: "heart.fill")
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isAnimating)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 8).fill(.ultraThinMaterial))
        .padding(.top, 4)
    }
    
    @ViewBuilder
    private var contextMenuItems: some View {
        Button(action: toggleFavorite) {
            Label(isFavorite ? "Favorilerden Çıkar" : "Favorilere Ekle",
                  systemImage: isFavorite ? "heart.slash" : "heart.fill")
        }
        
        Button(action: shareImage) {
            Label("Paylaş", systemImage: "square.and.arrow.up")
        }
        
        Button(action: saveToPhotos) {
            Label("Galeriye Kaydet", systemImage: "arrow.down.to.line")
        }
        
        if canDelete {
            Divider()
            Button(role: .destructive, action: { onDelete?(item) }) {
                Label("Sil", systemImage: "trash")
            }
        }
    }
    
    private var defaultAvatar: some View {
        Circle()
            .fill(.blue.gradient)
            .frame(width: 24, height: 24)
            .overlay {
                Text(uploaderUser?.initials ?? "?")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }
    }
    
    // MARK: - Methods
    
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
    
    private func shareImage() {
        print("Share image: \(item.id ?? "")")
    }
    
    private func saveToPhotos() {
        print("Save to photos: \(item.id ?? "")")
    }
    
    private func loadUploaderInfo() {
        if let cachedUser = vm.getUser(for: item.uploaderId) {
            uploaderUser = cachedUser
            return
        }
        
        guard !isLoadingUser else { return }
        isLoadingUser = true
        
        Task {
            do {
                let userService = FirestoreUserService()
                let user = try await userService.getUser(uid: item.uploaderId)
                
                await MainActor.run {
                    uploaderUser = user
                    isLoadingUser = false
                    vm.cacheUser(user, for: item.uploaderId)
                }
            } catch {
                print("Failed to load uploader info: \(error)")
                await MainActor.run {
                    isLoadingUser = false
                }
            }
        }
    }
    
    private func timeAgoText(_ date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "şimdi"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)dk"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)sa"
        } else if timeInterval < 604800 {
            let days = Int(timeInterval / 86400)
            return "\(days)g"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM"
            formatter.locale = Locale(identifier: "tr_TR")
            return formatter.string(from: date)
        }
    }
}
