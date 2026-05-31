import SwiftUI

struct RecordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = RecordViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.cameraPermissionGranted {
                // Camera preview
                CameraPreview(session: viewModel.captureSession)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.gray)
                    Text("需要相机权限")
                        .foregroundStyle(.white)
                    Text("请在设置中开启相机和麦克风权限")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }

            // UI overlay
            VStack {
                // Top bar
                HStack {
                    Button {
                        viewModel.cleanup()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.4)))
                    }

                    Spacer()

                    // Camera flip
                    Button {
                        viewModel.flipCamera()
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.4)))
                    }

                    // Flash toggle placeholder
                    Button {
                        // Flash toggle
                    } label: {
                        Image(systemName: "bolt.slash.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.4)))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 48)

                Spacer()

                // Recording time indicator
                if viewModel.isRecording {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                            .blinking()
                        Text(formatTime(viewModel.recordingProgress * Constants.maxVideoDuration))
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Capsule().fill(Color.black.opacity(0.5)))
                }

                // Bottom controls
                HStack(spacing: 40) {
                    // Upload from gallery button
                    Button {
                        // Gallery picker - Phase 3
                    } label: {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }

                    // Record button
                    RecordButton(
                        isRecording: viewModel.isRecording,
                        progress: viewModel.recordingProgress,
                        action: { viewModel.toggleRecording() }
                    )

                    // Duration label placeholder
                    Text(formatTime(Constants.maxVideoDuration))
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .frame(width: 40)
                }
                .padding(.bottom, 40)
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .fullScreenCover(isPresented: Bindable(viewModel).showUpload) {
            if let url = viewModel.recordedFileURL {
                UploadView(videoURL: url, onDismiss: {
                    dismiss()
                })
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Blinking animation for recording indicator

private struct BlinkingModifier: ViewModifier {
    @State private var opacity: Double = 1

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    opacity = 0.2
                }
            }
    }
}

extension View {
    func blinking() -> some View {
        modifier(BlinkingModifier())
    }
}

#Preview {
    RecordView()
}
