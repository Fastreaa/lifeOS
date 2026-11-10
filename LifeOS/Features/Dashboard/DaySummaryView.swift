import SwiftUI

/// Encabezado del dashboard: cuánto hay pendiente y qué toca hoy.
struct DaySummaryView: View {
    let summary: DaySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(headline)
                .font(.headline)
            if !details.isEmpty {
                Text(details.joined(separator: " · "))
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var headline: String {
        switch summary.pendingCount {
        case 0: String(localized: "Todo listo por ahora")
        case 1: String(localized: "1 tarea pendiente")
        default: String(localized: "\(summary.pendingCount) tareas pendientes")
        }
    }

    private var details: [String] {
        var parts: [String] = []
        switch summary.dueTodayCount {
        case 0: break
        case 1: parts.append(String(localized: "1 vence hoy"))
        default: parts.append(String(localized: "\(summary.dueTodayCount) vencen hoy"))
        }
        if summary.estimatedMinutesDueToday > 0 {
            let duration = Duration.seconds(summary.estimatedMinutesDueToday * 60)
                .formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
            parts.append(String(localized: "≈ \(duration) para hoy"))
        }
        if summary.pastDueCount > 0 {
            parts.append(String(localized: "\(summary.pastDueCount) con fecha anterior"))
        }
        return parts
    }
}
