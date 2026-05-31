import Foundation
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

final class AuthService {
    private let auth: Auth
    private let db: Firestore
    private var currentNonce: String?

    init(auth: Auth = FirebaseManager.shared.auth,
         db: Firestore = FirebaseManager.shared.db) {
        self.auth = auth
        self.db = db
    }

    // MARK: - Current User

    var currentUserId: String? {
        auth.currentUser?.uid
    }

    var isSignedIn: Bool {
        auth.currentUser != nil
    }

    // MARK: - Email / Password

    func signUp(email: String, password: String, username: String, displayName: String) async throws -> AppUser {
        // Check username uniqueness
        let usernameDoc = try await db.collection("usernames").document(username.lowercased()).getDocument()
        guard !usernameDoc.exists else {
            throw AuthError.usernameTaken
        }

        // Create Firebase Auth user
        let result = try await auth.createUser(withEmail: email, password: password)
        let uid = result.user.uid

        // Reserve username
        try await db.collection("usernames").document(username.lowercased()).setData([
            "uid": uid
        ])

        // Create user profile
        let user = AppUser(
            username: username,
            displayName: displayName,
            bio: "",
            avatarUrl: nil,
            email: email,
            followerCount: 0,
            followingCount: 0,
            videoCount: 0,
            fcmToken: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        try db.collection("users").document(uid).setData(from: user)
        return user
    }

    func signIn(email: String, password: String) async throws -> AppUser {
        let result = try await auth.signIn(withEmail: email, password: password)
        return try await fetchUser(uid: result.user.uid)
    }

    func signOut() throws {
        try auth.signOut()
    }

    // MARK: - Apple Sign-In

    func prepareAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }

    func signInWithApple(idToken: String, nonce: String?) async throws -> AppUser {
        guard let nonce = nonce ?? currentNonce else {
            throw AuthError.missingNonce
        }

        let credential = OAuthProvider.credential(
            providerID: AuthProviderID.apple,
            idToken: idToken,
            rawNonce: nonce
        )

        let result = try await auth.signIn(with: credential)
        let uid = result.user.uid

        // Check if user document exists, create if not
        let userDoc = try? await db.collection("users").document(uid).getDocument()
        if userDoc?.exists != true {
            let displayName = result.user.displayName ?? "User"
            let username = "user_\(String(uid.prefix(8)))"
            let user = AppUser(
                username: username,
                displayName: displayName,
                bio: "",
                avatarUrl: result.user.photoURL?.absoluteString,
                email: result.user.email ?? "",
                followerCount: 0,
                followingCount: 0,
                videoCount: 0,
                createdAt: Date(),
                updatedAt: Date()
            )
            try db.collection("users").document(uid).setData(from: user)
            try await db.collection("usernames").document(username.lowercased()).setData(["uid": uid])
            return user
        }

        return try await fetchUser(uid: uid)
    }

    // MARK: - Fetch User

    func fetchUser(uid: String) async throws -> AppUser {
        let snapshot = try await db.collection("users").document(uid).getDocument()
        guard let user = try? snapshot.data(as: AppUser.self) else {
            throw AuthError.userNotFound
        }
        return user
    }

    // MARK: - Delete Account

    func deleteAccount() async throws {
        guard let uid = currentUserId else { return }
        try await auth.currentUser?.delete()
        try await db.collection("users").document(uid).delete()
    }

    // MARK: - Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if errorCode != errSecSuccess { break }
            for random in randoms {
                if remainingLength == 0 { break }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

enum AuthError: LocalizedError {
    case usernameTaken
    case userNotFound
    case missingNonce

    var errorDescription: String? {
        switch self {
        case .usernameTaken: return "该用户名已被使用"
        case .userNotFound: return "用户不存在"
        case .missingNonce: return "登录验证失败，请重试"
        }
    }
}
