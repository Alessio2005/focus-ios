import Foundation
import FamilyControls

/// Soort regel: een dagelijkse limiet of een vast tijdschema.
enum RuleKind: String, Codable, CaseIterable {
    case dailyLimit
    case schedule
}

/// Eén blokkeerregel. Wordt gedeeld tussen de app en de ActivityMonitor-extensie.
struct FocusRule: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var kind: RuleKind
    var selection: FamilyActivitySelection = FamilyActivitySelection()
    var isEnabled: Bool = true

    // Dagelijkse limiet
    var dailyLimitMinutes: Int = 30

    // Tijdschema
    var startHour: Int = 9
    var startMinute: Int = 0
    var endHour: Int = 17
    var endMinute: Int = 0
    /// Calendar-weekdagen: 1 = zondag, 2 = maandag ... 7 = zaterdag.
    var weekdays: Set<Int> = [2, 3, 4, 5, 6]

    var hasSelection: Bool {
        !selection.applicationTokens.isEmpty
            || !selection.categoryTokens.isEmpty
            || !selection.webDomainTokens.isEmpty
    }

    var selectionSummary: String {
        let apps = selection.applicationTokens.count
        let cats = selection.categoryTokens.count
        let webs = selection.webDomainTokens.count
        var parts: [String] = []
        if apps > 0 { parts.append("\(apps) app\(apps == 1 ? "" : "s")") }
        if cats > 0 { parts.append("\(cats) categorie\(cats == 1 ? "" : "ën")") }
        if webs > 0 { parts.append("\(webs) website\(webs == 1 ? "" : "s")") }
        return parts.isEmpty ? "Nog niets gekozen" : parts.joined(separator: ", ")
    }

    var timeRangeText: String {
        String(format: "%02d:%02d – %02d:%02d", startHour, startMinute, endHour, endMinute)
    }

    var weekdaysText: String {
        if weekdays.count == 7 { return "Iedere dag" }
        if weekdays == [2, 3, 4, 5, 6] { return "Ma t/m vr" }
        if weekdays == [1, 7] { return "Weekend" }
        return Weekday.ordered
            .filter { weekdays.contains($0.rawValue) }
            .map(\.shortName)
            .joined(separator: ", ")
    }

    /// True als het schema over middernacht loopt, bijvoorbeeld 22:00 – 08:00.
    var crossesMidnight: Bool {
        (endHour * 60 + endMinute) <= (startHour * 60 + startMinute)
    }

    var detailText: String {
        switch kind {
        case .dailyLimit: return "\(dailyLimitMinutes) min per dag"
        case .schedule: return "\(weekdaysText), \(timeRangeText)"
        }
    }
}

enum Weekday: Int, CaseIterable, Identifiable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    /// Nederlandse volgorde: maandag eerst.
    static let ordered: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]

    var shortName: String {
        switch self {
        case .sunday: return "zo"
        case .monday: return "ma"
        case .tuesday: return "di"
        case .wednesday: return "wo"
        case .thursday: return "do"
        case .friday: return "vr"
        case .saturday: return "za"
        }
    }
}
