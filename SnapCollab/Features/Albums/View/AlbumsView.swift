import SwiftUI

struct AlbumsView: View {
    @StateObject var vm: AlbumsViewModel
    @Environment(\.di) var di
    @EnvironmentObject var appState: AppState
    @StateObject private var deepLinkHandler = DeepLinkHandler()
    @StateObject private var userCache = UserCacheManager()
    @State private var showProfile = false
    @State private var showJoinAlbum = false
    @State private var sortMode: SortMode = .newest
    
    enum SortMode: String, CaseIterable {
        case newest = "En Yeni"
        case oldest = "En Eski"
        case alphabetical = "A-Z"
        case mostMembers = "Çok Üyeli"
        case myAlbums = "Sahip Olduklarım"
        
        var icon: String {
            switch self {
            case .newest: return "clock"
            case .oldest: return "clock.arrow.circlepath"
            case .alphabetical: return "textformat.abc"
            case .mostMembers: return "person.3"
            case .myAlbums: return "crown"
            }
        }
    }

    var sortedAlbums: [Album] {
        let currentUID = di.authRepo.uid ?? ""
        
        switch sortMode {
        case .newest:
            return vm.albums.sorted { $0.updatedAt > $1.updatedAt }
        case .oldest:
            return vm.albums.sorted { $0.updatedAt < $1.updatedAt }
        case .alphabetical:
            return vm.albums.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .mostMembers:
            return vm.albums.sorted { $0.members.count > $1.members.count }
        case .myAlbums:
            return vm.albums.filter { $0.isOwner(currentUID) } + vm.albums.filter { !$0.isOwner(currentUID) }
        }
    }

    var body: some View {
        List {
            ForEach(sortedAlbums, id: \.id) { album in
                NavigationLink {
                    AlbumDetailView(album: album, di: di)
                } label: {
                    EnhancedAlbumRow(
                        album: album,
                        currentUserId: di.authRepo.uid,
                        userCache: userCache,
                        userService: FirestoreUserService(),
                        albumRepo: di.albumRepo
                    )
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
        }
        .listStyle(.plain)
        .navigationTitle("Albümler")
        .navigationBarTitleDisplayMode(.automatic)
        .toolbar(content: {
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Menu {
                        ForEach(SortMode.allCases, id: \.self) { mode in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    sortMode = mode
                                }
                            } label: {
                                HStack {
                                    Image(systemName: mode.icon)
                                    Text(mode.rawValue)
                                    Spacer()
                                    if sortMode == mode {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.body)
                    }
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
                            .font(.body)
                    }
                }
            }
        })
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
            await di.albumRepo.migrateAllAlbumFields()
        }
    }
}

struct ProfilePhotoButton: View {
    let user: User?
    
    var body: some View {
        Group {
            if let photoURL = user?.photoURL, !photoURL.isEmpty {
                AsyncImage(url: URL(string: photoURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    defaultAvatar
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .overlay(Circle().stroke(.gray.opacity(0.3), lineWidth: 1))
            } else {
                defaultAvatar
            }
        }
    }
    
    private var defaultAvatar: some View {
        Image(systemName: "person.crop.circle")
            .font(.title2)
            .foregroundStyle(.blue)
    }
}

struct EnhancedAlbumRow: View {
    let album: Album
    let currentUserId: String?
    @StateObject var userCache: UserCacheManager
    let userService: UserProviding
    let albumRepo: AlbumRepository
    
    var body: some View {
        HStack(spacing: 12) {
            AlbumCoverPhoto(
                album: album,
                albumRepo: albumRepo,
                size: 44,
                showEditButton: false
            )
            
            // Album Info
            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.caption)
                        Text("\(album.members.count)")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    
                    if album.isOwner(currentUserId ?? "") {
                        HStack(spacing: 2) {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        .padding(.leading, 4) // Add spacing from the member count
                    }
                    
                    Spacer()
                    
                    Text(simpleTimeText(album.updatedAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer(minLength: 0)
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

struct UserProfilePhoto: View {
    let user: User
    let size: CGFloat
    
    var body: some View {
        Group {
            if let photoURL = user.photoURL, !photoURL.isEmpty {
                AsyncImage(url: URL(string: photoURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    defaultAvatar
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(Circle().stroke(.gray.opacity(0.2), lineWidth: 1))
            } else {
                defaultAvatar
            }
        }
    }
    
    private var defaultAvatar: some View {
        Circle()
            .fill(.blue.gradient)
            .frame(width: size, height: size)
            .overlay {
                Text(user.initials)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundStyle(.white)
            }
    }
}

final class UserCacheManager: ObservableObject {
    private var cache: [String: User] = [:]
    
    func getUser(uid: String) -> User? {
        return cache[uid]
    }
    
    func setUser(_ user: User) {
        cache[user.uid] = user
    }
    
    func clearCache() {
        cache.removeAll()
    }
}

extension String {
    var isNilOrEmpty: Bool {
        return self.isEmpty
    }
}

extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
}

extension User {
    var initials: String {
        let name = displayName ?? email
        let components = name.components(separatedBy: .whitespaces)
        
        if components.count >= 2 {
            let first = String(components[0].prefix(1)).uppercased()
            let last = String(components[1].prefix(1)).uppercased()
            return first + last
        } else if let first = components.first, !first.isEmpty {
            return String(first.prefix(2)).uppercased()
        } else {
            return "U"
        }
    }
}

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
