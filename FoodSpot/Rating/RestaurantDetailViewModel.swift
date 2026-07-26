import Foundation

@MainActor
final class RestaurantDetailViewModel: ObservableObject {
    let restaurant: RestaurantSummary

    @Published private(set) var restaurantAverage: RestaurantRatingAverage?
    @Published private(set) var dishAverages: [DishRatingAverage] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    @Published private(set) var isBookmarked = false
    @Published private(set) var isTogglingBookmark = false

    private let repository = RatingsSummaryRepository()
    private let bookmarksRepository = BookmarksRepository()

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
            async let bookmarkTask = bookmarksRepository.isBookmarked(restaurantId: restaurant.id)
            restaurantAverage = try await averageTask
            dishAverages = try await dishesTask
            isBookmarked = try await bookmarkTask
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleBookmark() async {
        isTogglingBookmark = true
        defer { isTogglingBookmark = false }

        do {
            if isBookmarked {
                try await bookmarksRepository.remove(restaurantId: restaurant.id)
                isBookmarked = false
            } else {
                try await bookmarksRepository.add(restaurantId: restaurant.id)
                isBookmarked = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
