import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var manager: ScreenTimeManager

    private var blockedRules: [FocusRule] {
        manager.rules.filter { manager.isBlocked($0) }
    }

    var body: some View {
        NavigationStack {
            List {
                AuthorizationBanner()

                Section {
                    HStack(spacing: 12) {
                        StatTile(title: "Limieten", value: manager.rules(of: .dailyLimit).filter(\.isEnabled).count, systemImage: "hourglass")
                        StatTile(title: "Schema's", value: manager.rules(of: .schedule).filter(\.isEnabled).count, systemImage: "calendar")
                        StatTile(title: "Geblokkeerd", value: blockedRules.count, systemImage: "lock.fill")
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section("Nu geblokkeerd") {
                    if blockedRules.isEmpty {
                        Text("Er is op dit moment niets geblokkeerd.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(blockedRules) { rule in
                            Label {
                                VStack(alignment: .leading) {
                                    Text(rule.name)
                                    Text(rule.kind == .dailyLimit ? "Limiet bereikt" : "Tijdschema actief")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "lock.fill").foregroundStyle(.red)
                            }
                        }
                    }
                }

                Section("Alle regels") {
                    if manager.rules.isEmpty {
                        Text("Nog geen regels. Voeg een limiet of schema toe via de tabbladen hieronder.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(manager.rules) { RuleRow(rule: $0) }
                    }
                }

                if let error = manager.lastError {
                    Section { Text(error).foregroundStyle(.red).font(.footnote) }
                }
            }
            .navigationTitle("Focus")
            .refreshable { manager.refresh() }
        }
    }
}

private struct StatTile: View {
    let title: String
    let value: Int
    let systemImage: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage).font(.title3).foregroundStyle(.tint)
            Text("\(value)").font(.title.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
    }
}
