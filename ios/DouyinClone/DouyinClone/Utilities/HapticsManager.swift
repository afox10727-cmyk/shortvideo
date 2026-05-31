import UIKit

/// Lightweight haptic feedback manager for UI interactions.
enum HapticsManager {
    /// Light tap — like button press, tab switch
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Medium tap — like recording start, follow
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Heavy tap — like error, success confirmation
    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    /// Selection changed — like picker switch
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// Success notification — upload complete, action succeeded
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Warning notification — validation warning
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    /// Error notification — upload failed, network error
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
