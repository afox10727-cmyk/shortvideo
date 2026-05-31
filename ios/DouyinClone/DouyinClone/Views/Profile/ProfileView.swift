import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = ProfileViewModel()
    @State private var showEditProfile = false
    @State private var showFriendsList = false
    @State private var friendsListMode: FriendsListMode = .followers

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    profileHeader
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    // Bio
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.user?.displayName ?? "")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)

                        if let bio = viewModel.user?.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    // Action buttons
                    HStack(spacing: 8) {
                        Button {
                            showEditProfile = true
                        } label: {
                            Text("编辑资料")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.1))
                                )
                                .foregroundStyle(.white)
                        }

                        Button {
                            authViewModel.signOut()
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.subheadline)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.1))
                                )
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                    Divider()
                        .background(Color.white.opacity(0.1))

                    // Video grid
                    if viewModel.videos.isEmpty && !viewModel.isLoading {
                        EmptyStateView(
                            icon: "video.slash",
                            title: "暂无视频",
                            subtitle: "发布你的第一个视频吧"
                        )
                        .padding(.top, 60)
                    } else {
                        videoGrid
                    }
                }
                .padding(.top, 8)
            }
            .background(Color.black)
            .navigationTitle(viewModel.user?.username ?? "我")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                if let uid = viewModel.user?.id ?? authViewModel.currentUser?.id {
                    await viewModel.loadVideos(uid: uid)
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(viewModel: viewModel)
            }
            .sheet(isPresented: $showFriendsList) {
                FriendsListView(
                    userId: viewModel.user?.id ?? "",
                    mode: friendsListMode
                )
            }
            .task {
                if let uid = authViewModel.currentUser?.id {
                    await viewModel.loadUser(uid: uid)
                }
            }
        }
    }

    // MARK: - Header

    private var profileHeader: some View {
        HStack(alignment: .center, spacing: 24) {
            // Avatar
            if let avatarUrl = viewModel.user?.avatarUrl {
                AsyncImage(url: URL(string: avatarUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        avatarPlaceholder
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            } else {
                avatarPlaceholder
                    .frame(width: 80, height: 80)
            }

            Spacer()

            // Stats
            HStack(spacing: 28) {
                StatBadge(
                    count: viewModel.user?.videoCount ?? 0,
                    label: "视频"
                )
                StatBadge(
                    count: viewModel.user?.followerCount ?? 0,
                    label: "粉丝"
                ) {
                    friendsListMode = .followers
                    showFriendsList = true
                }
                StatBadge(
                    count: viewModel.user?.followingCount ?? 0,
                    label: "关注"
                ) {
                    friendsListMode = .following
                    showFriendsList = true
                }
            }
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.pink.opacity(0.6), .purple.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Text(String((viewModel.user?.username ?? "?").prefix(1)).uppercased())
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
    }

    // MARK: - Video Grid (3 columns)

    private var videoGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

        return LazyVGrid(columns: columns, spacing: 2) {
            ForEach(viewModel.videos) { video in
                ProfileVideoGridCell(video: video)
            }

            // Load more trigger
            if viewModel.videos.count >= 20 {
                Color.clear
                    .frame(height: 40)
                    .onAppear {
                        if let uid = viewModel.user?.id {
                            Task { await viewModel.loadMoreVideos(uid: uid) }
                        }
                    }
            }
        }
    }
}

// MARK: - Video Grid Cell

struct ProfileVideoGridCell: View {
    let video: Video

    var body: some View {
        ZStack {
            // Placeholder colored background
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hue: Double.random(in: 0...1), saturation: 0.3, brightness: 0.3),
                            Color(hue: Double.random(in: 0...1), saturation: 0.3, brightness: 0.15)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .aspectRatio(9/16, contentMode: .fill)

            // Play icon
            Image(systemName: "play.fill")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
                .padding(6)
                .background(Circle().fill(Color.black.opacity(0.4)))

            // Like count
            VStack {
                Spacer()
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                    Text(Formatters.formatCount(video.likeCount))
                        .font(.system(size: 10))
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(6)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .clipShape(Rectangle())
        .contentShape(Rectangle())
    }
}

// MARK: - Edit Profile

struct EditProfileView: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var displayName = ""
    @State private var bio = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("头像") {
                    HStack {
                        Spacer()
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.pink, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .overlay {
                                Image(systemName: "camera.fill")
                                    .foregroundStyle(.white)
                            }
                        Spacer()
                    }
                }
                .listRowBackground(Color.white.opacity(0.05))

                Section("昵称") {
                    TextField("昵称", text: $displayName)
                }
                .listRowBackground(Color.white.opacity(0.05))

                Section("简介") {
                    TextField("介绍一下自己...", text: $bio, axis: .vertical)
                        .lineLimit(3...5)
                }
                .listRowBackground(Color.white.opacity(0.05))
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        Task {
                            await viewModel.updateProfile(
                                uid: viewModel.user?.id ?? "",
                                displayName: displayName.isEmpty ? nil : displayName,
                                bio: bio.isEmpty ? nil : bio
                            )
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                displayName = viewModel.user?.displayName ?? ""
                bio = viewModel.user?.bio ?? ""
            }
        }
    }
}

// MARK: - Friends List Mode

enum FriendsListMode {
    case followers, following
}

#Preview {
    ProfileView()
        .environment(AuthViewModel())
        .preferredColorScheme(.dark)
}
