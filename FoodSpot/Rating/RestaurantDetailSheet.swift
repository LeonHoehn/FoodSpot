import SwiftUI

struct RestaurantDetailSheet: View {
    let restaurant: RestaurantSummary

    @Environment(\.dismiss) private var dismiss
    @State private var isShowingRatingForm = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(restaurant.name)
                        .font(.title2.bold())
                    if let address = restaurant.address {
                        Text(address)
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    isShowingRatingForm = true
                } label: {
                    Label("Gericht bewerten", systemImage: "star.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .sheet(isPresented: $isShowingRatingForm) {
            RatingFormView(restaurant: restaurant)
        }
    }
}
