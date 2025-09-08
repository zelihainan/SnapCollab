import SwiftUI

struct AlbumsView: View {
    @StateObject var vm: AlbumsViewModel
    @Environment(\.di) var di

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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { vm.showCreate = true } label: { Image(systemName: "plus") }
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
        .task { vm.start() }
    }
}
