import SwiftUI

struct RecordButton: View {
    let isRecording: Bool
    let progress: Double // 0.0 to 1.0
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.red, .pink, .red],
                            center: .center
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 80, height: 80)
                    .opacity(isRecording ? 1 : 0)

                // Progress ring (during recording)
                if isRecording {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(.red, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: progress)
                }

                // Inner button
                RoundedRectangle(cornerRadius: isRecording ? 8 : 40)
                    .fill(.red)
                    .frame(
                        width: isRecording ? 28 : 64,
                        height: isRecording ? 28 : 64
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isRecording)
            }
            .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 32) {
            RecordButton(isRecording: false, progress: 0, action: {})
            RecordButton(isRecording: true, progress: 0.35, action: {})
            RecordButton(isRecording: true, progress: 0.8, action: {})
        }
    }
}
