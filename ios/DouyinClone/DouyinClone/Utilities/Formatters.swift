import Foundation

enum Formatters {
    /// Format count like "1.2K", "3.4M"
    static func formatCount(_ count: Int) -> String {
        switch count {
        case 0..<1000:
            return "\(count)"
        case 1000..<1_000_000:
            let k = Double(count) / 1000.0
            return String(format: "%.1fK", k)
        default:
            let m = Double(count) / 1_000_000.0
            return String(format: "%.1fM", m)
        }
    }

    /// Format video duration like "1:23"
    static func formatDuration(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    /// Format relative time like "3小时前"
    static func relativeTime(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        switch interval {
        case 0..<60:
            return "刚刚"
        case 60..<3600:
            return "\(Int(interval / 60))分钟前"
        case 3600..<86400:
            return "\(Int(interval / 3600))小时前"
        case 86400..<604800:
            return "\(Int(interval / 86400))天前"
        case 604800..<2592000:
            return "\(Int(interval / 604800))周前"
        default:
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/M/d"
            return formatter.string(from: date)
        }
    }
}
