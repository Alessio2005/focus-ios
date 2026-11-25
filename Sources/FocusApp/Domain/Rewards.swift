import Foundation

/// Beloningsregels, gelijk aan domain/Rules.kt van de Android-app.
struct SessionReward: Codable, Equatable {
    var xp: Int
    var coins: Int
    var freeMinutes: Int

    static let none = SessionReward(xp: 0, coins: 0, freeMinutes: 0)
}

enum Rewards {
    static let cleanBonusPercent = 20
    static let maxPauseBank = 120
    static let achievementCoins = 5

    /// 1 XP per gefocuste minuut, +20% als je geen geblokkeerde app probeerde.
    /// 1 munt per 10 minuten. 10 minuten pauzetegoed per 50 gefocuste minuten.
    /// Een blok dat je vroeg stopt levert niets op.
    static func sessionReward(focusedMinutes: Int, blockedAttempts: Int, completed: Bool) -> SessionReward {
        guard completed, focusedMinutes > 0 else { return .none }
        let bonus = blockedAttempts == 0 ? focusedMinutes * cleanBonusPercent / 100 : 0
        return SessionReward(
            xp: focusedMinutes + bonus,
            coins: focusedMinutes / 10,
            freeMinutes: (focusedMinutes / 50) * 10
        )
    }

    /// Totale XP voor een level: 0, 100, 300, 600, 1000, ...
    static func xpForLevel(_ level: Int) -> Int { 50 * (level - 1) * level }

    static func level(forXP xp: Int) -> Int {
        var level = 1
        while xpForLevel(level + 1) <= xp { level += 1 }
        return level
    }

    static func levelProgress(xp: Int) -> Double {
        let current = Self.level(forXP: xp)
        let from = xpForLevel(current)
        let to = xpForLevel(current + 1)
        return min(max(Double(xp - from) / Double(to - from), 0), 1)
    }

    private static let levelNames = [
        "Beginner", "Starter", "Doorzetter", "Focusser", "Studieheld",
        "Kennisjager", "Meesterbrein", "Focusmeester", "Legende",
    ]

    static func levelName(_ level: Int) -> String {
        level <= levelNames.count ? levelNames[level - 1] : "Legende \(level - levelNames.count + 1)"
    }

    /// Groeifase van de plant op het startscherm (0...4).
    static func plantStage(_ level: Int) -> Int {
        switch level {
        case ...1: return 0
        case 2: return 1
        case 3...4: return 2
        case 5...6: return 3
        default: return 4
        }
    }
}

struct StreakState: Codable, Equatable {
    var streak: Int
    var lastDay: Int?
    var freezes: Int
}

enum Streaks {
    static let dailyMinutes = 25
    static let maxFreezes = 2

    struct Update {
        var state: StreakState
        var usedFreeze: Bool
        var earnedFreeze: Bool
    }

    static func update(_ state: StreakState, today: Int, minutesToday: Int, threshold: Int = dailyMinutes) -> Update {
        if minutesToday < threshold || state.lastDay == today {
            return Update(state: state, usedFreeze: false, earnedFreeze: false)
        }
        var freezes = state.freezes
        var usedFreeze = false
        let newStreak: Int
        if let last = state.lastDay {
            let gap = today - last
            if gap == 1 {
                newStreak = state.streak + 1
            } else if gap == 2 && freezes > 0 {
                freezes -= 1
                usedFreeze = true
                newStreak = state.streak + 1
            } else {
                newStreak = 1
            }
        } else {
            newStreak = 1
        }
        var earned = false
        if newStreak % 7 == 0 && freezes < maxFreezes {
            freezes += 1
            earned = true
        }
        return Update(state: StreakState(streak: newStreak, lastDay: today, freezes: freezes),
                      usedFreeze: usedFreeze, earnedFreeze: earned)
    }

