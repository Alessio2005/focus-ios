import SwiftUI

@main
struct FocusApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var screenTime = ScreenTimeManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(screenTime)
        }
    }
}
