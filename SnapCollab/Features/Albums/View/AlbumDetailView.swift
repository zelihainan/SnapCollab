import SwiftUI

struct AlbumDetailView: View {
    let album: Album
    @StateObject private var vm: MediaViewModel
    @Environment(\.di) var di
    @Environment(\.dismiss) var dismiss
    @State private var showInviteSheet = false
    @State private var showLeaveAlert = false
    @State private var showDeleteAlert = false
    @State private var showRenameSheet = false
    @State private var isDeleting = false

    init(album: Album, di: DIContainer) {
        self.album = album
        _vm = StateObject(wrappedValue: MediaViewModel(repo: di.mediaRepo, albumId: album.id!))
    }

    var body: some View {
        MediaGridView(vm: vm)
            .navigationTitle(album.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // Albüm Bilgileri
                        Label("\(album.members.count) üye", systemImage: "person.3")
                        
                        Divider()
                        
                        // Sahip için özel aksiyonlar
                        if album.isOwner(di.authRepo.uid ?? "") {
                            Button(action: { showRenameSheet = true }) {
                                Label("Albüm Adını Değiştir", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive, action: { showDeleteAlert = true }) {
                                Label("Albümü Sil", systemImage: "trash")
                            }
                            
                            Divider()
                        }
                        
                        // Davet Et - Tüm üyeler için
                        if album.isMember(di.authRepo.uid ?? "") {
                            if let inviteCode = album.inviteCode {
                                Button(action: { showInviteSheet = true }) {
                                    Label("Davet Et", systemImage: "person.badge.plus")
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Üyelik durumu
                        if album.isOwner(di.authRepo.uid ?? "") {
                            Label("Albüm Sahibi", systemImage: "crown.fill")
                        } else if album.isMember(di.authRepo.uid ?? "") {
                            Button(role: .destructive, action: { showLeaveAlert = true }) {
                                Label("Albümden Ayrıl", systemImage: "person.badge.minus")
                            }
                        }
                        
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                    }
                }
                
                // Üye sayısı göstergesi
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.3.fill")
                            .font(.caption)
                        Text("\(album.members.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
                }
            }
            .sheet(isPresented: $showInviteSheet) {
                InviteCodeView(album: album)
            }
            .sheet(isPresented: $showRenameSheet) {
                AlbumRenameSheet(album: album, albumRepo: di.albumRepo)
            }
            .alert("Albümden Ayrıl", isPresented: $showLeaveAlert) {
                Button("İptal", role: .cancel) { }
                Button("Ayrıl", role: .destructive) {
                    Task { await leaveAlbum() }
                }
            } message: {
                Text("Bu albümden ayrılmak istediğinizden emin misiniz?")
            }
            .alert("Albümü Sil", isPresented: $showDeleteAlert) {
                Button("İptal", role: .cancel) { }
                Button("Sil", role: .destructive) {
                    Task { await deleteAlbum() }
                }
            } message: {
                Text("Bu albümü kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.")
            }
            .disabled(isDeleting)
            .overlay {
                if isDeleting {
                    Color.black.opacity(0.3)
                        .overlay {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.2)
                                Text("Albüm siliniyor...")
                                    .foregroundStyle(.white)
                                    .font(.caption)
                            }
                        }
                        .ignoresSafeArea()
                }
            }
    }
    
    private func leaveAlbum() async {
        guard let albumId = album.id else { return }
        
        do {
            try await di.albumRepo.leaveAlbum(albumId)
            print("Successfully left album")
        } catch {
            print("Error leaving album: \(error)")
        }
    }
    
    private func deleteAlbum() async {
        guard let albumId = album.id else { return }
        
        isDeleting = true
        
        do {
            try await di.albumRepo.deleteAlbum(albumId)
            print("Successfully deleted album")
            
            // Ana sayfaya geri dön
            await MainActor.run {
                dismiss()
            }
            
        } catch {
            print("Error deleting album: \(error)")
            // Hata toast'ı gösterilebilir
        }
        
        isDeleting = false
    }
}

// MARK: - Album Rename Sheet
struct AlbumRenameSheet: View {
    let album: Album
    let albumRepo: AlbumRepository
    @Environment(\.dismiss) var dismiss
    
    @State private var newTitle: String
    @State private var isUpdating = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    
    init(album: Album, albumRepo: AlbumRepository) {
        self.album = album
        self.albumRepo = albumRepo
        self._newTitle = State(initialValue: album.title)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                    
                    Text("Albüm Adını Değiştir")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Mevcut ad: \"\(album.title)\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                TextField("Yeni albüm adı", text: $newTitle)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        Task { await updateTitle() }
                    }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                
                if showSuccess {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Albüm adı güncellendi!")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }
                
                Button("Güncelle") {
                    Task { await updateTitle() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                         newTitle.trimmingCharacters(in: .whitespacesAndNewlines) == album.title ||
                         isUpdating)
                .frame(maxWidth: .infinity)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle("Albümü Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
        }
        .disabled(isUpdating)
        .overlay {
            if isUpdating {
                Color.black.opacity(0.3)
                    .overlay {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            Text("Güncelleniyor...")
                                .foregroundStyle(.white)
                                .font(.caption)
                        }
                    }
                    .ignoresSafeArea()
            }
        }
        .onChange(of: showSuccess) { success in
            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }
    
    private func updateTitle() async {
        guard let albumId = album.id else { return }
        
        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, trimmedTitle != album.title else { return }
        
        isUpdating = true
        errorMessage = nil
        
        do {
            try await albumRepo.updateAlbumTitle(albumId, newTitle: trimmedTitle)
            
            await MainActor.run {
                showSuccess = true
            }
            
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
        
        isUpdating = false
    }
}
