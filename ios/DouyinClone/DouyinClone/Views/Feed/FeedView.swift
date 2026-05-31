import SwiftUI

struct FeedView: View {
    @State private var viewModel = FeedViewModel()
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var currentIndex = 0
    @State private var networkMonitor = NetworkMonitor.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if viewModel.videos.isEmpty && !viewModel.isLoading {
                    EmptyStateView(
                        icon: "play.rectangle",
                        title: "暂无视频",
                        subtitle: "下拉刷新试试"
                    )
                } else {
                    // Vertical paging feed
                    ScrollView(.vertical) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.videos.enumerated()), id: \.element.id) { index, video in
                                GeometryReader { geo in
                                    let isVisible = abs(geo.frame(in: .global).minY) < UIScreen.main.bounds.height * 0.7

                                    FeedCell(
                                        video: video,
                                        player: viewModel.player(for: video),
                                        isVisible: isVisible && index == currentIndex
                                    )
                                    .frame(
                                        width: UIScreen.main.bounds.width,
                                        height: UIScreen.main.bounds.height
                                    )
                                    .onAppear {
                                        if index == currentIndex {
                                            viewModel.preloadNextVideo(after: video)
                                        }
                                    }
                                    .onDisappear {
                                        viewModel.releasePlayer(for: video)
                                    }
                                }
                                .frame(height: UIScreen.main.bounds.height)
                            }

                            // Load more
                            if viewModel.hasMorePages {
                                ProgressView()
                                    .tint(.white)
                                    .frame(height: 100)
                                    .onAppear {
                                        Task { await viewModel.fetchNextPage() }
                                    }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: Binding(
                        get: {
                            currentIndex < viewModel.videos.count ? viewModel.videos[currentIndex].id : nil
                        },
                        set: { newId in
                            if let newId = newId,
                               let idx = viewModel.videos.firstIndex(where: { $0.id == newId }) {
                                currentIndex = idx
                            }
                        }
                    ))
                    .ignoresSafeArea()
                    .scrollIndicators(.hidden)
                }

                // Top bar
                VStack {
                    HStack {
                        // Feed mode toggle
                        Picker("", selection: Binding(
                            get: { viewModel.feedMode },
                            set: { newMode in
                                Task { await viewModel.switchMode(to: newMode) }
                            }
                        )) {
                            ForEach(FeedMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)

                        Spacer()

                        // Search
                        NavigationLink(destination: DiscoverView()) {
                            Image(systemName: "magnifyingglass")
                                .font(.title3)
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 56)
                    .background(
                        LinearGradient(
                            colors: [Color.black.opacity(0.6), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    Spacer()
                }

                // Offline banner
                if !networkMonitor.isConnected {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "wifi.slash")
                            Text("无网络连接 — 显示缓存内容")
                                .font(.caption)
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Capsule().fill(Color.orange.opacity(0.8)))
                        .padding(.bottom, 100)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await viewModel.fetchNextPage()
            }
            .refreshable {
                await viewModel.refresh()
            }
            .onDisappear {
                viewModel.cleanup()
            }
        }
    }
}

#Preview {
    FeedView()
        .environment(AuthViewModel())
}
