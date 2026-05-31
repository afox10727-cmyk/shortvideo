import SwiftUI

struct UploadProgressView: View {
    let progress: Double

    var body: some View {
        VStack(spacing: 12) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [.pink, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(progress), height: 12)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 12)

            HStack {
                Text("正在上传...")
                    .font(.caption)
                    .foregroundStyle(.gray)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            UploadProgressView(progress: 0.25)
            UploadProgressView(progress: 0.67)
            UploadProgressView(progress: 0.95)
        }
        .padding()
    }
}
