import SwiftUI

struct AlbumDetailView: View {
    let album: Album
    @StateObject private var vm: MediaViewModel

    init(album: Album, di: DIContainer) {
        self.album = album
        _vm = StateObject(wrappedValue: MediaViewModel(repo: di.mediaRepo,
                                                       albumId: album.id!))
    }

    var body: some View {
        MediaGridView(vm: vm)
            .navigationTitle(album.title)
    }
}
