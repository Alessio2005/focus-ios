import SwiftUI

struct RewardsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            ScrollScreen {
                Card {
                    HStack(spacing: 16) {
                        PlantView(stage: Rewards.plantStage(store.level)).frame(width: 80, height: 100)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Level \(store.level) · \(Rewards.levelName(store.level))").font(.headline)
                            ProgressView(value: Rewards.levelProgress(xp: store.profile.xp))
                            Text("Nog \(Rewards.xpForLevel(store.level + 1) - store.profile.xp) XP tot level \(store.level + 1)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                HStack(spacing: 10) {
                    StatTile(value: "\(store.profile.coins)", label: "munten", systemImage: "circle.hexagongrid.fill")
                    StatTile(value: "\(store.currentStreak)", label: "streak", systemImage: "flame.fill")
                    StatTile(value: "\(store.profile.freezes)", label: "freezes", systemImage: "snowflake")
                }

                Card(title: "Zo verdien je") {
                    Text("• 1 XP per gefocuste minuut, +20% als je geen geblokkeerde app probeert")
                    Text("• 1 munt per 10 minuten, +\(Rewards.achievementCoins) per prestatie")
                    Text("• 10 minuten pauzetegoed per 50 minuten. Gebruik het tijdens een blok (niet in strikte modus)")
                    Text("• Elke 7 dagen streak een streak-freeze (max \(Streaks.maxFreezes)): die redt je streak als je één dag mist")
                    Text("Je pauzetegoed: \(store.profile.pauseBank) min").bold().padding(.top, 4)
                }
                .font(.subheadline)

                Card(title: "Prestaties (\(store.profile.achievements.count)/\(Achievement.allCases.count))") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                        ForEach(Achievement.allCases) { a in
                            let unlocked = store.profile.achievements.contains(a.rawValue)
                            VStack(spacing: 4) {
                                Image(systemName: a.symbol)
                                    .font(.title2)
                                    .foregroundStyle(unlocked ? Color.yellow : Color.secondary.opacity(0.4))
                                Text(a.title).font(.caption.bold()).multilineTextAlignment(.center)
                                Text(a.detail).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .padding(8)
                            .background(Color.accentColor.opacity(unlocked ? 0.14 : 0.04),
                                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .opacity(unlocked ? 1 : 0.7)
                        }
                    }
                }

                Card(title: "Winkel: kleurthema's") {
                    ForEach(AppTheme.all) { theme in
                        let owned = store.profile.ownedThemes.contains(theme.id)
                        HStack {
                            Circle().fill(theme.color).frame(width: 28, height: 28)
                            Text(theme.name)
                            Spacer()
                            if store.profile.themeID == theme.id {
                                Text("In gebruik").font(.subheadline).foregroundStyle(.secondary)
                            } else if owned {
                                Button("Gebruik") { store.updateProfile { $0.themeID = theme.id } }
                                    .buttonStyle(.bordered)
                            } else {
                                Button("\(theme.price) munten") { store.buy(theme) }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(store.profile.coins < theme.price)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Beloningen")
        }
    }
}
