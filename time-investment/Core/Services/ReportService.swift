import Foundation

enum ReportService {
    static func weeklyReportMarkdown(records: [TimeRecord], hourlyRate: Double, tone: AdviceTone = .advisor) -> String {
        let summary = ValueCalculator.weeklySummary(for: records, baselineHourlyRate: hourlyRate)
        return """
        # 时间投资周报

        - 总价值：¥\(format(summary.totalValue))
        - 总时长：\(format(summary.totalSeconds / 3600)) 小时
        - ROI：\(format(summary.roi * 100))%

        ## 分类占比
        \(categorySection(summary: summary))

        ## 投资建议
        \(investmentAdvice(summary: summary, tone: tone))
        """
    }

    static func monthlyReportMarkdown(records: [TimeRecord], hourlyRate: Double, tone: AdviceTone = .advisor) -> String {
        let summary = ValueCalculator.weeklySummary(for: records, baselineHourlyRate: hourlyRate)
        return """
        # 时间投资月报

        - 总价值：¥\(format(summary.totalValue))
        - 总时长：\(format(summary.totalSeconds / 3600)) 小时
        - ROI：\(format(summary.roi * 100))%

        ## 分类占比
        \(categorySection(summary: summary))

        ## 投资建议
        \(investmentAdvice(summary: summary, tone: tone))
        """
    }

    private static func categorySection(summary: WeeklySummary) -> String {
        let total = max(1, summary.totalSeconds)
        return RecordCategory.allCases.compactMap { category in
            let seconds = summary.categorySeconds[category, default: 0]
            guard seconds > 0 else { return nil }
            let ratio = seconds / total * 100
            return "- \(category.rawValue)：\(format(ratio))%（\(format(seconds / 3600)) 小时）"
        }.joined(separator: "\n")
    }

    private static func format(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private static func investmentAdvice(summary: WeeklySummary, tone: AdviceTone) -> String {
        var advice: [String] = []
        if summary.roi >= 0.5 {
            advice.append(prefix(tone) + "你的时间投资回报表现优秀，建议保持当前高价值任务配比。")
        } else if summary.roi >= 0 {
            advice.append(prefix(tone) + "当前回报为正，建议把娱乐时段中的 10% 转移到学习或工作任务。")
        } else {
            advice.append(prefix(tone) + "本期 ROI 为负，建议先优化每日前两小时的任务结构，优先高效率分类。")
        }

        let studySeconds = summary.categorySeconds[.study, default: 0]
        let workSeconds = summary.categorySeconds[.work, default: 0]
        let entertainmentSeconds = summary.categorySeconds[.entertainment, default: 0]
        if entertainmentSeconds > (studySeconds + workSeconds) {
            advice.append(prefix(tone) + "娱乐投入高于学习+工作，建议设置娱乐上限并增加可量化产出的任务。")
        }
        if summary.totalSeconds / 3600 < 10 {
            advice.append(prefix(tone) + "有效记录时长较低，建议先稳定记录习惯，再优化 ROI。")
        }
        return advice.joined(separator: "\n")
    }

    private static func prefix(_ tone: AdviceTone) -> String {
        switch tone {
        case .advisor: return "- [投资顾问] "
        case .coach: return "- [教练] "
        case .neutral: return "- "
        }
    }
}
