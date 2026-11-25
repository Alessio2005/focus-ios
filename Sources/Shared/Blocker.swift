import Foundation
import ManagedSettings

/// Zet Apple's systeembrede blokkeerscherm (shield) aan of uit.
/// Elke regel krijgt een eigen ManagedSettingsStore, zodat regels elkaar niet opheffen.
enum Blocker {
    static func store(for id: UUID) -> ManagedSettingsStore {
        ManagedSettingsStore(named: ManagedSettingsStore.Name(rawValue: "rule.\(id.uuidString)"))
    }

    static func block(_ rule: FocusRule) {
        let store = store(for: rule.id)
        let selection = rule.selection
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        if selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = nil
            store.shield.webDomainCategories = nil
        } else {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
            store.shield.webDomainCategories = .specific(selection.categoryTokens)
        }
        FocusShared.setBlocked(true, ruleID: rule.id)
    }

    static func unblock(ruleID: UUID) {
        store(for: ruleID).clearAllSettings()
        FocusShared.setBlocked(false, ruleID: ruleID)
    }
}
