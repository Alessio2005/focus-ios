import DeviceActivity
import FamilyControls
import Foundation
import SwiftUI
import UserNotifications

/// Alles rond studieblokken: profiel, geschiedenis, parkeerlijst, blokkeerlijsten en het lopende blok.
/// Gegevens staan alleen op dit toestel (JSON in de App Group-map).
@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var profile: Profile
    @Published private(set) var sessions: [StudySession]
    @Published private(set) var notes: [ParkedNote]
    @Published private(set) var lists: [BlockList]
    @Published private(set) var active: ActiveSession?
    @Published var lastResult: SessionResult?
    @Published var lastError: String?

    private let center = DeviceActivityCenter()
    private let folder: URL

    init() {
        let fm = FileManager.default
        let base = fm.containerURL(forSecurityApplicationGroupIdentifier: FocusShared.appGroup)
            ?? fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        folder = base.appendingPathComponent("FocusBlok", isDirectory: true)
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)

        profile = Self.read(Profile.self, "profile.json", in: folder) ?? Profile()
        sessions = Self.read([StudySession].self, "sessions.json", in: folder) ?? []
        notes = Self.read([ParkedNote].self, "notes.json", in: folder) ?? []
        lists = Self.read([BlockList].self, "lists.json", in: folder) ?? [BlockList(name: "Social media")]
        active = FocusShared.activeSession()
    }

    // MARK: Opslag

    private static func read<T: Decodable>(_ type: T.Type, _ name: String, in folder: URL) -> T? {
        guard let data = try? Data(contentsOf: folder.appendingPathComponent(name)) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func write<T: Encodable>(_ value: T, _ name: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: folder.appendingPathComponent(name), options: .atomic)
    }

    private func saveProfile() { write(profile, "profile.json") }
    private func saveSessions() { write(sessions, "sessions.json") }
    private func saveNotes() { write(notes, "notes.json") }
    private func saveLists() { write(lists, "lists.json") }

    func updateProfile(_ change: (inout Profile) -> Void) {
        change(&profile)
        saveProfile()
    }

    // MARK: Afgeleide waarden

    var theme: AppTheme { AppTheme.with(id: profile.themeID) }
    var level: Int { Rewards.level(forXP: profile.xp) }
    var currentStreak: Int { Streaks.current(profile.streakState, today: Day.number(Date())) }
    var attempts: Int { FocusShared.sessionAttempts }

    var colorScheme: ColorScheme? {
        switch profile.darkMode {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    func minutes(on day: Date) -> Int {
        let cal = Calendar.current
        return sessions.filter { cal.isDate($0.startedAt, inSameDayAs: day) }.reduce(0) { $0 + $1.focusedMinutes }
    }

    var minutesToday: Int { minutes(on: Date()) }
    var totalMinutes: Int { sessions.reduce(0) { $0 + $1.focusedMinutes } }
    var completedCount: Int { sessions.filter(\.completed).count }

    var recentSubjects: [String] {
        var seen = Set<String>()
        return sessions.map(\.subject).filter { !$0.isEmpty && seen.insert($0).inserted }.prefix(8).map { $0 }
    }

    func notes(for session: ActiveSession) -> [ParkedNote] {
        notes.filter { $0.sessionStart == session.startedAt }
    }

    // MARK: Blokkeerlijsten

    func save(_ list: BlockList) {
        if let i = lists.firstIndex(where: { $0.id == list.id }) { lists[i] = list } else { lists.append(list) }
        saveLists()
    }

    func delete(_ list: BlockList) {
        lists.removeAll { $0.id == list.id }
        saveLists()
    }

    // MARK: Parkeerlijst

    func park(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        notes.insert(ParkedNote(sessionStart: active?.startedAt, text: trimmed), at: 0)
        saveNotes()
    }

    func toggle(_ note: ParkedNote) {
        guard let i = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[i].done.toggle()
        saveNotes()
    }

    func delete(_ note: ParkedNote) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }

    // MARK: Studieblok starten

    func start(task: String, subject: String, plan: SessionPlan, list: BlockList, strict: Bool) {
        let session = ActiveSession(
            startedAt: Date(), plan: plan,
            task: task.trimmingCharacters(in: .whitespacesAndNewlines),
            subject: subject.trimmingCharacters(in: .whitespacesAndNewlines),
            listName: list.name, selection: list.selection, strict: strict
        )
        lastResult = nil
        FocusShared.setActiveSession(session)
        FocusShared.sessionAttempts = 0
        active = session
        Blocker.blockSession(session)
        scheduleMonitoring(for: session)
        scheduleNotifications(for: session)
    }

    /// Elke focusronde krijgt een eigen DeviceActivity-interval, zodat de extensie
    /// ook bij een gesloten app blokkeert en weer vrijgeeft.
    private func scheduleMonitoring(for session: ActiveSession) {
        stopSessionMonitoring()
        let cal = Calendar.current
        let parts: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        for window in session.plan.focusWindows(from: session.startedAt) {
            let schedule = DeviceActivitySchedule(
                intervalStart: cal.dateComponents(parts, from: window.start),
                intervalEnd: cal.dateComponents(parts, from: window.end),
                repeats: false
            )
            do {
                try center.startMonitoring(ActivityNaming.name(.session, id: session.id, index: window.round), during: schedule)
            } catch {
                lastError = "Achtergrondbewaking lukte niet (\(error.localizedDescription)). Open FocusBlok na je blok om de apps vrij te geven."
            }
        }
    }

    private func stopSessionMonitoring() {
        let names = center.activities.filter {
            guard let kind = ActivityNaming.parse($0)?.kind else { return false }
            return kind == .session || kind == .pause
        }
        if !names.isEmpty { center.stopMonitoring(names) }
    }

    private func scheduleNotifications(for session: ActiveSession) {
        let nc = UNUserNotificationCenter.current()
        nc.removeAllPendingNotificationRequests()
        func add(_ id: String, _ title: String, _ body: String, at date: Date) {
            let seconds = date.timeIntervalSinceNow
            guard seconds > 1 else { return }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
            nc.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
        let windows = session.plan.focusWindows(from: session.startedAt)
        for window in windows where window.round < session.plan.rounds {
            add("break.\(window.round)", "Pauze!", "Ronde \(window.round) zit erop. Even \(session.plan.breakMinutes) minuten pauze.", at: window.end)
            if let next = windows.first(where: { $0.round == window.round + 1 }) {
                add("focus.\(next.round)", "Weer focussen", "Ronde \(next.round) begint: \(session.task)", at: next.start)
            }
        }
        add("done", "Studieblok klaar", "Goed gedaan! Open FocusBlok voor je beloning.", at: session.endsAt)
    }

    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: Tijdens het blok

    /// Pauzetegoed besteden: de apps zijn een paar minuten vrij. Niet in strikte modus.
    @discardableResult
    func usePause(minutes: Int) -> Bool {
        guard var session = active, !session.strict, profile.pauseBank >= minutes else { return false }
        let now = Date()
        updateProfile { $0.pauseBank -= minutes }
        session.unlockedUntil = now.addingTimeInterval(TimeInterval(minutes * 60))
        session.pauseUsedSeconds += TimeInterval(minutes * 60)
        persist(session)
        Blocker.unblockSession()

        // iOS wil intervallen van minstens 15 minuten. Daarom laten we het interval
        // eerder beginnen, zodat het einde precies op het eind van de pauze valt.
        let cal = Calendar.current
        let parts: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        let end = session.unlockedUntil
        let schedule = DeviceActivitySchedule(
            intervalStart: cal.dateComponents(parts, from: end.addingTimeInterval(-16 * 60)),
            intervalEnd: cal.dateComponents(parts, from: end),
            repeats: false
        )
        let name = ActivityNaming.name(.pause, id: session.id)
        center.stopMonitoring([name])
        do {
            try center.startMonitoring(name, during: schedule)
        } catch {
            lastError = "De pauze kon niet automatisch eindigen. Open FocusBlok om weer te blokkeren."
        }
        return true
    }

    private func persist(_ session: ActiveSession?) {
        FocusShared.setActiveSession(session)
        active = session
    }

    /// Bijwerken als de app weer open gaat: blok afronden als de tijd om is,
    /// blokkade in de juiste stand zetten en vaste studietijden verwerken.
    func refresh() {
        active = FocusShared.activeSession()
        if let session = active {
            if session.phase().finished {
                finish(completed: true)
            } else {
                Blocker.syncSession(session)
            }
        }
        for run in FocusShared.takePendingRuns() { record(run) }
        objectWillChange.send()
    }

    // MARK: Afronden en belonen

    func finish(completed: Bool) {
        guard let session = active else { return }
        let attempts = FocusShared.sessionAttempts
        FocusShared.setActiveSession(nil)
        active = nil
        Blocker.unblockSession()
        stopSessionMonitoring()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        let now = min(Date(), session.endsAt)
        let focused = max(session.plan.focusedSeconds(at: now.timeIntervalSince(session.startedAt)) - session.pauseUsedSeconds, 0)
        let minutes = Int(focused / 60)
        lastResult = award(
            task: session.task, subject: session.subject, listName: session.listName,
            start: session.startedAt, end: now, planned: session.plan.plannedFocusMinutes,
            focused: minutes, attempts: attempts, strict: session.strict, completed: completed, scheduled: false
        )
    }

    /// Een vaste studietijd die buiten de app liep telt als afgerond blok.
    private func record(_ run: ScheduledRun) {
        let minutes = max(Int(run.end.timeIntervalSince(run.start) / 60), 0)
        guard minutes > 0, !sessions.contains(where: { $0.startedAt == run.start }) else { return }
        let result = award(
            task: run.task, subject: "", listName: run.listName, start: run.start, end: run.end,
            planned: minutes, focused: minutes, attempts: run.attempts, strict: false, completed: true, scheduled: true
        )
        if lastResult == nil { lastResult = result }
    }

    private func award(task: String, subject: String, listName: String, start: Date, end: Date,
                       planned: Int, focused: Int, attempts: Int, strict: Bool, completed: Bool,
                       scheduled: Bool) -> SessionResult {
        let reward = Rewards.sessionReward(focusedMinutes: focused, blockedAttempts: attempts, completed: completed)
        sessions.insert(StudySession(
            startedAt: start, endedAt: end, plannedFocusMinutes: planned, focusedMinutes: focused,
            task: task, subject: subject, listName: listName, strict: strict, attempts: attempts,
            completed: completed, reward: reward, scheduled: scheduled
        ), at: 0)
        sessions.sort { $0.startedAt > $1.startedAt }
        saveSessions()

        let today = Day.number(Date())
        let levelBefore = level
        let update = Streaks.update(profile.streakState, today: today, minutesToday: minutesToday)
        updateProfile { p in
            p.xp += reward.xp
            p.coins += reward.coins
            p.pauseBank = min(p.pauseBank + reward.freeMinutes, Rewards.maxPauseBank)
            p.streak = update.state.streak
            p.lastStreakDay = update.state.lastDay
            p.freezes = update.state.freezes
        }
        let streakNow = currentStreak
        let stats = AchievementStats(
            completedSessions: completedCount,
            totalMinutes: totalMinutes,
            streak: streakNow,
            strictCompleted: sessions.filter { $0.completed && $0.strict }.count,
            cleanSessions: sessions.filter { $0.completed && $0.attempts == 0 }.count,
            parkedNotes: notes.count,
            level: level
        )
        let newly = Achievement.newlyUnlocked(stats, unlocked: profile.achievements)
        if !newly.isEmpty {
            updateProfile { p in
                p.achievements.formUnion(newly.map(\.rawValue))
                p.coins += newly.count * Rewards.achievementCoins
            }
        }
        return SessionResult(
            completed: completed, task: task, focusedMinutes: focused, attempts: attempts, reward: reward,
            streak: streakNow, usedFreeze: update.usedFreeze, earnedFreeze: update.earnedFreeze,
            newAchievements: newly, levelBefore: levelBefore, levelAfter: level
        )
    }

    // MARK: Winkel

    func buy(_ theme: AppTheme) {
        guard !profile.ownedThemes.contains(theme.id), profile.coins >= theme.price else { return }
        updateProfile { p in
            p.coins -= theme.price
            p.ownedThemes.insert(theme.id)
            p.themeID = theme.id
        }
    }

    // MARK: Gegevens

    struct Export: Encodable {
        var profile: Profile
        var sessions: [StudySession]
        var notes: [ParkedNote]
        var blockLists: [String]
        var exportedAt = Date()
    }

    func exportFile() -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let export = Export(profile: profile, sessions: sessions, notes: notes, blockLists: lists.map(\.name))
        guard let data = try? encoder.encode(export) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("focusblok-export.json")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    func wipeAll() {
        center.stopMonitoring()
        Blocker.clearEverything()
        FocusShared.wipe()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        profile = Profile()
        sessions = []
        notes = []
        lists = [BlockList(name: "Social media")]
        active = nil
        lastResult = nil
        saveProfile(); saveSessions(); saveNotes(); saveLists()
    }
}
