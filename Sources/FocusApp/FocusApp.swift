import SwiftUI

@main
struct FocusApp: App {
    @StateObject private var manager = ScreenTimeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(manager)
        }
    }
}
