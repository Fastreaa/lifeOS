import SwiftUI

/// Anillo de progreso de 0 a 1.
struct ProgressRing: View {
    let progress: Double
    var tint: Color = .lifeAccent
    var lineWidth: CGFloat = 5

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .animation(.easeOut, value: clamped)
        .accessibilityElement()
        .accessibilityLabel(Text("Progreso"))
        .accessibilityValue(Text(clamped, format: .percent.precision(.fractionLength(0))))
    }
}
