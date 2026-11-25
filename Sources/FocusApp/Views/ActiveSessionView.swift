import SwiftUI

struct ActiveSessionView: View {
    @EnvironmentObject private var store: AppStore
    @State private var noteText = ""
    @State private var confirmStop = false
    @State private var showStrictStop = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            if let session = store.active {
                content(session, now: context.date)
                    .onChange(of: session.phase(at: context.date).finished) { finished in
                        if finished { store.finish(completed: true) }
                    }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .confirmationDialog("Studieblok stoppen?", isPresented: $confirmStop, titleVisibility: .visible) {
            Button("Stoppen zonder beloning", role: .destructive) { store.finish(completed: false) }
            Button("Doorgaan", role: .cancel) {}
        } message: {
            Text("Als je nu stopt, krijg je geen XP, munten of pauzetegoed.")
        }
        .sheet(isPresented: $showStrictStop) {
            StrictStopView { store.finish(completed: false) }
        }
    }

    @ViewBuilder
    private func content(_ session: ActiveSession, now: Date) -> some View {
        let phase = session.phase(at: now)
        let unlocked = now < session.unlockedUntil
        let phaseLength = TimeInterval((phase.isFocus ? session.plan.focusMinutes : session.plan.breakMinutes) * 60)

        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 4) {
                    Text(phase.isFocus ? "Focus" : "Pauze")
                        .font(.headline)
                        .foregroundStyle(phase.isFocus ? Color.accentColor : .orange)
                    if session.plan.isPomodoro {
                        Text("Ronde \(phase.round) van \(session.plan.rounds)").font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 24)

                ZStack {
                    ProgressRing(progress: phaseLength > 0 ? 1 - phase.remaining / phaseLength : 1, lineWidth: 16)
                    VStack(spacing: 6) {
                        Text(formatClock(phase.remaining))
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("Klaar om \(session.endsAt.formatted(date: .omitted, time: .shortened))")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .frame(width: 260, height: 260)

                if store.bouncedFromApp {
                    Card {
                        Label("Even niet! Je zit in je studieblok.", systemImage: "hand.raised.fill").font(.headline)
                        Text("Die app moet wachten tot je blok of pauze. Zet het op je parkeerlijst als het belangrijk is.")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Button("Oké, verder studeren") { store.bouncedFromApp = false }
                            .buttonStyle(.borderedProminent)
                    }
                }

                Card {
                    Label(session.task, systemImage: "target").font(.headline)
                    if !session.subject.isEmpty {
                        Label(session.subject, systemImage: "book.closed").font(.subheadline).foregroundStyle(.secondary)
                    }
                    if FocusConfig.screenTimeEnabled {
                        Label("Op slot: \(session.listName)", systemImage: "lock.fill").font(.subheadline).foregroundStyle(.secondary)
                    }
                    if session.strict {
                        Label("Strikte modus", systemImage: "exclamationmark.shield.fill").font(.subheadline).foregroundStyle(.red)
                    }
                    let attempts = store.attempts
                    if attempts > 0 {
                        Label("\(attempts) keer een geblokkeerde app geprobeerd", systemImage: "hand.raised.fill")
                            .font(.subheadline).foregroundStyle(.orange)
                    }
                }

                if unlocked {
                    Card {
                        Label("Pauze: apps vrij tot \(session.unlockedUntil.formatted(date: .omitted, time: .shortened))",
                              systemImage: "cup.and.saucer.fill")
                    }
                } else if phase.isFocus && !session.strict && store.profile.pauseBank >= 5 {
                    Card(title: "Pauzetegoed: \(store.profile.pauseBank) min") {
                        HStack {
                            ForEach([5, 10], id: \.self) { minutes in
                                if store.profile.pauseBank >= minutes {
                                    Button("\(minutes) min pauze") { store.usePause(minutes: minutes) }
                                        .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }

                Card(title: "Parkeerlijst") {
                    Text("Schiet je iets te binnen? Parkeer het hier en ga door.")
                        .font(.footnote).foregroundStyle(.secondary)
                    HStack {
                        TextField("Bijv. mail docent over deadline", text: $noteText)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit(park)
                        Button(action: park) { Image(systemName: "plus.circle.fill").font(.title2) }
                            .disabled(noteText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    ForEach(store.notes(for: session)) { note in
                        Label(note.text, systemImage: "note.text").font(.subheadline)
                    }
                }

                Button(role: .destructive) {
                    if session.strict { showStrictStop = true } else { confirmStop = true }
                } label: {
                    Text("Stoppen").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)
        }
    }

    private func park() {
        store.park(noteText)
        noteText = ""
    }
}

/// Strikte modus: 30 seconden wachten en een zin overtypen voordat je kunt stoppen.
struct StrictStopView: View {
    let onStop: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var startedAt = Date()
    @State private var typed = ""

    static let sentence = "Ik stop bewust met mijn studieblok"

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let left = max(0, 30 - Int(context.date.timeIntervalSince(startedAt)))
                Form {
                    Section {
                        Text("Weet je het zeker? Wacht even en typ de zin hieronder over.")
                    }
                    Section("Typ over: \"\(Self.sentence)\"") {
                        TextField(Self.sentence, text: $typed)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    Section {
                        Button("Stoppen zonder beloning", role: .destructive) {
                            dismiss()
                            onStop()
                        }
                        .disabled(left > 0 || typed.trimmingCharacters(in: .whitespaces).lowercased() != Self.sentence.lowercased())
                    } footer: {
                        if left > 0 { Text("Nog \(left) seconden wachten.") }
                    }
                }
            }
            .navigationTitle("Stoppen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Doorgaan met studeren") { dismiss() }
                }
            }
        }
    }
}

struct ResultView: View {
    @EnvironmentObject private var store: AppStore
    let result: SessionResult

    var body: some View {
        NavigationStack {
            ScrollScreen {
                VStack(spacing: 8) {
                    Image(systemName: result.completed ? "checkmark.seal.fill" : "xmark.octagon.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(result.completed ? Color.accentColor : .orange)
                    Text(result.completed ? "Blok afgerond!" : "Blok gestopt")
                        .font(.title.bold())
                    Text(result.task).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)

                HStack(spacing: 10) {
                    StatTile(value: "\(result.focusedMinutes)", label: "min gefocust", systemImage: "clock.fill")
                    StatTile(value: "\(result.attempts)", label: "pogingen", systemImage: "hand.raised.fill")
                    StatTile(value: "\(result.streak)", label: "dagen streak", systemImage: "flame.fill")
                }

                if result.completed {
                    Card(title: "Je beloning") {
                        Label("+\(result.reward.xp) XP\(result.attempts == 0 ? " (incl. 20% bonus voor geen pogingen)" : "")",
                              systemImage: "star.fill")
                        Label("+\(result.reward.coins) munten", systemImage: "circle.hexagongrid.fill")
                        if result.reward.freeMinutes > 0 {
                            Label("+\(result.reward.freeMinutes) min pauzetegoed", systemImage: "cup.and.saucer.fill")
                        }
                        if result.levelAfter > result.levelBefore {
                            Label("Level omhoog! Je bent nu level \(result.levelAfter): \(Rewards.levelName(result.levelAfter))",
                                  systemImage: "arrow.up.circle.fill").bold()
                        }
                        if result.usedFreeze { Label("Een streak-freeze heeft je streak gered", systemImage: "snowflake") }
                        if result.earnedFreeze { Label("Je verdiende een streak-freeze", systemImage: "snowflake") }
                    }
                } else {
                    Card {
                        Text("Je bent vroeg gestopt, dus dit blok levert geen beloning op. Volgende keer beter: kies gerust een korter blok.")
                            .font(.subheadline)
                    }
                }

                if !result.newAchievements.isEmpty {
                    Card(title: "Nieuwe prestaties (+\(Rewards.achievementCoins) munten per stuk)") {
                        ForEach(result.newAchievements) { a in
                            Label {
                                VStack(alignment: .leading) {
                                    Text(a.title).bold()
                                    Text(a.detail).font(.caption).foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: a.symbol).foregroundStyle(.yellow)
                            }
                        }
                    }
                }

                Button {
                    store.lastResult = nil
                } label: {
                    Text("Klaar").bold().frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Resultaat")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
