import SwiftUI

struct FriendsListView: View {
    let userId: String
    let mode: FriendsListMode

    @State private var users: [AppUser] = []
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss

    private let userService = UserService()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if users.isEmpty {
                    EmptyStateView(
                        icon: "person.2.slash",
                        title: mode == .followers ? "暂无粉丝" : "暂未关注",
                        subtitle: mode == .followers
                            ? "发布更多视频来吸引粉丝吧"
                            : "去看看推荐用户吧"
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(users) { user in
                            friendRow(user)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color.black)
            .navigationTitle(mode == .followers ? "粉丝" : "关注")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") { dismiss() }
                }
            }
            .task { await loadUsers() }
        }
    }

    private func friendRow(_ user: AppUser) -> some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.pink.opacity(0.5), .purple.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
                .overlay {
                    Text(String(user.username.prefix(1)).uppercased())
                        .font(.headline)
                        .foregroundStyle(.white)
                }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundStyle(.gray)
                if !user.bio.isEmpty {
                    Text(user.bio)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Stats
            VStack(alignment: .trailing, spacing: 2) {
                Text(Formatters.formatCount(user.followerCount))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text("粉丝")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }

            // Follow button
            FollowButton(isFollowing: false, action: {
                // TODO: Connect to current user's follow action
            })
            .frame(width: 80)
        }
        .padding(.vertical, 4)
    }

    private func loadUsers() async {
        isLoading = true
        defer { isLoading = false }

        do {
            switch mode {
            case .followers:
                users = try await userService.fetchFollowers(userId: userId)
            case .following:
                users = try await userService.fetchFollowing(userId: userId)
            }
        } catch {
            print("Failed to load users: \(error)")
        }
    }
}

#Preview {
    FriendsListView(userId: "test", mode: .followers)
}
