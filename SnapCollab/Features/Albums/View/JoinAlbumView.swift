//
//  JoinAlbumView.swift
//  SnapCollab
//
//  Created by Your Name on Date.
//

import SwiftUI

struct JoinAlbumView: View {
    @StateObject private var vm: JoinAlbumViewModel
    @Environment(\.dismiss) var dismiss
    
    init(albumRepo: AlbumRepository, initialCode: String? = nil) {
        _vm = StateObject(wrappedValue: JoinAlbumViewModel(repo: albumRepo, initialCode: initialCode))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        
                        Text("Albüme Katıl")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Davet kodunu girerek arkadaşlarınızın albümüne katılabilirsiniz")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Input Section - Simplified
                    VStack(spacing: 20) {
                        Text("Davet Kodu")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Simple Text Field Input
                        TextField("6 haneli davet kodu", text: $vm.inviteCode)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.asciiCapable)
                            .autocapitalization(.allCharacters)
                            .autocorrectionDisabled()
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .onChange(of: vm.inviteCode) { newValue in
                                vm.validateAndFormatCode(newValue)
                            }
                        
                        // Visual Code Display
                        if !vm.inviteCode.isEmpty {
                            HStack(spacing: 8) {
                                ForEach(0..<6, id: \.self) { index in
                                    Text(vm.getDigit(at: index))
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(vm.getDigit(at: index).isEmpty ? .gray : .blue)
                                        .frame(width: 40, height: 50)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(.blue.opacity(0.1))
                                        )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Paste Button
                        if UIPasteboard.general.hasStrings {
                            Button("Panodan Yapıştır") {
                                vm.pasteFromClipboard()
                            }
                            .font(.caption)
                            .foregroundStyle(.blue)
                        }
                    }
                    
                    // Preview Section
                    if let album = vm.foundAlbum {
                        AlbumPreviewCard(album: album)
                    }
                    
                    // Error Message
                    if let error = vm.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Success Message
                    if vm.joinSuccess {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Albüme başarıyla katıldınız!")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Action Button
                    Button(action: {
                        Task { await vm.joinAlbum() }
                    }) {
                        Group {
                            if vm.isLoading {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Katılıyor...")
                                }
                            } else if vm.foundAlbum != nil {
                                HStack(spacing: 8) {
                                    Image(systemName: "person.badge.plus")
                                    Text("Albüme Katıl")
                                }
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                    Text("Albüm Ara")
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(vm.isFormValid ? .blue : .gray)
                        )
                    }
                    .disabled(!vm.isFormValid || vm.isLoading)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Albüme Katıl")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
        }
        .onChange(of: vm.joinSuccess) { success in
            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Album Preview Card
struct AlbumPreviewCard: View {
    let album: Album
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Albüm Bulundu")
                .font(.caption)
                .foregroundStyle(.green)
                .fontWeight(.medium)
            
            HStack(spacing: 16) {
                // Album Icon
                Circle()
                    .fill(.blue.gradient)
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "photo.on.rectangle.angled")
                            .foregroundStyle(.white)
                            .font(.title3)
                    }
                
                // Album Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(album.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("\(album.members.count) üye")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("Oluşturulma: \(album.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.green.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.green.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    // Mock preview
    let mockAuthRepo = AuthRepository(
        service: FirebaseAuthService(),
        userService: FirestoreUserService()
    )
    let mockAlbumRepo = AlbumRepository(
        service: FirestoreAlbumService(),
        auth: mockAuthRepo,
        userService: FirestoreUserService()
    )
    
    JoinAlbumView(albumRepo: mockAlbumRepo)
}
