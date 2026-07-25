# Foodspot App

## Was diese App macht

Eine iOS-App zum Finden von Foodspots. Der zentrale Unterschied zu Google/Yelp:
Bewertungen hängen am **Gericht**, nicht am Restaurant. Sucht ein Nutzer "Carbonara",
sollen die besten Carbonara-Gerichte in der Umgebung angezeigt werden — egal ob sie
bei einem Italiener oder zufällig bei einer Dönerbude serviert werden.

## Kernfunktionen

### Karte
- Zeigt alle Restaurants in der Umgebung als Pins (MapKit)
- Suchleiste oben: Suche nach einem konkreten Gericht (z. B. "Ramen", "Döner",
  "Kaiserschmarrn")
- Ergebnis: Restaurants, die für dieses Gericht Bewertungen haben, sortiert nach
  Durchschnittsbewertung dieses Gerichts
- Radius-Einstellung neben der Suchleiste (in km), filtert die Ergebnisse

### Bewertungssystem — zwei getrennte Bewertungsblöcke

**Bewertung des Gerichts** (0–5 Sterne je Kategorie):
- Geschmack
- Textur
- Aussehen
- Geruch

**Bewertung des Restaurants** (0–5 Sterne je Kategorie):
- Service
- Ambiente
- Preis-Leistung
- Wartezeit

Beide Bewertungen werden **getrennt voneinander angezeigt**, nie vermischt.
Am Ende wird pro Block ein Durchschnitt aus den Einzelkategorien gebildet.

### Restaurantdaten
- Kommen aus Apple MapKit / MapKit Server API (MKLocalSearch, POI-Kategorie
  "Restaurant") — Name, Adresse, Koordinaten
- Beim ersten Treffer wird ein lokaler Eintrag in unserer eigenen DB angelegt
  (nur Referenz-ID + Name + Location), an den Ratings gehängt werden
- Wir pflegen KEINE eigene Restaurant-Datenbank von Grund auf

### Gerichte (Dishes)
- Es gibt keine externe Datenbank für "welches Restaurant hat welches Gericht" —
  das entsteht ausschließlich durch Nutzerbewertungen (Crowdsourcing, ist das
  Kernprodukt)
- Kuratierte Basisliste der ~100–200 gängigsten Gerichte mit Autocomplete beim
  Bewerten (inkl. Synonyme, z. B. Döner/Kebab/Dürüm)
- Freitext-Fallback, falls Gericht nicht in der Liste — wird als neuer Tag
  gespeichert
- Fuzzy-Matching bei der Suche (Postgres `pg_trgm`), damit Tippfehler/Varianten
  trotzdem Treffer liefern

## Tech-Stack

- **Frontend:** Swift + SwiftUI, natives iOS-Design (SF Symbols, Dynamic Type)
- **Karte/Standort:** MapKit, CoreLocation
- **Backend:** Supabase (Postgres + PostGIS für Geo-Radius-Queries, Auth,
  Row-Level-Security)
- **Login:** Sign in with Apple
- **Verteilung:** zunächst TestFlight (Freunde/Beta-Tester), später App Store

## Datenmodell (Kern-Tabellen)

- `restaurants`: id, apple_maps_id, name, lat, lng, address
- `dishes`: id, name/tag, restaurant_id (FK)
- `ratings`: id, user_id, dish_id, restaurant_id,
  taste, texture, appearance, smell (Gericht-Block),
  service, ambience, value, wait_time (Restaurant-Block),
  created_at

Durchschnittswerte pro Gericht und pro Restaurant werden über eine SQL View
oder einen Trigger berechnet, nicht im Client.

## Design-Prinzipien

- Modernes, typisches iOS-Design — an Apple Human Interface Guidelines
  orientieren
- Sterne-Bewertung 0–5, halbe Sterne möglich falls sinnvoll
- Bewertungsblöcke (Gericht vs. Restaurant) visuell klar getrennte Sektionen,
  nie eine gemeinsame Gesamtzahl ohne Kontext

## Entwicklungs-Reihenfolge (bitte in dieser Phasen-Logik vorgehen, nicht alles
auf einmal)

1. Supabase-Setup: Tabellen, PostGIS-Extension, RLS-Policies
2. Auth: Sign in with Apple anbinden
3. Kartenansicht mit Pins aus Supabase
4. Suchleiste + Radius-Filter gegen `dishes`-Tabelle (Geo + Fuzzy-Match)
5. Bewertungs-Flow (zweigeteiltes Formular, 0–5 Sterne je Kategorie)
6. Anzeige der getrennten Durchschnittswerte
7. Feinschliff UI/UX, Lade- und Leerzustände
8. TestFlight-Vorbereitung

## Bekannte offene Fragen / Entscheidungen für später
- Wie viele Bewertungen mindestens nötig, bevor ein Gericht in Suchergebnissen
  auftaucht?
- Umgang mit Duplikaten/Fake-Bewertungen
- Fotos zu Bewertungen erlauben?
