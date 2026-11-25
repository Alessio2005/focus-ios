import Foundation
import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Het blokkeerscherm dat iOS toont als je een geblokkeerde app opent.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    private let teal = UIColor(red: 0x0F / 255, green: 0x76 / 255, blue: 0x6E / 255, alpha: 1)

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration()
    }

    private func makeConfiguration() -> ShieldConfiguration {
        let title: String
        let subtitle: String

        if let session = FocusShared.activeSession(), session.shouldBlock() {
            let minutes = max(1, Int((session.phase().remaining / 60).rounded(.up)))
            title = "Je zit in een studieblok"
            var lines = ["Taak: \(session.task)", "Nog \(minutes) min tot \(session.plan.isPomodoro ? "je pauze" : "het einde")."]
            if !session.strict { lines.append("Pauzetegoed gebruiken kan in FocusBlok.") }
            subtitle = lines.joined(separator: "\n")
        } else {
            title = "Even niet"
            subtitle = "Deze app is nu geblokkeerd door FocusBlok."
        }

        return ShieldConfiguration(
            backgroundBlurStyle: .systemThickMaterial,
            backgroundColor: teal.withAlphaComponent(0.15),
            icon: UIImage(systemName: "leaf.fill"),
            title: ShieldConfiguration.Label(text: title, color: .label),
            subtitle: ShieldConfiguration.Label(text: subtitle, color: .secondaryLabel),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Terug naar studeren", color: .white),
            primaryButtonBackgroundColor: teal,
            secondaryButtonLabel: nil
        )
    }
}
