import Foundation
import FirebaseFirestore
import FirebaseStorage

final class UserService {
    private let db: Firestore
    private let storageService: StorageService

    init(
        db: Firestore = FirebaseManager.shared.db,
        storageService: StorageService = StorageService()
    ) {
        self.db = db
        self.storageService = storageService
    }

    // MARK: - Fetch

    func fetchUser(uid: String) async throws -> AppUser {
        let snapshot = try await db.collection(Constants.usersCollection)
            .document(uid).getDocument()
        guard let user = try? snapshot.data(as: AppUser.self) else {
            throw UserError.notFound
        }
        return user
    }

    // MARK: - Update Profile

    func updateProfile(
        uid: String,
        displayName: String? = nil,
        bio: String? = nil,
        avatarImageData: Data? = nil
    ) async throws {
        var data: [String: Any] = ["updatedAt": FieldValue.serverTimestamp()]

        if let name = displayName {
            data["displayName"] = name
        }
        if let bio = bio {
            data["bio"] = bio
        }
        if let imageData = avatarImageData {
            let avatarPath = try await storageService.uploadAvatar(
                imageData: imageData,
                userId: uid
            )
            data["avatarUrl"] = avatarPath
        }

        try await db.collection(Constants.usersCollection).document(uid)
            .updateData(data)
    }

    // MARK: - Follow / Unfollow

    func follow(followerId: String, followingId: String) async throws {
        let docId = "\(followerId)_\(followingId)"
        try await db.collection(Constants.followsCollection).document(docId).setData([
            "followerId": followerId,
            "followingId": followingId,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }

    func unfollow(followerId: String, followingId: String) async throws {
        let docId = "\(followerId)_\(followingId)"
        try await db.collection(Constants.followsCollection).document(docId).delete()
    }

    func isFollowing(followerId: String, followingId: String) async throws -> Bool {
        let docId = "\(followerId)_\(followingId)"
        let doc = try await db.collection(Constants.followsCollection).document(docId).getDocument()
        return doc.exists
    }

    // MARK: - Followers / Following Lists

    func fetchFollowers(userId: String, limit: Int = 30) async throws -> [AppUser] {
        let snapshot = try await db.collection(Constants.followsCollection)
            .whereField("followingId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        let ids = snapshot.documents.compactMap { $0.data()["followerId"] as? String }
        return try await fetchUsers(ids: ids)
    }

    func fetchFollowing(userId: String, limit: Int = 30) async throws -> [AppUser] {
        let snapshot = try await db.collection(Constants.followsCollection)
            .whereField("followerId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        let ids = snapshot.documents.compactMap { $0.data()["followingId"] as? String }
        return try await fetchUsers(ids: ids)
    }

    // MARK: - Search

    func searchUsers(query: String, limit: Int = 20) async throws -> [AppUser] {
        let lowerQuery = query.lowercased()

        // User search by username prefix
        let snapshot = try await db.collection(Constants.usersCollection)
            .whereField("username", isGreaterThanOrEqualTo: lowerQuery)
            .whereField("username", isLessThan: lowerQuery + "\u{f8ff}")
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: AppUser.self) }
    }

    // MARK: - Private Helpers

    private func fetchUsers(ids: [String]) async throws -> [AppUser] {
        guard !ids.isEmpty else { return [] }

        // Firestore `whereField in` supports up to 30
        let batch = Array(ids.prefix(30))
        guard !batch.isEmpty else { return [] }

        let snapshot = try await db.collection(Constants.usersCollection)
            .whereField(FieldPath.documentID(), in: batch)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: AppUser.self) }
    }

    // MARK: - FCM Token

    func updateFCMToken(uid: String, token: String) async throws {
        try await db.collection(Constants.usersCollection).document(uid).updateData([
            "fcmToken": token,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
}

enum UserError: LocalizedError {
    case notFound

    var errorDescription: String? {
        switch self {
        case .notFound: return "用户不存在"
        }
    }
}
