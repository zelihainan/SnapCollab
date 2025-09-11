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
    @State private var showMembersSheet = false
    @State private var showCoverManagement = false
    @State private var isDeleting = false
    @State private var selectedCategory: MediaCategory = .all
    @State private var showMediaGrid = false

    enum MediaCategory: String, CaseIterable {
        case all = "Tümü"
        case favorites = "Favoriler"
        case photos = "Fotoğraflar"
        case videos = "Videolar"
        
        var icon: String {
            switch self {
            case .all: return "photo.stack"
            case .favorites: return "heart.fill"
            case .photos: return "photo"
            case .videos: return "video"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .blue
            case .favorites: return .red
            case .photos: return .blue
            case .videos: return .green
            }
        }
    }

    init(album: Album, di: DIContainer) {
        self.album = album
        _vm = StateObject(wrappedValue: MediaViewModel(repo: di.mediaRepo, albumId: album.id!))
    }

    var body: some View {
        VStack(spacing: 20) {
            // HEADER - Kapak fotoğrafı, albüm adı, üye butonu
            VStack(spacing: 16) {
                // Kapak fotoğrafı
                AlbumCoverPhoto(
                    album: album,
                    albumRepo: di.albumRepo,
                    size: 100,
                    showEditButton: album.isOwner(di.authRepo.uid ?? "")
                )
                .onTapGesture {
                    if album.isOwner(di.authRepo.uid ?? "") {
                        showCoverManagement = true
                    }
                }
                
                
                Button(action: {
                    showMembersSheet = true
                }) {
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
            .padding(.top, 10)
            
            // Category Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 1), spacing: 16) {
                ForEach(MediaCategory.allCases, id: \.self) { category in
                    CategoryCard(
                        category: category,
                        count: getCount(for: category),
                        onTap: {
                            selectedCategory = category
                            showMediaGrid = true
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .navigationTitle(album.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if album.isOwner(di.authRepo.uid ?? "") {
                        Button(action: { showCoverManagement = true }) {
                            Label("Kapak Fotoğrafı", systemImage: "photo.circle")
                        }
                        
                        Button(action: { showRenameSheet = true }) {
                            Label("Albüm Adını Değiştir", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: { showDeleteAlert = true }) {
                            Label("Albümü Sil", systemImage: "trash")
                        }
                        
                        Divider()
                    }
                    
                    // Davet Et
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
        }
        // SHEET'LER
        .fullScreenCover(isPresented: $showMediaGrid) {
            NavigationView {
                MediaGridView(vm: vm)
                    .navigationTitle(selectedCategory.rawValue)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Kapat") {
                                showMediaGrid = false
                                vm.setFilter(.all)
                            }
                        }
                    }
                    .onAppear {
                        switch selectedCategory {
                        case .all: vm.setFilter(.all)
                        case .favorites: vm.setFilter(.favorites)
                        case .photos: vm.setFilter(.photos)
                        case .videos: vm.setFilter(.videos)
                        }
                    }
            }
        }
        .sheet(isPresented: $showInviteSheet) {
            InviteCodeView(album: album)
        }
        .sheet(isPresented: $showRenameSheet) {
            AlbumRenameSheet(album: album, albumRepo: di.albumRepo)
        }
        .sheet(isPresented: $showMembersSheet) {
            AlbumMembersView(album: album, albumRepo: di.albumRepo)
        }
        .sheet(isPresented: $showCoverManagement) {
            AlbumCoverManagementSheet(album: album, albumRepo: di.albumRepo)
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
        .task { vm.start() }
    }
    
    private func getCount(for category: MediaCategory) -> Int {
        switch category {
        case .all: return vm.items.count
        case .favorites: return vm.favoritesCount
        case .photos: return vm.photosCount
        case .videos: return vm.videosCount
        }
    }
    
    private func leaveAlbum() async {
        guard let albumId = album.id else { return }
        do {
            try await di.albumRepo.leaveAlbum(albumId)
        } catch {
            print("Error leaving album: \(error)")
        }
    }
    
    private func deleteAlbum() async {
        guard let albumId = album.id else { return }
        isDeleting = true
        do {
            try await di.albumRepo.deleteAlbum(albumId)
            await MainActor.run { dismiss() }
        } catch {
            print("Error deleting album: \(error)")
        }
        isDeleting = false
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let category: AlbumDetailView.MediaCategory
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.1))
                        .frame(width: 60, height: 60)
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundStyle(category.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.rawValue)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("\(count) öğe")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
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
            await MainActor.run { showSuccess = true }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
        
        isUpdating = false
    }
}

// MARK: - Album Members View
struct AlbumMembersView: View {
    let album: Album
    let albumRepo: AlbumRepository
    @Environment(\.dismiss) var dismiss
    @State private var members: [User] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showRemoveAlert = false
    @State private var memberToRemove: User?
    @State private var isRemoving = false
    
    private var isOwner: Bool {
        album.isOwner(albumRepo.auth.uid ?? "")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)
                    Text("Albüm Üyeleri")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(album.title)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                
                Divider().padding(.top, 20)
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView().scaleEffect(1.2)
                        Text("Üyeler yükleniyor...")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if members.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.slash")
                            .font(.system(size: 40))
                            .foregroundStyle(.gray)
                        Text("Üye bulunamadı")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(sortedMembers, id: \.uid) { member in
                                MemberRowView(
                                    member: member,
                                    album: album,
                                    isOwner: isOwner,
                                    currentUserUID: albumRepo.auth.uid ?? "",
                                    onRemove: { user in
                                        memberToRemove = user
                                        showRemoveAlert = true
                                    }
                                )
                                
                                if member.uid != sortedMembers.last?.uid {
                                    Divider().padding(.leading, 64)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding()
                        .multilineTextAlignment(.center)
                }
            }
            .navigationTitle("Üyeler (\(members.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
        .onAppear { loadMembers() }
        .alert("Üyeyi Çıkar", isPresented: $showRemoveAlert) {
            Button("İptal", role: .cancel) { memberToRemove = nil }
            Button("Çıkar", role: .destructive) {
                if let member = memberToRemove {
                    Task { await removeMember(member) }
                }
            }
        } message: {
            if let member = memberToRemove {
                Text("\(member.displayName ?? member.email) kullanıcısını albümden çıkarmak istediğinizden emin misiniz?")
            }
        }
    }
    
    private var sortedMembers: [User] {
        members.sorted { user1, user2 in
            let user1IsOwner = album.isOwner(user1.uid)
            let user2IsOwner = album.isOwner(user2.uid)
            
            if user1IsOwner && !user2IsOwner {
                return true
            } else if !user1IsOwner && user2IsOwner {
                return false
            } else {
                let name1 = user1.displayName ?? user1.email
                let name2 = user2.displayName ?? user2.email
                return name1.localizedCaseInsensitiveCompare(name2) == .orderedAscending
            }
        }
    }
    
    private func loadMembers() {
        Task { await loadMembersAsync() }
    }
    
    private func loadMembersAsync() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let userService = FirestoreUserService()
            var loadedMembers: [User] = []
            
            for memberUID in album.members {
                if let user = try await userService.getUser(uid: memberUID) {
                    loadedMembers.append(user)
                } else {
                    let placeholderUser = User(uid: memberUID, email: "Bilinmeyen kullanıcı", displayName: "Silinmiş hesap")
                    loadedMembers.append(placeholderUser)
                }
            }
            
            await MainActor.run {
                members = loadedMembers
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Üyeler yüklenirken hata: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func removeMember(_ user: User) async {
        guard let albumId = album.id else {
            memberToRemove = nil
            return
        }
        
        isRemoving = true
        
        do {
            try await albumRepo.removeMemberFromAlbum(albumId, memberUID: user.uid)
            await MainActor.run {
                members.removeAll { $0.uid == user.uid }
                memberToRemove = nil
            }
        } catch {
            await MainActor.run {
                errorMessage = "Üye çıkarılırken hata: \(error.localizedDescription)"
                memberToRemove = nil
            }
        }
        
        isRemoving = false
    }
}

// MARK: - Member Row View
struct MemberRowView: View {
    let member: User
    let album: Album
    let isOwner: Bool
    let currentUserUID: String
    let onRemove: (User) -> Void
    
    private var isCurrentUser: Bool { member.uid == currentUserUID }
    private var isAlbumOwner: Bool { album.isOwner(member.uid) }
    
    var body: some View {
        HStack(spacing: 16) {
            Group {
                if let photoURL = member.photoURL, !photoURL.isEmpty {
                    AsyncImage(url: URL(string: photoURL)) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        defaultAvatar
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.gray.opacity(0.2), lineWidth: 1))
                } else {
                    defaultAvatar
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(member.displayName ?? "İsimsiz Kullanıcı")
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    if isAlbumOwner {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    
                    if isCurrentUser {
                        Text("(Sen)")
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .fontWeight(.medium)
                    }
                }
                
                if !member.email.isEmpty && member.email != "Bilinmeyen kullanıcı" {
                    Text(member.email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if isOwner && !isAlbumOwner && !isCurrentUser {
                Button(action: { onRemove(member) }) {
                    Image(systemName: "person.badge.minus")
                        .font(.title3)
                        .foregroundStyle(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
    
    private var defaultAvatar: some View {
        Circle()
            .fill(.blue.gradient)
            .frame(width: 40, height: 40)
            .overlay {
                Text(member.initials)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }
    }
}

