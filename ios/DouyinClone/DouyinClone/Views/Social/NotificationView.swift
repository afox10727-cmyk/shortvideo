import SwiftUI

struct NotificationView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = NotificationViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if viewModel.notifications.isEmpty && !viewModel.isLoading {
                    EmptyStateView(
                        icon: "bell.slash",
                        title: "暂无通知",
                        subtitle: "当有人点赞、评论或关注你时会显示在这里"
                    )
                } else {
                    List {
                        ForEach(viewModel.notifications) { notification in
                            NotificationRow(notification: notification)
                                .listRowBackground(
                                    notification.isRead
                                        ? Color.clear
                                        : Color.white.opacity(0.03)
                                )
                                .listRowSeparator(.hidden)
                                .onTapGesture {
                                    Task { await viewModel.markAsRead(notification) }
                                }
                                .swipeActions(edge: .trailing) {
                                    Button("已读") {
                                        Task { await viewModel.markAsRead(notification) }
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        if let uid = authViewModel.currentUser?.id {
                            await viewModel.loadNotifications(userId: uid)
                        }
                    }
                }
            }
            .navigationTitle("通知")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.unreadCount > 0 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("全部已读") {
                            if let uid = authViewModel.currentUser?.id {
                                Task { await viewModel.markAllAsRead(userId: uid) }
                            }
                        }
                        .font(.caption)
                    }
                }
            }
            .task {
                if let uid = authViewModel.currentUser?.id {
                    await viewModel.loadNotifications(userId: uid)
                }
            }
        }
    }
}

// MARK: - Notification Row

struct NotificationRow: View {
    let notification: Notification

    var body: some View {
        HStack(spacing: 12) {
            // Icon based on type
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 44, height: 44)

                Image(systemName: iconName)
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(notification.createdAt.timeAgo)
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }

            Spacer()

            // Unread indicator
            if !notification.isRead {
                Circle()
                    .fill(.pink)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 2)
        .opacity(notification.isRead ? 0.6 : 1.0)
    }

    private var iconName: String {
        switch notification.type {
        case .like: return "heart.fill"
        case .comment: return "bubble.right.fill"
        case .follow: return "person.fill.badge.plus"
        case .videoProcessed: return "checkmark.circle.fill"
        }
    }

    private var iconBackgroundColor: Color {
        switch notification.type {
        case .like: return .red
        case .comment: return .blue
        case .follow: return .green
        case .videoProcessed: return .purple
        }
    }
}

#Preview {
    NotificationView()
        .environment(AuthViewModel())
}
