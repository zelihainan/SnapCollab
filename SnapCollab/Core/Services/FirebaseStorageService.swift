//
//  FirebaseStorageService.swift
//  SnapCollab
//
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
        
        var metadata = StorageMetadata()
        
        if storagePath.lowercased().hasSuffix(".mp4") {
            metadata.contentType = "video/mp4"
        } else if storagePath.lowercased().hasSuffix(".mov") {
            metadata.contentType = "video/quicktime"
        } else if storagePath.lowercased().hasSuffix(".jpg") || storagePath.lowercased().hasSuffix(".jpeg") {
            metadata.contentType = "image/jpeg"
        } else if storagePath.lowercased().hasSuffix(".png") {
            metadata.contentType = "image/png"
        }
        
        metadata.cacheControl = "public, max-age=300"
        
        _ = try await ref.putDataAsync(data, metadata: metadata)
        print("🔥 Firebase Storage: Uploaded with content-type: \(metadata.contentType ?? "none")")
    }
    
    func delete(path: String) async throws {
        let ref = storage.reference(withPath: path)
        try await ref.delete()
    }
}
