import SwiftUI

struct FollowButton: View {
    let isFollowing: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text(isFollowing ? "已关注" : "关注")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            isFollowing
                                ? Color.white.opacity(0.15)
                                : Color.pink
                        )
                )
                .foregroundStyle(isFollowing ? .white : .white)
                .overlay {
                    if isFollowing {
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    }
                }
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFollowing)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack(spacing: 24) {
            FollowButton(isFollowing: false, action: {})
            FollowButton(isFollowing: true, action: {})
        }
    }
}
