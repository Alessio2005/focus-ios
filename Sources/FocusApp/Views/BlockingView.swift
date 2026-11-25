import FamilyControls
import SwiftUI

/// Tabblad Blokkeren: blokkeerlijsten voor studieblokken, dagelijkse limieten en vaste studietijden.
struct BlockingView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @State private var editingList: BlockList?
    @State private var editingRule: FocusRule?

    var body: some View {
        NavigationStack {
            List {
                if !screenTime.isAuthorized {
                    Section {
                        AuthorizationBanner()
                    }
                }

                Section {
                    ForEach(store.lists) { list in
                        Button { editingList = list } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(list.name).foregroundStyle(.primary)
                                Text(list.summary).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { offsets in
                        let items = store.lists
                        for i in offsets where items.count > 1 { store.delete(items[i]) }
                    }
                    Button {
                        editingList = BlockList(name: "Nieuwe lijst")
                    } label: { Label("Lijst toevoegen", systemImage: "plus") }
                } header: {
                    Text("Blokkeerlijsten")
                } footer: {
                    Text("Deze apps gaan op slot tijdens een studieblok.")
                }

                ruleSection(kind: .schedule, title: "Vaste studietijden",
                            footer: "Start vanzelf op de gekozen dagen en tijden, ook als FocusBlok dicht is. Een tijdvak duurt minstens 15 minuten.",
                            newRule: FocusRule(name: "Studieblok", kind: .schedule))

                ruleSection(kind: .dailyLimit, title: "Dagelijkse limieten",
                            footer: "Na de limiet blokkeert iOS de gekozen apps tot middernacht.",
                            newRule: FocusRule(name: "Nieuwe limiet", kind: .dailyLimit))

                if let error = screenTime.lastError {
                    Section { Text(error).font(.footnote).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Blokkeren")
            .sheet(item: $editingList) { list in
                BlockListEditor(list: list)
            }
            .sheet(item: $editingRule) { rule in
                RuleEditorView(rule: rule)
            }
        }
    }

    @ViewBuilder
    private func ruleSection(kind: RuleKind, title: String, footer: String, newRule: FocusRule) -> some View {
        Section {
            ForEach(screenTime.rules(of: kind)) { rule in
                Button { editingRule = rule } label: { RuleRow(rule: rule) }
                    .buttonStyle(.plain)
            }
            .onDelete { offsets in
                let items = screenTime.rules(of: kind)
                for i in offsets { screenTime.delete(items[i]) }
            }
            Button { editingRule = newRule } label: { Label("Toevoegen", systemImage: "plus") }
        } header: {
            Text(title)
        } footer: {
            Text(footer)
        }
    }
}

struct BlockListEditor: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @Environment(\.dismiss) private var dismiss
    @State private var list: BlockList
    @State private var showPicker = false

    init(list: BlockList) {
        _list = State(initialValue: list)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Naam") {
                    TextField("Bijv. Social media", text: $list.name)
                }
                Section {
                    Button { showPicker = true } label: {
                        Label("Apps en websites kiezen", systemImage: "apps.iphone")
                    }
                    Text(list.summary).foregroundStyle(.secondary)
                    ForEach(Array(list.selection.applicationTokens), id: \.self) { token in
                        Label(token)
                    }
                    ForEach(Array(list.selection.categoryTokens), id: \.self) { token in
                        Label(token)
                    }
                } header: {
                    Text("Apps")
                } footer: {
                    if !screenTime.isAuthorized {
                        Text("Geef eerst Schermtijd-toestemming, anders blijft de appkiezer leeg.")
                    }
                }
            }
            .navigationTitle("Blokkeerlijst")
            .navigationBarTitleDisplayMode(.inline)
            .familyActivityPicker(isPresented: $showPicker, selection: $list.selection)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuleer") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bewaar") {
                        store.save(list)
                        dismiss()
                    }
                    .disabled(list.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

/// Kaart die vraagt om Schermtijd-toestemming als die nog ontbreekt.
struct AuthorizationBanner: View {
    @EnvironmentObject private var screenTime: ScreenTimeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Schermtijd-toegang nodig", systemImage: "lock.shield").font(.headline)
            Text("FocusBlok heeft toestemming nodig om apps te kiezen en te blokkeren.")
                .font(.subheadline).foregroundStyle(.secondary)
            Button("Toestemming geven") {
                Task { await screenTime.requestAuthorization() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 4)
    }
}

/// Eén regel in een lijst.
struct RuleRow: View {
    @EnvironmentObject private var screenTime: ScreenTimeManager
    let rule: FocusRule

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(rule.name).font(.body.weight(.medium))
                Text(rule.detailText).font(.subheadline).foregroundStyle(.secondary)
                Text(rule.selectionSummary).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if screenTime.isBlocked(rule) {
                Image(systemName: "lock.fill").foregroundStyle(.red)
            }
            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { screenTime.setEnabled($0, for: rule) }
            ))
            .labelsHidden()
        }
        .contentShape(Rectangle())
    }
}
