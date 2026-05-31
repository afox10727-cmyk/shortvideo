import SwiftUI
import FirebaseCore

@main
struct DouyinCloneApp: App {
    @State private var authViewModel = AuthViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authViewModel)
                .preferredColorScheme(.dark)
        }
    }
}
