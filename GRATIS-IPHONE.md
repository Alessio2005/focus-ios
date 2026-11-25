# FocusBlok gratis op je eigen iPhone (Windows, gratis Apple ID)

Zonder betaald Apple-account kun je FocusBlok toch op je eigen iPhone zetten. Je hebt nodig:
een Windows-pc, een USB-kabel, je iPhone en je gewone (gratis) Apple ID.

## Wat werkt er wel en niet?

| Werkt | Werkt niet (vereist betaald account) |
|---|---|
| Studieblokken met taak, Pomodoro, timer en meldingen | Echte Schermtijd-blokkade van apps |
| Parkeerlijst, pauzetegoed, strikte modus | Eigen blokkeerscherm van iOS |
| XP, levels, plant, streaks, munten, prestaties, thema's | Dagelijkse limieten en vaste studietijden op de achtergrond |
| Inzicht, geschiedenis, export, credits | |
| **Blokkeren via Opdrachten**: open je tijdens een focusronde een afleidende app, dan opent je iPhone FocusBlok | |

Met een gratis Apple ID moet je de app **elke 7 dagen opnieuw ondertekenen** (Sideloadly doet dat in een paar klikken).

## 1. De .ipa downloaden

1. Ga naar https://github.com/Alessio2005/focus-ios/actions en open de nieuwste groene run van **Build iOS App**.
2. Download onderaan het artifact **FocusBlok-gratis-ipa** en pak het zip-bestand uit. Je krijgt `FocusBlok-gratis.ipa`.

## 2. Sideloadly installeren (Windows)

1. Installeer **iTunes** en **iCloud** van de website van Apple (niet de Microsoft Store-versie):
   https://support.apple.com/nl-nl/106372 (iTunes) en https://support.apple.com/nl-nl/103232 (iCloud).
2. Installeer **Sideloadly**: https://sideloadly.io

## 3. FocusBlok op je iPhone zetten

1. Sluit je iPhone met de kabel aan en tik op de iPhone op **Vertrouw**.
2. Open Sideloadly, sleep `FocusBlok-gratis.ipa` in het venster.
3. Vul bij **Apple ID** je eigen Apple ID in en klik op **Start**. Sideloadly vraagt je wachtwoord en eventueel een code; die vul je zelf in.
4. Op je iPhone: **Instellingen > Algemeen > VPN en apparaatbeheer**, tik op je Apple ID en kies **Vertrouw**.
5. iOS 16 of nieuwer: **Instellingen > Privacy en beveiliging > Ontwikkelaarsmodus** aanzetten en de iPhone herstarten.
6. Open FocusBlok.

## 4. Blokkeren instellen met Opdrachten

In de app staat dit ook, in het tabblad **Blokkeren**:

1. Open **Opdrachten** > **Automatisering** > **+** > **App**.
2. Kies je afleidende apps (bijv. Instagram, TikTok, YouTube), laat **Is geopend** aan.
3. Kies **Voer onmiddellijk uit**, zet **Melding bij uitvoeren** uit, tik **Volgende**.
4. **Nieuwe lege automatisering** > voeg **Bewaak studieblok** (FocusBlok) toe.
5. Voeg **Als** toe: **Als Bewaak studieblok is Waar**.
6. Zet daarin **Open app** > **FocusBlok**. Tik **Gereed**.

Open je nu tijdens een focusronde Instagram, dan kom je meteen terug in FocusBlok en telt de poging mee.
Tijdens pauzes en met pauzetegoed laat FocusBlok je door.

## Elke 7 dagen

Sluit je iPhone aan en klik in Sideloadly opnieuw op **Start** met hetzelfde bestand. Je gegevens blijven bewaard.
