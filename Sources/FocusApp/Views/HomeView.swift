import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @State private var showStart = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let part = hour < 6 ? "Goedenacht" : hour < 12 ? "Goedemorgen" : hour < 18 ? "Goedemiddag" : "Goedenavond"
        let name = store.profile.nickname.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? part : "\(part), \(name)"
    }

    var body: some View {
        NavigationStack {
            ScrollScreen {
                Text(greeting).font(.title2.bold())

                if !screenTime.isAuthorized {
                    Card(title: "Schermtijd-toegang nodig") {
                        Text("FocusBlok heeft toestemming nodig om apps te blokkeren tijdens je studieblok.")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Button("Toestemming geven") {
                            Task { await screenTime.requestAuthorization() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                Card {
                    HStack(spacing: 16) {
                        PlantView(stage: Rewards.plantStage(store.level))
                            .frame(width: 96, height: 120)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Level \(store.level) · \(Rewards.levelName(store.level))").font(.headline)
                            ProgressView(value: Rewards.levelProgress(xp: store.profile.xp))
                            Text("\(store.profile.xp) XP").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                HStack(spacing: 10) {
                    StatTile(value: "\(store.currentStreak)", label: "dagen streak", systemImage: "flame.fill")
                    StatTile(value: "\(store.minutesToday)", label: "min vandaag", systemImage: "clock.fill")
                    StatTile(value: "\(store.profile.coins)", label: "munten", systemImage: "circle.hexagongrid.fill")
                }

                Button {
                    showStart = true
                } label: {
                    Label("Start studieblok", systemImage: "play.fill")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 16))

                Card(title: "Zo werkt het") {
                    Label("Kies één concrete taak voor dit blok.", systemImage: "1.circle.fill")
                    Label("Afleidende apps gaan op slot tot het blok klaar is.", systemImage: "2.circle.fill")
                    Label("Schiet je iets te binnen? Zet het op je parkeerlijst.", systemImage: "3.circle.fill")
                    Label("Klaar? Je krijgt XP, munten en pauzetegoed.", systemImage: "4.circle.fill")
                }
                .font(.subheadline)

                if store.profile.pauseBank > 0 || store.profile.freezes > 0 {
                    Card {
                        if store.profile.pauseBank > 0 {
                            Label("Pauzetegoed: \(store.profile.pauseBank) min", systemImage: "cup.and.saucer.fill")
                        }
                        if store.profile.freezes > 0 {
                            Label("Streak-freezes: \(store.profile.freezes)", systemImage: "snowflake")
                        }
                    }
                    .font(.subheadline)
                }

                if let error = store.lastError {
                    Text(error).font(.footnote).foregroundStyle(.red)
                }
            }
            .navigationTitle("FocusBlok")
            .sheet(isPresented: $showStart) {
                StartSessionView()
            }
        }
    }
}
