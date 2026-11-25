import FamilyControls
import Foundation
import SwiftUI

struct Profile: Codable, Equatable {
    var xp = 0
    var coins = 0
    var pauseBank = 0
    var streak = 0
    var lastStreakDay: Int?
    var freezes = 0
    var themeID = "teal"
    var ownedThemes: Set<String> = ["teal"]
    /// 0 = systeem, 1 = licht, 2 = donker
    var darkMode = 0
    var onboardingDone = false
    var achievements: Set<String> = []
    var nickname = ""

    var streakState: StreakState { StreakState(streak: streak, lastDay: lastStreakDay, freezes: freezes) }
}

struct BlockList: Codable, Equatable, Identifiable {
    var id = UUID()
    var name: String
    var selection = FamilyActivitySelection()

    var hasSelection: Bool {
        !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty || !selection.webDomainTokens.isEmpty
    }

    var summary: String {
        FocusRule(name: name, kind: .dailyLimit, selection: selection).selectionSummary
    }
}

struct StudySession: Codable, Equatable, Identifiable {
    var id = UUID()
    var startedAt: Date
    var endedAt: Date
    var plannedFocusMinutes: Int
    var focusedMinutes: Int
    var task: String
    var subject: String
    var listName: String
    var strict: Bool
    var attempts: Int
    var completed: Bool
    var reward: SessionReward
    var scheduled = false
}

struct ParkedNote: Codable, Equatable, Identifiable {
    var id = UUID()
    var sessionStart: Date?
    var text: String
    var createdAt = Date()
    var done = false
}

struct SessionResult: Equatable, Identifiable {
    var id = UUID()
    var completed: Bool
    var task: String
    var focusedMinutes: Int
    var attempts: Int
    var reward: SessionReward
    var streak: Int
    var usedFreeze: Bool
    var earnedFreeze: Bool
    var newAchievements: [Achievement]
    var levelBefore: Int
    var levelAfter: Int
}

struct AppTheme: Identifiable, Equatable {
    var id: String
    var name: String
    var color: Color
    var price: Int

    static let all: [AppTheme] = [
        AppTheme(id: "teal", name: "Zeegroen", color: Color(red: 0x0F / 255, green: 0x76 / 255, blue: 0x6E / 255), price: 0),
        AppTheme(id: "ocean", name: "Oceaan", color: Color(red: 0x1D / 255, green: 0x4E / 255, blue: 0xD8 / 255), price: 20),
        AppTheme(id: "sunset", name: "Zonsondergang", color: Color(red: 0xC2 / 255, green: 0x41 / 255, blue: 0x0C / 255), price: 30),
        AppTheme(id: "forest", name: "Bos", color: Color(red: 0x15 / 255, green: 0x80 / 255, blue: 0x3D / 255), price: 30),
        AppTheme(id: "lavender", name: "Lavendel", color: Color(red: 0x7C / 255, green: 0x3A / 255, blue: 0xED / 255), price: 40),
        AppTheme(id: "raspberry", name: "Framboos", color: Color(red: 0xBE / 255, green: 0x18 / 255, blue: 0x5D / 255), price: 50),
    ]

    static func with(id: String) -> AppTheme { all.first { $0.id == id } ?? all[0] }
}
