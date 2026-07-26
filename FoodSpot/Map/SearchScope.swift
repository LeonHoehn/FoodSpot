import Foundation

enum SearchScope: String, CaseIterable, Identifiable {
    case global = "Global"
    case nearby = "Umgebung"

    var id: String { rawValue }
}
