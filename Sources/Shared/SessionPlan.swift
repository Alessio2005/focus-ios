import Foundation

/// Plan van een studieblok: vrij (1 ronde) of Pomodoro (meerdere rondes met pauzes).
/// Gelijk aan SessionPlan in de Android-app.
struct SessionPlan: Codable, Equatable {
    var focusMinutes: Int
    var breakMinutes: Int
    var rounds: Int

    static func single(_ minutes: Int) -> SessionPlan {
        SessionPlan(focusMinutes: minutes, breakMinutes: 0, rounds: 1)
    }

    var totalMinutes: Int { focusMinutes * rounds + breakMinutes * max(rounds - 1, 0) }
    var totalSeconds: TimeInterval { TimeInterval(totalMinutes * 60) }
    var plannedFocusMinutes: Int { focusMinutes * rounds }
    var isPomodoro: Bool { rounds > 1 }

    private var focusSeconds: TimeInterval { TimeInterval(focusMinutes * 60) }
    private var cycleSeconds: TimeInterval { TimeInterval((focusMinutes + breakMinutes) * 60) }

    struct Phase: Equatable {
        var isFocus: Bool
        var round: Int
        var remaining: TimeInterval
        var finished: Bool
    }

    func phase(at elapsed: TimeInterval) -> Phase {
        if elapsed >= totalSeconds {
            return Phase(isFocus: true, round: rounds, remaining: 0, finished: true)
        }
        let t = max(elapsed, 0)
        let round = Int(t / cycleSeconds)
        let inCycle = t - Double(round) * cycleSeconds
        if inCycle < focusSeconds {
            return Phase(isFocus: true, round: round + 1, remaining: focusSeconds - inCycle, finished: false)
        }
        return Phase(isFocus: false, round: round + 1, remaining: cycleSeconds - inCycle, finished: false)
    }

    func focusedSeconds(at elapsed: TimeInterval) -> TimeInterval {
        let t = min(max(elapsed, 0), totalSeconds)
        let full = (t / cycleSeconds).rounded(.down)
        let rest = t - full * cycleSeconds
        return full * focusSeconds + min(rest, focusSeconds)
    }

    /// Begin- en eindtijd van elke focusronde, vanaf het startmoment.
    func focusWindows(from start: Date) -> [(round: Int, start: Date, end: Date)] {
        (0..<rounds).map { index in
            let s = start.addingTimeInterval(Double(index) * cycleSeconds)
            return (index + 1, s, s.addingTimeInterval(focusSeconds))
        }
    }
}
