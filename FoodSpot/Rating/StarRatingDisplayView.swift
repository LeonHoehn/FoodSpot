import SwiftUI

/// Read-only Sterne-Reihe für Durchschnittswerte (im Gegensatz zu
/// StarRatingView, das interaktiv fürs Bewerten gedacht ist).
struct StarRatingDisplayView: View {
    let value: Double
    var font: Font = .footnote

    private let starCount = 5

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<starCount, id: \.self) { index in
                Image(systemName: systemName(for: index))
                    .font(font)
                    .foregroundStyle(.orange)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value, specifier: "%.1f") von 5 Sternen")
    }

    private func systemName(for index: Int) -> String {
        let starValue = value - Double(index)
        if starValue >= 1 { return "star.fill" }
        if starValue >= 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }
}

#Preview {
    StarRatingDisplayView(value: 3.5)
        .padding()
}
