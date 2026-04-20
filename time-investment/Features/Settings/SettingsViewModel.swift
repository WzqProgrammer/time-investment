import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var settings: UserSettings
    private let onSave: (UserSettings) -> Void

    init(settings: UserSettings, onSave: @escaping (UserSettings) -> Void) {
        self.settings = settings
        self.onSave = onSave
    }

    func save() {
        onSave(settings)
    }

    func efficiencyBindingValue(for category: RecordCategory) -> Double {
        settings.efficiency(for: category)
    }

    func setEfficiency(_ value: Double, for category: RecordCategory) {
        settings.setEfficiency(value, for: category)
    }
}
