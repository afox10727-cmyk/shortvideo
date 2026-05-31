import AVFoundation

/// Compresses video before upload to reduce file size and normalize format.
actor VideoCompressor {
    /// Compress a video to MP4 at the specified bitrate.
    /// - Parameters:
    ///   - sourceURL: Original recorded video URL (.mov)
    ///   - targetBitrate: Bitrate in bits per second (default 4 Mbps)
    /// - Returns: URL of compressed video (.mp4)
    func compress(
        sourceURL: URL,
        targetBitrate: Float = Constants.videoBitrate
    ) async throws -> URL {
        let asset = AVAsset(url: sourceURL)
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("compressed_\(UUID().uuidString).mp4")

        // Remove existing file
        try? FileManager.default.removeItem(at: outputURL)

        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw CompressionError.exportSessionFailed
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        // Configure video composition for orientation normalization
        if let videoTrack = try? await asset.loadTracks(withMediaType: .video).first {
            let composition = AVMutableVideoComposition()
            let naturalSize = try await videoTrack.load(.naturalSize)
            let preferredTransform = try await videoTrack.load(.preferredTransform)

            composition.renderSize = naturalSize
            composition.frameDuration = CMTime(value: 1, timescale: 30)

            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(
                start: .zero,
                duration: try await asset.load(.duration)
            )

            let layerInstruction = AVMutableVideoCompositionLayerInstruction(
                assetTrack: videoTrack
            )
            layerInstruction.setTransform(preferredTransform, at: .zero)

            instruction.layerInstructions = [layerInstruction]
            composition.instructions = [instruction]

            exportSession.videoComposition = composition
        }

        // Set bitrate if possible
        if let videoTrack = try? await asset.loadTracks(withMediaType: .video).first {
            let naturalSize = try? await videoTrack.load(.naturalSize)
            let estimatedDataRate = Int(targetBitrate)
            exportSession.fileLengthLimit = Int64(
                Float(estimatedDataRate) * Float(CMTimeGetSeconds(
                    try await asset.load(.duration)
                )) / 8
            )
        }

        await exportSession.export()

        guard exportSession.status == .completed else {
            throw CompressionError.exportFailed(
                exportSession.error?.localizedDescription ?? "Unknown error"
            )
        }

        return outputURL
    }
}

enum CompressionError: LocalizedError {
    case exportSessionFailed
    case exportFailed(String)

    var errorDescription: String? {
        switch self {
        case .exportSessionFailed:
            return "无法创建压缩会话"
        case .exportFailed(let reason):
            return "视频压缩失败：\(reason)"
        }
    }
}
