import FamilyControls
import SwiftUI

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink { NotesView() } label: { Label("Parkeerlijst", systemImage: "note.text") }
                    NavigationLink { SettingsView() } label: { Label("Instellingen", systemImage: "gearshape") }
                    NavigationLink { CreditsView() } label: { Label("Over FocusBlok", systemImage: "info.circle") }
                }
            }
            .navigationTitle("Meer")
        }
    }
}

struct NotesView: View {
    @EnvironmentObject private var store: AppStore
    @State private var text = ""

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("Nieuwe gedachte", text: $text).onSubmit(add)
                    Button(action: add) { Image(systemName: "plus.circle.fill") }
                        .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } footer: {
                Text("Gedachten die je tijdens een blok parkeert, komen hier terecht. Pak ze op na je blok.")
            }
            Section {
                if store.notes.isEmpty {
                    Text("Je parkeerlijst is leeg.").foregroundStyle(.secondary)
                }
                ForEach(store.notes.sorted { !$0.done && $1.done }) { note in
                    Button { store.toggle(note) } label: {
                        HStack {
                            Image(systemName: note.done ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(note.done ? Color.accentColor : .secondary)
                            VStack(alignment: .leading) {
                                Text(note.text).strikethrough(note.done).foregroundStyle(note.done ? .secondary : .primary)
                                Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) { store.delete(note) } label: { Label("Verwijder", systemImage: "trash") }
                    }
                }
            }
        }
        .navigationTitle("Parkeerlijst")
    }

    private func add() {
        store.park(text)
        text = ""
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @State private var nickname = ""
    @State private var confirmWipe = false
    @State private var confirmStop = false
    @State private var exportURL: URL?

    private var statusText: String {
        switch screenTime.authorizationStatus {
        case .approved: return "Toegestaan"
        case .denied: return "Geweigerd"
        case .notDetermined: return "Nog niet gevraagd"
        default: return "Onbekend"
        }
    }

    var body: some View {
        Form {
            Section("Rechten") {
                if FocusConfig.screenTimeEnabled {
                    LabeledContent("Schermtijd", value: statusText)
                    if !screenTime.isAuthorized {
                        Button("Toestemming vragen") { Task { await screenTime.requestAuthorization() } }
                    }
                }
                Button("Meldingen toestaan") { AppStore.requestNotificationPermission() }
            }

            Section("Weergave") {
                Picker("Thema", selection: Binding(
                    get: { store.profile.darkMode },
                    set: { value in store.updateProfile { $0.darkMode = value } }
                )) {
                    Text("Systeem").tag(0)
                    Text("Licht").tag(1)
                    Text("Donker").tag(2)
                }
                TextField("Je naam (voor de begroeting)", text: $nickname)
                Button("Naam opslaan") {
                    let name = nickname.trimmingCharacters(in: .whitespaces)
                    store.updateProfile { $0.nickname = name }
                }
            }

            if FocusConfig.screenTimeEnabled {
                Section {
                    Button("Alle limieten en vaste tijden uitzetten", role: .destructive) { confirmStop = true }
                } footer: {
                    Text("Noodknop: stopt alle limieten en vaste studietijden en heft hun blokkades op.")
                }
            }

            Section {
                if let exportURL {
                    ShareLink(item: exportURL) { Label("Exporteer mijn gegevens (JSON)", systemImage: "square.and.arrow.up") }
                }
                Button("Uitleg opnieuw bekijken") { store.updateProfile { $0.onboardingDone = false } }
                Button("Alle gegevens wissen", role: .destructive) { confirmWipe = true }
            } header: {
                Text("Gegevens")
            } footer: {
                Text("Alles staat alleen op deze telefoon. Er gaat niets naar internet.")
            }
        }
        .navigationTitle("Instellingen")
        .onAppear {
            nickname = store.profile.nickname
            exportURL = store.exportFile()
        }
        .confirmationDialog("Alles uitzetten?", isPresented: $confirmStop, titleVisibility: .visible) {
            Button("Uitzetten", role: .destructive) { screenTime.stopEverything() }
        }
        .confirmationDialog("Alles wissen?", isPresented: $confirmWipe, titleVisibility: .visible) {
            Button("Wissen", role: .destructive) {
                store.wipeAll()
                screenTime.reload()
            }
        } message: {
            Text("Je blokken, XP, munten, streak, lijsten en parkeerlijst worden verwijderd. Dit kan niet ongedaan worden.")
        }
    }
}

struct CreditsView: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
    }

    var body: some View {
        ScrollScreen {
            VStack(spacing: 8) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                Text("FocusBlok").font(.title.bold())
                Text("Versie \(version)").foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)

            Card(title: "Gemaakt door") {
                Text("Alessio").font(.headline)
                Text("Isabelle").font(.headline)
                Text("Ties").font(.headline)
                Text("Saxion Deventer, Design Challenge").font(.footnote).foregroundStyle(.secondary)
            }

            Card(title: "Onze ontwerpvraag") {
                Text("Hoe kunnen we studenten helpen om tijdens het zelfstandig studeren praktische strategieën toe te passen, zodat hun telefoon hen minder afleidt?")
                Text("FocusBlok is ontworpen voor studenten zoals onze persona Sam: wie de strategieën wel kent, maar ze niet altijd toepast. Telefoonvrije blokken met één duidelijke taak, een parkeerlijst voor lastige vragen en een beloning na afloop.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text("Met dank aan iedereen die meedeed aan onze interviews en brainstormsessie.")
                    .font(.footnote).foregroundStyle(.secondary)
            }

            Card(title: "Techniek") {
                Text(FocusConfig.screenTimeEnabled
                     ? "Gebouwd met Swift, SwiftUI en Apple's Screen Time API (FamilyControls, ManagedSettings en DeviceActivity)."
                     : "Gebouwd met Swift en SwiftUI. Deze gratis versie blokkeert via een automatisering in de app Opdrachten.")
                Text("Ideeën opgedaan bij de open-source apps Rewire en Reef (MIT-licentie).")
                Text("Code geschreven met hulp van Claude (Anthropic).")
            }
            .font(.footnote)

            Card(title: "Privacy") {
                Text("FocusBlok heeft geen account en geen internetverbinding nodig. Je blokken, notities en beloningen staan alleen op deze telefoon. Je kunt ze exporteren of wissen via Instellingen.")
                    .font(.footnote)
            }
        }
        .navigationTitle("Over")
        .navigationBarTitleDisplayMode(.inline)
    }
}
