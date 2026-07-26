import Foundation

@MainActor
final class RatingFormViewModel: ObservableObject {
    let restaurant: RestaurantSummary
    private let initialDishId: UUID?

    @Published var dishQuery = ""

    // Gericht-Block
    @Published var taste: Double = 0
    @Published var texture: Double = 0
    @Published var appearance: Double = 0
    @Published var smell: Double = 0

    // Restaurant-Block
    @Published var service: Double = 0
    @Published var ambience: Double = 0
    @Published var value: Double = 0
    @Published var waitTime: Double = 0

    @Published private(set) var isSubmitting = false
    @Published private(set) var isDeleting = false
    @Published var errorMessage: String?
    @Published private(set) var didSubmit = false
    @Published private(set) var didDelete = false

    private let dishRepository = DishRepository()
    private let ratingRepository = RatingRepository()

    /// Nur gesetzt, wenn eine eigene Bewertung zu diesem Gericht existiert
    /// (zum Bearbeiten geöffnet) - macht den Löschen-Button sichtbar.
    private(set) var existingDishId: UUID?

    init(restaurant: RestaurantSummary, initialDishName: String? = nil, initialDishId: UUID? = nil) {
        self.restaurant = restaurant
        self.initialDishId = initialDishId
        self.dishQuery = initialDishName ?? ""
    }

    var dishSuggestions: [DishCatalogEntry] {
        Array(DishCatalog.search(dishQuery).prefix(6))
    }

    var isValid: Bool {
        !dishQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && allCategoriesRated
    }

    private var allCategoriesRated: Bool {
        [taste, texture, appearance, smell, service, ambience, value, waitTime].allSatisfy { $0 > 0 }
    }

    /// Lädt die eigene bestehende Bewertung (falls vorhanden) und füllt
    /// die Sterne damit vor, statt blind neu bewerten zu lassen.
    func loadExistingRatingIfNeeded() async {
        guard let dishId = initialDishId else { return }

        do {
            guard let rating = try await ratingRepository.fetchOwn(dishId: dishId) else { return }
            existingDishId = dishId
            taste = rating.taste
            texture = rating.texture
            appearance = rating.appearance
            smell = rating.smell
            service = rating.service
            ambience = rating.ambience
            value = rating.value
            waitTime = rating.waitTime
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func submit() async {
        guard isValid else { return }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let dishName = dishQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            let dish = try await dishRepository.findOrCreate(name: dishName, restaurantId: restaurant.id)
            try await ratingRepository.upsert(
                dishId: dish.id,
                restaurantId: restaurant.id,
                taste: taste,
                texture: texture,
                appearance: appearance,
                smell: smell,
                service: service,
                ambience: ambience,
                value: value,
                waitTime: waitTime
            )
            didSubmit = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteExistingRating() async {
        guard let dishId = existingDishId else { return }

        isDeleting = true
        errorMessage = nil
        defer { isDeleting = false }

        do {
            try await ratingRepository.delete(dishId: dishId)
            didDelete = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
