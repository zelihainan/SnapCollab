//
//  StorageManager.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 15.09.2025.


import Foundation
import SwiftUI

class StorageManager: ObservableObject {
    static let shared = StorageManager()
    
    @Published var totalStorageUsed: Int64 = 0
    @Published var isCalculating = false
    
    private init() {}
    
    func calculateStorageUsage() async {
        await MainActor.run {
            isCalculating = true
        }
        
        var totalSize: Int64 = 0
        
        if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            totalSize += await calculateDirectorySize(url: cacheURL)
        }
        
        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            totalSize += await calculateDirectorySize(url: documentsURL)
        }
        
        totalSize += await calculateUserDefaultsSize()
        
        await MainActor.run {
            self.totalStorageUsed = totalSize
            self.isCalculating = false
        }
    }
    
    private func calculateDirectorySize(url: URL) async -> Int64 {
        var totalSize: Int64 = 0
        
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                if let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
            } catch {
                continue
            }
        }
        
        return totalSize
    }
    
    private func calculateUserDefaultsSize() async -> Int64 {
        let userDefaults = UserDefaults.standard
        let dict = userDefaults.dictionaryRepresentation()
        
        do {
            let data = try PropertyListSerialization.data(
                fromPropertyList: dict,
                format: .binary,
                options: 0
            )
            return Int64(data.count)
        } catch {
            return 0
        }
    }
    
    func clearCache() async throws {
        guard let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return
        }
        
        let fileManager = FileManager.default
        let cacheContents = try fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil)
        
        for fileURL in cacheContents {
            try fileManager.removeItem(at: fileURL)
        }
        
        await calculateStorageUsage()
    }
    
    func formatStorageSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
