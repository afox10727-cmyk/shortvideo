import SwiftUI
import AVKit

struct FeedCell: View {
    let video: Video
    let player: AVPlayer?
    let isVisible: Bool

    @State private var isLiked = false
    @State private var isMuted = false
    @State private var showComments = false

    var onLike: (() -> Void)?
    var onComment: (() -> Void)?
    var onProfileTap: (() -> Void)?
    var onShare: (() -> Void)?

    var body: some View {
        ZStack {
            // Video player
            VideoPlayerView(
                player: player,
                isMuted: isMuted,
                shouldPlay: isVisible
            )

            // Tap to mute/unmute
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation { isMuted.toggle() }
                    player?.isMuted = isMuted
                }

            // Right-side action buttons
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    VStack(spacing: 24) {
                        Spacer()

                        // Profile avatar
                        Button {
                            onProfileTap?()
                        } label: {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.pink, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                                .overlay {
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(.white)
                                        .font(.system(size: 20))
                                }
                        }

                        // Like button
                        VideoActionButton(
                            icon: isLiked ? "heart.fill" : "heart",
                            count: Formatters.formatCount(video.likeCount),
                            activeColor: .red
                        ) {
                            HapticsManager.medium()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                isLiked.toggle()
                            }
                            onLike?()
                        }

                        // Comment button
                        VideoActionButton(
                            icon: "message",
                            count: Formatters.formatCount(video.commentCount)
                        ) {
                            HapticsManager.light()
                            showComments = true
                            onComment?()
                        }

                        // Share button
                        VideoActionButton(
                            icon: "arrowshape.turn.up.right",
                            count: Formatters.formatCount(video.shareCount)
                        ) {
                            HapticsManager.medium()
                            ShareSheetHelper.share(video: video)
                            onShare?()
                        }
                    }
                    .padding(.trailing, 8)
                }
            }

            // Bottom: Video info overlay
            VStack {
                Spacer()

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        // Username
                        Button {
                            onProfileTap?()
                        } label: {
                            Text("@user_placeholder")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }

                        // Caption
                        Text(video.caption)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .lineLimit(3)

                        // Tags
                        if !video.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(video.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.8))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(
                                                Capsule()
                                                    .fill(Color.white.opacity(0.15))
                                            )
                                    }
                                }
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }

            // Mute indicator
            if isMuted {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "speaker.slash.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                            .padding(.leading, 16)
                        Spacer()
                    }
                    .padding(.bottom, 130)
                }
                .transition(.opacity)
            }
        }
        .background(Color.black)
        .sheet(isPresented: $showComments) {
            CommentsView(video: video)
                .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - VideoActionButton

struct VideoActionButton: View {
    let icon: String
    let count: String
    var activeColor: Color = .white
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(activeColor)

                Text(count)
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .fontWeight(.medium)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FeedCell(
        video: Video(
            userId: "test",
            caption: "测试视频",
            tags: ["#测试", "#搞笑"],
            duration: 30,
            width: 1080,
            height: 1920,
            likeCount: 1234,
            commentCount: 56,
            shareCount: 7,
            viewCount: 10000,
            processingStatus: .ready,
            isPrivate: false,
            createdAt: Date(),
            updatedAt: Date()
        ),
        player: nil,
        isVisible: true
    )
}
