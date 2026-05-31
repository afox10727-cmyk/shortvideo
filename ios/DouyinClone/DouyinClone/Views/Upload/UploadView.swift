import SwiftUI
import AVKit

struct UploadView: View {
    let videoURL: URL
    let onDismiss: () -> Void

    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = UploadViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Video preview + form
                    ScrollView {
                        VStack(spacing: 20) {
                            // Video preview
                            if let player = player {
                                VideoPlayer(player: player)
                                    .aspectRatio(9/16, contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .disabled(true) // Prevent full-screen
                            }

                            // Caption
                            VStack(alignment: .leading, spacing: 8) {
                                Text("描述")
                                    .font(.caption)
                                    .foregroundStyle(.gray)

                                TextField("添加视频描述...", text: Bindable(viewModel).caption, axis: .vertical)
                                    .lineLimit(3...6)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            // Tags
                            VStack(alignment: .leading, spacing: 8) {
                                Text("标签（用空格分隔）")
                                    .font(.caption)
                                    .foregroundStyle(.gray)

                                TextField("#搞笑 #日常", text: Bindable(viewModel).tagsText)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .autocapitalization(.none)
                            }

                            // Visibility
                            Toggle(isOn: Bindable(viewModel).isPrivate) {
                                Label("私密视频", systemImage: "lock.fill")
                            }
                            .tint(.pink)
                        }
                        .padding()
                    }

                    // Bottom: Progress or Publish button
                    VStack(spacing: 12) {
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        switch viewModel.uploadState {
                        case .pending, .compressing:
                            Button {
                                guard let userId = authViewModel.currentUser?.id else { return }
                                Task { await viewModel.publish(userId: userId, videoURL: videoURL) }
                            } label: {
                                HStack {
                                    if viewModel.uploadState == .compressing {
                                        ProgressView()
                                            .tint(.white)
                                    }
                                    Text("发布")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(viewModel.isValid ? Color.pink : Color.gray)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(!viewModel.isValid || viewModel.uploadState == .compressing)

                        case .uploading:
                            UploadProgressView(progress: viewModel.uploadProgress)

                        case .completed:
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("发布成功！")
                                    .foregroundStyle(.white)
                            }
                            .padding()
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    dismiss()
                                    onDismiss()
                                }
                            }

                        case .failed:
                            Button {
                                guard let userId = authViewModel.currentUser?.id else { return }
                                Task { await viewModel.publish(userId: userId, videoURL: videoURL) }
                            } label: {
                                Text("重试")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.pink)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("发布视频")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            player = AVPlayer(url: videoURL)
            player?.play()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}

#Preview {
    UploadView(videoURL: URL(fileURLWithPath: "/tmp/test.mp4"), onDismiss: {})
        .environment(AuthViewModel())
}
