import Foundation
import FamilyControls
import ManagedSettings

/// Zet Apple's systeembrede blokkeerscherm (shield) aan of uit.
/// Elke regel en het lopende studieblok krijgen een eigen ManagedSettingsStore,
/// zodat ze elkaar niet opheffen.
enum Blocker {
    static let sessionStoreName = ManagedSettingsStore.Name(rawValue: "focus.session")

    static func store(for id: UUID) -> ManagedSettingsStore {
        ManagedSettingsStore(named: ManagedSettingsStore.Name(rawValue: "rule.\(id.uuidString)"))
    }

    static func apply(_ selection: FamilyActivitySelection, to store: ManagedSettingsStore) {
        guard FocusConfig.screenTimeEnabled else { return }
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        if selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = nil
            store.shield.webDomainCategories = nil
        } else {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
            store.shield.webDomainCategories = .specific(selection.categoryTokens)
        }
    }

    // MARK: Regels

    static func block(_ rule: FocusRule) {
        apply(rule.selection, to: store(for: rule.id))
        FocusShared.setBlocked(true, ruleID: rule.id)
    }

    static func unblock(ruleID: UUID) {
        guard FocusConfig.screenTimeEnabled else { return }
        store(for: ruleID).clearAllSettings()
        FocusShared.setBlocked(false, ruleID: ruleID)
    }

    // MARK: Studieblok

    static func blockSession(_ session: ActiveSession) {
        guard FocusConfig.screenTimeEnabled else { return }
        let store = ManagedSettingsStore(named: sessionStoreName)
        apply(session.selection, to: store)
        // Strikte modus: geblokkeerde apps kunnen tijdens het blok ook niet verwijderd worden.
        store.application.denyAppRemoval = session.strict ? true : nil
    }

    static func unblockSession() {
        guard FocusConfig.screenTimeEnabled else { return }
        ManagedSettingsStore(named: sessionStoreName).clearAllSettings()
    }

    /// Zet de blokkade van het studieblok in de juiste stand voor dit moment.
    static func syncSession(_ session: ActiveSession?, now: Date = Date()) {
        if let session, session.shouldBlock(at: now) {
            blockSession(session)
        } else {
            unblockSession()
        }
    }

    static func clearEverything() {
        guard FocusConfig.screenTimeEnabled else { return }
        ManagedSettingsStore().clearAllSettings()
        unblockSession()
        for rule in FocusShared.loadRules() { store(for: rule.id).clearAllSettings() }
    }
}
