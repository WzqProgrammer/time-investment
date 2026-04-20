import Foundation
import Combine

@MainActor
final class RecordsViewModel: ObservableObject {
    @Published var records: [TimeRecord] = []
    @Published var selectedCategory: RecordCategory = .work
    @Published var note: String = ""

    private let repository: TimeRecordRepository
    private let settingsProvider: () -> UserSettings
    private let onRecordChanged: () -> Void

    init(
        repository: TimeRecordRepository,
        settingsProvider: @escaping () -> UserSettings,
        onRecordChanged: @escaping () -> Void
    ) {
        self.repository = repository
        self.settingsProvider = settingsProvider
        self.onRecordChanged = onRecordChanged
        self.repository.observeChanges { [weak self] in
            Task { @MainActor in
                self?.reload()
            }
        }
        reload()
    }

    func reload() {
        records = repository.fetchAll()
    }

    func addManualRecord(minutes: Double = 30) {
        let settings = settingsProvider()
        let end = Date()
        let start = end.addingTimeInterval(-minutes * 60)
        let record = TimeRecord(
            id: UUID(),
            startTime: start,
            endTime: end,
            category: selectedCategory,
            appName: nil,
            websiteURL: nil,
            note: note,
            hourlyRateSnapshot: settings.hourlyRate,
            efficiencyScore: settings.efficiency(for: selectedCategory),
            source: "manual"
        )
        repository.save(record)
        note = ""
        reload()
        onRecordChanged()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            repository.delete(id: records[index].id)
        }
        reload()
        onRecordChanged()
    }
}
