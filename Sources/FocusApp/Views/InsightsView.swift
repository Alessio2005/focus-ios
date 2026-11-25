import Charts
import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var store: AppStore

    private struct DayMinutes: Identifiable {
        let date: Date
        let minutes: Int
        var id: Date { date }
    }

    private var lastSevenDays: [DayMinutes] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return DayMinutes(date: day, minutes: store.minutes(on: day))
        }
    }

    private struct SubjectMinutes: Identifiable {
        let subject: String
        let minutes: Int
        var id: String { subject }
    }

    private var perSubject: [SubjectMinutes] {
        var totals: [String: Int] = [:]
        for s in store.sessions {
            totals[s.subject.isEmpty ? "Overig" : s.subject, default: 0] += s.focusedMinutes
        }
        return totals.map { SubjectMinutes(subject: $0.key, minutes: $0.value) }.sorted { $0.minutes > $1.minutes }
    }

    private var weekMinutes: Int { lastSevenDays.reduce(0) { $0 + $1.minutes } }
    private var totalAttempts: Int { store.sessions.reduce(0) { $0 + $1.attempts } }

    var body: some View {
        NavigationStack {
            ScrollScreen {
                HStack(spacing: 10) {
                    StatTile(value: formatMinutes(weekMinutes), label: "deze week")
                    StatTile(value: "\(store.completedCount)", label: "blokken af")
                    StatTile(value: "\(totalAttempts)", label: "pogingen")
                }

                Card(title: "Minuten per dag") {
                    Chart(lastSevenDays) { day in
                        BarMark(
                            x: .value("Dag", day.date, unit: .day),
                            y: .value("Minuten", day.minutes)
                        )
                        .foregroundStyle(Color.accentColor.gradient)
                        .cornerRadius(4)
                        RuleMark(y: .value("Streakdoel", Streaks.dailyMinutes))
                            .foregroundStyle(.secondary)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    }
                    .frame(height: 180)
                    Text("Streak telt vanaf \(Streaks.dailyMinutes) minuten per dag.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                if !perSubject.isEmpty {
                    Card(title: "Per vak") {
                        ForEach(perSubject) { item in
                            HStack {
                                Text(item.subject)
                                Spacer()
                                Text(formatMinutes(item.minutes)).foregroundStyle(.secondary).monospacedDigit()
                            }
                        }
                    }
                }

                Card(title: "Geschiedenis") {
                    if store.sessions.isEmpty {
                        Text("Nog geen blokken. Start je eerste!").foregroundStyle(.secondary)
                    } else {
                        ForEach(store.sessions.prefix(30)) { s in
                            HStack(alignment: .top) {
                                Image(systemName: s.completed ? "checkmark.circle.fill" : "xmark.circle")
                                    .foregroundStyle(s.completed ? Color.accentColor : .orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(s.task).font(.subheadline.weight(.medium))
                                    Text("\(s.startedAt.formatted(date: .abbreviated, time: .shortened)) · \(s.focusedMinutes) min\(s.subject.isEmpty ? "" : " · \(s.subject)")\(s.scheduled ? " · vaste tijd" : "")")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if s.reward.xp > 0 {
                                    Text("+\(s.reward.xp) XP").font(.caption.bold()).foregroundStyle(.tint)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                Card {
                    Text("Schermtijd van je geblokkeerde apps zie je op iOS in Instellingen > Schermtijd. Apple geeft die cijfers alleen via een apart rapport en niet direct aan apps.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Inzicht")
        }
    }
}
