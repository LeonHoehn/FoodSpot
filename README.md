# FoodSpot — Setup

Stand: Phasen 1–7 aus `CLAUDE.md` sind umgesetzt (Supabase-Setup, Auth,
Karte, Suche, Bewertungs-Flow, Durchschnittswerte, UI-Feinschliff). Dieses
Dokument sammelt die Schritte, die nicht automatisiert werden können, weil
sie Zugriff auf eure Accounts (Apple Developer, App Store Connect,
Supabase) brauchen.

## 1. Xcode-Projekt generieren

Das Projekt wird nicht als `.xcodeproj` versioniert erzeugt, sondern über
[XcodeGen](https://github.com/yonaskolb/XcodeGen) aus `project.yml` generiert.

```bash
brew install xcodegen   # einmalig
xcodegen generate       # erzeugt FoodSpot.xcodeproj
open FoodSpot.xcodeproj
```

Nach jeder Änderung an `project.yml` (neue Targets, Settings, Dependencies)
erneut `xcodegen generate` ausführen.

## 2. Supabase-Projekt

1. Projekt auf [supabase.com](https://supabase.com) anlegen.
2. Supabase CLI installieren und verknüpfen:
   ```bash
   brew install supabase/tap/supabase
   supabase login
   supabase link --project-ref <dein-project-ref>
   ```
3. Migration einspielen (Tabellen, PostGIS, `pg_trgm`, RLS-Policies aus
   `supabase/migrations/20260725000000_init_schema.sql`):
   ```bash
   supabase db push
   ```

## 3. Secrets in Xcode hinterlegen

`Config/Secrets.xcconfig` ist gitignored. Werte aus dem Supabase-Dashboard
(*Project Settings → API*) eintragen:

```
SUPABASE_URL = https:/$()/<project-ref>.supabase.co
SUPABASE_ANON_KEY = <anon-key>
```

Das `$()` zwischen den Slashes ist kein Tippfehler — `.xcconfig`-Dateien
interpretieren `//` sonst als Kommentar.

## 4. Sign in with Apple aktivieren

Das kann nicht automatisiert werden, da es Zugriff auf euren Apple-Developer-
und Supabase-Account erfordert:

1. **Apple Developer Portal**: App-ID mit Bundle-Identifier (Standard hier:
   `com.foodspot.app`, in `project.yml` unter
   `targets.FoodSpot.settings.base.PRODUCT_BUNDLE_IDENTIFIER` anpassbar)
   registrieren und Capability **Sign in with Apple** aktivieren.
2. **Xcode**: In *Signing & Capabilities* das eigene Team auswählen — die
   Capability selbst ist bereits über `project.yml` /
   `FoodSpot.entitlements` gesetzt.
3. **Supabase Dashboard**: *Authentication → Providers → Apple* aktivieren
   und die Bundle-ID unter *Authorized Client IDs* eintragen (nativer
   Sign-in-Flow via `signInWithIdToken`, kein OAuth-Redirect nötig).

## 5. TestFlight-Vorbereitung

Was schon erledigt ist:

- `PrivacyInfo.xcprivacy` deklariert die einzigen selbst erhobenen
  Datentypen (präziser Standort, User-ID via Sign in with Apple), jeweils
  für App-Funktionalität, kein Tracking.
- `ITSAppUsesNonExemptEncryption = false` in der Info.plist, damit beim
  Upload nicht jedes Mal die Export-Compliance-Frage auftaucht (die App
  nutzt nur Standard-HTTPS-Transportverschlüsselung).
- App Icon ist im Asset-Katalog hinterlegt (`AppIcon.appiconset`).

Was noch manuell im Apple-Account passieren muss:

1. **Apple Developer Program**: Mitgliedschaft muss aktiv sein (kostet
   99 $/Jahr), sonst kein TestFlight möglich.
2. **App-ID registrieren** (falls noch nicht durch Schritt 4 oben
   geschehen) mit der finalen Bundle-ID und Capability *Sign in with
   Apple*.
3. **App Store Connect**: neuen App-Eintrag anlegen (gleiche Bundle-ID,
   Name „FoodSpot“ oder Variante falls belegt), Primary Language,
   Kategorie (Food & Drink) setzen.
4. **Privacy Nutrition Labels** in App Store Connect ausfüllen — sollten
   deckungsgleich mit `PrivacyInfo.xcprivacy` sein (Standort + User-ID,
   „nicht zum Tracking verwendet“).
5. **Xcode**: In *Signing & Capabilities* das Team wählen, `Product →
   Archive`, dann im Organizer *Distribute App → TestFlight & App Store*.
6. **TestFlight**: interne Tester (bis zu 100, per Apple-ID-E-Mail,
   brauchen kein Review) sofort einladbar; externe Tester brauchen ein
   kurzes Beta-App-Review durch Apple sowie eine öffentlich erreichbare
   Datenschutzerklärung-URL (dafür gibt es aktuell noch keine — muss
   vor externem Testing gehostet werden).
7. **Versionierung**: `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION` in
   `project.yml` vor jedem neuen Upload hochzählen (App Store Connect
   akzeptiert keine doppelte Build-Nummer pro Version).

## Projektstruktur

```
FoodSpot/
  App/            App-Entry-Point, ContentView (Auth-State-Routing)
  Auth/           AuthViewModel, SignInView (Sign in with Apple)
  Core/           SupabaseManager, Repositories (Restaurant/Dish/Rating/
                  RatingsSummary/DishSearch), LocationManager,
                  RestaurantSearchService (MapKit)
  Data/           DishCatalog (kuratierte Autocomplete-Liste)
  Map/            MapView/-ViewModel (Pins, Suche, Radius-Filter)
  Rating/         Bewertungsformular, Restaurant-Detail-Sheet,
                  Stern-Komponenten
  Search/         AddRestaurantSearchView (MapKit-Restaurantsuche)
  Models/         Restaurant, Dish, Rating, DishSearchResult,
                  RestaurantSummary, Rating-Durchschnitte, MapPin
  Resources/      Info.plist-Grundwerte, PrivacyInfo.xcprivacy,
                  Assets.xcassets
supabase/
  migrations/     SQL-Migrationen (Schema, RLS, Views, Search-RPC)
  config.toml     lokale Supabase-CLI-Konfiguration
```
