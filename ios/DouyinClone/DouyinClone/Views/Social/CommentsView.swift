import SwiftUI
import FirebaseFirestore

struct CommentsView: View {
    let video: Video

    @State private var comments: [Comment] = []
    @State private var newCommentText = ""
    @State private var isLoading = false
    @Environment(AuthViewModel.self) private var authViewModel

    private let commentService = CommentService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Comment count header
                Text("\(Formatters.formatCount(video.commentCount)) 条评论")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .padding(.vertical, 8)

                // Comments list
                if comments.isEmpty && !isLoading {
                    EmptyStateView(
                        icon: "bubble.left",
                        title: "暂无评论",
                        subtitle: "成为第一个评论的人吧"
                    )
                    .padding(.top, 60)
                } else {
                    List {
                        ForEach(comments) { comment in
                            CommentRow(comment: comment)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }

                // Input bar
                HStack(spacing: 12) {
                    TextField("添加评论...", text: $newCommentText, axis: .vertical)
                        .lineLimit(1...4)
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    Button {
                        Task { await postComment() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(
                                newCommentText.trimmed.isEmpty ? .gray : .pink
                            )
                    }
                    .disabled(newCommentText.trimmed.isEmpty)
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("评论")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadComments()
            }
        }
    }

    private func loadComments() async {
        isLoading = true
        defer { isLoading = false }

        guard let videoId = video.id else { return }
        do {
            comments = try await commentService.fetchComments(videoId: videoId)
        } catch {
            print("Failed to load comments: \(error)")
        }
    }

    private func postComment() async {
        guard let userId = authViewModel.currentUser?.id,
              let videoId = video.id,
              !newCommentText.trimmed.isEmpty else { return }

        do {
            try await commentService.postComment(
                videoId: videoId,
                userId: userId,
                text: newCommentText.trimmed
            )
            newCommentText = ""
            await loadComments()
        } catch {
            print("Failed to post comment: \(error)")
        }
    }
}

struct CommentRow: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("@user_placeholder")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                    Text(comment.createdAt.timeAgo)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
                Text(comment.text)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }

            Spacer()
        }
    }
}

#Preview {
    CommentsView(video: Video(
        userId: "test",
        caption: "Test",
        tags: [],
        duration: 30,
        width: 1080,
        height: 1920,
        likeCount: 100,
        commentCount: 5,
        shareCount: 3,
        viewCount: 1000,
        processingStatus: .ready,
        isPrivate: false,
        createdAt: Date(),
        updatedAt: Date()
    ))
}
