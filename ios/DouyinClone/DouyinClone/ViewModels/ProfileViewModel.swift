import SwiftUI
import Observation

@Observable
final class ProfileViewModel {
    private let userService = UserService()
    private let videoService = VideoService()

    var user: AppUser?
    var videos: [Video] = []
    var isLoading = false
    var isFollowing = false
    var errorMessage: String?

    private var lastDocument: DocumentSnapshot?
    private var hasMorePages = true

    // MARK: - Load

    func loadUser(uid: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            user = try await userService.fetchUser(uid: uid)
            await loadVideos(uid: uid)
        } catch {
            errorMessage = "加载用户失败: \(error.localizedDescription)"
        }
    }

    func loadVideos(uid: String) async {
        do {
            let (newVideos, lastDoc) = try await videoService.fetchUserVideos(
                userId: uid, lastDocument: nil
            )
            videos = newVideos
            lastDocument = lastDoc
            hasMorePages = newVideos.count >= 20
        } catch {
            print("Failed to load videos: \(error)")
        }
    }

    func loadMoreVideos(uid: String) async {
        guard !isLoading, hasMorePages else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let (newVideos, lastDoc) = try await videoService.fetchUserVideos(
                userId: uid, lastDocument: lastDocument
            )
            videos.append(contentsOf: newVideos)
            lastDocument = lastDoc
            hasMorePages = newVideos.count >= 20
        } catch {
            print("Failed to load more videos: \(error)")
        }
    }

    // MARK: - Follow

    func checkFollowStatus(myId: String, targetId: String) async {
        do {
            isFollowing = try await userService.isFollowing(
                followerId: myId, followingId: targetId
            )
        } catch {
            print("Follow check error: \(error)")
        }
    }

    func toggleFollow(myId: String, targetId: String) async {
        do {
            if isFollowing {
                try await userService.unfollow(followerId: myId, followingId: targetId)
                isFollowing = false
            } else {
                try await userService.follow(followerId: myId, followingId: targetId)
                isFollowing = true
            }
        } catch {
            errorMessage = "操作失败: \(error.localizedDescription)"
        }
    }

    // MARK: - Edit

    func updateProfile(uid: String, displayName: String? = nil, bio: String? = nil, avatarData: Data? = nil) async {
        do {
            try await userService.updateProfile(
                uid: uid,
                displayName: displayName,
                bio: bio,
                avatarImageData: avatarData
            )
            // Reload
            if let updatedUser = try? await userService.fetchUser(uid: uid) {
                user = updatedUser
            }
        } catch {
            errorMessage = "更新失败: \(error.localizedDescription)"
        }
    }
}
