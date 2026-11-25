# FocusBlok op je iPhone zetten (zonder Mac)

Alles wat een Mac normaal doet, doet GitHub Actions. Jij hebt alleen een browser, je Windows-pc en je iPhone nodig.

Er zijn twee manieren:

| | Ontwikkel-build | TestFlight |
|---|---|---|
| Voor wie | Jouw eigen iPhone (en tot 100 geregistreerde toestellen) | Isabelle, Ties en testpersonen |
| Extra toestemming van Apple nodig | Nee | Ja: Family Controls (Distribution) |
| Installeren | Via iMazing of 3uTools op Windows | Via de TestFlight-app |
| Geldig | 1 jaar | 90 dagen per build |

## 1. Eenmalig: Apple-account en sleutels

1. **Apple Developer Program** (99 dollar per jaar): meld je aan op https://developer.apple.com/programs/enroll/
   (kan ook in de Apple Developer-app op je iPhone). Goedkeuring duurt meestal 1 tot 2 dagen.
2. **Team ID**: https://developer.apple.com/account > Membership details. Tien tekens, bijvoorbeeld `AB12CD34EF`.
3. **App Store Connect API-sleutel**: https://appstoreconnect.apple.com/access/integrations/api
   - Klik op *Team-sleutel genereren*, naam `GitHub`, toegang **Admin**.
   - Download het `.p8`-bestand. Dat kan maar één keer, bewaar het goed.
   - Noteer de **Key ID** (naast de sleutel) en de **Issuer ID** (boven de lijst).
4. **Secrets in GitHub**: open https://github.com/Alessio2005/focus-ios/settings/secrets/actions en maak met
   *New repository secret* deze vier aan:

   | Naam | Waarde |
   |---|---|
   | `APPLE_TEAM_ID` | je Team ID |
   | `ASC_KEY_ID` | de Key ID |
   | `ASC_ISSUER_ID` | de Issuer ID |
   | `ASC_KEY_P8` | de hele inhoud van het `.p8`-bestand (open het in Kladblok, alles kopiëren, inclusief de BEGIN- en END-regels) |

   Secrets zijn niet zichtbaar voor anderen, ook niet in een openbare repository. Zet de sleutel nooit in een bestand in de repository.

## 2. Ontwikkel-build op je eigen iPhone

1. **UDID van je iPhone**: sluit je iPhone aan op je pc en open [iMazing](https://imazing.com) of [3uTools](https://www.3u.com).
   Het UDID staat bij de toestelgegevens (lange code van 25 of 40 tekens).
2. **Build starten**: ga naar https://github.com/Alessio2005/focus-ios/actions, kies **iPhone-build (ondertekend)** > *Run workflow*.
   Kies `development`, plak je UDID en klik op *Run workflow*. Het UDID hoeft alleen de eerste keer.
3. Na ongeveer 5 minuten staat onderaan de run het artifact **FocusBlok-iPhone**. Download en unzip het.
4. **Installeren**: sleep de `.ipa` in iMazing (*Apps beheren* > *Installeren*) of 3uTools (*Apps* > *IPA installeren*).
5. **Ontwikkelaarsmodus** op je iPhone: *Instellingen > Privacy en beveiliging > Ontwikkelaarsmodus* aan en herstarten.
   Dit staat er pas nadat de app één keer geïnstalleerd is.
6. Open FocusBlok en geef Schermtijd-toestemming. Klaar: apps worden nu echt geblokkeerd.

## 3. TestFlight voor je team en testpersonen

1. **Family Controls (Distribution) aanvragen**: https://developer.apple.com/contact/request/family-controls-distribution
   Vraag het aan voor alle vier de bundle-ID's:
   `nl.focusapp.focus`, `nl.focusapp.focus.ActivityMonitor`, `nl.focusapp.focus.ShieldConfiguration`, `nl.focusapp.focus.ShieldAction`.
   Leg uit dat het een studieproject is om studenten te helpen hun telefoon minder te gebruiken tijdens het studeren.
   Apple beoordeelt dit zelf; dat kan dagen tot weken duren.
2. **App aanmaken** in https://appstoreconnect.apple.com/apps > *+* > *Nieuwe app*: platform iOS, naam FocusBlok,
   bundle-ID `nl.focusapp.focus` (die staat erin na je eerste ontwikkel-build).
3. Start de workflow met `testflight`. De build komt na 10 tot 30 minuten in TestFlight.
4. Voeg testers toe onder *TestFlight* in App Store Connect. Zij installeren de app via de TestFlight-app.

## Als het misgaat

- **"Deze secrets ontbreken"**: stap 1.4 is nog niet (helemaal) gedaan.
- **Bundle-ID al in gebruik**: iemand anders heeft `nl.focusapp.focus` al. Vraag Claude om een andere naam te kiezen
  (die staat in `project.yml` en in de App Group in `Sources/Shared/FocusShared.swift`).
- **TestFlight-upload geweigerd om Family Controls**: de aanvraag uit stap 3.1 is nog niet goedgekeurd.
  De ontwikkel-build werkt intussen wel.
