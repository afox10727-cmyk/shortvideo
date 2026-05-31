import Foundation
import SwiftData

/// SwiftData-backed feed cache for offline viewing.
/// Caches the last N feed items as serialized JSON for offline display.
@ModelActor
actor FeedCacheActor {
    func cacheVideos(_ videos: [Video]) throws {
        // Clear old cache
        let oldItems = try modelContext.fetch(FetchDescriptor<CachedFeedItem>())
        for item in oldItems {
            modelContext.delete(item)
        }

        // Insert new items
        for video in videos {
            guard let videoId = video.id,
                  let jsonData = try? JSONEncoder().encode(video) else { continue }
            let item = CachedFeedItem(videoId: videoId, jsonData: jsonData, cachedAt: Date())
            modelContext.insert(item)
        }

        try modelContext.save()
    }

    func loadCachedVideos() -> [Video] {
        guard let items = try? modelContext.fetch(
            FetchDescriptor<CachedFeedItem>(sortBy: [SortDescriptor(\.cachedAt, order: .reverse)])
        ) else { return [] }

        return items.compactMap { item in
            try? JSONDecoder().decode(Video.self, from: item.jsonData)
        }
    }

    func clearCache() throws {
        let items = try modelContext.fetch(FetchDescriptor<CachedFeedItem>())
        for item in items {
            modelContext.delete(item)
        }
        try modelContext.save()
    }
}

// MARK: - Sync Service

@Observable
final class FeedCacheService {
    private var actor: FeedCacheActor?

    func setActor(_ actor: FeedCacheActor) {
        self.actor = actor
    }

    func cacheFeed(_ videos: [Video]) {
        guard let actor = actor else { return }
        Task {
            try? await actor.cacheVideos(videos)
        }
    }

    func loadCachedFeed() async -> [Video] {
        guard let actor = actor else { return [] }
        return await actor.loadCachedVideos()
    }
}
