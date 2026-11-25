import SwiftUI

/// Tabblad "Limieten": apps kiezen en een dagelijkse limiet instellen.
struct AppSelectionView: View {
    @EnvironmentObject private var manager: ScreenTimeManager
    @State private var editing: FocusRule?

    var body: some View {
        NavigationStack {
            List {
                AuthorizationBanner()
                Section {
                    ForEach(manager.rules(of: .dailyLimit)) { rule in
                        Button { editing = rule } label: { RuleRow(rule: rule) }
                            .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        let items = manager.rules(of: .dailyLimit)
                        for index in offsets { manager.delete(items[index]) }
                    }
                } footer: {
                    Text("Als je de limiet bereikt, blokkeert iOS de gekozen apps tot middernacht.")
                }
            }
            .navigationTitle("Limieten")
            .toolbar {
                Button {
                    editing = FocusRule(name: "Nieuwe limiet", kind: .dailyLimit)
                } label: { Image(systemName: "plus") }
            }
            .sheet(item: $editing) { rule in
                RuleEditorView(rule: rule)
            }
        }
    }
}
