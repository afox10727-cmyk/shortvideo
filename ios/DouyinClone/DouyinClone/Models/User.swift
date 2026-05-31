import Foundation
import FirebaseFirestore

struct AppUser: Identifiable, Codable {
    @DocumentID var id: String?
    var username: String
    var displayName: String
    var bio: String
    var avatarUrl: String?
    var email: String
    var followerCount: Int
    var followingCount: Int
    var videoCount: Int
    var fcmToken: String?
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName
        case bio
        case avatarUrl
        case email
        case followerCount
        case followingCount
        case videoCount
        case fcmToken
        case createdAt
        case updatedAt
    }
}
