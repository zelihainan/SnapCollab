import SwiftUI

struct AlbumsView: View {
    @StateObject var vm: AlbumsViewModel
    @Environment(\.di) var di
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @StateObject private var deepLinkHandler = DeepLinkHandler()
    @StateObject private var userCache = UserCacheManager()
    @State private var showProfile = false
    @State private var showJoinAlbum = false
    @State private var sortMode: SortMode = .newest
    @State private var pinnedAlbums: Set<String> = []
    
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
        let albums = vm.albums
        
        // Pinlenen ve pinlenmemiş albümleri ayır
        let pinnedList = albums.filter { album in
            guard let id = album.id else { return false }
            return pinnedAlbums.contains(id)
        }
        
        let unpinnedList = albums.filter { album in
            guard let id = album.id else { return false }
            return !pinnedAlbums.contains(id)
        }
        
        // Her grup için sıralama uygula
        let sortedPinned = applySorting(to: pinnedList, currentUID: currentUID)
        let sortedUnpinned = applySorting(to: unpinnedList, currentUID: currentUID)
        
        return sortedPinned + sortedUnpinned
    }
    
    private func applySorting(to albums: [Album], currentUID: String) -> [Album] {
        switch sortMode {
        case .newest:
            return albums.sorted { $0.updatedAt > $1.updatedAt }
        case .oldest:
            return albums.sorted { $0.updatedAt < $1.updatedAt }
        case .alphabetical:
            return albums.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .mostMembers:
            return albums.sorted { $0.members.count > $1.members.count }
        case .myAlbums:
            let ownedFirst = albums.filter { $0.isOwner(currentUID) }
            let notOwned = albums.filter { !$0.isOwner(currentUID) }
            return ownedFirst + notOwned
        }
    }

    var body: some View {
        List {
            ForEach(sortedAlbums, id: \.id) { album in
                Button(action: {
                    if let albumId = album.id {
                        navigationCoordinator.pushToAlbumDetail(albumId: albumId)
                    }
                }) {
                    SpotifyStyleAlbumRow(
                        album: album,
                        currentUserId: di.authRepo.uid,
                        userCache: userCache,
                        userService: FirestoreUserService(),
                        albumRepo: di.albumRepo,
                        isPinned: isPinned(album),
                        onPinToggle: {
                            Task { await togglePin(album) }
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    // Pin/Unpin action with color coding
                    Button(action: {
                        Task { await togglePin(album) }
                    }) {
                        Label(
                            isPinned(album) ? "Sabitlemeyi Kaldır" : "Sabitle",
                            systemImage: isPinned(album) ? "pin.slash.fill" : "pin.fill"
                        )
                    }
                    .tint(isPinned(album) ? .orange : .green)
                }
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
            let joinVM = JoinAlbumViewModel(
                repo: di.albumRepo,
                notificationRepo: di.notificationRepo
            )
            
            JoinAlbumViewContent(
                vm: joinVM,
                initialCode: deepLinkHandler.pendingInviteCode
            )
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
        .onChange(of: navigationCoordinator.shouldNavigateToAlbum) { albumId in
            handleDeepNavigation(albumId)
        }
        .task {
            vm.start()
            await loadPinnedAlbums()
            await di.albumRepo.migrateAllAlbumFields()
        }
    }
    
    private func handleDeepNavigation(_ albumId: String?) {
        guard let albumId = albumId else { return }
        
        print("AlbumsView: Handling deep navigation to album: \(albumId)")
        
        if let album = vm.albums.first(where: { $0.id == albumId }) {
            print("AlbumsView: Found album in current list, navigating...")
            if let albumId = album.id {
                navigationCoordinator.pushToAlbumDetail(albumId: albumId)
            }
            navigationCoordinator.clearNavigationRequest()
        } else {
            print("AlbumsView: Album not found in current list, will try when albums load")
        }
    }
    
    private func isPinned(_ album: Album) -> Bool {
        guard let albumId = album.id else { return false }
        return pinnedAlbums.contains(albumId)
    }
    
    private func loadPinnedAlbums() async {
        let pinned = di.albumRepo.getPinnedAlbums()
        await MainActor.run {
            pinnedAlbums = Set(pinned)
        }
    }
    
    private func togglePin(_ album: Album) async {
        guard let albumId = album.id else { return }
        
        do {
            try await di.albumRepo.toggleAlbumPin(albumId)
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Anında UI güncellemesi
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    if pinnedAlbums.contains(albumId) {
                        pinnedAlbums.remove(albumId)
                    } else {
                        pinnedAlbums.insert(albumId)
                    }
                }
            }
            
        } catch {
            print("Pin toggle error: \(error)")
        }
    }
}

// MARK: - Spotify-Style Album Row with Pin Indicator
struct SpotifyStyleAlbumRow: View {
    let album: Album
    let currentUserId: String?
    @StateObject var userCache: UserCacheManager
    let userService: UserProviding
    let albumRepo: AlbumRepository
    let isPinned: Bool
    let onPinToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Album Cover
            AlbumCoverPhoto(
                album: album,
                albumRepo: albumRepo,
                size: 56,
                showEditButton: false
            )
            
            // Album Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    // Pin indicator - Spotify style
                    if isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.green)
                            .rotationEffect(.degrees(45))
                    }
                    
                    Text(album.title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                HStack(spacing: 8) {
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
                        .padding(.leading, 4)
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

// Diğer view'lar aynı kalır (CreateAlbumSheet, JoinAlbumViewContent, etc.)
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

struct JoinAlbumViewContent: View {
    @StateObject var vm: JoinAlbumViewModel
    let initialCode: String?
    @Environment(\.dismiss) var dismiss
    
    init(vm: JoinAlbumViewModel, initialCode: String?) {
        _vm = StateObject(wrappedValue: vm)
        self.initialCode = initialCode
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
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
                    
                    VStack(spacing: 20) {
                        Text("Davet Kodu")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
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
                        
                        if UIPasteboard.general.hasStrings {
                            Button("Panodan Yapıştır") {
                                vm.pasteFromClipboard()
                            }
                            .font(.caption)
                            .foregroundStyle(.blue)
                        }
                    }
                    
                    if let album = vm.foundAlbum {
                        AlbumPreviewCard(album: album)
                    }
                    
                    if let error = vm.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
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
        .onAppear {
            if let code = initialCode?.uppercased() {
                vm.inviteCode = String(code.prefix(6))
                vm.activeIndex = min(code.count, 6)
            }
        }
        .onDisappear {
            vm.reset()
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
