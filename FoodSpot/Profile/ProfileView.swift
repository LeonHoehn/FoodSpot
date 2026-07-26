import CoreLocation
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @ObservedObject var locationManager: LocationManager
    @StateObject private var viewModel = ProfileViewModel()
    @State private var selectedRestaurant: RestaurantSummary?

    var body: some View {
        List {
            if viewModel.groupedRatings.isEmpty {
                Section("Meine Bewertungen") {
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        Text("Noch keine eigenen Bewertungen.")
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                ForEach(viewModel.groupedRatings) { group in
                    Section(group.dishName) {
                        ForEach(group.entries) { entry in
                            Button {
                                selectedRestaurant = entry.summary
                            } label: {
                                myRatingRow(entry)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Section("Merkliste") {
                if viewModel.bookmarks.isEmpty {
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        Text("Noch keine gemerkten Restaurants.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(viewModel.bookmarks) { bookmark in
                        Button {
                            selectedRestaurant = bookmark.summary
                        } label: {
                            bookmarkRow(bookmark)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Section {
                Button("Abmelden", role: .destructive) {
                    Task { await authViewModel.signOut() }
                }
            }
        }
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .sheet(item: $selectedRestaurant) { restaurant in
            RestaurantDetailSheet(restaurant: restaurant)
                .onDisappear { Task { await viewModel.load() } }
        }
    }

    private func myRatingRow(_ entry: MyRatingRow) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.restaurant.name)
                    .foregroundStyle(.primary)
                if let address = entry.restaurant.address {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                StarRatingDisplayView(value: entry.dishAverage)
                Text(String(format: "%.1f", entry.dishAverage))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func bookmarkRow(_ bookmark: BookmarkedRestaurant) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(bookmark.restaurant.name)
                    .foregroundStyle(.primary)
                if let address = bookmark.restaurant.address {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let distance = distanceText(to: bookmark.summary.coordinate) {
                Text(distance)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func distanceText(to coordinate: CLLocationCoordinate2D) -> String? {
        guard let userLocation = locationManager.currentLocation else { return nil }
        let from = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let to = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let meters = from.distance(from: to)
        if meters < 1000 {
            return "\(Int(meters)) m"
        }
        return String(format: "%.1f km", meters / 1000)
    }
}
