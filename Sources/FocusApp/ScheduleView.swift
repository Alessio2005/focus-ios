import SwiftUI

/// Tabblad "Schema's": apps blokkeren op vaste tijden.
struct ScheduleView: View {
    @EnvironmentObject private var manager: ScreenTimeManager
    @State private var editing: FocusRule?

    var body: some View {
        NavigationStack {
            List {
                AuthorizationBanner()
                Section {
                    ForEach(manager.rules(of: .schedule)) { rule in
                        Button { editing = rule } label: { RuleRow(rule: rule) }
                            .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        let items = manager.rules(of: .schedule)
                        for index in offsets { manager.delete(items[index]) }
                    }
                } footer: {
                    Text("Binnen het tijdvak blokkeert iOS de gekozen apps. Daarna wordt de blokkade automatisch opgeheven.")
                }
            }
            .navigationTitle("Schema's")
            .toolbar {
                Button {
                    editing = FocusRule(name: "Studieblok", kind: .schedule)
                } label: { Image(systemName: "plus") }
            }
            .sheet(item: $editing) { rule in
                RuleEditorView(rule: rule)
            }
        }
    }
}
