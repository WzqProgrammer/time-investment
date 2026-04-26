import SwiftUI
import CoreGraphics

enum AuditCopy {
    enum Content {
        static let navOverview: LocalizedStringKey = "content.nav.overview"
        static let navLedger: LocalizedStringKey = "content.nav.ledger"
        static let navAnalytics: LocalizedStringKey = "content.nav.analytics"
        static let navReports: LocalizedStringKey = "content.nav.reports"
        static let navSubscription: LocalizedStringKey = "content.nav.subscription"
        static let navSettings: LocalizedStringKey = "content.nav.settings"
        static let topbarSearchPlaceholder: LocalizedStringKey = "content.topbar.search.placeholder"
        static let customRangeReportTitle: String.LocalizationValue = "content.export.customRange.title"
        static let exportSuccess: String.LocalizationValue = "content.export.success"
        static let exportFailure: String.LocalizationValue = "content.export.failure"
        static let copiedReport: String.LocalizationValue = "content.report.copied"
        static let toolbarCopy: LocalizedStringKey = "content.toolbar.copy"
        static let toolbarExport: LocalizedStringKey = "content.toolbar.export"
    }

    enum Overview {
        static let title: LocalizedStringKey = "overview.title"
        static let subtitle: LocalizedStringKey = "overview.subtitle"
        static let roiLabel: LocalizedStringKey = "overview.roi.label"
        static let roiHint: LocalizedStringKey = "overview.roi.hint"
        static let gaugeCaption: LocalizedStringKey = "overview.gauge.caption"
        static let gaugeTitle: LocalizedStringKey = "overview.gauge.title"
    }

    enum Ledger {
        static let title: LocalizedStringKey = "ledger.title"
        static let subtitle: LocalizedStringKey = "ledger.subtitle"
        static let durationPrefix: String.LocalizationValue = "ledger.duration.prefix"
        static let categoryPicker: LocalizedStringKey = "ledger.category.picker"
        static let notePlaceholder: LocalizedStringKey = "ledger.note.placeholder"
        static let addThirtyMinutes: LocalizedStringKey = "ledger.action.addThirtyMinutes"
        static let startManual: LocalizedStringKey = "ledger.action.startManual"
        static let stopAndSave: LocalizedStringKey = "ledger.action.stopAndSave"
    }

    enum Analytics {
        static let title: LocalizedStringKey = "analytics.title"
        static let subtitle: LocalizedStringKey = "analytics.subtitle"
        static let categoryTitle: LocalizedStringKey = "analytics.category.title"
        static let trendTitle: LocalizedStringKey = "analytics.trend.title"
        static let exportTitle: LocalizedStringKey = "analytics.export.title"
        static let rangeStart: LocalizedStringKey = "analytics.export.rangeStart"
        static let rangeEnd: LocalizedStringKey = "analytics.export.rangeEnd"
        static let includeAppName: LocalizedStringKey = "analytics.export.includeAppName"
        static let includeURL: LocalizedStringKey = "analytics.export.includeURL"
        static let includeNote: LocalizedStringKey = "analytics.export.includeNote"
        static let includeSource: LocalizedStringKey = "analytics.export.includeSource"
        static let generateAction: LocalizedStringKey = "analytics.export.generate"
        static let mainCategory: LocalizedStringKey = "analytics.category.main"
    }

    enum Reports {
        static let title: LocalizedStringKey = "reports.title"
        static let subtitle: LocalizedStringKey = "reports.subtitle"
        static let searchPlaceholder: LocalizedStringKey = "reports.search.placeholder"
        static let createWeekly: LocalizedStringKey = "reports.action.createWeekly"
        static let createMonthly: LocalizedStringKey = "reports.action.createMonthly"
        static let openExportFile: LocalizedStringKey = "reports.action.openExportFile"
        static let open: LocalizedStringKey = "reports.action.open"
        static let export: LocalizedStringKey = "reports.action.export"
        static let delete: LocalizedStringKey = "reports.action.delete"
        static let statsTitle: LocalizedStringKey = "reports.stats.title"
        static let totalReports: LocalizedStringKey = "reports.stats.total"
        static let weeklyReports: LocalizedStringKey = "reports.stats.weekly"
        static let monthlyReports: LocalizedStringKey = "reports.stats.monthly"
        static let storageRatioTitle: LocalizedStringKey = "reports.storage.title"
        static let storageRatioNote: LocalizedStringKey = "reports.storage.note"
        static let weeklyRatioCaption: LocalizedStringKey = "reports.storage.weeklyRatio"

        static let filterOptions: [AuditFilterOption] = [
            .init(value: "all", title: "reports.filter.all"),
            .init(value: "weekly", title: "reports.filter.weekly"),
            .init(value: "monthly", title: "reports.filter.monthly")
        ]
        static let filterWeeklyValue = "weekly"
        static let filterMonthlyValue = "monthly"
        static let filterDefaultValue = "all"
    }

    enum Subscription {
        static let title: LocalizedStringKey = "subscription.title"
        static let subtitle: LocalizedStringKey = "subscription.subtitle"
        static let currentPlan: LocalizedStringKey = "subscription.currentPlan"
        static let planPicker: LocalizedStringKey = "subscription.plan.picker"
        static let freePlan: LocalizedStringKey = "subscription.plan.free"
        static let proPlan: LocalizedStringKey = "subscription.plan.pro"
        static let toneLabel: LocalizedStringKey = "subscription.tone.label"
        static let tonePicker: LocalizedStringKey = "subscription.tone.picker"
        static let save: LocalizedStringKey = "subscription.save"

        static func tone(_ tone: AdviceTone) -> LocalizedStringKey {
            switch tone {
            case .advisor:
                return "subscription.tone.advisor"
            case .coach:
                return "subscription.tone.coach"
            case .neutral:
                return "subscription.tone.neutral"
            }
        }
    }

    enum Settings {
        static let title: LocalizedStringKey = "settings.title"
        static let subtitle: LocalizedStringKey = "settings.subtitle"
        static let pricingTitle: LocalizedStringKey = "settings.pricing.title"
        static let hourlyRatePlaceholder: LocalizedStringKey = "settings.pricing.hourlyRatePlaceholder"
        static let autoTrack: LocalizedStringKey = "settings.toggle.autoTrack"
        static let trackApps: LocalizedStringKey = "settings.toggle.trackApps"
        static let trackBrowsers: LocalizedStringKey = "settings.toggle.trackBrowsers"
        static let saveAgreement: LocalizedStringKey = "settings.saveAgreement"
    }

    enum Table {
        static let ledgerTitle: LocalizedStringKey = "table.ledger.title"
        static let viewAll: LocalizedStringKey = "table.ledger.viewAll"
        static let timeColumn: LocalizedStringKey = "table.column.time"
        static let categoryColumn: LocalizedStringKey = "table.column.category"
        static let durationColumn: LocalizedStringKey = "table.column.duration"
        static let valueColumn: LocalizedStringKey = "table.column.value"
    }
}

enum AuditMetrics {
    static let heroStatSize: CGFloat = 60
    static let gaugeLarge: CGFloat = 220
    static let sideGauge: CGFloat = 180
    static let reportPanelWidth: CGFloat = 300
    static let analyticsRightWidth: CGFloat = 420
}
