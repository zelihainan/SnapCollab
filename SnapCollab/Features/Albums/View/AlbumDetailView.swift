import SwiftUI

struct AlbumDetailView: View {
    let album: Album
    @StateObject private var vm: MediaViewModel
    @Environment(\.di) var di
    @State private var showInviteSheet = false
    @State private var showLeaveAlert = false

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
                        
                        // Davet Et - Sadece üyeler için
                        if album.isMember(di.authRepo.uid ?? "") {
                            if let inviteCode = album.inviteCode {
                                Button(action: { showInviteSheet = true }) {
                                    Label("Davet Et", systemImage: "person.badge.plus")
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Sahiplik/Üyelik Durumu
                        if album.isOwner(di.authRepo.uid ?? "") {
                            Label("Albüm Sahibi", systemImage: "crown.fill")
                        } else if album.isMember(di.authRepo.uid ?? "") {
                            // Albümden Ayrıl
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
            .alert("Albümden Ayrıl", isPresented: $showLeaveAlert) {
                Button("İptal", role: .cancel) { }
                Button("Ayrıl", role: .destructive) {
                    Task { await leaveAlbum() }
                }
            } message: {
                Text("Bu albümden ayrılmak istediğinizden emin misiniz? Tekrar katılmak için davet kodu gerekecek.")
            }
    }
    
    private func leaveAlbum() async {
        guard let albumId = album.id else { return }
        
        do {
            try await di.albumRepo.leaveAlbum(albumId)
            print("Successfully left album")
            // Navigation otomatik olarak geri gidecek çünkü albüm listesi güncellenecek
        } catch {
            print("Error leaving album: \(error)")
            // Error handling - toast veya alert gösterilebilir
        }
    }
}

#Preview {
    let mockDI = DIContainer.bootstrap()
    let mockAlbum = Album(title: "Test Album", ownerId: "test-uid")
    
    NavigationView {
        AlbumDetailView(album: mockAlbum, di: mockDI)
    }
}
