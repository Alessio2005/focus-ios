# FocusBlok (iOS)

iOS-versie van FocusBlok: blokkeert afleidende apps tijdens telefoonvrije studieblokken en beloont je voor gefocust studeren.
Gemaakt door Alessio, Isabelle en Ties (Saxion Deventer, Design Challenge).

Gebouwd met Swift en SwiftUI op Windows, gecompileerd door GitHub Actions op macOS. Geen Mac nodig.

## Functies

- **Studieblok** met één concrete taak en optioneel vak: vrij (15–180 min) of Pomodoro (focus, pauze, rondes)
- **Blokkeerlijsten** met Apple's appkiezer. Tijdens een focusronde gaan de apps op slot met Apple's systeembrede blokkeerscherm
- **Eigen blokkeerscherm** met je taak en de resterende tijd. Elke tik op het blokkeerscherm telt als poging
- **Parkeerlijst** voor gedachten tijdens je blok
- **Pauzetegoed** (5 of 10 min apps vrij) en **strikte modus** (30 s wachten + zin overtypen, apps niet te verwijderen)
- **Beloningen**: XP en levels met een groeiende plant, streaks met streak-freezes, munten, 14 prestaties, kleurthema's in de winkel
- **Inzicht**: minuten per dag (grafiek), per vak, pogingen en geschiedenis
- **Vaste studietijden** die vanzelf starten (ook als de app dicht is) en **dagelijkse limieten**
- Onboarding, meldingen bij pauze en einde, licht/donker, naam, export (JSON) en alles wissen
- Alles lokaal: geen account, geen internet

## Structuur

```
project.yml                        XcodeGen-configuratie (maakt Focus.xcodeproj)
Sources/FocusApp/                  De app: Domain (regels), Store (opslag, Schermtijd), Views (schermen), Assets (logo)
Sources/ActivityMonitor/           DeviceActivityMonitor: blokkeert en geeft vrij op de achtergrond
Sources/ShieldConfiguration/       Uiterlijk van het blokkeerscherm
Sources/ShieldAction/              Telt pogingen op het blokkeerscherm
Sources/Shared/                    Code die app en extensies delen
.github/workflows/ios-build.yml    Build op GitHub Actions
```

App en extensies delen gegevens via App Group `group.nl.focusapp.focus`.

## Bouwen

Push naar `main` of start de workflow handmatig onder **Actions > Build iOS App > Run workflow**. De workflow
genereert het Xcode-project met XcodeGen, bouwt een simulator-build zonder signing en zet `Focus.app`
klaar als artifact **Focus-iOS-Build**.

## Wat (nog) niet kan

- De simulator-build bewijst dat alles compileert. Echt blokkeren werkt niet in de simulator.
- Voor een echte iPhone is een ondertekende build nodig met de **Family Controls**-capability. Die is niet
  beschikbaar voor een gratis Apple ID; daarvoor is het Apple Developer Program (99 dollar per jaar) nodig.
  Voor TestFlight of de App Store moet je daarnaast het Family Controls (Distribution)-entitlement bij Apple aanvragen.
- iOS laat apps Niet storen niet automatisch aanzetten (dat kan de Android-versie wel). Gebruik een iOS-focusmodus.
- Schermtijd per app tonen in de app vereist een apart DeviceActivityReport-rapport; die zit er nog niet in.
- Bellen en berichten blokkeert iOS nooit; dat is ook de bedoeling.
