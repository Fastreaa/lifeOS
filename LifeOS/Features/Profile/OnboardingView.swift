import SwiftUI

/// Bienvenida de la primera vez: idea de la app, nombre y horario.
struct OnboardingView: View {
    let viewModel: ProfileViewModel

    @State private var draft: ProfileDraft
    @State private var page = 0
    @State private var errorMessage: String?

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        _draft = State(initialValue: ProfileDraft(profile: viewModel.profile))
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $page) {
                welcomePage.tag(0)
                namePage.tag(1)
                hoursPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Ahora no") {
                        viewModel.skipOnboarding()
                    }
                    .accessibilityIdentifier("onboarding.skip")
                }
            }
        }
        .interactiveDismissDisabled()
    }

    // MARK: - Páginas

    private var welcomePage: some View {
        page(
            symbol: "sun.max.fill",
            title: "Te damos la bienvenida a LifeOS",
            subtitle: "Un lugar para organizar tu día de forma realista."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                principle("checklist", "Tareas, agenda, hábitos y bienestar en un solo lugar.")
                principle("cup.and.saucer", "Días realistas, con espacio para descansar.")
                principle("heart", "Sin culpa: los días imperfectos también cuentan.")
                principle("lock.shield", "Tus datos se guardan solo en este iPhone.")
            }
            nextButton(id: "onboarding.next.welcome")
        }
    }

    private var namePage: some View {
        page(
            symbol: "person.crop.circle",
            title: "¿Cómo te llamamos?",
            subtitle: "Lo usaremos para saludarte. Es opcional."
        ) {
            TextField("Tu nombre", text: $draft.name)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.words)
                .accessibilityIdentifier("onboarding.name")
            nextButton(id: "onboarding.next.name")
        }
    }

    private var hoursPage: some View {
        page(
            symbol: "clock",
            title: "¿Cómo es tu día?",
            subtitle: "La agenda calcula tu tiempo libre dentro de este horario. Puedes cambiarlo en Ajustes."
        ) {
            VStack(spacing: 12) {
                DatePicker("Me levanto", selection: $draft.dayStart, displayedComponents: .hourAndMinute)
                DatePicker("Me acuesto", selection: $draft.dayEnd, displayedComponents: .hourAndMinute)
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(Color.red)
            }
            Button(action: finish) {
                Text("Empezar")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("onboarding.finish")
        }
    }

    // MARK: - Piezas

    private func page<Content: View>(
        symbol: String,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: symbol)
                    .font(.system(size: 56))
                    .foregroundStyle(Color.lifeAccent)
                    .padding(.top, 32)
                    .accessibilityHidden(true)
                VStack(spacing: 8) {
                    Text(title)
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    Text(subtitle)
                        .font(.body)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                }
                content()
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 56)
        }
    }

    private func principle(_ symbol: String, _ text: LocalizedStringKey) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(Color.lifeAccent)
                .frame(width: 28)
        }
    }

    private func nextButton(id: String) -> some View {
        Button {
            withAnimation {
                page += 1
            }
        } label: {
            Text("Siguiente")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .accessibilityIdentifier(id)
    }

    private func finish() {
        do {
            try viewModel.completeOnboarding(with: draft)
        } catch let error as ProfileValidationError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = String(localized: "No se pudo guardar. Inténtalo de nuevo.")
        }
    }
}
