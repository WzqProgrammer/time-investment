import Foundation

protocol SettingsStore {
    func load() -> UserSettings
    func save(_ settings: UserSettings)
}

final class UserDefaultsSettingsStore: SettingsStore {
    private let key = "time_investment.user_settings"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> UserSettings {
        guard let data = defaults.data(forKey: key) else { return UserSettings() }
        return (try? decoder.decode(UserSettings.self, from: data)) ?? UserSettings()
    }

    func save(_ settings: UserSettings) {
        guard let data = try? encoder.encode(settings) else { return }
        defaults.set(data, forKey: key)
    }
}
