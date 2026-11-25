import SwiftUI

/// Gratis versie: uitleg om afleidende apps te "blokkeren" met een automatisering in Opdrachten.
struct ShortcutsSetupView: View {
    @Environment(\.openURL) private var openURL

    private let steps: [(String, String)] = [
        ("square.on.square", "Open de app **Opdrachten** en tik onderaan op **Automatisering**."),
        ("plus.circle", "Tik op **+** (of **Nieuwe automatisering**) en kies **App**."),
        ("apps.iphone", "Tik op **Kies** en selecteer de apps die je afleiden, zoals Instagram, TikTok en YouTube. Laat **Is geopend** aangevinkt."),
        ("bolt.fill", "Kies **Voer onmiddellijk uit** en zet **Melding bij uitvoeren** uit. Tik op **Volgende**."),
        ("plus.square", "Kies **Nieuwe lege automatisering** en voeg de taak **Bewaak studieblok** (FocusBlok) toe."),
        ("arrow.triangle.branch", "Voeg de taak **Als** toe. Zet de voorwaarde op: **Als Bewaak studieblok is Waar**."),
        ("arrow.uturn.backward.circle", "Zet binnen dat Als-blok de taak **Open app** en kies **FocusBlok**. Tik op **Gereed**."),
    ]

    var body: some View {
        NavigationStack {
            ScrollScreen {
                Card {
                    Label("Zo werkt blokkeren in de gratis versie", systemImage: "info.circle.fill").font(.headline)
                    Text("Apple laat echte app-blokkades alleen toe met een betaald ontwikkelaarsaccount. Daarom gebruikt deze versie een automatisering: open je tijdens een focusronde een afleidende app, dan opent je iPhone meteen FocusBlok. Buiten je blokken gebeurt er niets.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }

                Card(title: "Instellen in 2 minuten") {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.subheadline.bold())
                                .frame(width: 26, height: 26)
                                .background(Color.accentColor.opacity(0.15), in: Circle())
                            Text(.init(step.1)).font(.subheadline)
                        }
                    }
                    Button {
                        if let url = URL(string: "shortcuts://") { openURL(url) }
                    } label: {
                        Label("Open Opdrachten", systemImage: "arrow.up.forward.app")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
                }

                Card(title: "Testen") {
                    Text("Start een kort studieblok en open een van je gekozen apps. Je komt terug in FocusBlok en de poging wordt geteld.")
                        .font(.subheadline)
                    Text("Tijdens pauzes en als je pauzetegoed gebruikt, laat FocusBlok je gewoon door.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Card {
                    Text("Let op: dit is minder streng dan echte Schermtijd-blokkering. Je kunt de automatisering zelf uitzetten. Wil je dat moeilijker maken, zet dan de strikte modus aan bij je blok.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Blokkeren")
        }
    }
}
