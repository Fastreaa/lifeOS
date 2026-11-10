import SwiftUI

/// Fila de siete botones para elegir días de la semana.
/// Respeta el primer día de la semana del usuario (lunes en España y México).
struct WeekdayPicker: View {
    @Binding var selection: Set<Int>
    var calendar: Calendar = .current

    var body: some View {
        HStack(spacing: 6) {
            ForEach(orderedWeekdays, id: \.self) { weekday in
                dayButton(weekday)
            }
        }
    }

    private var orderedWeekdays: [Int] {
        (0..<7).map { (calendar.firstWeekday - 1 + $0) % 7 + 1 }
    }

    private func dayButton(_ weekday: Int) -> some View {
        let isOn = selection.contains(weekday)
        return Button {
            if isOn {
                selection.remove(weekday)
            } else {
                selection.insert(weekday)
            }
        } label: {
            Text(calendar.veryShortWeekdaySymbols[weekday - 1])
                .font(.subheadline.weight(.semibold))
                .frame(width: 36, height: 36)
                .background(isOn ? Color.accentColor : Color.secondary.opacity(0.15), in: Circle())
                .foregroundStyle(isOn ? Color.white : Color.primary)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(calendar.weekdaySymbols[weekday - 1])
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
