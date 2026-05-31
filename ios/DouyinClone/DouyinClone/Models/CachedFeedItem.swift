import Foundation
import SwiftData

/// SwiftData model for offline feed caching.
/// Stores serialized Video data to persist across app launches.
@Model
final class CachedFeedItem {
    var videoId: String
    var jsonData: Data
    var cachedAt: Date

    init(videoId: String, jsonData: Data, cachedAt: Date = Date()) {
        self.videoId = videoId
        self.jsonData = jsonData
        self.cachedAt = cachedAt
    }
}
