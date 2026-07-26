import SwiftUI

struct RatingFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: RatingFormViewModel
    @State private var isShowingDeleteConfirmation = false

    init(restaurant: RestaurantSummary, initialDishName: String? = nil, initialDishId: UUID? = nil) {
        _viewModel = StateObject(
            wrappedValue: RatingFormViewModel(
                restaurant: restaurant,
                initialDishName: initialDishName,
                initialDishId: initialDishId
            )
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("z. B. Ramen, Döner, Kaiserschmarrn", text: $viewModel.dishQuery)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)

                    ForEach(viewModel.dishSuggestions) { entry in
                        Button(entry.name) {
                            viewModel.dishQuery = entry.name
                        }
                    }
                } header: {
                    Text("Gericht")
                } footer: {
                    Text("Wähle einen Vorschlag oder tippe frei einen Namen ein, falls dein Gericht nicht dabei ist.")
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

                if viewModel.existingDishId != nil {
                    Section {
                        Button("Bewertung löschen", role: .destructive) {
                            isShowingDeleteConfirmation = true
                        }
                        .disabled(viewModel.isDeleting)
                    }
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
                if viewModel.isSubmitting || viewModel.isDeleting {
                    ProgressView()
                }
            }
            .confirmationDialog(
                "Bewertung wirklich löschen?",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Löschen", role: .destructive) {
                    Task {
                        await viewModel.deleteExistingRating()
                        if viewModel.didDelete {
                            dismiss()
                        }
                    }
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Deine Bewertung für „\(viewModel.dishQuery)“ wird endgültig entfernt.")
            }
            .task {
                await viewModel.loadExistingRatingIfNeeded()
            }
        }
    }
}
