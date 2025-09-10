
import SwiftUI
import PhotosUI

struct MediaGridView: View {
    @ObservedObject var vm: MediaViewModel
    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedItem: MediaItem?
    @State private var showViewer = false
    
    var body: some View {
        GeometryReader { geometry in
            if vm.filteredItems.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: getEmptyStateIcon())
                        .font(.system(size: 60))
                        .foregroundStyle(getEmptyStateColor())
                    
                    Text(getEmptyStateTitle())
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(getEmptyStateMessage())
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    PinterestGrid(
                        items: vm.filteredItems,
                        spacing: 8,
                        columns: 2,
                        containerWidth: geometry.size.width
                    ) { item in
                        MediaGridCard(vm: vm, item: item) {
                            selectedItem = item
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showViewer = true
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Image(systemName: "plus")
                        .font(.title2)
                }
            }
        }
        .onChange(of: pickerItem) { newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    vm.pickedImage = img
                    await vm.uploadPicked()
                }
                pickerItem = nil
            }
        }
        .fullScreenCover(isPresented: $showViewer) {
            selectedItem = nil
        } content: {
            if let selectedItem = selectedItem {
                MediaViewerView(vm: vm, initialItem: selectedItem) {
                    showViewer = false
                }
            }
        }
        .task { vm.start() }
    }
    
    // MARK: - Helper Methods
    private func getEmptyStateIcon() -> String {
        switch vm.currentFilter {
        case .all: return "photo.stack"
        case .photos: return "photo"
        case .videos: return "video"
        case .favorites: return "heart"
        }
    }
    
    private func getEmptyStateColor() -> Color {
        switch vm.currentFilter {
        case .all: return .blue
        case .photos: return .blue
        case .videos: return .green
        case .favorites: return .red
        }
    }
    
    private func getEmptyStateTitle() -> String {
        switch vm.currentFilter {
        case .all: return "Henüz içerik yok"
        case .photos: return "Henüz fotoğraf yok"
        case .videos: return "Henüz video yok"
        case .favorites: return "Henüz favori yok"
        }
    }
    
    private func getEmptyStateMessage() -> String {
        switch vm.currentFilter {
        case .all: return "Bu albüme henüz fotoğraf veya video eklenmemiş. Sağ üstteki '+' butonuna tıklayarak içerik ekleyebilirsiniz."
        case .photos: return "Bu albümde henüz fotoğraf bulunmuyor. Sağ üstteki '+' butonuna tıklayarak fotoğraf ekleyebilirsiniz."
        case .videos: return "Bu albümde henüz video bulunmuyor. Video yükleme özelliği yakında eklenecek."
        case .favorites: return "Henüz hiçbir fotoğrafı favorilere eklememişsiniz. Fotoğraflarda kalp simgesine tıklayarak favori ekleyebilirsiniz."
        }
    }
}

                        struct MediaGridCard: View {
                            @ObservedObject var vm: MediaViewModel
                            let item: MediaItem
                            let onTap: () -> Void
                            @State private var uploaderUser: User?
                            @State private var isLoadingUser = false
        
        private var isFavorite: Bool {
            guard let itemId = item.id else { return false }
            return vm.isFavorite(itemId)
        }
        
        var body: some View {
            VStack(spacing: 0) {
                // Fotoğraf
                AsyncImageView(pathProvider: { await vm.imageURL(for: item) })
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                    .shadow(
                        color: .black.opacity(0.08),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                    )
                    .overlay(alignment: .topTrailing) {
                        // Favorite indicator
                        if isFavorite {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                                .font(.caption)
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .environment(\.colorScheme, .light)
                                )
                                .padding(8)
                        }
                    }
                    .onTapGesture {
                        onTap()
                    }
                    .hoverEffect(.lift) // iOS 17+ hover effect
                
                // Kullanıcı bilgisi footer
                HStack(spacing: 8) {
                    // Profil fotoğrafı
                    Group {
                        if isLoadingUser {
                            Circle()
                                .fill(.secondary.opacity(0.3))
                                .frame(width: 24, height: 24)
                                .overlay {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                }
                        } else if let photoURL = uploaderUser?.photoURL, !photoURL.isEmpty {
                            AsyncImage(url: URL(string: photoURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                defaultAvatar
                            }
                            .frame(width: 24, height: 24)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 0.5))
                        } else {
                            defaultAvatar
                        }
                    }
                    
                    // İsim ve zaman
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
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                )
                .padding(.top, 4)
            }
            .onAppear {
                loadUploaderInfo()
            }
        }
        
        // MARK: - Helper Views
        
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
        
        // MARK: - Helper Methods
        
        private func loadUploaderInfo() {
            // Önce cache'den kontrol et (eğer MediaViewModel'de cache varsa)
            if let cachedUser = vm.getUser(for: item.uploaderId) {
                uploaderUser = cachedUser
                return
            }
            
            // Cache'de yoksa yükle
            guard !isLoadingUser else { return }
            isLoadingUser = true
            
            Task {
                do {
                    let userService = FirestoreUserService()
                    let user = try await userService.getUser(uid: item.uploaderId)
                    
                    await MainActor.run {
                        uploaderUser = user
                        isLoadingUser = false
                        
                        // MediaViewModel'de cache varsa orada da sakla
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
    
    // MARK: - Pinterest Grid
    struct PinterestGrid<Item: Identifiable, Content: View>: View {
        let items: [Item]
        let spacing: CGFloat
        let columns: Int
        let containerWidth: CGFloat
        let content: (Item) -> Content
        
        private var columnWidth: CGFloat {
            let totalSpacing = spacing * CGFloat(columns - 1) + 24 // 12 padding each side
            return (containerWidth - totalSpacing) / CGFloat(columns)
        }
        
        var body: some View {
            HStack(alignment: .top, spacing: spacing) {
                ForEach(0..<columns, id: \.self) { columnIndex in
                    LazyVStack(spacing: spacing) {
                        ForEach(itemsForColumn(columnIndex)) { item in
                            content(item)
                                .frame(width: columnWidth)
                        }
                    }
                }
            }
        }
        
        private func itemsForColumn(_ columnIndex: Int) -> [Item] {
            var columnItems: [Item] = []
            
            for (index, item) in items.enumerated() {
                if index % columns == columnIndex {
                    columnItems.append(item)
                }
            }
            
            return columnItems
        }
    }
    
    // MARK: - Dynamic Pinterest Grid (Alternative)
    struct DynamicPinterestGrid<Item: Identifiable, Content: View>: View {
        let items: [Item]
        let spacing: CGFloat
        let columns: Int
        let containerWidth: CGFloat
        let content: (Item) -> Content
        
        @State private var columnHeights: [CGFloat]
        
        init(items: [Item], spacing: CGFloat = 8, columns: Int = 2, containerWidth: CGFloat, @ViewBuilder content: @escaping (Item) -> Content) {
            self.items = items
            self.spacing = spacing
            self.columns = columns
            self.containerWidth = containerWidth
            self.content = content
            self._columnHeights = State(initialValue: Array(repeating: 0, count: columns))
        }
        
        private var columnWidth: CGFloat {
            let totalSpacing = spacing * CGFloat(columns - 1) + 24
            return (containerWidth - totalSpacing) / CGFloat(columns)
        }
        
        var body: some View {
            HStack(alignment: .top, spacing: spacing) {
                ForEach(0..<columns, id: \.self) { columnIndex in
                    LazyVStack(spacing: spacing) {
                        ForEach(itemsForColumn(columnIndex)) { item in
                            content(item)
                                .frame(width: columnWidth)
                        }
                    }
                }
            }
        }
        
        private func itemsForColumn(_ columnIndex: Int) -> [Item] {
            // Basit dağıtım - gerçek Pinterest'te height'e göre en kısa kolona eklenir
            return items.enumerated().compactMap { index, item in
                index % columns == columnIndex ? item : nil
            }
        }
    }
    
    // MARK: - Pinterest AsyncImageView
    struct PinterestAsyncImageView: View {
        let pathProvider: () async -> URL?
        @State private var url: URL?
        @State private var isLoading = true
        @State private var aspectRatio: CGFloat = 1.0
        
        var body: some View {
            Group {
                if let url {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img
                                .resizable()
                                .aspectRatio(aspectRatio, contentMode: .fit)
                                .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                                .onAppear {
                                    // Gerçek aspect ratio'yu hesapla
                                    calculateAspectRatio(from: img)
                                }
                        case .failure(_):
                            failurePlaceholder
                        case .empty:
                            loadingPlaceholder
                        @unknown default:
                            loadingPlaceholder
                        }
                    }
                } else {
                    if isLoading {
                        loadingPlaceholder
                    } else {
                        failurePlaceholder
                    }
                }
            }
            .onAppear {
                Task {
                    url = await pathProvider()
                    if url == nil {
                        isLoading = false
                    }
                }
            }
        }
        
        private var loadingPlaceholder: some View {
            Rectangle()
                .fill(.secondary.opacity(0.1))
                .aspectRatio(aspectRatio, contentMode: .fit)
                .overlay {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                }
        }
        
        private var failurePlaceholder: some View {
            Rectangle()
                .fill(.secondary.opacity(0.1))
                .aspectRatio(aspectRatio, contentMode: .fit)
                .overlay {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
        }
        
        private func calculateAspectRatio(from image: Image) {
            // Bu basit bir yaklaşım - gerçek implementasyonda UIImage'dan aspect ratio alınabilir
            let randomRatios: [CGFloat] = [3/4, 4/5, 1, 5/4, 4/3, 3/2]
            aspectRatio = randomRatios.randomElement() ?? 1.0
        }
    }

