import SwiftUI
import Observation

@Observable
final class SearchViewModel {
    private let userService = UserService()

    var searchQuery = ""
    var searchResults: [AppUser] = []
    var isSearching = false
    var trendingTags: [String] = [
        "搞笑", "舞蹈", "美食", "旅行", "音乐", "时尚",
        "运动", "宠物", "科技", "美妆"
    ]

    func search() async {
        guard !searchQuery.trimmed.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        defer { isSearching = false }

        do {
            searchResults = try await userService.searchUsers(query: searchQuery.trimmed)
        } catch {
            print("Search error: \(error)")
        }
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }
}
