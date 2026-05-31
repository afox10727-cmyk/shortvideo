import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showRecordView = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                FeedView()
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        Text("首页")
                    }
                    .tag(0)

                DiscoverView()
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "magnifyingglass.circle.fill" : "magnifyingglass")
                        Text("发现")
                    }
                    .tag(1)

                // Placeholder for center "+" button
                Color.clear
                    .tabItem { Text("") }
                    .tag(2)

                NotificationView()
                    .tabItem {
                        Image(systemName: selectedTab == 3 ? "bell.fill" : "bell")
                        Text("通知")
                    }
                    .tag(3)

                ProfileView()
                    .tabItem {
                        Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                        Text("我")
                    }
                    .tag(4)
            }
            .tint(.white)

            // Center record button
            Button {
                showRecordView = true
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.pink, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .offset(y: -2)
        }
        .fullScreenCover(isPresented: $showRecordView) {
            RecordView()
        }
    }
}

#Preview {
    MainTabView()
        .environment(AuthViewModel())
}
