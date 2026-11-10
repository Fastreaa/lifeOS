import SwiftUI

/// Resumen visual de un registro: tres indicadores, sueño y nota.
struct CheckInSummaryView: View {
    let checkIn: WellnessCheckIn

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                tile(.energy, level: checkIn.energy)
                tile(.mood, level: checkIn.mood)
                tile(.stress, level: checkIn.stress)
            }
            if let hours = checkIn.sleepHours {
                Label(String(localized: "\(WellnessFormat.hours(hours)) de sueño"), systemImage: "bed.double.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }
            if let note = checkIn.note {
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(3)
            }
        }
    }

    private func tile(_ metric: WellnessMetric, level: Int) -> some View {
        VStack(spacing: 4) {
            Image(systemName: metric.symbolName)
                .foregroundStyle(Color.lifeWellness)
            Text("\(level)/5")
                .font(.headline)
            Text(metric.title)
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(Text(metric.title)): \(Text(metric.label(for: level)))"))
    }
}
