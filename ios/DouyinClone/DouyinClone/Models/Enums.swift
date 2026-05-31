import Foundation

enum FeedMode: String, CaseIterable {
    case forYou = "推荐"
    case following = "关注"
}

enum UploadState: String, Codable {
    case pending
    case compressing
    case uploading
    case completed
    case failed
}

enum AuthState {
    case loading
    case signedOut
    case signedIn
    case error(String)
}
