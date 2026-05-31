import SwiftUI

/// Animated skeleton placeholder for loading states.
struct SkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.05),
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .mask(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white, .clear],
                                startPoint: UnitPoint(x: isAnimating ? 1 : -1, y: 0.5),
                                endPoint: UnitPoint(x: isAnimating ? 2 : 0, y: 0.5)
                            )
                        )
                )
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        isAnimating = true
                    }
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Feed Skeleton

struct FeedSkeletonCell: View {
    var body: some View {
        ZStack {
            Color.black

            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    // Left info skeleton
                    VStack(alignment: .leading, spacing: 8) {
                        SkeletonView()
                            .frame(width: 120, height: 18)
                        SkeletonView()
                            .frame(width: 200, height: 14)
                        SkeletonView()
                            .frame(width: 160, height: 14)
                    }

                    Spacer()

                    // Right actions skeleton
                    VStack(spacing: 24) {
                        ForEach(0..<4, id: \.self) { _ in
                            SkeletonView()
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 120)
            }
        }
    }
}

// MARK: - Profile Skeleton

struct ProfileSkeletonView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 24) {
                SkeletonView()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                Spacer()
                HStack(spacing: 28) {
                    ForEach(0..<3, id: \.self) { _ in
                        VStack(spacing: 4) {
                            SkeletonView().frame(width: 40, height: 24)
                            SkeletonView().frame(width: 30, height: 12)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)

            // Grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3),
                spacing: 2
            ) {
                ForEach(0..<9, id: \.self) { _ in
                    SkeletonView()
                        .aspectRatio(9/16, contentMode: .fill)
                }
            }
        }
    }
}

// MARK: - Notification Skeleton

struct NotificationSkeletonRow: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonView()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                SkeletonView().frame(width: 200, height: 14)
                SkeletonView().frame(width: 100, height: 12)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            FeedSkeletonCell()
                .frame(height: 300)
            ProfileSkeletonView()
            NotificationSkeletonRow()
        }
    }
}