    /// De streak zoals die vandaag getoond wordt (0 als hij gebroken is).
    static func current(_ state: StreakState, today: Int) -> Int {
        guard let last = state.lastDay else { return 0 }
        let gap = today - last
        if gap <= 1 { return state.streak }
        if gap == 2 && state.freezes > 0 { return state.streak }
        return 0
    }
}

struct AchievementStats {
    var completedSessions: Int
    var totalMinutes: Int
    var streak: Int
    var strictCompleted: Int
    var cleanSessions: Int
    var parkedNotes: Int
    var level: Int
}

enum Achievement: String, CaseIterable, Identifiable, Codable {
    case first, five, twentyFive, hundred, streak3, streak7, streak30
    case hours10, hours50, strict, clean, clean10, parker, level5

    var id: String { rawValue }

    var title: String {
        switch self {
        case .first: return "Eerste blok"
        case .five: return "Op gang"
        case .twentyFive: return "Gewoontevormer"
        case .hundred: return "Honderdklapper"
        case .streak3: return "Drie op rij"
        case .streak7: return "Weekstrijder"
        case .streak30: return "Maandmonster"
        case .hours10: return "Tien uur"
        case .hours50: return "Vijftig uur"
        case .strict: return "IJzeren wil"
        case .clean: return "Ongestoord"
        case .clean10: return "Smetteloos"
        case .parker: return "Gedachteparkeerder"
        case .level5: return "Studieheld"
        }
    }

    var detail: String {
        switch self {
        case .first: return "Rond je eerste studieblok af"
        case .five: return "Rond 5 studieblokken af"
        case .twentyFive: return "Rond 25 studieblokken af"
        case .hundred: return "Rond 100 studieblokken af"
        case .streak3: return "Haal een streak van 3 dagen"
        case .streak7: return "Haal een streak van 7 dagen"
        case .streak30: return "Haal een streak van 30 dagen"
        case .hours10: return "Studeer in totaal 10 uur gefocust"
        case .hours50: return "Studeer in totaal 50 uur gefocust"
        case .strict: return "Rond een blok af in strikte modus"
        case .clean: return "Rond een blok af zonder een geblokkeerde app te proberen"
        case .clean10: return "Rond 10 blokken af zonder poging"
        case .parker: return "Zet 5 gedachten op je parkeerlijst"
        case .level5: return "Bereik level 5"
        }
    }

    var symbol: String {
        switch self {
        case .first, .five, .twentyFive, .hundred: return "checkmark.seal.fill"
        case .streak3, .streak7, .streak30: return "flame.fill"
        case .hours10, .hours50: return "clock.fill"
        case .strict: return "lock.fill"
        case .clean, .clean10: return "sparkles"
        case .parker: return "note.text"
        case .level5: return "star.fill"
        }
    }

    func isMet(_ s: AchievementStats) -> Bool {
        switch self {
        case .first: return s.completedSessions >= 1
        case .five: return s.completedSessions >= 5
        case .twentyFive: return s.completedSessions >= 25
        case .hundred: return s.completedSessions >= 100
        case .streak3: return s.streak >= 3
        case .streak7: return s.streak >= 7
        case .streak30: return s.streak >= 30
        case .hours10: return s.totalMinutes >= 600
        case .hours50: return s.totalMinutes >= 3000
        case .strict: return s.strictCompleted >= 1
        case .clean: return s.cleanSessions >= 1
        case .clean10: return s.cleanSessions >= 10
        case .parker: return s.parkedNotes >= 5
        case .level5: return s.level >= 5
        }
    }

    static func newlyUnlocked(_ stats: AchievementStats, unlocked: Set<String>) -> [Achievement] {
        allCases.filter { !unlocked.contains($0.rawValue) && $0.isMet(stats) }
    }
}

/// Dagnummer in de lokale tijdzone, voor streaks.
enum Day {
    static func number(_ date: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        let offset = TimeInterval(calendar.timeZone.secondsFromGMT(for: start))
        return Int(((start.timeIntervalSince1970 + offset) / 86_400).rounded())
    }
}
