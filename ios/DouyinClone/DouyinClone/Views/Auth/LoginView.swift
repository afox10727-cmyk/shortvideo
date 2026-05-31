import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Email field
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundStyle(.gray)
                TextField("邮箱", text: Bindable(authViewModel).loginEmail)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Password field
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.gray)
                SecureField("密码", text: Bindable(authViewModel).loginPassword)
                    .textContentType(.password)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Error message
            if let error = authViewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            // Login button
            Button {
                Task { await authViewModel.login() }
            } label: {
                Text("登录")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.pink, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(authViewModel.isLoading)

            // Divider
            HStack {
                Rectangle().frame(height: 1).foregroundStyle(.white.opacity(0.2))
                Text("或").font(.caption).foregroundStyle(.gray)
                Rectangle().frame(height: 1).foregroundStyle(.white.opacity(0.2))
            }
            .padding(.vertical, 8)

            // Sign in with Apple
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
                request.nonce = AuthService().prepareAppleSignIn()
            } onCompletion: { result in
                switch result {
                case .success(let authorization):
                    if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                       let idTokenData = appleIDCredential.identityToken,
                       let idToken = String(data: idTokenData, encoding: .utf8) {
                        Task {
                            await authViewModel.handleAppleCredential(
                                userId: appleIDCredential.user,
                                idToken: idToken,
                                rawNonce: appleIDCredential.fullName?.description
                            )
                        }
                    }
                case .failure(let error):
                    authViewModel.errorMessage = "Apple 登录失败：\(error.localizedDescription)"
                }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    LoginView()
        .environment(AuthViewModel())
}
