import Foundation

enum ReportService {
    static func weeklyReportMarkdown(records: [TimeRecord], hourlyRate: Double, tone: AdviceTone = .advisor) -> String {
        let summary = ValueCalculator.weeklySummary(for: records, baselineHourlyRate: hourlyRate)
        return """
        # \(String(localized: "report.title.weekly"))

        - \(String(localized: "report.metric.totalValue"))：¥\(format(summary.totalValue))
        - \(String(localized: "report.metric.totalHours"))：\(format(summary.totalSeconds / 3600)) \(String(localized: "report.unit.hours"))
        - ROI：\(format(summary.roi * 100))%

        ## \(String(localized: "report.section.category"))
        \(categorySection(summary: summary))

        ## \(String(localized: "report.section.advice"))
        \(investmentAdvice(summary: summary, tone: tone))
        """
    }

    static func monthlyReportMarkdown(records: [TimeRecord], hourlyRate: Double, tone: AdviceTone = .advisor) -> String {
        let summary = ValueCalculator.weeklySummary(for: records, baselineHourlyRate: hourlyRate)
        return """
        # \(String(localized: "report.title.monthly"))

        - \(String(localized: "report.metric.totalValue"))：¥\(format(summary.totalValue))
        - \(String(localized: "report.metric.totalHours"))：\(format(summary.totalSeconds / 3600)) \(String(localized: "report.unit.hours"))
        - ROI：\(format(summary.roi * 100))%

        ## \(String(localized: "report.section.category"))
        \(categorySection(summary: summary))

        ## \(String(localized: "report.section.advice"))
        \(investmentAdvice(summary: summary, tone: tone))
        """
    }

    private static func categorySection(summary: WeeklySummary) -> String {
        let total = max(1, summary.totalSeconds)
        return RecordCategory.allCases.compactMap { category in
            let seconds = summary.categorySeconds[category, default: 0]
            guard seconds > 0 else { return nil }
            let ratio = seconds / total * 100
            return "- \(category.rawValue)：\(format(ratio))%（\(format(seconds / 3600)) \(String(localized: "report.unit.hours") )）"
        }.joined(separator: "\n")
    }

    private static func format(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private static func investmentAdvice(summary: WeeklySummary, tone: AdviceTone) -> String {
        var advice: [String] = []
        if summary.roi >= 0.5 {
            advice.append(prefix(tone) + String(localized: "report.advice.highROI"))
        } else if summary.roi >= 0 {
            advice.append(prefix(tone) + String(localized: "report.advice.positiveROI"))
        } else {
            advice.append(prefix(tone) + String(localized: "report.advice.negativeROI"))
        }

        let studySeconds = summary.categorySeconds[.study, default: 0]
        let workSeconds = summary.categorySeconds[.work, default: 0]
        let entertainmentSeconds = summary.categorySeconds[.entertainment, default: 0]
        if entertainmentSeconds > (studySeconds + workSeconds) {
            advice.append(prefix(tone) + String(localized: "report.advice.entertainmentHeavy"))
        }
        if summary.totalSeconds / 3600 < 10 {
            advice.append(prefix(tone) + String(localized: "report.advice.lowRecordedHours"))
        }
        return advice.joined(separator: "\n")
    }

    private static func prefix(_ tone: AdviceTone) -> String {
        switch tone {
        case .advisor: return String(localized: "report.tonePrefix.advisor")
        case .coach: return String(localized: "report.tonePrefix.coach")
        case .neutral: return String(localized: "report.tonePrefix.neutral")
        }
    }
}
