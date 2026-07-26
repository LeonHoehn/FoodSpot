import SwiftUI

struct RatingFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: RatingFormViewModel

    init(restaurant: RestaurantSummary) {
        _viewModel = StateObject(wrappedValue: RatingFormViewModel(restaurant: restaurant))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Gericht") {
                    TextField("z. B. Ramen, Döner, Kaiserschmarrn", text: $viewModel.dishQuery)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)

                    ForEach(viewModel.dishSuggestions) { entry in
                        Button(entry.name) {
                            viewModel.dishQuery = entry.name
                        }
                    }
                }

                // Die beiden Bewertungsblöcke bleiben strikt getrennt: nie
                // eine gemeinsame Gesamtzahl, immer eigene Sektion.
                Section {
                    StarRatingView(label: "Geschmack", value: $viewModel.taste)
                    StarRatingView(label: "Textur", value: $viewModel.texture)
                    StarRatingView(label: "Aussehen", value: $viewModel.appearance)
                    StarRatingView(label: "Geruch", value: $viewModel.smell)
                } header: {
                    Text("Bewertung des Gerichts")
                }

                Section {
                    StarRatingView(label: "Service", value: $viewModel.service)
                    StarRatingView(label: "Ambiente", value: $viewModel.ambience)
                    StarRatingView(label: "Preis-Leistung", value: $viewModel.value)
                    StarRatingView(label: "Wartezeit", value: $viewModel.waitTime)
                } header: {
                    Text("Bewertung des Restaurants")
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle(viewModel.restaurant.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        Task {
                            await viewModel.submit()
                            if viewModel.didSubmit {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSubmitting)
                }
            }
            .overlay {
                if viewModel.isSubmitting {
                    ProgressView()
                }
            }
        }
    }
}
