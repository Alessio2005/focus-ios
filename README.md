# Focus (iOS)

Native iOS-app (Swift + SwiftUI) die afleidende apps blokkeert met Apple's Screen Time API.
Gebouwd op Windows, gecompileerd door GitHub Actions op macOS. Geen Mac nodig.

## Functies (MVP)

- **Dashboard**: overzicht van actieve limieten, schema's en wat nu geblokkeerd is.
- **Limieten**: apps kiezen via Apple's appkiezer en een dagelijkse limiet instellen. Na de limiet worden de apps tot middernacht geblokkeerd.
- **Schema's**: apps blokkeren op vaste tijden (bijv. ma t/m vr 09:00–17:00, of iedere dag 22:00–08:00). Na afloop wordt de blokkade automatisch opgeheven.
- **Blokkeerscherm**: Apple's systeembrede shield.
- **Instellingen**: toestemming en een knop om alles op te heffen.

## Structuur

```
project.yml                     XcodeGen-configuratie (maakt Focus.xcodeproj)
Sources/FocusApp/               De app (SwiftUI-schermen + ScreenTimeManager)
Sources/ActivityMonitor/        DeviceActivityMonitor-extensie: blokkeert op de achtergrond
Sources/Shared/                 Code die app en extensie delen (regels, opslag, blokkeren)
.github/workflows/ios-build.yml Build op GitHub Actions
```

App en extensie delen de regels via App Group `group.nl.focusapp.focus`.

## Bouwen

Push naar `main` (of start de workflow handmatig onder **Actions**). De workflow:
1. installeert XcodeGen en genereert `Focus.xcodeproj`,
2. bouwt een simulator-build zonder signing,
3. zet `Focus.app` klaar als artifact **Focus-iOS-Build**.

## Beperkingen

- De simulator-build bewijst dat de code compileert. Echte blokkering werkt niet in de simulator.
- Voor een echte iPhone is een ondertekende build nodig met de **Family Controls**-capability.
  Die is niet beschikbaar voor een gratis Apple ID (Personal Team); daarvoor is het
  Apple Developer Program (99 dollar per jaar) nodig. Voor App Store-distributie moet je
  daarnaast het Family Controls (Distribution)-entitlement bij Apple aanvragen.
- iOS vereist dat een schema minstens 15 minuten duurt, en een app kan maximaal ongeveer 20 schema's tegelijk bewaken.
  Een schema met losse weekdagen gebruikt één bewaking per dag.
