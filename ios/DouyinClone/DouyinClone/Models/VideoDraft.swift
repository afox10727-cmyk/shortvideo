import Foundation
import SwiftData

@Model
final class VideoDraft {
    var id: UUID
    var localVideoPath: String
    var caption: String
    var tags: [String]
    var createdAt: Date
    var uploadStateRaw: String
    var uploadProgress: Double

    var uploadState: UploadState {
        get { UploadState(rawValue: uploadStateRaw) ?? .pending }
        set { uploadStateRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        localVideoPath: String,
        caption: String = "",
        tags: [String] = [],
        uploadState: UploadState = .pending,
        uploadProgress: Double = 0.0
    ) {
        self.id = id
        self.localVideoPath = localVideoPath
        self.caption = caption
        self.tags = tags
        self.createdAt = Date()
        self.uploadStateRaw = uploadState.rawValue
        self.uploadProgress = uploadProgress
    }
}
