import Foundation

enum Constants {
    // MARK: - Firestore Collections
    static let usersCollection = "users"
    static let videosCollection = "videos"
    static let followsCollection = "follows"
    static let likesCollection = "likes"
    static let commentsCollection = "comments"
    static let notificationsCollection = "notifications"
    static let usernamesCollection = "usernames"

    // MARK: - Storage Paths
    static let rawVideosPath = "videos/raw"
    static let processedVideosPath = "videos/processed"
    static let thumbnailsPath = "thumbnails"
    static let avatarsPath = "avatars"

    // MARK: - Video
    static let maxVideoDuration: Double = 180  // 3 minutes
    static let videoResolution = CGSize(width: 1080, height: 1920)
    static let videoFrameRate: Int32 = 30
    static let videoBitrate: Float = 4_000_000  // 4 Mbps

    // MARK: - Limits
    static let feedPageSize = 10
    static let maxCaptionLength = 300
    static let maxCommentLength = 500
    static let maxBioLength = 150

    // MARK: - UI
    static let tabBarHeight: CGFloat = 49
    static let feedCellCornerRadius: CGFloat = 0
    static let thumbnailCornerRadius: CGFloat = 8
}

import CoreGraphics
