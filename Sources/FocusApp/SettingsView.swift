import FamilyControls
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var manager: ScreenTimeManager
    @State private var confirmStop = false

    private var statusText: String {
        switch manager.authorizationStatus {
        case .approved: return "Toegestaan"
        case .denied: return "Geweigerd"
        case .notDetermined: return "Nog niet gevraagd"
        @unknown default: return "Onbekend"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Schermtijd") {
                    LabeledContent("Toestemming", value: statusText)
                    if !manager.isAuthorized {
                        Button("Toestemming vragen") {
                            Task { await manager.requestAuthorization() }
                        }
                    }
                }

                Section {
                    Button("Alle blokkades opheffen", role: .destructive) { confirmStop = true }
                } footer: {
                    Text("Stopt alle limieten en schema's en zet ze uit.")
                }

                Section("Over") {
                    LabeledContent("Versie", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–")
                    Text("Blokkeren gebeurt met Apple's Screen Time API (FamilyControls, ManagedSettings en DeviceActivity). Dit werkt alleen op een echte iPhone met het Family Controls-entitlement, niet in de simulator.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Instellingen")
            .confirmationDialog("Alle blokkades opheffen?", isPresented: $confirmStop, titleVisibility: .visible) {
                Button("Opheffen", role: .destructive) { manager.stopEverything() }
            }
        }
    }
}
