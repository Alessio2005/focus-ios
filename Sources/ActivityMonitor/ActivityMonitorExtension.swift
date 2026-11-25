import DeviceActivity
import Foundation
import ManagedSettings

/// iOS roept deze extensie aan op de achtergrond, ook als FocusBlok dicht is.
class ActivityMonitorExtension: DeviceActivityMonitor {

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        guard let parsed = ActivityNaming.parse(activity) else { return }

        switch parsed.kind {
        case .schedule:
            // Vaste studietijd begint: blokkeren en onthouden voor de beloning.
            guard let rule = FocusShared.rule(id: parsed.id), rule.isEnabled else { return }
            Blocker.block(rule)
            FocusShared.markScheduleStarted(rule.id)
        case .dailyLimit:
            // Nieuwe dag: de blokkade van gisteren opheffen.
            Blocker.unblock(ruleID: parsed.id)
        case .session:
            // Een focusronde van het studieblok begint.
            Blocker.syncSession(currentSession(parsed.id))
        case .pause:
            break
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard let parsed = ActivityNaming.parse(activity) else { return }

        switch parsed.kind {
        case .schedule:
            Blocker.unblock(ruleID: parsed.id)
            if let rule = FocusShared.rule(id: parsed.id) { FocusShared.markScheduleEnded(rule) }
        case .dailyLimit:
            Blocker.unblock(ruleID: parsed.id)
        case .session:
            // Focusronde voorbij: pauze of einde van het blok.
            Blocker.unblockSession()
        case .pause:
            // Pauzetegoed op: weer blokkeren als we nog in een focusronde zitten.
            Blocker.syncSession(currentSession(parsed.id))
        }
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

    private func currentSession(_ id: UUID) -> ActiveSession? {
        guard let session = FocusShared.activeSession(), session.id == id else { return nil }
        return session
    }
}
