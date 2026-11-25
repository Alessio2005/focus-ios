import Foundation
import DeviceActivity

/// Namen voor DeviceActivity-schema's. Het regel-ID zit in de naam,
/// zodat de extensie weet welke regel bij een melding hoort.
enum ActivityNaming {
    static let limitEvent = DeviceActivityEvent.Name(rawValue: "limit.reached")

    static func limitActivity(for id: UUID) -> DeviceActivityName {
        DeviceActivityName(rawValue: "\(RuleKind.dailyLimit.rawValue).\(id.uuidString)")
    }

    /// weekday 0 = iedere dag.
    static func scheduleActivity(for id: UUID, weekday: Int) -> DeviceActivityName {
        DeviceActivityName(rawValue: "\(RuleKind.schedule.rawValue).\(id.uuidString).\(weekday)")
    }

    static func parse(_ name: DeviceActivityName) -> (kind: RuleKind, id: UUID)? {
        let parts = name.rawValue.split(separator: ".")
        guard parts.count >= 2,
              let kind = RuleKind(rawValue: String(parts[0])),
              let id = UUID(uuidString: String(parts[1])) else { return nil }
        return (kind, id)
    }
}
