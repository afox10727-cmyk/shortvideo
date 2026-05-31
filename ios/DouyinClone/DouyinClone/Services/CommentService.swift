import Foundation
import FirebaseFirestore

final class CommentService {
    private let db: Firestore

    init(db: Firestore = FirebaseManager.shared.db) {
        self.db = db
    }

    func fetchComments(videoId: String, limit: Int = 50) async throws -> [Comment] {
        let snapshot = try await db.collection("videos").document(videoId)
            .collection("comments")
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Comment.self) }
    }

    func postComment(videoId: String, userId: String, text: String) async throws {
        let data: [String: Any] = [
            "userId": userId,
            "text": text,
            "likeCount": 0,
            "createdAt": FieldValue.serverTimestamp()
        ]
        try await db.collection("videos").document(videoId)
            .collection("comments")
            .addDocument(data: data)
    }

    func deleteComment(videoId: String, commentId: String) async throws {
        try await db.collection("videos").document(videoId)
            .collection("comments")
            .document(commentId)
            .delete()
    }
}
