import SwiftUI
import Observation

@Observable
final class UploadViewModel {
    private let videoService = VideoService()

    var caption = ""
    var tagsText = ""
    var isPrivate = false
    var uploadProgress: Double = 0
    var uploadState: UploadState = .pending
    var errorMessage: String?
    var publishedVideoId: String?

    var tags: [String] {
        tagsText
            .split(separator: " ")
            .map { $0.hasPrefix("#") ? String($0) : "#\($0)" }
            .filter { $0.count > 1 }
    }

    // MARK: - Publish

    func publish(userId: String, videoURL: URL) async {
        uploadState = .compressing
        errorMessage = nil

        do {
            let videoId = try await videoService.publishVideo(
                localURL: videoURL,
                userId: userId,
                caption: caption,
                tags: tags,
                onUploadProgress: { [weak self] progress in
                    Task { @MainActor in
                        self?.uploadProgress = progress
                        self?.uploadState = .uploading
                    }
                }
            )

            uploadProgress = 1.0
            publishedVideoId = videoId
            uploadState = .completed
        } catch {
            errorMessage = "上传失败：\(error.localizedDescription)"
            uploadState = .failed
        }
    }

    var isValid: Bool {
        !caption.trimmed.isEmpty
    }
}
