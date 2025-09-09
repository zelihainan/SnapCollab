import SwiftUI

struct AlbumsView: View {
    @StateObject var vm: AlbumsViewModel
    @Environment(\.di) var di
    @EnvironmentObject var appState: AppState
    @StateObject private var deepLinkHandler = DeepLinkHandler()
    @State private var showProfile = false
    @State private var showJoinAlbum = false

    var body: some View {
        List {
            ForEach(vm.albums, id: \.id) { album in
                NavigationLink {
                    AlbumDetailView(album: album, di: di)
                } label: {
                    CleanAlbumRow(album: album, currentUserId: di.authRepo.uid)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
        }
        .listStyle(.plain)
        .navigationTitle("Albums")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showProfile = true }) {
                    Image(systemName: "person.crop.circle")
                        .font(.title2)
                }
            }
            
            // Sağ taraftaki butonlar - Menu içinde
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        vm.showCreate = true
                    } label: {
                        Label("Yeni Albüm", systemImage: "plus")
                    }
                    
                    Button {
                        showJoinAlbum = true
                    } label: {
                        Label("Albüme Katıl", systemImage: "person.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $vm.showCreate) {
            CreateAlbumSheet(vm: vm)
        }
        .sheet(isPresented: $showJoinAlbum) {
            JoinAlbumView(albumRepo: di.albumRepo, initialCode: deepLinkHandler.pendingInviteCode)
                .onDisappear {
                    deepLinkHandler.clearPendingInvite()
                }
        }
        .fullScreenCover(isPresented: $showProfile) {
            let profileVM = ProfileViewModel(authRepo: di.authRepo, mediaRepo: di.mediaRepo)
            let sessionVM = SessionViewModel(auth: di.authRepo, state: appState)
            
            ProfileView(vm: profileVM)
                .onAppear {
                    profileVM.setSessionViewModel(sessionVM)
                }
        }
        // Deep link handling
        .onOpenURL { url in
            print("AlbumsView: Received deep link: \(url)")
            deepLinkHandler.handleURL(url)
        }
        .onChange(of: deepLinkHandler.shouldShowJoinView) { shouldShow in
            if shouldShow {
                showJoinAlbum = true
                deepLinkHandler.shouldShowJoinView = false
            }
        }
        .task {
            vm.start()
            
            // GEÇİCİ: İlk açılışta migration çalıştır
            Task {
                await di.albumRepo.migrateOldAlbums()
            }
        }
    }
}

// MARK: - Create Album Sheet
struct CreateAlbumSheet: View {
    @ObservedObject var vm: AlbumsViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                    
                    Text("Yeni Albüm")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.top, 20)
                
                TextField("Albüm Adı", text: $vm.newTitle)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 20)
                
                Button("Albüm Oluştur") {
                    Task { await vm.create() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle("Yeni Albüm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        vm.newTitle = ""
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: vm.showCreate) { isShowing in
            if !isShowing {
                dismiss()
            }
        }
    }
}

// MARK: - Clean Album Row
struct CleanAlbumRow: View {
    let album: Album
    let currentUserId: String?
    
    var body: some View {
        HStack(spacing: 12) {
            // Minimal Album Icon
            Circle()
                .fill(.blue.gradient)
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "photo.on.rectangle.angled")
                        .foregroundStyle(.white)
                        .font(.title3)
                }
            
            // Album Info
            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 6) {
                    // Member count with icon
                    Image(systemName: "person.2")
                        .font(.caption)
                    Text("\(album.members.count)")
                        .font(.caption)
                    
                    // Owner badge (if applicable)
                    if album.isOwner(currentUserId ?? "") {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    
                    Spacer()
                    
                    // Simple time
                    Text(simpleTimeText(album.createdAt))
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.clear)
        )
        .contentShape(Rectangle())
    }
    
    private func simpleTimeText(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Bugün"
        } else if calendar.isDateInYesterday(date) {
            return "Dün"
        } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(date) == true {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            formatter.locale = Locale(identifier: "tr_TR")
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.locale = Locale(identifier: "tr_TR")
            return formatter.string(from: date)
        }
    }
}
