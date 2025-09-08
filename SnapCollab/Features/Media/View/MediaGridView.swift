import SwiftUI
import PhotosUI

struct MediaGridView: View {
    @ObservedObject var vm: MediaViewModel
    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedItem: MediaItem?
    @State private var showViewer = false

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [.init(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                ForEach(vm.items) { item in
                    AsyncImageView(pathProvider: { await vm.imageURL(for: item) })
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                        .cornerRadius(8)
                        .onTapGesture {
                            selectedItem = item
                            showViewer = true
                        }
                }
            }
            .padding(8)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Image(systemName: "plus")
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
            if let selectedItem {
                MediaViewerView(vm: vm, item: selectedItem) {
                    showViewer = false
                }
            } else {
                // güvenli kapatma
                Color.black.ignoresSafeArea().onTapGesture { showViewer = false }
            }
        }
        .task { vm.start() }
    }
}
