# FoodSpot — Setup

Stand: Phase 1 (Supabase-Setup) + Phase 2 (Sign in with Apple) aus `CLAUDE.md`.

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

## Projektstruktur

```
FoodSpot/
  App/            App-Entry-Point, ContentView (Auth-State-Routing)
  Auth/           AuthViewModel, SignInView (Sign in with Apple)
  Core/           SupabaseManager (SupabaseClient-Singleton)
  Models/         Restaurant, Dish, Rating (spiegeln das Supabase-Schema)
  Resources/      Info.plist-Grundwerte, Assets.xcassets
supabase/
  migrations/     SQL-Migrationen
  config.toml     lokale Supabase-CLI-Konfiguration
```

Kartenansicht, Suche und Bewertungs-Flow folgen in Phase 3 ff.
