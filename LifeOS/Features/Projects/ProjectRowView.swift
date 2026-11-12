import SwiftUI

struct ProjectRowView: View {
    let project: Project
    let progress: ProjectProgress

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: project.symbolName)
                .font(.title3)
                .foregroundStyle(project.color.color)
                .frame(width: 40, height: 40)
                .background(project.color.color.opacity(0.15), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(project.name)
                Text(ProjectFormat.summary(progress))
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }

            Spacer(minLength: 0)

            if progress.totalCount > 0 {
                ProgressRing(progress: progress.fraction, tint: project.color.color, lineWidth: 4)
                    .frame(width: 26, height: 26)
            }
        }
        .padding(.vertical, 2)
    }
}

enum ProjectFormat {
    static func summary(_ progress: ProjectProgress) -> String {
        guard progress.totalCount > 0 else {
            return String(localized: "Sin tareas todavía")
        }
        var parts = [
            progress.pendingCount == 1
                ? String(localized: "1 pendiente")
                : String(localized: "\(progress.pendingCount) pendientes"),
            progress.completedCount == 1
                ? String(localized: "1 hecha")
                : String(localized: "\(progress.completedCount) hechas"),
        ]
        if progress.pendingMinutes > 0 {
            parts.append(String(localized: "≈ \(AgendaFormat.duration(progress.pendingMinutes))"))
        }
        return parts.joined(separator: " · ")
    }
}
