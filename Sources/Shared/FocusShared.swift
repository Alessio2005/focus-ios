import Foundation

/// Gedeelde opslag via een App Group, zodat de extensie dezelfde regels ziet als de app.
enum FocusShared {
    static let appGroup = "group.nl.focusapp.focus"
    private static let rulesKey = "focus.rules"
    private static let activeKey = "focus.activeBlocks"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    static func loadRules() -> [FocusRule] {
        guard let data = defaults.data(forKey: rulesKey) else { return [] }
        return (try? JSONDecoder().decode([FocusRule].self, from: data)) ?? []
    }

    static func saveRules(_ rules: [FocusRule]) {
        guard let data = try? JSONEncoder().encode(rules) else { return }
        defaults.set(data, forKey: rulesKey)
    }

    static func rule(id: UUID) -> FocusRule? {
        loadRules().first { $0.id == id }
    }

    // MARK: Actieve blokkades (voor het dashboard)

    static func activeBlockIDs() -> Set<UUID> {
        let strings = defaults.stringArray(forKey: activeKey) ?? []
        return Set(strings.compactMap(UUID.init(uuidString:)))
    }

    static func setBlocked(_ blocked: Bool, ruleID: UUID) {
        var ids = activeBlockIDs()
        if blocked { ids.insert(ruleID) } else { ids.remove(ruleID) }
        defaults.set(ids.map(\.uuidString), forKey: activeKey)
    }

    static func clearAllActive() {
        defaults.removeObject(forKey: activeKey)
    }
}
