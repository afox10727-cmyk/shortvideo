import SwiftUI
import Observation

@Observable
final class FeedViewModel {
    private let videoService = VideoService()
    private let playerPool = VideoPlayerPool()

    var videos: [Video] = []
    var isLoading = false
    var isRefreshing = false
    var errorMessage: String?
    var feedMode: FeedMode = .forYou

    private var lastDocument: DocumentSnapshot?
    private var followingIds: [String] = []
    private var hasMorePages = true

    // MARK: - Fetch

    func fetchNextPage() async {
        guard !isLoading, hasMorePages else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let (newVideos, lastDoc): ([Video], DocumentSnapshot?)
            switch feedMode {
            case .forYou:
                (newVideos, lastDoc) = try await videoService.fetchFeed(
                    lastDocument: lastDocument,
                    limit: Constants.feedPageSize
                )
            case .following:
                (newVideos, lastDoc) = try await videoService.fetchFollowingFeed(
                    followingIds: followingIds,
                    lastDocument: lastDocument,
                    limit: Constants.feedPageSize
                )
            }

            videos.append(contentsOf: newVideos)
            lastDocument = lastDoc
            hasMorePages = newVideos.count == Constants.feedPageSize
        } catch {
            errorMessage = "加载失败：\(error.localizedDescription)"
        }
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        lastDocument = nil
        hasMorePages = true

        do {
            let (newVideos, lastDoc) = try await videoService.fetchFeed(limit: Constants.feedPageSize)
            videos = newVideos
            lastDocument = lastDoc
            hasMorePages = newVideos.count == Constants.feedPageSize
        } catch {
            errorMessage = "刷新失败：\(error.localizedDescription)"
        }
    }

    // MARK: - Player Management

    func player(for video: Video) -> AVPlayer? {
        guard let videoId = video.id,
              let videoUrl = video.videoUrl else { return nil }
        // Construct download URL from Storage path
        let urlString = "https://firebasestorage.googleapis.com/v0/b/\(videoUrl)?alt=media"
        guard let url = URL(string: urlString) else { return nil }
        return Task { await playerPool.acquire(for: videoId, url: url) }.value
    }

    func releasePlayer(for video: Video) {
        guard let videoId = video.id else { return }
        Task { await playerPool.release(videoId: videoId) }
    }

    func preloadNextVideo(after currentVideo: Video) {
        guard let currentIndex = videos.firstIndex(where: { $0.id == currentVideo.id }),
              currentIndex + 1 < videos.count else { return }
        let nextVideo = videos[currentIndex + 1]
        guard let videoId = nextVideo.id,
              let videoUrl = nextVideo.videoUrl,
              let url = URL(string: "https://firebasestorage.googleapis.com/v0/b/\(videoUrl)?alt=media") else { return }
        Task { await playerPool.preload(videoId: videoId, url: url) }
    }

    // MARK: - Like

    func toggleLike(for video: Video, userId: String) async {
        guard let videoId = video.id else { return }
        do {
            let alreadyLiked = try await videoService.isLiked(videoId: videoId, userId: userId)
            if alreadyLiked {
                try await videoService.unlikeVideo(videoId: videoId, userId: userId)
            } else {
                try await videoService.likeVideo(videoId: videoId, userId: userId)
            }
        } catch {
            print("Like error: \(error)")
        }
    }

    // MARK: - Mode Switch

    func switchMode(to mode: FeedMode) async {
        feedMode = mode
        lastDocument = nil
        hasMorePages = true
        videos = []
        await fetchNextPage()
    }

    // MARK: - Cleanup

    func cleanup() {
        Task { await playerPool.reset() }
    }
}
