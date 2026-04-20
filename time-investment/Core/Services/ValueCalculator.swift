import Foundation

enum ValueCalculator {
    static func timeValue(hourlyRate: Double, duration: TimeInterval, efficiency: Double) -> Double {
        let hours = duration / 3600
        return hourlyRate * hours * efficiency
    }

    static func roi(actualValue: Double, expectedValue: Double) -> Double {
        guard expectedValue > 0 else { return 0 }
        return (actualValue - expectedValue) / expectedValue
    }

    static func dailySummary(for records: [TimeRecord]) -> DailySummary {
        let totalSeconds = records.reduce(0) { $0 + $1.duration }
        let totalValue = records.reduce(0) {
            $0 + timeValue(
                hourlyRate: $1.hourlyRateSnapshot,
                duration: $1.duration,
                efficiency: $1.efficiencyScore
            )
        }
        let highValueSeconds = records.filter { $0.efficiencyScore > 1 }.reduce(0) { $0 + $1.duration }
        return DailySummary(totalSeconds: totalSeconds, totalValue: totalValue, highValueSeconds: highValueSeconds)
    }

    static func weeklySummary(for records: [TimeRecord], baselineHourlyRate: Double) -> WeeklySummary {
        let daily = dailySummary(for: records)
        let expectedValue = max(1, daily.totalSeconds / 3600 * baselineHourlyRate)
        let weeklyROI = roi(actualValue: daily.totalValue, expectedValue: expectedValue)
        var categorySeconds: [RecordCategory: TimeInterval] = [:]
        for record in records {
            categorySeconds[record.category, default: 0] += record.duration
        }
        return WeeklySummary(
            totalSeconds: daily.totalSeconds,
            totalValue: daily.totalValue,
            roi: weeklyROI,
            categorySeconds: categorySeconds
        )
    }

    static func monthlyTrend(records: [TimeRecord], days: Int = 30) -> [MonthlyTrendPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var points: [MonthlyTrendPoint] = []

        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today),
                  let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else {
                continue
            }
            let dayRecords = records.filter { $0.startTime >= day && $0.startTime < nextDay }
            let summary = dailySummary(for: dayRecords)
            points.append(MonthlyTrendPoint(date: day, totalValue: summary.totalValue, totalSeconds: summary.totalSeconds))
        }
        return points
    }
}
