import AppIntents
import Foundation

/// Actie voor de app Opdrachten. Geeft "waar" als je nu in een focusronde zit (en je geen pauzetegoed gebruikt).
/// In de gratis versie bouw je hiermee de blokkade: een automatisering
/// "Als Instagram wordt geopend" > Bewaak studieblok > Als resultaat waar is > Open FocusBlok.
struct GuardStudyBlockIntent: AppIntent {
    static var title: LocalizedStringResource = "Bewaak studieblok"
    static var description = IntentDescription(
        "Geeft waar als je in een studieblok zit. Telt dan ook een poging. Gebruik het in een automatisering die FocusBlok opent."
    )
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        guard let session = FocusShared.activeSession(), session.shouldBlock() else {
            return .result(value: false)
        }
        FocusShared.recordAttempt()
        FocusShared.defaults.set(true, forKey: FocusShared.bouncedKey)
        return .result(value: true)
    }
}

struct FocusBlokShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GuardStudyBlockIntent(),
            phrases: ["Bewaak studieblok in \(.applicationName)"],
            shortTitle: "Bewaak studieblok",
            systemImageName: "lock.shield"
        )
    }
}
