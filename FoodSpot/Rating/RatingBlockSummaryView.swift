import SwiftUI

/// Zeigt einen Bewertungsblock (Gericht ODER Restaurant) mit Gesamt-
/// durchschnitt + Einzelkategorien. Wird nie mit dem jeweils anderen Block
/// in einer gemeinsamen Zahl vermischt.
struct RatingBlockSummaryView: View {
    let categories: [(label: String, value: Double)]
    let overall: Double
    let ratingCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(String(format: "Ø %.1f", overall))
                    .font(.title3.bold())
                StarRatingDisplayView(value: overall, font: .body)
                Spacer()
                Text("\(ratingCount) Bewertung\(ratingCount == 1 ? "" : "en")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(categories, id: \.label) { category in
                HStack {
                    Text(category.label)
                        .font(.subheadline)
                    Spacer()
                    StarRatingDisplayView(value: category.value)
                    Text(String(format: "%.1f", category.value))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
