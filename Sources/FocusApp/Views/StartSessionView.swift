import SwiftUI

struct StartSessionView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @Environment(\.dismiss) private var dismiss

    enum Mode: String, CaseIterable, Identifiable {
        case free = "Vrij"
        case pomodoro = "Pomodoro"
        var id: String { rawValue }
    }

    @State private var task = ""
    @State private var subject = ""
    @State private var mode: Mode = .free
    @State private var minutes = 45
    @State private var focusMinutes = 25
    @State private var breakMinutes = 5
    @State private var rounds = 4
    @State private var listID: UUID?
    @State private var strict = false

    private var plan: SessionPlan {
        mode == .free ? .single(minutes) : SessionPlan(focusMinutes: focusMinutes, breakMinutes: breakMinutes, rounds: rounds)
    }

    private var selectedList: BlockList? {
        store.lists.first { $0.id == listID } ?? store.lists.first
    }

    private var canStart: Bool {
        !task.trimmingCharacters(in: .whitespaces).isEmpty && (selectedList != nil || !FocusConfig.screenTimeEnabled)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Bijv. hoofdstuk 3 samenvatten", text: $task, axis: .vertical)
                } header: {
                    Text("Wat ga je doen?")
                } footer: {
                    Text("Eén concrete taak werkt beter dan \"studeren\".")
                }

                Section("Vak (optioneel)") {
                    TextField("Bijv. Statistiek", text: $subject)
                    if !store.recentSubjects.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(store.recentSubjects, id: \.self) { s in
                                    Button(s) { subject = s }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                }
                            }
                        }
                    }
                }

                Section("Soort blok") {
                    Picker("Soort", selection: $mode) {
                        ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    switch mode {
                    case .free:
                        Stepper(value: $minutes, in: 15...180, step: 5) {
                            Text("\(minutes) minuten")
                        }
                    case .pomodoro:
                        Stepper(value: $focusMinutes, in: 15...60, step: 5) { Text("Focus: \(focusMinutes) min") }
                        Stepper(value: $breakMinutes, in: 3...20) { Text("Pauze: \(breakMinutes) min") }
                        Stepper(value: $rounds, in: 2...8) { Text("Rondes: \(rounds)") }
                        Text("Totaal \(formatMinutes(plan.totalMinutes)), waarvan \(plan.plannedFocusMinutes) min focus.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }

                if FocusConfig.screenTimeEnabled {
                Section {
                    Picker("Blokkeerlijst", selection: Binding(
                        get: { selectedList?.id },
                        set: { listID = $0 }
                    )) {
                        ForEach(store.lists) { list in
                            Text(list.name).tag(Optional(list.id))
                        }
                    }
                    if let list = selectedList {
                        Text(list.summary).font(.footnote).foregroundStyle(.secondary)
                        if !list.hasSelection {
                            Text("Deze lijst is nog leeg. Kies apps via het tabblad Blokkeren.")
                                .font(.footnote).foregroundStyle(.orange)
                        }
                    }
                } header: {
                    Text("Wat gaat op slot?")
                } footer: {
                    Text("Bellen en berichten van iOS zelf blijven altijd werken.")
                }
                } else {
                    Section {
                        Label("Afleidende apps sturen je terug naar FocusBlok via je Opdrachten-automatisering.", systemImage: "arrow.uturn.backward.circle")
                            .font(.footnote)
                    } header: {
                        Text("Wat gaat op slot?")
                    } footer: {
                        Text("Nog niet ingesteld? Kijk in het tabblad Blokkeren.")
                    }
                }

                Section {
                    Toggle("Strikte modus", isOn: $strict)
                } footer: {
                    Text(FocusConfig.screenTimeEnabled
                         ? "Stoppen kost 30 seconden wachten en een zin overtypen. Pauzetegoed is uit en geblokkeerde apps kun je niet verwijderen."
                         : "Stoppen kost 30 seconden wachten en een zin overtypen. Pauzetegoed is uit.")
                }

                if FocusConfig.screenTimeEnabled && !screenTime.isAuthorized {
                    Section {
                        Text("Zonder Schermtijd-toestemming loopt de timer wel, maar worden er geen apps geblokkeerd.")
                            .font(.footnote).foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle("Nieuw studieblok")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        guard let list = selectedList ?? (FocusConfig.screenTimeEnabled ? nil : BlockList(name: "Opdrachten")) else { return }
                        AppStore.requestNotificationPermission()
                        store.start(task: task, subject: subject, plan: plan, list: list, strict: strict)
                        dismiss()
                    }
                    .disabled(!canStart)
                    .bold()
                }
            }
        }
    }
}
