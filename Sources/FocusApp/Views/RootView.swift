import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if store.profile.onboardingDone {
                MainTabs()
            } else {
                OnboardingView()
            }
        }
        .tint(store.theme.color)
        .accentColor(store.theme.color)
        .preferredColorScheme(store.colorScheme)
        .onAppear { refresh() }
        .onChange(of: scenePhase) { phase in
            if phase == .active { refresh() }
        }
    }

    private func refresh() {
        store.refresh()
        screenTime.refresh()
    }
}

struct MainTabs: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Start", systemImage: "leaf.fill") }
            InsightsView()
                .tabItem { Label("Inzicht", systemImage: "chart.bar.fill") }
            RewardsView()
                .tabItem { Label("Beloningen", systemImage: "star.fill") }
            Group {
                if FocusConfig.screenTimeEnabled {
                    BlockingView()
                } else {
                    ShortcutsSetupView()
                }
            }
            .tabItem { Label("Blokkeren", systemImage: "lock.shield.fill") }
            MoreView()
                .tabItem { Label("Meer", systemImage: "ellipsis.circle.fill") }
        }
        .fullScreenCover(isPresented: Binding(
            get: { store.active != nil || store.lastResult != nil },
            set: { shown in if !shown { store.lastResult = nil } }
        )) {
            SessionFlowView()
                .environmentObject(store)
                .tint(store.theme.color)
                .accentColor(store.theme.color)
                .preferredColorScheme(store.colorScheme)
        }
    }
}

/// Lopend blok, en daarna de uitslag.
struct SessionFlowView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        if store.active != nil {
            ActiveSessionView()
        } else if let result = store.lastResult {
            ResultView(result: result)
        } else {
            Color.clear
        }
    }
}
