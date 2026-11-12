import Foundation

/// Guarda las preferencias de recordatorios en `UserDefaults`, como JSON.
/// Si el formato guardado no se puede leer, se usan los valores por defecto.
nonisolated final class UserDefaultsReminderSettingsStore: ReminderSettingsStore {
    private let defaults: UserDefaults
    private let key = "lifeos.reminderSettings"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    @MainActor
    func load() -> ReminderSettings {
        guard let data = defaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(ReminderSettings.self, from: data) else {
            return ReminderSettings()
        }
        return settings
    }

    @MainActor
    func save(_ settings: ReminderSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: key)
    }
}

/// Guarda las preferencias solo en memoria. Para pruebas y vistas previas.
nonisolated final class InMemoryReminderSettingsStore: ReminderSettingsStore {
    private var stored: ReminderSettings

    init(settings: ReminderSettings = ReminderSettings()) {
        stored = settings
    }

    @MainActor
    func load() -> ReminderSettings {
        stored
    }

    @MainActor
    func save(_ settings: ReminderSettings) {
        stored = settings
    }
}
