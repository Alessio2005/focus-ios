import Combine
import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

/// Regelt toestemming, opslag van regels en het starten/stoppen van DeviceActivity-schema's.
@MainActor
final class ScreenTimeManager: ObservableObject {
    @Published private(set) var authorizationStatus: AuthorizationStatus
    @Published private(set) var rules: [FocusRule]
    @Published private(set) var activeBlocks: Set<UUID>
    @Published var lastError: String?

    private let center = DeviceActivityCenter()
    private var cancellables = Set<AnyCancellable>()

    init() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        rules = FocusShared.loadRules()
        activeBlocks = FocusShared.activeBlockIDs()

        AuthorizationCenter.shared.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in self?.authorizationStatus = status }
            .store(in: &cancellables)
    }

    var isAuthorized: Bool { authorizationStatus == .approved }

    func rules(of kind: RuleKind) -> [FocusRule] {
        rules.filter { $0.kind == kind }
    }

    func isBlocked(_ rule: FocusRule) -> Bool {
        activeBlocks.contains(rule.id)
    }

    func refresh() {
        activeBlocks = FocusShared.activeBlockIDs()
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }

    // MARK: Toestemming

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            lastError = nil
        } catch {
            lastError = "Toestemming mislukt: \(error.localizedDescription)"
        }
        refresh()
    }

    // MARK: Regels beheren

    func save(_ rule: FocusRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
        } else {
            rules.append(rule)
        }
        FocusShared.saveRules(rules)
        apply(rule)
    }

    func delete(_ rule: FocusRule) {
        stopMonitoring(rule.id)
        Blocker.unblock(ruleID: rule.id)
        rules.removeAll { $0.id == rule.id }
        FocusShared.saveRules(rules)
        refresh()
    }

    func setEnabled(_ enabled: Bool, for rule: FocusRule) {
        var updated = rule
        updated.isEnabled = enabled
        save(updated)
    }

    /// Hef alle blokkades op en stop alle bewaking (noodknop in Instellingen).
    func stopEverything() {
        center.stopMonitoring()
        for rule in rules { Blocker.unblock(ruleID: rule.id) }
        FocusShared.clearAllActive()
        rules = rules.map { var r = $0; r.isEnabled = false; return r }
        FocusShared.saveRules(rules)
        refresh()
    }

    // MARK: DeviceActivity

    private func apply(_ rule: FocusRule) {
        stopMonitoring(rule.id)
        Blocker.unblock(ruleID: rule.id)

        guard rule.isEnabled, rule.hasSelection else {
            refresh()
            return
        }

        do {
            switch rule.kind {
            case .dailyLimit: try startDailyLimit(rule)
            case .schedule: try startSchedule(rule)
            }
            lastError = nil
        } catch {
            lastError = "Bewaking starten mislukt: \(error.localizedDescription)"
        }
        refresh()
    }

    /// Een interval van de hele dag, met een event dat afgaat zodra de limiet bereikt is.
    private func startDailyLimit(_ rule: FocusRule) throws {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        let event = DeviceActivityEvent(
            applications: rule.selection.applicationTokens,
            categories: rule.selection.categoryTokens,
            webDomains: rule.selection.webDomainTokens,
            threshold: DateComponents(minute: rule.dailyLimitMinutes)
        )
        try center.startMonitoring(
            ActivityNaming.limitActivity(for: rule.id),
            during: schedule,
            events: [ActivityNaming.limitEvent: event]
        )
    }

    /// Eén schema per gekozen weekdag (of één voor iedere dag).
    /// iOS vereist dat een interval minstens 15 minuten duurt.
    private func startSchedule(_ rule: FocusRule) throws {
        if rule.weekdays.count == 7 {
            let schedule = DeviceActivitySchedule(
                intervalStart: DateComponents(hour: rule.startHour, minute: rule.startMinute),
                intervalEnd: DateComponents(hour: rule.endHour, minute: rule.endMinute),
                repeats: true
            )
            try center.startMonitoring(ActivityNaming.scheduleActivity(for: rule.id, weekday: 0), during: schedule)
            return
        }

        for weekday in rule.weekdays.sorted() {
            let endWeekday = rule.crossesMidnight ? (weekday % 7) + 1 : weekday
            let schedule = DeviceActivitySchedule(
                intervalStart: DateComponents(hour: rule.startHour, minute: rule.startMinute, weekday: weekday),
                intervalEnd: DateComponents(hour: rule.endHour, minute: rule.endMinute, weekday: endWeekday),
                repeats: true
            )
            try center.startMonitoring(ActivityNaming.scheduleActivity(for: rule.id, weekday: weekday), during: schedule)
        }
    }

    private func stopMonitoring(_ id: UUID) {
        let names = center.activities.filter { ActivityNaming.parse($0)?.id == id }
        if !names.isEmpty { center.stopMonitoring(names) }
    }
}
