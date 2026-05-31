import Foundation

extension Date {
    var timeAgo: String {
        Formatters.relativeTime(from: self)
    }
}

extension String {
    var isValidEmail: Bool {
        let regex = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/
        return self.wholeMatch(in: regex, options: .caseInsensitive) != nil
    }

    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
