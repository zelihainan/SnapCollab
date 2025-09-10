//
//  SelectableMediaCard.swift
//  SnapCollab
//
//  Selectable media card for batch operations
//

import SwiftUI

struct SelectableMediaCard: View {
    @ObservedObject var vm: MediaViewModel
    let item: MediaItem
    let isSelected: Bool
    let onSelection: (String) -> Void
    @State private var uploaderUser: User?
    
    private var isFavorite: Bool {
        guard let itemId = item.id else { return false }
        return vm.isFavorite(itemId)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Image
                AsyncImageView(pathProvider: { await vm.imageURL(for: item) })
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? .blue : .clear, lineWidth: 3)
                    )
                    .overlay(
                        // Selection overlay
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? .blue.opacity(0.2) : .clear)
                    )
                
                // Selection checkbox
                VStack {
                    HStack {
                        Spacer()
                        
                        Button {
                            guard let itemId = item.id else { return }
                            onSelection(itemId)
                        } label: {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(isSelected ? .blue : .white)
                                .background(
                                    Circle()
                                        .fill(isSelected ? .white : .black.opacity(0.3))
                                        .frame(width: 24, height: 24)
                                )
                        }
                        .scaleEffect(isSelected ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                    }
                    Spacer()
                }
                .padding(8)
                
                // Favorite indicator
                if isFavorite {
                    VStack {
                        HStack {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .background(
                                    Circle()
                                        .fill(.white.opacity(0.8))
                                        .frame(width: 20, height: 20)
                                )
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
            
            // User info footer (simplified for selection mode)
            HStack(spacing: 8) {
                if let photoURL = uploaderUser?.photoURL, !photoURL.isEmpty {
                    AsyncImage(url: URL(string: photoURL)) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle().fill(.blue.gradient)
                    }
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(.blue.gradient)
                        .frame(width: 20, height: 20)
                        .overlay {
                            Text(uploaderUser?.initials ?? "?")
                                .font(.caption2)
                                .foregroundStyle(.white)
                        }
                }
                
                Text(uploaderUser?.displayName ?? "Bilinmeyen")
                    .font(.caption2)
                    .lineLimit(1)
                
                Spacer()
                
                Text(timeAgoText(item.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.top, 4)
        }
        .onAppear {
            loadUploaderInfo()
        }
        .onTapGesture {
            guard let itemId = item.id else { return }
            onSelection(itemId)
        }
    }
    
    private func loadUploaderInfo() {
        if let cachedUser = vm.getUser(for: item.uploaderId) {
            uploaderUser = cachedUser
            return
        }
        
        Task {
            do {
                let userService = FirestoreUserService()
                let user = try await userService.getUser(uid: item.uploaderId)
                await MainActor.run {
                    uploaderUser = user
                    vm.cacheUser(user, for: item.uploaderId)
                }
            } catch {
                print("Failed to load uploader info: \(error)")
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
