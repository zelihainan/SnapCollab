//
//  FirebaseStorageService.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import FirebaseStorage
import Foundation

final class FirebaseStorageService: ImageCaching {
    private let storage = Storage.storage()

    func url(for storagePath: String) async throws -> URL {
        let ref = storage.reference(withPath: storagePath)
        return try await ref.downloadURL()
    }

    func put(data: Data, to storagePath: String) async throws {
        let ref = storage.reference(withPath: storagePath)
        _ = try await ref.putDataAsync(data)
    }
}
