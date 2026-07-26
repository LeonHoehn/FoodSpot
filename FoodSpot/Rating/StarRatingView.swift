import SwiftUI

/// 0–5 Sterne, halbe Schritte per Tap/Drag über die Sternreihe.
struct StarRatingView: View {
    let label: String
    @Binding var value: Double

    private let starCount = 5
    private let starsWidth: CGFloat = 130
    private let starsHeight: CGFloat = 24

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            starsControl
            Text(value == 0 ? "–" : String(format: "%.1f", value))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 30, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value == 0 ? "keine Bewertung" : "\(value) von 5 Sternen")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(value + 0.5, Double(starCount))
            case .decrement: value = max(value - 0.5, 0)
            default: break
            }
        }
    }

    private var starsControl: some View {
        GeometryReader { geometry in
            HStack(spacing: 4) {
                ForEach(0..<starCount, id: \.self) { index in
                    starImage(for: index)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        updateValue(x: drag.location.x, width: geometry.size.width)
                    }
            )
        }
        .frame(width: starsWidth, height: starsHeight)
    }

    private func starImage(for index: Int) -> some View {
        let starValue = value - Double(index)
        let systemName: String
        if starValue >= 1 {
            systemName = "star.fill"
        } else if starValue >= 0.5 {
            systemName = "star.leadinghalf.filled"
        } else {
            systemName = "star"
        }
        return Image(systemName: systemName)
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity)
    }

    private func updateValue(x: CGFloat, width: CGFloat) {
        guard width > 0 else { return }
        let starWidth = width / CGFloat(starCount)
        let rawValue = Double(x / starWidth)
        let stepped = (rawValue * 2).rounded() / 2
        value = min(max(stepped, 0), Double(starCount))
    }
}

#Preview {
    @Previewable @State var value: Double = 3.5
    return StarRatingView(label: "Geschmack", value: $value)
        .padding()
}
