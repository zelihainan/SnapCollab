//
//  FirestoreNotificationService.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 12.09.2025.
//

import Foundation
import FirebaseFirestore

protocol NotificationProviding {
    func createNotification(_ notification: AppNotification) async throws
    func getNotifications(for userId: String) -> AsyncStream<[AppNotification]>
    func markAsRead(_ notificationId: String) async throws
    func markAllAsRead(for userId: String) async throws
    func deleteNotification(_ notificationId: String) async throws
}

final class FirestoreNotificationService: NotificationProviding {
    private let db = Firestore.firestore()
    
    func createNotification(_ notification: AppNotification) async throws {
        let ref = db.collection("notifications").document()
        var notificationWithId = notification
        notificationWithId.id = ref.documentID
        
        try ref.setData(from: notificationWithId)
        print("Notification created: \(notification.type.rawValue)")
    }
    
    func getNotifications(for userId: String) -> AsyncStream<[AppNotification]> {
        AsyncStream { continuation in
            let listener = db.collection("notifications")
                .whereField("toUserId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
                .limit(to: 100)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        print("Notification fetch error: \(error)")
                        continuation.yield([])
                        return
                    }
                    
                    let notifications = snapshot?.documents.compactMap { doc in
                        try? doc.data(as: AppNotification.self)
                    } ?? []
                    
                    continuation.yield(notifications)
                }
            
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
    
    func markAsRead(_ notificationId: String) async throws {
        try await db.collection("notifications")
            .document(notificationId)
            .updateData(["isRead": true])
    }
    
    func markAllAsRead(for userId: String) async throws {
        let batch = db.batch()
        let snapshot = try await db.collection("notifications")
            .whereField("toUserId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()
        
        for doc in snapshot.documents {
            batch.updateData(["isRead": true], forDocument: doc.reference)
        }
        
        try await batch.commit()
    }
    
    func deleteNotification(_ notificationId: String) async throws {
        try await db.collection("notifications")
            .document(notificationId)
            .delete()
    }
}
