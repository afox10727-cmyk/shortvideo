import Foundation
import FirebaseFirestore

struct Video: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var caption: String
    var tags: [String]
    var videoUrl: String?
    var thumbnailUrl: String?
    var duration: Double
    var width: Int
    var height: Int
    var likeCount: Int
    var commentCount: Int
    var shareCount: Int
    var viewCount: Int
    var processingStatus: ProcessingStatus
    var isPrivate: Bool
    var createdAt: Date
    var updatedAt: Date

    enum ProcessingStatus: String, Codable {
        case uploading
        case processing
        case ready
        case failed
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case caption
        case tags
        case videoUrl
        case thumbnailUrl
        case duration
        case width
        case height
        case likeCount
        case commentCount
        case shareCount
        case viewCount
        case processingStatus
        case isPrivate
        case createdAt
        case updatedAt
    }
}

struct Comment: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var text: String
    var likeCount: Int
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case text
        case likeCount
        case createdAt
    }
}

struct Notification: Identifiable, Codable {
    @DocumentID var id: String?
    var recipientId: String
    var senderId: String
    var type: NotificationType
    var videoId: String?
    var commentId: String?
    var message: String
    var isRead: Bool
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case recipientId
        case senderId
        case type
        case videoId
        case commentId
        case message
        case isRead
        case createdAt
    }
}

enum NotificationType: String, Codable {
    case like
    case comment
    case follow
    case videoProcessed = "video_processed"
}

struct FollowRelation: Identifiable, Codable {
    @DocumentID var id: String?
    var followerId: String
    var followingId: String
    var createdAt: Date
}
