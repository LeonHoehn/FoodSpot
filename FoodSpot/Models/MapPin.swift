import CoreLocation
import Foundation

struct MapPin: Identifiable {
    enum Kind {
        /// Öffentlich sichtbar: Restaurant hat mindestens eine Bewertung.
        case rated
        /// Nur für den eigenen Nutzer: auf der Merkliste, aber (noch) nicht
        /// zwingend bewertet.
        case bookmarked
        /// Treffer der Gericht-Suche (Global/Umgebung-Sheet).
        case searchResult
    }

    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
    let kind: Kind
}
