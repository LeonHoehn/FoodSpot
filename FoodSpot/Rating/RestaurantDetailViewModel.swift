import Foundation

@MainActor
final class RestaurantDetailViewModel: ObservableObject {
    let restaurant: RestaurantSummary

    @Published private(set) var restaurantAverage: RestaurantRatingAverage?
    @Published private(set) var dishAverages: [DishRatingAverage] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let repository = RatingsSummaryRepository()

    init(restaurant: RestaurantSummary) {
        self.restaurant = restaurant
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let averageTask = repository.fetchRestaurantAverage(restaurantId: restaurant.id)
            async let dishesTask = repository.fetchDishAverages(restaurantId: restaurant.id)
            restaurantAverage = try await averageTask
            dishAverages = try await dishesTask
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
