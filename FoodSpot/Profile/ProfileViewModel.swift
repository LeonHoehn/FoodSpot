import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    struct DishTypeGroup: Identifiable {
        let dishName: String
        let entries: [MyRatingRow]
        var id: String { dishName }
    }

    @Published private(set) var groupedRatings: [DishTypeGroup] = []
    @Published private(set) var bookmarks: [BookmarkedRestaurant] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let ratingsSummaryRepository = RatingsSummaryRepository()
    private let bookmarksRepository = BookmarksRepository()

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let ratingsTask = ratingsSummaryRepository.fetchMyRatings()
            async let bookmarksTask = bookmarksRepository.fetchAll()

            let ratings = try await ratingsTask
            bookmarks = try await bookmarksTask

            groupedRatings = Dictionary(grouping: ratings, by: { $0.dish.name })
                .map { dishName, entries in
                    DishTypeGroup(dishName: dishName, entries: entries.sorted { $0.dishAverage > $1.dishAverage })
                }
                .sorted { ($0.entries.first?.dishAverage ?? 0) > ($1.entries.first?.dishAverage ?? 0) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
