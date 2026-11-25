import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var manager: ScreenTimeManager
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Overzicht", systemImage: "gauge.medium") }
            AppSelectionView()
                .tabItem { Label("Limieten", systemImage: "hourglass") }
            ScheduleView()
                .tabItem { Label("Schema's", systemImage: "calendar.badge.clock") }
            SettingsView()
                .tabItem { Label("Instellingen", systemImage: "gearshape") }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { manager.refresh() }
        }
    }
}

/// Kaart die vraagt om Schermtijd-toestemming als die nog ontbreekt.
struct AuthorizationBanner: View {
    @EnvironmentObject private var manager: ScreenTimeManager

    var body: some View {
        if !manager.isAuthorized {
            VStack(alignment: .leading, spacing: 8) {
                Label("Schermtijd-toegang nodig", systemImage: "lock.shield")
                    .font(.headline)
                Text("Focus heeft toestemming nodig om apps te kiezen en te blokkeren.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Toestemming geven") {
                    Task { await manager.requestAuthorization() }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.vertical, 4)
        }
    }
}

/// Eén regel in een lijst.
struct RuleRow: View {
    @EnvironmentObject private var manager: ScreenTimeManager
    let rule: FocusRule

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(rule.name).font(.body.weight(.medium))
                Text(rule.detailText).font(.subheadline).foregroundStyle(.secondary)
                Text(rule.selectionSummary).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if manager.isBlocked(rule) {
                Image(systemName: "lock.fill").foregroundStyle(.red)
            }
            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { manager.setEnabled($0, for: rule) }
            ))
            .labelsHidden()
        }
    }
}
