import SwiftUI

struct AlbumDetailView: View {
    let album: Album
    @StateObject private var vm: MediaViewModel
    @Environment(\.di) var di
    @State private var showInviteSheet = false

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
                        
                        if let inviteCode = album.inviteCode {
                            Button(action: { showInviteSheet = true }) {
                                Label("Davet Et (\(inviteCode))", systemImage: "person.badge.plus")
                            }
                        }
                        
                        Divider()
                        
                        // Test: Sahiplik kontrolü
                        if album.isOwner(di.authRepo.uid ?? "") {
                            Label("Sen bu albümün sahibisin", systemImage: "crown.fill")
                        } else {
                            Label("Albüm üyesisin", systemImage: "person.fill")
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
    }
}

// Basit Davet Kodu Gösterici
struct InviteCodeView: View {
    let album: Album
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    
                    Text("Albüme Davet Et")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(album.title)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                VStack(spacing: 16) {
                    Text("Davet Kodu")
                        .font(.headline)
                    
                    Text(album.inviteCode ?? "INVALID")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                        .padding()
                        .background(.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Button("Kodu Kopyala") {
                        UIPasteboard.general.string = album.inviteCode
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Text("Bu kodu paylaştığınız kişiler albüme katılabilir")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Davet Kodu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}
