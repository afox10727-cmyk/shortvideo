import Foundation
import FirebaseFirestore

final class VideoService {
    private let db: Firestore
    private let storageService: StorageService

    init(
        db: Firestore = FirebaseManager.shared.db,
        storageService: StorageService = StorageService()
    ) {
        self.db = db
        self.storageService = storageService
    }

    // MARK: - Create Video Document

    /// Create a placeholder video document before upload starts.
    func createVideoPlaceholder(
        userId: String,
        caption: String,
        tags: [String]
    ) throws -> DocumentReference {
        let data: [String: Any] = [
            "userId": userId,
            "caption": caption,
            "tags": tags,
            "videoUrl": NSNull(),
            "thumbnailUrl": NSNull(),
            "duration": 0,
            "width": 0,
            "height": 0,
            "likeCount": 0,
            "commentCount": 0,
            "shareCount": 0,
            "viewCount": 0,
            "processingStatus": Video.ProcessingStatus.uploading.rawValue,
            "isPrivate": false,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        return try db.collection(Constants.videosCollection).addDocument(data: data)
    }

    // MARK: - Complete Upload Flow

    /// Full upload flow: compress → upload → mark processing → wait for ready.
    func publishVideo(
        localURL: URL,
        userId: String,
        caption: String,
        tags: [String],
        onUploadProgress: @escaping (Double) -> Void
    ) async throws -> String {
        // 1. Create placeholder
        let videoRef = try createVideoPlaceholder(userId: userId, caption: caption, tags: tags)
        let videoId = videoRef.documentID

        // 2. Upload video
        let videoPath = try await storageService.uploadVideo(
            localURL: localURL,
            userId: userId,
            videoId: videoId,
            onProgress: onUploadProgress
        )

        // 3. Mark as processing (triggers Cloud Function)
        try await videoRef.updateData([
            "videoUrl": videoPath,
            "processingStatus": Video.ProcessingStatus.processing.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ])

        return videoId
    }

    // MARK: - Fetch Videos

    /// Fetch global feed (newest videos that are ready)
    func fetchFeed(lastDocument: DocumentSnapshot? = nil, limit: Int = 10) async throws -> ([Video], DocumentSnapshot?) {
        var query = db.collection(Constants.videosCollection)
            .whereField("processingStatus", isEqualTo: Video.ProcessingStatus.ready.rawValue)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)

        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }

        let snapshot = try await query.getDocuments()
        let videos = snapshot.documents.compactMap { try? $0.data(as: Video.self) }
        return (videos, snapshot.documents.last)
    }

    /// Fetch videos by a specific user
    func fetchUserVideos(userId: String, lastDocument: DocumentSnapshot? = nil, limit: Int = 20) async throws -> ([Video], DocumentSnapshot?) {
        var query = db.collection(Constants.videosCollection)
            .whereField("userId", isEqualTo: userId)
            .whereField("processingStatus", isEqualTo: Video.ProcessingStatus.ready.rawValue)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)

        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }

        let snapshot = try await query.getDocuments()
        let videos = snapshot.documents.compactMap { try? $0.data(as: Video.self) }
        return (videos, snapshot.documents.last)
    }

    /// Fetch following feed
    func fetchFollowingFeed(followingIds: [String], lastDocument: DocumentSnapshot? = nil, limit: Int = 10) async throws -> ([Video], DocumentSnapshot?) {
        guard !followingIds.isEmpty else { return ([], nil) }

        // Firestore `in` supports up to 30 values
        let batch = Array(followingIds.prefix(30))

        var query = db.collection(Constants.videosCollection)
            .whereField("userId", in: batch)
            .whereField("processingStatus", isEqualTo: Video.ProcessingStatus.ready.rawValue)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)

        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }

        let snapshot = try await query.getDocuments()
        let videos = snapshot.documents.compactMap { try? $0.data(as: Video.self) }
        return (videos, snapshot.documents.last)
    }

    // MARK: - Single Video

    func fetchVideo(videoId: String) async throws -> Video {
        let snapshot = try await db.collection(Constants.videosCollection).document(videoId).getDocument()
        guard let video = try? snapshot.data(as: Video.self) else {
            throw VideoError.notFound
        }
        return video
    }

    // MARK: - Like / Unlike

    func likeVideo(videoId: String, userId: String) async throws {
        let likeId = "\(userId)_\(videoId)"
        try await db.collection(Constants.likesCollection).document(likeId).setData([
            "userId": userId,
            "videoId": videoId,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }

    func unlikeVideo(videoId: String, userId: String) async throws {
        let likeId = "\(userId)_\(videoId)"
        try await db.collection(Constants.likesCollection).document(likeId).delete()
    }

    func isLiked(videoId: String, userId: String) async throws -> Bool {
        let likeId = "\(userId)_\(videoId)"
        let doc = try await db.collection(Constants.likesCollection).document(likeId).getDocument()
        return doc.exists
    }

    // MARK: - Delete

    func deleteVideo(videoId: String) async throws {
        // Delete Storage files
        let video = try await fetchVideo(videoId: videoId)
        if let videoPath = video.videoUrl {
            try? await storageService.deleteVideo(at: videoPath)
        }
        if let thumbnailPath = video.thumbnailUrl {
            try? await storageService.deleteVideo(at: thumbnailPath)
        }

        // Delete Firestore document
        try await db.collection(Constants.videosCollection).document(videoId).delete()
    }

    // MARK: - Listen for Processing

    func observeVideoProcessing(videoId: String, onChange: @escaping (Video.ProcessingStatus) -> Void) -> ListenerRegistration {
        return db.collection(Constants.videosCollection).document(videoId)
            .addSnapshotListener { snapshot, error in
                guard let data = snapshot?.data(),
                      let statusRaw = data["processingStatus"] as? String,
                      let status = Video.ProcessingStatus(rawValue: statusRaw) else {
                    return
                }
                onChange(status)
            }
    }
}

enum VideoError: LocalizedError {
    case notFound

    var errorDescription: String? {
        switch self {
        case .notFound: return "视频不存在"
        }
    }
}
