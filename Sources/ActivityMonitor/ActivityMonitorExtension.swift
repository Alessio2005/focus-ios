import DeviceActivity
import Foundation
import ManagedSettings

/// iOS roept deze extensie aan op de achtergrond, ook als de Focus-app dicht is.
class ActivityMonitorExtension: DeviceActivityMonitor {

    /// Begin van een interval.
    /// - Tijdschema: het blokvenster start, dus blokkeren.
    /// - Dagelijkse limiet: er begint een nieuwe dag, dus de blokkade van gisteren opheffen.
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        guard let parsed = ActivityNaming.parse(activity) else { return }

        switch parsed.kind {
        case .schedule:
            guard let rule = FocusShared.rule(id: parsed.id), rule.isEnabled else { return }
            Blocker.block(rule)
        case .dailyLimit:
            Blocker.unblock(ruleID: parsed.id)
        }
    }

    /// Einde van een interval: de ingestelde periode is voorbij, blokkade opheffen.
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard let parsed = ActivityNaming.parse(activity) else { return }
        Blocker.unblock(ruleID: parsed.id)
    }

    /// De dagelijkse limiet is bereikt: apps blokkeren tot het eind van de dag.
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        guard event == ActivityNaming.limitEvent,
              let parsed = ActivityNaming.parse(activity),
              parsed.kind == .dailyLimit,
              let rule = FocusShared.rule(id: parsed.id),
              rule.isEnabled else { return }
        Blocker.block(rule)
    }
}
