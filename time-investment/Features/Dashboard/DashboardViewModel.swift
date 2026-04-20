import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var summary = DailySummary(totalSeconds: 0, totalValue: 0, highValueSeconds: 0)
    @Published var roi: Double = 0

    private let repository: TimeRecordRepository

    init(repository: TimeRecordRepository) {
        self.repository = repository
        refresh()
    }

    func refresh() {
        let todayRecords = repository.fetchAll().filter { Calendar.current.isDateInToday($0.startTime) }
        refresh(with: ValueCalculator.dailySummary(for: todayRecords))
    }

    func refresh(with summary: DailySummary) {
        self.summary = summary
        let expectedValue = max(1, summary.totalSeconds / 3600 * 100)
        roi = ValueCalculator.roi(actualValue: summary.totalValue, expectedValue: expectedValue)
    }
}
