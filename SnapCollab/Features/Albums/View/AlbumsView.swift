//
// Temiz AlbumsView.swift
//

import SwiftUI

struct AlbumsView: View {
    @StateObject var vm: AlbumsViewModel
    @Environment(\.di) var di
    @EnvironmentObject var appState: AppState
    @State private var showProfile = false

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
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { vm.showCreate = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $vm.showCreate) {
            VStack(spacing: 12) {
                TextField("Album title", text: $vm.newTitle)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                Button("Create") { Task { await vm.create() } }
                    .buttonStyle(.borderedProminent)
            }
            .presentationDetents([.height(180)])
        }
        .fullScreenCover(isPresented: $showProfile) {
            let profileVM = ProfileViewModel(authRepo: di.authRepo, mediaRepo: di.mediaRepo)
            let sessionVM = SessionViewModel(auth: di.authRepo, state: appState)
            
            ProfileView(vm: profileVM)
                .onAppear {
                    profileVM.setSessionViewModel(sessionVM)
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

// Temiz ve Minimal Album Row
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
