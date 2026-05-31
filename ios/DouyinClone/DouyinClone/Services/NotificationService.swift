import Foundation
import FirebaseFirestore

final class NotificationService {
    private let db: Firestore

    init(db: Firestore = FirebaseManager.shared.db) {
        self.db = db
    }

    func fetchNotifications(userId: String, limit: Int = 30) async throws -> [Notification] {
        let snapshot = try await db.collection(Constants.notificationsCollection)
            .whereField("recipientId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Notification.self) }
    }

    func markAsRead(notificationId: String) async throws {
        try await db.collection(Constants.notificationsCollection)
            .document(notificationId)
            .updateData(["isRead": true])
    }

    func markAllAsRead(userId: String) async throws {
        let unread = try await db.collection(Constants.notificationsCollection)
            .whereField("recipientId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()

        let batch = db.batch()
        for doc in unread.documents {
            batch.updateData(["isRead": true], forDocument: doc.reference)
        }
        try await batch.commit()
    }

    func unreadCount(userId: String) async throws -> Int {
        let snapshot = try await db.collection(Constants.notificationsCollection)
            .whereField("recipientId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .count
            .getAggregation(source: .server)

        return Int(truncating: snapshot.count)
    }
}
