import Foundation

struct ExportOptions {
    var includeAppName: Bool = true
    var includeWebsiteURL: Bool = true
    var includeNote: Bool = true
    var includeSource: Bool = true
}

private struct ExportRecordRow: Codable {
    var id: String
    var startTime: String
    var endTime: String
    var durationMinutes: Int
    var category: String
    var hourlyRate: Double
    var efficiency: Double
    var timeValue: Double
    var appName: String?
    var websiteURL: String?
    var note: String?
    var source: String?
}

enum ExportService {
    static func makeCSV(records: [TimeRecord], options: ExportOptions = ExportOptions()) -> String {
        let rows = mapRows(records: records, options: options)
        var headers = ["id", "startTime", "endTime", "durationMinutes", "category", "hourlyRate", "efficiency", "timeValue"]
        if options.includeAppName { headers.append("appName") }
        if options.includeWebsiteURL { headers.append("websiteURL") }
        if options.includeNote { headers.append("note") }
        if options.includeSource { headers.append("source") }

        var lines: [String] = [headers.joined(separator: ",")]
        for row in rows {
            var values: [String] = [
                row.id,
                row.startTime,
                row.endTime,
                "\(row.durationMinutes)",
                row.category,
                "\(row.hourlyRate)",
                "\(row.efficiency)",
                "\(row.timeValue)"
            ]
            if options.includeAppName { values.append(sanitize(row.appName ?? "")) }
            if options.includeWebsiteURL { values.append(sanitize(row.websiteURL ?? "")) }
            if options.includeNote { values.append(sanitize(row.note ?? "")) }
            if options.includeSource { values.append(sanitize(row.source ?? "")) }
            lines.append(values.map { "\"\($0)\"" }.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    static func saveCSVToTemp(records: [TimeRecord], options: ExportOptions = ExportOptions()) throws -> URL {
        let filename = exportFilename(ext: "csv")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try makeCSV(records: records, options: options).write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    static func makeJSON(records: [TimeRecord], options: ExportOptions = ExportOptions()) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(mapRows(records: records, options: options)) else { return "[]" }
        return String(decoding: data, as: UTF8.self)
    }

    static func saveJSONToTemp(records: [TimeRecord], options: ExportOptions = ExportOptions()) throws -> URL {
        let filename = exportFilename(ext: "json")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try makeJSON(records: records, options: options).write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    static func makeMarkdown(
        records: [TimeRecord],
        hourlyRate: Double,
        tone: AdviceTone = .advisor,
        title: String = String(localized: "export.title.default")
    ) -> String {
        var content = ReportService.weeklyReportMarkdown(records: records, hourlyRate: hourlyRate, tone: tone)
        let weeklyTitle = String(localized: "report.title.weekly")
        if title != weeklyTitle {
            content = content.replacingOccurrences(of: weeklyTitle, with: title)
        }
        return content
    }

    static func saveMarkdownToTemp(
        records: [TimeRecord],
        hourlyRate: Double,
        tone: AdviceTone = .advisor,
        title: String = String(localized: "export.title.default")
    ) throws -> URL {
        let filename = exportFilename(ext: "md")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try makeMarkdown(records: records, hourlyRate: hourlyRate, tone: tone, title: title).write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    static func saveReportToTemp(_ report: InvestmentReport) throws -> URL {
        let safeTitle = report.title.replacingOccurrences(of: " ", with: "-")
        let filename = "\(safeTitle)-\(Int(Date().timeIntervalSince1970)).md"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try report.content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func iso(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private static func sanitize(_ value: String) -> String {
        value.replacingOccurrences(of: "\"", with: "\"\"")
    }

    private static func exportFilename(ext: String) -> String {
        "time-investment-export-\(Int(Date().timeIntervalSince1970)).\(ext)"
    }

    private static func mapRows(records: [TimeRecord], options: ExportOptions) -> [ExportRecordRow] {
        records.map { record in
            let value = ValueCalculator.timeValue(
                hourlyRate: record.hourlyRateSnapshot,
                duration: record.duration,
                efficiency: record.efficiencyScore
            )
            return ExportRecordRow(
                id: record.id.uuidString,
                startTime: iso(record.startTime),
                endTime: iso(record.endTime),
                durationMinutes: Int(record.duration / 60),
                category: record.category.rawValue,
                hourlyRate: record.hourlyRateSnapshot,
                efficiency: record.efficiencyScore,
                timeValue: value,
                appName: options.includeAppName ? record.appName : nil,
                websiteURL: options.includeWebsiteURL ? record.websiteURL : nil,
                note: options.includeNote ? record.note : nil,
                source: options.includeSource ? record.source : nil
            )
        }
    }
}
