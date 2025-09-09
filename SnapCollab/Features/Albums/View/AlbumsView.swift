//
// AlbumsView.swift güncellemesi - toolbar kısmında profil butonu eklenecek
//

import SwiftUI

struct AlbumsView: View {
    @StateObject var vm: AlbumsViewModel
    @Environment(\.di) var di
    @State private var showProfile = false

    var body: some View {
        List {
            ForEach(vm.albums, id: \.id) { album in
                NavigationLink(album.title) {
                    AlbumDetailView(album: album, di: di)
                }
            }
        }
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
            ProfileView(vm: ProfileViewModel(authRepo: di.authRepo, mediaRepo: di.mediaRepo))
        }
        .task { vm.start() }
    }
}
