import SwiftUI

struct WellnessView: View {
    @Bindable var viewModel: WellnessViewModel
    @State private var sheet: CheckInSheet?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            List {
                Section {
                    todayCard
                }

                Section {
                    WeeklyWellnessView(summary: viewModel.weekly)
                } header: {
                    Text("Últimos 7 días")
                } footer: {
                    Text("Es un registro personal para conocerte mejor, no un diagnóstico. Si algo te preocupa, habla con un profesional de la salud.")
                }

                if !viewModel.pastHistory.isEmpty {
                    Section("Registros anteriores") {
                        ForEach(viewModel.pastHistory) { checkIn in
                            historyRow(checkIn)
                        }
                    }
                }
            }
            .navigationTitle("Bienestar")
            .sheet(item: $sheet) { sheet in
                CheckInFormView(sheet: sheet) { draft in
                    try viewModel.save(draft, for: sheet.day)
                }
            }
            .alert("Algo salió mal", isPresented: $viewModel.isShowingError) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task {
                viewModel.load()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    viewModel.load()
                }
            }
        }
    }

    @ViewBuilder
    private var todayCard: some View {
        if let checkIn = viewModel.todayCheckIn {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Hoy")
                        .font(.headline)
                    Spacer()
                    Button("Editar") {
                        sheet = CheckInSheet(day: viewModel.today, existing: checkIn, isToday: true)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityIdentifier("wellness.editToday")
                }
                CheckInSummaryView(checkIn: checkIn)
            }
            .padding(.vertical, 4)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("¿Cómo estás hoy?")
                    .font(.headline)
                Text("Registrar tu energía, ánimo y estrés toma unos segundos.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                Button {
                    sheet = CheckInSheet(day: viewModel.today, existing: nil, isToday: true)
                } label: {
                    Label("Registrar", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("wellness.checkIn")
            }
            .padding(.vertical, 4)
        }
    }

    private func historyRow(_ checkIn: WellnessCheckIn) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(WellnessFormat.dayTitle(checkIn.day))
                .font(.subheadline.weight(.semibold))
            Text("Energía \(checkIn.energy) · Ánimo \(checkIn.mood) · Estrés \(checkIn.stress)")
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            sheet = CheckInSheet(day: checkIn.day, existing: checkIn, isToday: false)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.delete(checkIn)
            } label: {
                Label("Borrar", systemImage: "trash")
            }
        }
    }
}

#if DEBUG
#Preview("Con registros") {
    WellnessView(viewModel: WellnessViewModel(repository: PreviewWellnessRepository.sample))
}

#Preview("Vacío") {
    WellnessView(viewModel: WellnessViewModel(repository: PreviewWellnessRepository()))
}
#endif
