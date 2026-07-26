import SwiftUI

struct RestaurantDetailSheet: View {
    let restaurant: RestaurantSummary

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: RestaurantDetailViewModel
    @State private var isShowingRatingForm = false
    @State private var prefillDishName: String?

    init(restaurant: RestaurantSummary) {
        self.restaurant = restaurant
        _viewModel = StateObject(wrappedValue: RestaurantDetailViewModel(restaurant: restaurant))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(restaurant.name)
                            .font(.title2.bold())
                        if let address = restaurant.address {
                            Text(address)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Restaurant") {
                    if let restaurantAverage = viewModel.restaurantAverage {
                        RatingBlockSummaryView(
                            categories: [
                                ("Service", restaurantAverage.avgService),
                                ("Ambiente", restaurantAverage.avgAmbience),
                                ("Preis-Leistung", restaurantAverage.avgValue),
                                ("Wartezeit", restaurantAverage.avgWaitTime),
                            ],
                            overall: restaurantAverage.avgOverall,
                            ratingCount: restaurantAverage.ratingCount
                        )
                    } else if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        Text("Noch keine Restaurant-Bewertung.")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Bewertete Gerichte") {
                    if viewModel.dishAverages.isEmpty {
                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Noch keine bewerteten Gerichte.")
                                .foregroundStyle(.secondary)
                        }
                    }

                    ForEach(viewModel.dishAverages) { dish in
                        DisclosureGroup {
                            RatingBlockSummaryView(
                                categories: [
                                    ("Geschmack", dish.avgTaste),
                                    ("Textur", dish.avgTexture),
                                    ("Aussehen", dish.avgAppearance),
                                    ("Geruch", dish.avgSmell),
                                ],
                                overall: dish.avgOverall,
                                ratingCount: dish.ratingCount
                            )

                            Button {
                                prefillDishName = dish.dishName
                                isShowingRatingForm = true
                            } label: {
                                Label("Erneut bewerten", systemImage: "star.fill")
                            }
                            .buttonStyle(.borderless)
                        } label: {
                            HStack {
                                Text(dish.dishName)
                                    .foregroundStyle(.primary)
                                Spacer()
                                StarRatingDisplayView(value: dish.avgOverall)
                                Text(String(format: "%.1f", dish.avgOverall))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Section {
                    Button {
                        prefillDishName = nil
                        isShowingRatingForm = true
                    } label: {
                        Label("Neues Gericht bewerten", systemImage: "star.fill")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.toggleBookmark() }
                    } label: {
                        Image(systemName: viewModel.isBookmarked ? "bookmark.fill" : "bookmark")
                    }
                    .disabled(viewModel.isTogglingBookmark)
                    .accessibilityLabel(viewModel.isBookmarked ? "Aus Merkliste entfernen" : "Zur Merkliste hinzufügen")
                }
            }
            .task { await viewModel.load() }
        }
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $isShowingRatingForm) {
            RatingFormView(restaurant: restaurant, initialDishName: prefillDishName)
                .onDisappear { Task { await viewModel.load() } }
        }
    }
}
