//
//  time_investmentTests.swift
//  time-investmentTests
//
//  Created by wangzhengqing on 2026/4/20.
//

import Testing
@testable import time_investment
import Foundation

struct time_investmentTests {

    @Test func timeValueCalculation() async throws {
        let value = ValueCalculator.timeValue(hourlyRate: 120, duration: 1800, efficiency: 1.2)
        #expect(abs(value - 72) < 0.001)
    }

    @Test func roiCalculation() async throws {
        let roi = ValueCalculator.roi(actualValue: 180, expectedValue: 120)
        #expect(abs(roi - 0.5) < 0.0001)
    }

    @Test func dailySummaryCalculation() async throws {
        let now = Date()
        let records = [
            TimeRecord(
                id: UUID(),
                startTime: now.addingTimeInterval(-3600),
                endTime: now,
                category: .study,
                appName: nil,
                websiteURL: nil,
                note: "",
                hourlyRateSnapshot: 100,
                efficiencyScore: 1.2,
                source: "manual"
            ),
            TimeRecord(
                id: UUID(),
                startTime: now.addingTimeInterval(-1800),
                endTime: now,
                category: .entertainment,
                appName: nil,
                websiteURL: nil,
                note: "",
                hourlyRateSnapshot: 100,
                efficiencyScore: 0.5,
                source: "manual"
            )
        ]
        let summary = ValueCalculator.dailySummary(for: records)
        #expect(abs(summary.totalSeconds - 5400) < 0.001)
        #expect(abs(summary.totalValue - 145) < 0.001)
    }

    @Test func coreDataRepositoryCRUD() async throws {
        let repository = CoreDataTimeRecordRepository(inMemory: true)
        let start = Date().addingTimeInterval(-600)
        let record = TimeRecord(
            id: UUID(),
            startTime: start,
            endTime: Date(),
            category: .work,
            appName: "Xcode",
            websiteURL: nil,
            note: "test",
            hourlyRateSnapshot: 100,
            efficiencyScore: 1.0,
            source: "manual"
        )

        repository.save(record)
        var all = repository.fetchAll()
        #expect(all.count == 1)
        #expect(all.first?.note == "test")

        var updated = record
        updated.note = "updated"
        repository.update(updated)
        all = repository.fetchAll()
        #expect(all.first?.note == "updated")

        repository.delete(id: record.id)
        all = repository.fetchAll()
        #expect(all.isEmpty)
    }

    @Test func repositoryObserveChangesTriggered() async throws {
        let repository = CoreDataTimeRecordRepository(inMemory: true)
        var triggerCount = 0
        repository.observeChanges {
            triggerCount += 1
        }

        let record = TimeRecord(
            id: UUID(),
            startTime: Date().addingTimeInterval(-300),
            endTime: Date(),
            category: .study,
            appName: nil,
            websiteURL: nil,
            note: "observe",
            hourlyRateSnapshot: 100,
            efficiencyScore: 1.2,
            source: "manual"
        )
        repository.save(record)
        #expect(triggerCount >= 1)
    }

    @Test func weeklySummaryCalculation() async throws {
        let now = Date()
        let records = [
            TimeRecord(
                id: UUID(),
                startTime: now.addingTimeInterval(-7200),
                endTime: now.addingTimeInterval(-3600),
                category: .work,
                appName: nil,
                websiteURL: nil,
                note: "",
                hourlyRateSnapshot: 100,
                efficiencyScore: 1.0,
                source: "manual"
            ),
            TimeRecord(
                id: UUID(),
                startTime: now.addingTimeInterval(-1800),
                endTime: now,
                category: .study,
                appName: nil,
                websiteURL: nil,
                note: "",
                hourlyRateSnapshot: 100,
                efficiencyScore: 1.2,
                source: "manual"
            )
        ]

        let summary = ValueCalculator.weeklySummary(for: records, baselineHourlyRate: 100)
        #expect(abs(summary.totalSeconds - 5400) < 0.001)
        #expect(summary.categorySeconds[.work] != nil)
        #expect(summary.categorySeconds[.study] != nil)
    }

    @Test func exportJSONAndMarkdown() async throws {
        let now = Date()
        let records = [
            TimeRecord(
                id: UUID(),
                startTime: now.addingTimeInterval(-1200),
                endTime: now,
                category: .work,
                appName: "Xcode",
                websiteURL: nil,
                note: "coding",
                hourlyRateSnapshot: 100,
                efficiencyScore: 1.0,
                source: "manual"
            )
        ]

        let json = ExportService.makeJSON(records: records)
        #expect(json.contains("\"category\""))

        let markdown = ExportService.makeMarkdown(records: records, hourlyRate: 100)
        #expect(markdown.contains("时间投资周报"))
    }

    @Test func exportOptionsExcludeFields() async throws {
        let now = Date()
        let records = [
            TimeRecord(
                id: UUID(),
                startTime: now.addingTimeInterval(-600),
                endTime: now,
                category: .study,
                appName: "Safari",
                websiteURL: "https://example.com",
                note: "note",
                hourlyRateSnapshot: 100,
                efficiencyScore: 1.2,
                source: "auto"
            )
        ]
        let options = ExportOptions(
            includeAppName: false,
            includeWebsiteURL: false,
            includeNote: false,
            includeSource: false
        )
        let csv = ExportService.makeCSV(records: records, options: options)
        #expect(!csv.contains("appName"))
        #expect(!csv.contains("websiteURL"))
        #expect(!csv.contains("note"))
        #expect(!csv.contains("source"))
    }

    @Test func reportContainsAdvice() async throws {
        let now = Date()
        let records = [
            TimeRecord(
                id: UUID(),
                startTime: now.addingTimeInterval(-3600),
                endTime: now,
                category: .entertainment,
                appName: nil,
                websiteURL: nil,
                note: "",
                hourlyRateSnapshot: 100,
                efficiencyScore: 0.5,
                source: "manual"
            )
        ]
        let report = ReportService.weeklyReportMarkdown(records: records, hourlyRate: 100, tone: .coach)
        #expect(report.contains("投资建议"))
        #expect(report.contains("[教练]"))
    }

    @Test func monthlyTrendHasRequestedDays() async throws {
        let now = Date()
        let records = [
            TimeRecord(
                id: UUID(),
                startTime: now.addingTimeInterval(-3600),
                endTime: now,
                category: .work,
                appName: nil,
                websiteURL: nil,
                note: "",
                hourlyRateSnapshot: 100,
                efficiencyScore: 1.0,
                source: "manual"
            )
        ]
        let points = ValueCalculator.monthlyTrend(records: records, days: 7)
        #expect(points.count == 7)
    }

    @Test func reportRepositoryCRUD() async throws {
        let defaults = UserDefaults(suiteName: "report-repo-test-\(UUID().uuidString)")!
        let repository = UserDefaultsReportRepository(defaults: defaults)
        let report = InvestmentReport(
            id: UUID(),
            createdAt: Date(),
            type: .weekly,
            title: "测试周报",
            content: "content"
        )

        repository.save(report)
        let all = repository.fetchAll()
        #expect(all.count == 1)
        #expect(all.first?.title == "测试周报")

        repository.delete(id: report.id)
        #expect(repository.fetchAll().isEmpty)
    }

    @Test func exportSingleReportToTemp() async throws {
        let report = InvestmentReport(
            id: UUID(),
            createdAt: Date(),
            type: .weekly,
            title: "测试报告",
            content: "# title"
        )
        let url = try ExportService.saveReportToTemp(report)
        #expect(url.pathExtension == "md")
    }

}
