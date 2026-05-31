import Foundation
import FirebaseStorage

final class StorageService {
    private let storage: Storage
    private let videoCompressor = VideoCompressor()

    init(storage: Storage = FirebaseManager.shared.storage) {
        self.storage = storage
    }

    // MARK: - Video Upload

    /// Upload a video file to Firebase Storage with progress tracking.
    /// Returns the Storage path on completion.
    func uploadVideo(
        localURL: URL,
        userId: String,
        videoId: String,
        onProgress: @escaping (Double) -> Void
    ) async throws -> String {
        // Compress first
        let compressedURL: URL
        do {
            compressedURL = try await videoCompressor.compress(sourceURL: localURL)
        } catch {
            // If compression fails, upload original
            print("Compression failed, uploading original: \(error)")
            compressedURL = localURL
        }

        let storagePath = "\(FirebaseManager.StoragePaths.rawVideos)/\(userId)/\(videoId).mp4"
        let storageRef = storage.reference().child(storagePath)

        // Create metadata
        let metadata = StorageMetadata()
        metadata.contentType = "video/mp4"
        metadata.customMetadata = [
            "userId": userId,
            "videoId": videoId
        ]

        // Upload with progress
        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let uploadTask = storageRef.putFile(from: compressedURL, metadata: metadata)

            uploadTask.observe(.progress) { snapshot in
                if let progress = snapshot.progress {
                    let pct = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                    onProgress(pct)
                }
            }

            uploadTask.observe(.success) { _ in
                continuation.resume()
            }

            uploadTask.observe(.failure) { snapshot in
                if let error = snapshot.error {
                    continuation.resume(throwing: error)
                }
            }
        }

        // Clean up temp files
        try? FileManager.default.removeItem(at: compressedURL)
        if compressedURL != localURL {
            try? FileManager.default.removeItem(at: localURL)
        }

        return storagePath
    }

    // MARK: - Thumbnail Upload

    func uploadThumbnail(
        imageData: Data,
        videoId: String
    ) async throws -> String {
        let storagePath = "\(FirebaseManager.StoragePaths.thumbnails)/\(videoId).jpg"
        let storageRef = storage.reference().child(storagePath)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        return storagePath
    }

    // MARK: - Avatar Upload

    func uploadAvatar(
        imageData: Data,
        userId: String
    ) async throws -> String {
        let storagePath = "\(FirebaseManager.StoragePaths.avatars)/\(userId).jpg"
        let storageRef = storage.reference().child(storagePath)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        return storagePath
    }

    // MARK: - Delete

    func deleteVideo(at path: String) async throws {
        try await storage.reference().child(path).delete()
    }

    // MARK: - Download URL

    func getDownloadURL(for path: String) async throws -> URL {
        let ref = storage.reference().child(path)
        return try await ref.downloadURL()
    }
}
