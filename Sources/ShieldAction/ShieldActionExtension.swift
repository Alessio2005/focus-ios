import Foundation
import ManagedSettings

/// Wordt aangeroepen als iemand op een knop van het blokkeerscherm tikt.
/// We tellen dat als een poging om een geblokkeerde app te openen.
class ShieldActionExtension: ShieldActionDelegate {
    override func handle(action: ShieldAction, for application: ApplicationToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        FocusShared.recordAttempt()
        completionHandler(.close)
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        FocusShared.recordAttempt()
        completionHandler(.close)
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        FocusShared.recordAttempt()
        completionHandler(.close)
    }
}
