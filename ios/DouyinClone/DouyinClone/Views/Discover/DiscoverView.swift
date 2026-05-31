import SwiftUI

struct DiscoverView: View {
    @State private var viewModel = SearchViewModel()
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 10) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.gray)
                            TextField("搜索用户", text: Bindable(viewModel).searchQuery)
                                .autocapitalization(.none)
                                .submitLabel(.search)
                                .onSubmit {
                                    Task { await viewModel.search() }
                                }

                            if !viewModel.searchQuery.isEmpty {
                                Button {
                                    viewModel.clearSearch()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.gray)
                                }
                            }
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    // Content
                    if viewModel.isSearching {
                        ProgressView()
                            .tint(.white)
                            .padding(.top, 60)
                    } else if !viewModel.searchQuery.isEmpty {
                        // Search results
                        if viewModel.searchResults.isEmpty {
                            EmptyStateView(
                                icon: "person.slash",
                                title: "未找到用户",
                                subtitle: "试试其他关键词"
                            )
                            .padding(.top, 60)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(viewModel.searchResults) { user in
                                        searchResultRow(user)
                                    }
                                }
                            }
                        }
                    } else {
                        // Default discover content
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                // Trending section
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "flame.fill")
                                            .foregroundStyle(.orange)
                                        Text("热门话题")
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                    }

                                    LazyVGrid(
                                        columns: [
                                            GridItem(.flexible()),
                                            GridItem(.flexible())
                                        ],
                                        spacing: 8
                                    ) {
                                        ForEach(viewModel.trendingTags, id: \.self) { tag in
                                            Button {
                                                viewModel.searchQuery = tag
                                                Task { await viewModel.search() }
                                            } label: {
                                                HStack {
                                                    Text("#\(tag)")
                                                        .font(.subheadline)
                                                        .foregroundStyle(.white)
                                                    Spacer()
                                                    Text("热门")
                                                        .font(.caption2)
                                                        .foregroundStyle(.orange)
                                                }
                                                .padding(12)
                                                .background(Color.white.opacity(0.06))
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)

                                // Suggested users
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "person.2.fill")
                                            .foregroundStyle(.blue)
                                        Text("推荐用户")
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                    }

                                    ForEach(0..<5, id: \.self) { _ in
                                        suggestedUserRow
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
            }
            .navigationTitle("发现")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Search Result Row

    private func searchResultRow(_ user: AppUser) -> some View {
        HStack(spacing: 12) {
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

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()

            if let myId = authViewModel.currentUser?.id, let userId = user.id, myId != userId {
                FollowButton(isFollowing: false) {
                    // Follow action
                }
                .frame(width: 80)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Suggested User Row

    private var suggestedUserRow: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.gray)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("推荐用户")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                Text("热门创作者")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()

            FollowButton(isFollowing: false, action: {})
                .frame(width: 80)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DiscoverView()
        .environment(AuthViewModel())
}
