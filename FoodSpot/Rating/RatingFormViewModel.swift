import Foundation

@MainActor
final class RatingFormViewModel: ObservableObject {
    let restaurant: RestaurantSummary

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
    @Published var errorMessage: String?
    @Published private(set) var didSubmit = false

    private let dishRepository = DishRepository()
    private let ratingRepository = RatingRepository()

    init(restaurant: RestaurantSummary, initialDishName: String? = nil) {
        self.restaurant = restaurant
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
}
