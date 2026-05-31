import SwiftUI

extension View {
    func debugBorder(_ color: Color = .red) -> some View {
        self.overlay(Rectangle().stroke(color, lineWidth: 1))
    }
}

extension Color {
    static let appBackground = Color.black
    static let appSurface = Color(white: 0.12)
    static let appTextPrimary = Color.white
    static let appTextSecondary = Color(white: 0.6)
    static let appAccent = Color.pink
}
