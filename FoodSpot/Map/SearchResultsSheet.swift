import SwiftUI

struct SearchResultsSheet: View {
    @ObservedObject var viewModel: MapViewModel
    @ObservedObject var locationManager: LocationManager
    @State private var selectedRestaurant: RestaurantSummary?

    private static let radiusOptions: [Double] = [1, 2, 5, 10, 25, 50, 100]

    var body: some View {
        List {
            Section {
                searchField
            }

            Section {
                Picker("Suchbereich", selection: $viewModel.searchScope) {
                    ForEach(SearchScope.allCases) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: viewModel.searchScope == .nearby ? 6 : 10, trailing: 16))

                if viewModel.searchScope == .nearby {
                    radiusControl
                }
            }

            Section {
                resultsSectionContent
            }
        }
        .scrollContentBackground(.hidden)
        .onChange(of: viewModel.searchText) {
            performSearch()
        }
        .onChange(of: viewModel.searchScope) {
            performSearch()
        }
        .onChange(of: viewModel.radiusKm) {
            performSearch()
        }
        .onChange(of: locationManager.locationUpdateCount) {
            if viewModel.searchScope == .nearby {
                performSearch()
            }
        }
        .task {
            performSearch()
        }
        .sheet(item: $selectedRestaurant) { restaurant in
            RestaurantDetailSheet(restaurant: restaurant)
        }
    }

    private func performSearch() {
        viewModel.performSearch(
            near: locationManager.currentLocation,
            isAuthorizationDenied: locationManager.isAuthorizationDenied
        )
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Gericht suchen, z. B. Ramen", text: $viewModel.searchText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var radiusControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Umkreis: \(Int(viewModel.radiusKm)) km")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Slider(
                value: Binding(
                    get: {
                        Double(Self.radiusOptions.firstIndex(of: viewModel.radiusKm) ?? 2)
                    },
                    set: { newValue in
                        let index = Int(newValue.rounded())
                        viewModel.radiusKm = Self.radiusOptions[index]
                    }
                ),
                in: 0...Double(Self.radiusOptions.count - 1),
                step: 1
            )
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private var resultsSectionContent: some View {
        if viewModel.isSearching {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .padding(.vertical, 32)
        } else if viewModel.searchResults.isEmpty {
            if viewModel.isSearchActive {
                ContentUnavailableView.search(text: viewModel.searchText)
            } else {
                ContentUnavailableView {
                    Label("Noch keine Bewertungen", systemImage: "fork.knife")
                } description: {
                    Text(
                        viewModel.searchScope == .global
                            ? "Sobald irgendwo Gerichte bewertet wurden, siehst du hier die bestbewerteten."
                            : "Sobald in diesem Umkreis Gerichte bewertet wurden, siehst du hier die bestbewerteten."
                    )
                }
            }
        } else {
            ForEach(viewModel.searchResults) { result in
                Button {
                    selectedRestaurant = result.summary
                } label: {
                    resultRow(result)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func resultRow(_ result: DishSearchResult) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(result.restaurantName)
                    .font(.headline)
                Text(result.dishName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if viewModel.searchScope == .nearby, let distanceMeters = result.distanceMeters {
                    Text(formattedDistance(distanceMeters))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                StarRatingDisplayView(value: result.avgOverall)
                Text(String(format: "%.1f", result.avgOverall))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formattedDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters)) m"
        }
        return String(format: "%.1f km", meters / 1000)
    }
}
