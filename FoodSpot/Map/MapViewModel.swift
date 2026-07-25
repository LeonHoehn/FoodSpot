import Foundation

@MainActor
final class MapViewModel: ObservableObject {
    @Published private(set) var restaurants: [Restaurant] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let repository = RestaurantRepository()

    func loadRestaurants() async {
        isLoading = true
        defer { isLoading = false }

        do {
            restaurants = try await repository.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
