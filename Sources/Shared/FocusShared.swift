import Foundation

/// Gedeelde opslag via een App Group, zodat app en extensies dezelfde gegevens zien.
enum FocusShared {
    static let appGroup = "group.nl.focusapp.focus"
    static let bouncedKey = "focus.bounced"
    private static let rulesKey = "focus.rules"
    private static let activeKey = "focus.activeBlocks"
    private static let sessionKey = "focus.activeSession"
    private static let attemptsKey = "focus.sessionAttempts"
    private static let scheduleStartsKey = "focus.scheduleStarts"
    private static let scheduleAttemptsKey = "focus.scheduleAttempts"
    private static let pendingRunsKey = "focus.pendingRuns"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func store<T: Encodable>(_ value: T?, key: String) {
        guard let value, let data = try? JSONEncoder().encode(value) else {
            defaults.removeObject(forKey: key)
            return
        }
        defaults.set(data, forKey: key)
    }

    // MARK: Regels (limieten en vaste studietijden)

    static func loadRules() -> [FocusRule] { load([FocusRule].self, key: rulesKey) ?? [] }
    static func saveRules(_ rules: [FocusRule]) { store(rules, key: rulesKey) }
    static func rule(id: UUID) -> FocusRule? { loadRules().first { $0.id == id } }

    // MARK: Actieve blokkades van regels (voor het overzicht)

    static func activeBlockIDs() -> Set<UUID> {
        let strings = defaults.stringArray(forKey: activeKey) ?? []
        return Set(strings.compactMap(UUID.init(uuidString:)))
    }

    static func setBlocked(_ blocked: Bool, ruleID: UUID) {
        var ids = activeBlockIDs()
        if blocked { ids.insert(ruleID) } else { ids.remove(ruleID) }
        defaults.set(ids.map(\.uuidString), forKey: activeKey)
    }

    static func clearAllActive() { defaults.removeObject(forKey: activeKey) }

    // MARK: Lopend studieblok

    static func activeSession() -> ActiveSession? { load(ActiveSession.self, key: sessionKey) }

    static func setActiveSession(_ session: ActiveSession?) {
        store(session, key: sessionKey)
        if session == nil { defaults.set(0, forKey: attemptsKey) }
    }

    static var sessionAttempts: Int {
        get { defaults.integer(forKey: attemptsKey) }
        set { defaults.set(newValue, forKey: attemptsKey) }
    }

    /// Aangeroepen door de ShieldAction-extensie als iemand een geblokkeerde app probeert te openen.
    static func recordAttempt() {
        if activeSession() != nil { sessionAttempts += 1 }
        var perRule = defaults.dictionary(forKey: scheduleAttemptsKey) as? [String: Int] ?? [:]
        for key in scheduleStarts().keys { perRule[key, default: 0] += 1 }
        defaults.set(perRule, forKey: scheduleAttemptsKey)
    }

    // MARK: Vaste studietijden die buiten de app lopen

    private static func scheduleStarts() -> [String: Double] {
        defaults.dictionary(forKey: scheduleStartsKey) as? [String: Double] ?? [:]
    }

    static func markScheduleStarted(_ ruleID: UUID, at date: Date = Date()) {
        var starts = scheduleStarts()
        starts[ruleID.uuidString] = date.timeIntervalSince1970
        defaults.set(starts, forKey: scheduleStartsKey)
        var perRule = defaults.dictionary(forKey: scheduleAttemptsKey) as? [String: Int] ?? [:]
        perRule[ruleID.uuidString] = 0
        defaults.set(perRule, forKey: scheduleAttemptsKey)
    }

    static func markScheduleEnded(_ rule: FocusRule, at date: Date = Date()) {
        var starts = scheduleStarts()
        guard let startValue = starts.removeValue(forKey: rule.id.uuidString) else { return }
        defaults.set(starts, forKey: scheduleStartsKey)
        var perRule = defaults.dictionary(forKey: scheduleAttemptsKey) as? [String: Int] ?? [:]
        let attempts = perRule.removeValue(forKey: rule.id.uuidString) ?? 0
        defaults.set(perRule, forKey: scheduleAttemptsKey)

        var runs = pendingRuns()
        runs.append(ScheduledRun(
            ruleID: rule.id, task: rule.task.isEmpty ? rule.name : rule.task, listName: rule.name,
            start: Date(timeIntervalSince1970: startValue), end: date, attempts: attempts
        ))
        store(runs, key: pendingRunsKey)
    }

    static func pendingRuns() -> [ScheduledRun] { load([ScheduledRun].self, key: pendingRunsKey) ?? [] }

    static func takePendingRuns() -> [ScheduledRun] {
        let runs = pendingRuns()
        defaults.removeObject(forKey: pendingRunsKey)
        return runs
    }

    static func wipe() {
        for key in [rulesKey, activeKey, sessionKey, attemptsKey, scheduleStartsKey, scheduleAttemptsKey, pendingRunsKey] {
            defaults.removeObject(forKey: key)
        }
    }
}
