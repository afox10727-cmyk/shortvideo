import SwiftUI

struct AuthView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Logo area
                VStack(spacing: 12) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.linearGradient(
                            colors: [.pink, .red, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))

                    Text("ShortVideo")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                .padding(.top, 80)
                .padding(.bottom, 40)

                // Tab switcher
                Picker("", selection: $selectedTab) {
                    Text("登录").tag(0)
                    Text("注册").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 40)
                .padding(.bottom, 24)

                // Form
                if selectedTab == 0 {
                    LoginView()
                } else {
                    SignUpView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Loading overlay
            if authViewModel.isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .onChange(of: selectedTab) { _, _ in
            authViewModel.resetForms()
        }
    }
}

#Preview {
    AuthView()
        .environment(AuthViewModel())
}
