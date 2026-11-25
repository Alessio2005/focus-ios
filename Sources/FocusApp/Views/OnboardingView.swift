import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @State private var page = 0

    private struct Page {
        let symbol: String
        let title: String
        let text: String
    }

    private let pages = [
        Page(symbol: "target", title: "Eén blok, één taak",
             text: "Plan een telefoonvrij studieblok met één concrete taak. Vrij of met Pomodoro-rondes."),
        Page(symbol: "lock.shield.fill", title: "Afleiding op slot",
             text: "Tijdens je blok zet FocusBlok de apps die jou afleiden op slot. Bellen en berichten blijven werken."),
        Page(symbol: "note.text", title: "Parkeer je gedachten",
             text: "Schiet je iets te binnen? Zet het op je parkeerlijst en ga door. Na je blok pak je het op."),
        Page(symbol: "star.fill", title: "Verdien je beloning",
             text: "Verdien XP, munten, pauzetegoed en prestaties. Laat je plant groeien en houd je streak vast."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    VStack(spacing: 18) {
                        if i == 0 {
                            Image("Logo")
                                .resizable().scaledToFit()
                                .frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        } else {
                            Image(systemName: pages[i].symbol)
                                .font(.system(size: 72))
                                .foregroundStyle(.tint)
                        }
                        Text(pages[i].title).font(.title.bold()).multilineTextAlignment(.center)
                        Text(pages[i].text).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    .padding(32)
                    .tag(i)
                }
                permissionPage.tag(pages.count)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if page < pages.count {
                    withAnimation { page += 1 }
                } else {
                    AppStore.requestNotificationPermission()
                    store.updateProfile { $0.onboardingDone = true }
                }
            } label: {
                Text(page < pages.count ? "Volgende" : "Aan de slag")
                    .bold().frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .padding(24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    @ViewBuilder
    private var permissionPage: some View {
        if FocusConfig.screenTimeEnabled {
            screenTimePage
        } else {
            VStack(spacing: 18) {
                Image(systemName: "square.on.square.squareshape.controlhandles").font(.system(size: 64)).foregroundStyle(.tint)
                Text("Blokkeren met Opdrachten").font(.title.bold())
                Text("Deze gratis versie blokkeert met een automatisering in de app Opdrachten: open je tijdens een blok een afleidende app, dan stuurt je iPhone je terug naar FocusBlok. In het tabblad Blokkeren staat hoe je dat in 2 minuten instelt.")
                    .foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            .padding(32)
        }
    }

    private var screenTimePage: some View {
        VStack(spacing: 18) {
            Image(systemName: "hand.raised.fill").font(.system(size: 64)).foregroundStyle(.tint)
            Text("Toestemming").font(.title.bold())
            Text("FocusBlok gebruikt Apple's Schermtijd om apps te blokkeren. Je kiest zelf welke apps. Alles blijft op je telefoon.")
                .foregroundStyle(.secondary).multilineTextAlignment(.center)
            if screenTime.isAuthorized {
                Label("Toestemming gegeven", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
            } else {
                Button("Schermtijd-toegang geven") {
                    Task { await screenTime.requestAuthorization() }
                }
                .buttonStyle(.bordered)
                if let error = screenTime.lastError {
                    Text(error).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center)
                }
                Text("Dit kan ook later via Instellingen.").font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding(32)
    }
}
