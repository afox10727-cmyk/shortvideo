import SwiftUI

struct StatBadge: View {
    let count: Int
    let label: String
    var action: (() -> Void)?

    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    content
                }
                .buttonStyle(.plain)
            } else {
                content
            }
        }
    }

    private var content: some View {
        VStack(spacing: 2) {
            Text(Formatters.formatCount(count))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.gray)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack(spacing: 32) {
            StatBadge(count: 0, label: "视频")
            StatBadge(count: 128, label: "粉丝", action: {})
            StatBadge(count: 56, label: "关注", action: {})
        }
    }
}
