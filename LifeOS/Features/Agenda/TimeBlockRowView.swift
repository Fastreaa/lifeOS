import SwiftUI

struct TimeBlockRowView: View {
    let block: TimeBlock
    let hasConflict: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(AgendaFormat.time(block.startMinute, on: block.day))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                Text(AgendaFormat.time(block.endMinute, on: block.day))
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .monospacedDigit()
            }
            .frame(minWidth: 56, alignment: .trailing)

            RoundedRectangle(cornerRadius: 2)
                .fill(block.kind.color)
                .frame(width: 4, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(block.title)
                Label {
                    Text("\(Text(block.kind.label)) · \(AgendaFormat.duration(block.durationMinutes))")
                } icon: {
                    Image(systemName: block.kind.symbolName)
                }
                .font(.caption)
                .foregroundStyle(Color.secondary)
            }

            Spacer(minLength: 0)

            if hasConflict {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.orange)
                    .accessibilityLabel("Se solapa con otro bloque")
            }
        }
        .padding(.vertical, 2)
    }
}
