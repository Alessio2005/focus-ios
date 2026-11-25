import Foundation
import DeviceActivity

/// Soorten DeviceActivity-bewaking. Het ID zit in de naam, zodat de extensie weet waar een melding bij hoort.
enum ActivityKind: String {
    case dailyLimit
    case schedule
    case session
    case pause
}

enum ActivityNaming {
    static let limitEvent = DeviceActivityEvent.Name(rawValue: "limit.reached")

    static func name(_ kind: ActivityKind, id: UUID, index: Int = 0) -> DeviceActivityName {
        DeviceActivityName(rawValue: "\(kind.rawValue).\(id.uuidString).\(index)")
    }

    static func limitActivity(for id: UUID) -> DeviceActivityName { name(.dailyLimit, id: id) }

    /// weekday 0 = iedere dag.
    static func scheduleActivity(for id: UUID, weekday: Int) -> DeviceActivityName {
        name(.schedule, id: id, index: weekday)
    }

    static func parse(_ name: DeviceActivityName) -> (kind: ActivityKind, id: UUID, index: Int)? {
        let parts = name.rawValue.split(separator: ".")
        guard parts.count >= 2,
              let kind = ActivityKind(rawValue: String(parts[0])),
              let id = UUID(uuidString: String(parts[1])) else { return nil }
        let index = parts.count >= 3 ? Int(parts[2]) ?? 0 : 0
        return (kind, id, index)
    }
}
