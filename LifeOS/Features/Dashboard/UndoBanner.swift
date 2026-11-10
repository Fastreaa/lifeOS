import SwiftUI

/// Aviso temporal tras borrar una tarea, con opción de deshacer.
struct UndoBanner: View {
    let taskTitle: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("Borraste «\(taskTitle)»")
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Deshacer", action: onUndo)
                .fontWeight(.semibold)
                .accessibilityIdentifier("dashboard.undoDelete")
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
