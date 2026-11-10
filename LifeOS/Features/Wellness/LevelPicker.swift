import SwiftUI

/// Selector de nivel del 1 al 5 con la etiqueta del valor elegido.
struct LevelPicker: View {
    let metric: WellnessMetric
    @Binding var level: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label {
                    Text(metric.title)
                } icon: {
                    Image(systemName: metric.symbolName)
                        .foregroundStyle(Color.accentColor)
                }
                .font(.headline)
                Spacer()
                Text(metric.label(for: level))
                    .foregroundStyle(Color.secondary)
            }

            HStack(spacing: 8) {
                ForEach(WellnessCheckIn.levelRange, id: \.self) { value in
                    levelButton(value)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func levelButton(_ value: Int) -> some View {
        let isSelected = value == level
        return Button {
            level = value
        } label: {
            Text("\(value)")
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(
                    isSelected ? Color.accentColor : Color.secondary.opacity(0.15),
                    in: RoundedRectangle(cornerRadius: 10)
                )
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(metric.label(for: value)))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
