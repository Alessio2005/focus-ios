import Foundation
import FamilyControls

/// Het lopende studieblok. Staat in de gedeelde opslag zodat ook de extensies het zien.
struct ActiveSession: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var startedAt: Date
    var plan: SessionPlan
    var task: String
    var subject: String
    var listName: String
    var selection: FamilyActivitySelection
    var strict: Bool
    var unlockedUntil: Date = .distantPast
    var pauseUsedSeconds: TimeInterval = 0
    /// Gevuld als het blok door een vaste studietijd is gestart.
    var scheduleID: UUID?

    var endsAt: Date { startedAt.addingTimeInterval(plan.totalSeconds) }

    func phase(at now: Date = Date()) -> SessionPlan.Phase {
        plan.phase(at: now.timeIntervalSince(startedAt))
    }

    /// Moeten de apps op dit moment geblokkeerd zijn?
    func shouldBlock(at now: Date = Date()) -> Bool {
        let p = phase(at: now)
        return p.isFocus && !p.finished && now >= unlockedUntil
    }
}

/// Een vaste studietijd die buiten de app om is gelopen (gestart en gestopt door de extensie).
/// De app zet dit bij de volgende keer openen om in een afgerond blok met beloning.
struct ScheduledRun: Codable, Equatable {
    var ruleID: UUID
    var task: String
    var listName: String
    var start: Date
    var end: Date
    var attempts: Int
}
