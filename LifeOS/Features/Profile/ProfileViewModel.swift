import Foundation
import Observation

/// Perfil del usuario y control de la bienvenida inicial.
@Observable
final class ProfileViewModel {
    private(set) var profile: UserProfile
    /// Enlazado a la pantalla de bienvenida (`fullScreenCover`).
    var isShowingOnboarding = false
    private(set) var errorMessage: String?

    private let repository: any ProfileRepository
    private let calendar: Calendar
    private let now: () -> Date
    /// En las pruebas de interfaz la bienvenida no se muestra (salvo que se pida).
    private let suppressesOnboarding: Bool

    init(
        repository: any ProfileRepository,
        suppressesOnboarding: Bool = false,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() }
    ) {
        self.profile = .makeDefault(now: now())
        self.repository = repository
        self.suppressesOnboarding = suppressesOnboarding
        self.calendar = calendar
        self.now = now
    }

    /// Ver D-013.
    nonisolated deinit {}

    var displayName: String? { profile.displayName }

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    // MARK: - Acciones

    func load() {
        do {
            if let stored = try repository.loadProfile() {
                profile = stored
            }
            isShowingOnboarding = !suppressesOnboarding && !profile.hasCompletedOnboarding
        } catch {
            errorMessage = String(localized: "No se pudo cargar tu perfil.")
        }
    }

    /// Guarda los cambios hechos en Ajustes.
    func save(_ draft: ProfileDraft) throws {
        var updated = profile
        try apply(draft, to: &updated)
        try repository.save(updated)
        profile = updated
    }

    /// Termina la bienvenida guardando lo que el usuario eligió.
    func completeOnboarding(with draft: ProfileDraft) throws {
        var updated = profile
        try apply(draft, to: &updated)
        updated.markOnboardingCompleted(at: now())
        try repository.save(updated)
        profile = updated
        isShowingOnboarding = false
    }

    /// "Ahora no": usa los valores por defecto y no vuelve a mostrar la bienvenida.
    func skipOnboarding() {
        var updated = profile
        updated.markOnboardingCompleted(at: now())
        do {
            try repository.save(updated)
            profile = updated
        } catch {
            errorMessage = String(localized: "No se pudo guardar tu perfil.")
        }
        isShowingOnboarding = false
    }

    // MARK: - Privado

    private func apply(_ draft: ProfileDraft, to profile: inout UserProfile) throws {
        let start = MinuteOfDay.from(draft.dayStart, calendar: calendar)
        let end = MinuteOfDay.from(draft.dayEnd, calendar: calendar)
        try profile.update(
            displayName: draft.name,
            dayStartMinute: start,
            // Elegir 00:00 para acostarse significa "a medianoche".
            dayEndMinute: end == 0 ? MinuteOfDay.endOfDay : end,
            now: now()
        )
    }
}
