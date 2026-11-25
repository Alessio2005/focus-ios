import Foundation

/// Welke variant van de app dit is.
/// De gratis variant (FocusBlokFree) werkt met een gratis Apple ID: zonder Apple's Schermtijd-API,
/// en blokkeert via een Opdrachten-automatisering die FocusBlok opent als je een afleidende app opent.
enum FocusConfig {
    #if FREE_BUILD
    static let screenTimeEnabled = false
    #else
    static let screenTimeEnabled = true
    #endif
}
