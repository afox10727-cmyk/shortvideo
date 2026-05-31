import AVFoundation

/// Actor that manages a pool of AVPlayer instances for feed video playback.
/// Limits concurrent players to 3, recycles them as cells appear/disappear.
actor VideoPlayerPool {
    static let maxPoolSize = 3

    private var availablePlayers: [AVPlayer] = []
    private var inUsePlayers: [String: AVPlayer] = [:]
    private var preloadTasks: [String: Task<Void, Never>] = [:]

    // MARK: - Public

    /// Get a player for a specific video. Returns from pool or creates new.
    func acquire(for videoId: String, url: URL) -> AVPlayer {
        // Return existing if already in use
        if let existing = inUsePlayers[videoId] {
            return existing
        }

        // Grab from pool or create new
        let player: AVPlayer
        if let recycled = availablePlayers.popLast() {
            player = recycled
        } else {
            player = AVPlayer()
        }

        // Configure player
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        player.isMuted = true  // Start muted in feed
        player.automaticallyWaitsToAvoidStalling = true

        inUsePlayers[videoId] = player
        return player
    }

    /// Return a player to the pool when its cell disappears.
    func release(videoId: String) {
        guard let player = inUsePlayers[videoId] else { return }
        player.pause()
        player.seek(to: .zero)
        player.replaceCurrentItem(with: nil)
        inUsePlayers.removeValue(forKey: videoId)

        if availablePlayers.count < Self.maxPoolSize {
            availablePlayers.append(player)
        }
    }

    /// Preload the next video's HLS playlist into a standby player.
    func preload(videoId: String, url: URL) {
        preloadTasks[videoId]?.cancel()
        preloadTasks[videoId] = Task {
            let asset = AVURLAsset(url: url)
            _ = try? await asset.load(.duration)
            // Asset is cached by AVFoundation after loading
        }
    }

    func cancelPreload(for videoId: String) {
        preloadTasks[videoId]?.cancel()
        preloadTasks.removeValue(forKey: videoId)
    }

    /// Pause all active players.
    func pauseAll() {
        for (_, player) in inUsePlayers {
            player.pause()
        }
    }

    /// Clean up all players.
    func reset() {
        for (_, player) in inUsePlayers {
            player.pause()
            player.replaceCurrentItem(with: nil)
        }
        inUsePlayers.removeAll()
        for player in availablePlayers {
            player.replaceCurrentItem(with: nil)
        }
        availablePlayers.removeAll()
        preloadTasks.values.forEach { $0.cancel() }
        preloadTasks.removeAll()
    }
}
