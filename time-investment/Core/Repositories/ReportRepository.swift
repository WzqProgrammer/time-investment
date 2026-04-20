import Foundation

protocol ReportRepository {
    func fetchAll() -> [InvestmentReport]
    func save(_ report: InvestmentReport)
    func delete(id: UUID)
}

final class UserDefaultsReportRepository: ReportRepository {
    private let key = "time_investment.reports"
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
    }

    func fetchAll() -> [InvestmentReport] {
        guard let data = defaults.data(forKey: key),
              let reports = try? decoder.decode([InvestmentReport].self, from: data) else {
            return []
        }
        return reports.sorted { $0.createdAt > $1.createdAt }
    }

    func save(_ report: InvestmentReport) {
        var reports = fetchAll()
        reports.insert(report, at: 0)
        persist(reports)
    }

    func delete(id: UUID) {
        var reports = fetchAll()
        reports.removeAll { $0.id == id }
        persist(reports)
    }

    private func persist(_ reports: [InvestmentReport]) {
        guard let data = try? encoder.encode(reports) else { return }
        defaults.set(data, forKey: key)
    }
}
