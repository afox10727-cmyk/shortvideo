import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import FirebaseMessaging

/// Central singleton for Firebase service instances.
/// Every other service depends on this.
final class FirebaseManager {
    static let shared = FirebaseManager()

    let db: Firestore
    let storage: Storage
    let auth: Auth

    private init() {
        self.db = Firestore.firestore()
        self.storage = Storage.storage()
        self.auth = Auth.auth()

        // Enable offline persistence
        let settings = FirestoreSettings()
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        settings.isPersistenceEnabled = true
        db.settings = settings
    }
}

// MARK: - Collection Paths

extension FirebaseManager {
    enum Collections {
        static let users = "users"
        static let videos = "videos"
        static let follows = "follows"
        static let likes = "likes"
        static let comments = "comments"
        static let notifications = "notifications"
        static let usernames = "usernames"
    }

    enum StoragePaths {
        static let rawVideos = "videos/raw"
        static let processedVideos = "videos/processed"
        static let thumbnails = "thumbnails"
        static let avatars = "avatars"
    }
}
