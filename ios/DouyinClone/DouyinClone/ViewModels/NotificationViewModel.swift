import SwiftUI
import Observation

@Observable
final class NotificationViewModel {
    private let notificationService = NotificationService()

    var notifications: [Notification] = []
    var unreadCount = 0
    var isLoading = false

    func loadNotifications(userId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            notifications = try await notificationService.fetchNotifications(userId: userId)
            unreadCount = try await notificationService.unreadCount(userId: userId)
        } catch {
            print("Failed to load notifications: \(error)")
        }
    }

    func markAsRead(_ notification: Notification) async {
        guard let id = notification.id, !notification.isRead else { return }
        do {
            try await notificationService.markAsRead(notificationId: id)
            if let idx = notifications.firstIndex(where: { $0.id == id }) {
                notifications[idx].isRead = true
            }
            unreadCount = max(0, unreadCount - 1)
        } catch {
            print("Failed to mark as read: \(error)")
        }
    }

    func markAllAsRead(userId: String) async {
        do {
            try await notificationService.markAllAsRead(userId: userId)
            for i in notifications.indices {
                notifications[i].isRead = true
            }
            unreadCount = 0
        } catch {
            print("Failed to mark all as read: \(error)")
        }
    }
}
