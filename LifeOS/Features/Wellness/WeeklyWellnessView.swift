import Charts
import SwiftUI

/// Promedios y gráfico de los últimos 7 días.
struct WeeklyWellnessView: View {
    let summary: WeeklyWellnessSummary
    var calendar: Calendar = .current

    var body: some View {
        if summary.loggedDays == 0 {
            Text("Cuando registres algunos días, aquí verás cómo van tu energía, tu ánimo y tu estrés.")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                .padding(.vertical, 4)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text(averagesText)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)

                Chart(chartPoints) { point in
                    LineMark(
                        x: .value("Día", point.date, unit: .day),
                        y: .value("Nivel", point.value)
                    )
                    .foregroundStyle(by: .value("Medida", point.series))
                    .symbol(by: .value("Medida", point.series))
                }
                .chartYScale(domain: 1...5)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                    }
                }
                .frame(height: 170)
                .accessibilityLabel(Text("Gráfico de energía, ánimo y estrés de los últimos 7 días"))
            }
            .padding(.vertical, 4)
        }
    }

    private var averagesText: String {
        var parts: [String] = []
        if let energy = summary.averageEnergy {
            parts.append(String(localized: "Energía \(WellnessFormat.average(energy))"))
        }
        if let mood = summary.averageMood {
            parts.append(String(localized: "Ánimo \(WellnessFormat.average(mood))"))
        }
        if let stress = summary.averageStress {
            parts.append(String(localized: "Estrés \(WellnessFormat.average(stress))"))
        }
        if let sleep = summary.averageSleepHours {
            parts.append(String(localized: "Sueño \(WellnessFormat.hours(sleep))"))
        }
        parts.append(String(localized: "\(summary.loggedDays) de 7 días registrados"))
        return parts.joined(separator: " · ")
    }

    private struct ChartPoint: Identifiable {
        let id: String
        let date: Date
        let value: Int
        let series: String
    }

    private var chartPoints: [ChartPoint] {
        summary.points.flatMap { point -> [ChartPoint] in
            guard let checkIn = point.checkIn,
                  let date = point.day.middayDate(in: calendar) else { return [] }
            let energy = String(localized: "Energía")
            let mood = String(localized: "Ánimo")
            let stress = String(localized: "Estrés")
            return [
                ChartPoint(id: "\(point.id)-e", date: date, value: checkIn.energy, series: energy),
                ChartPoint(id: "\(point.id)-m", date: date, value: checkIn.mood, series: mood),
                ChartPoint(id: "\(point.id)-s", date: date, value: checkIn.stress, series: stress),
            ]
        }
    }
}
