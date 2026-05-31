import SwiftUI
import AVKit

/// UIViewRepresentable wrapping AVPlayer for full control over playback.
struct VideoPlayerView: UIViewRepresentable {
    let player: AVPlayer?
    var isMuted: Bool = false
    var shouldPlay: Bool = true

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
        player?.isMuted = isMuted

        if shouldPlay {
            player?.play()
        } else {
            player?.pause()
        }
    }

    static func dismantleUIView(_ uiView: PlayerUIView, coordinator: ()) {
        uiView.playerLayer.player?.pause()
        uiView.playerLayer.player = nil
    }
}

final class PlayerUIView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        // swiftlint:disable:next force_cast
        layer as! AVPlayerLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
