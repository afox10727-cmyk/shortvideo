import SwiftUI
import Observation

@Observable
final class AuthViewModel {
    private let authService = AuthService()

    var authState: AuthState = .loading
    var currentUser: AppUser?
    var isAuthenticated = false

    // Login form
    var loginEmail = ""
    var loginPassword = ""

    // Sign up form
    var signUpEmail = ""
    var signUpPassword = ""
    var signUpUsername = ""
    var signUpDisplayName = ""

    var errorMessage: String?
    var isLoading = false

    private let userService = UserService()
    private var fcmObserver: NSObjectProtocol?

    init() {
        checkAuthState()
        observeFCMToken()
    }

    private func observeFCMToken() {
        fcmObserver = NotificationCenter.default.addObserver(
            forName: .fcmTokenReceived,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let token = notification.userInfo?["token"] as? String,
                  let uid = self?.currentUser?.id else { return }
            Task {
                try? await self?.userService.updateFCMToken(uid: uid, token: token)
            }
        }
    }

    deinit {
        if let observer = fcmObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Auth State

    func checkAuthState() {
        authState = .loading
        if authService.isSignedIn {
            Task {
                do {
                    if let uid = authService.currentUserId {
                        currentUser = try await authService.fetchUser(uid: uid)
                        isAuthenticated = true
                        authState = .signedIn
                    }
                } catch {
                    authState = .signedOut
                }
            }
        } else {
            authState = .signedOut
        }
    }

    // MARK: - Login

    func login() async {
        guard !loginEmail.isEmpty, !loginPassword.isEmpty else {
            errorMessage = "请输入邮箱和密码"
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let user = try await authService.signIn(email: loginEmail, password: loginPassword)
            currentUser = user
            isAuthenticated = true
            authState = .signedIn
        } catch {
            errorMessage = "登录失败：\(error.localizedDescription)"
            authState = .error(error.localizedDescription)
        }
    }

    // MARK: - Sign Up

    func signUp() async {
        guard !signUpEmail.isEmpty, !signUpPassword.isEmpty,
              !signUpUsername.isEmpty, !signUpDisplayName.isEmpty else {
            errorMessage = "请填写所有字段"
            return
        }

        guard signUpPassword.count >= 6 else {
            errorMessage = "密码至少需要6位"
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let user = try await authService.signUp(
                email: signUpEmail,
                password: signUpPassword,
                username: signUpUsername,
                displayName: signUpDisplayName
            )
            currentUser = user
            isAuthenticated = true
            authState = .signedIn
        } catch {
            errorMessage = "注册失败：\(error.localizedDescription)"
            authState = .error(error.localizedDescription)
        }
    }

    // MARK: - Apple Sign-In

    func signInWithApple() async {
        // Handled via Sign in with Apple UI flow
        // The actual credential is passed from the view
    }

    func handleAppleCredential(userId: String, idToken: String, rawNonce: String?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let user = try await authService.signInWithApple(idToken: idToken, nonce: rawNonce)
            currentUser = user
            isAuthenticated = true
            authState = .signedIn
        } catch {
            errorMessage = "Apple 登录失败：\(error.localizedDescription)"
        }
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try authService.signOut()
            currentUser = nil
            isAuthenticated = false
            authState = .signedOut
        } catch {
            errorMessage = "退出失败：\(error.localizedDescription)"
        }
    }

    // MARK: - Reset

    func resetForms() {
        loginEmail = ""
        loginPassword = ""
        signUpEmail = ""
        signUpPassword = ""
        signUpUsername = ""
        signUpDisplayName = ""
        errorMessage = nil
    }
}
