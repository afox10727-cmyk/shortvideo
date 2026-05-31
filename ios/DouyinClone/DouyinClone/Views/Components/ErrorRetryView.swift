import SwiftUI

/// Full-screen error state with retry button.
struct ErrorRetryView: View {
    let title: String
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundStyle(.gray)

            Text(title)
                .font(.headline)
                .foregroundStyle(.white)

            Text(message)
                .font(.caption)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)

            Button(action: {
                HapticsManager.medium()
                retryAction()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("重试")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
        }
        .padding()
    }
}

// MARK: - Share Sheet Helper

struct ShareSheetHelper {
    /// Present native share sheet for a video
    static func share(video: Video) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else { return }

        var items: [Any] = []

        // Share caption
        if !video.caption.isEmpty {
            items.append(video.caption)
        }

        // Share tags
        if !video.tags.isEmpty {
            items.append(video.tags.joined(separator: " "))
        }

        // Share video URL if available
        if let videoUrl = video.videoUrl {
            items.append("在 ShortVideo 上观看: \(videoUrl)")
        }

        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        rootVC.present(activityVC, animated: true)
    }
}
