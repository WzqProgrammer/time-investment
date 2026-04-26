import SwiftUI

struct ReportsPageView: View {
    let canUseReports: Bool
    let reports: [InvestmentReport]
    @Binding var searchText: String
    @Binding var typeFilter: String
    let message: String?
    let lastExportURL: URL?
    let onCreateWeekly: () -> Void
    let onCreateMonthly: () -> Void
    let onOpen: (InvestmentReport) -> Void
    let onExport: (InvestmentReport) -> Void
    let onDelete: (UUID) -> Void
    let onOpenExportURL: (URL) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AuditTheme.sectionGap) {
                AuditHeader(title: AuditCopy.Reports.title, subtitle: AuditCopy.Reports.subtitle)
                AuditSplitLayout(rightWidth: AuditMetrics.reportPanelWidth) {
                    VStack(alignment: .leading, spacing: AuditTheme.cardGap) {
                        controlBar
                        reportList
                    }
                } right: {
                    ReportInsightPanel(
                        total: filteredReports.count,
                        weekly: filteredReports.filter { $0.type == .weekly }.count,
                        monthly: filteredReports.filter { $0.type == .monthly }.count
                    )
                }

                if let message {
                    Text(message).font(.footnote).foregroundStyle(AuditTheme.textSecondary)
                }
                if let lastExportURL {
                    Button(AuditCopy.Reports.openExportFile) { onOpenExportURL(lastExportURL) }
                        .buttonStyle(AuditSecondaryButtonStyle())
                }
            }
            .padding(AuditTheme.pagePadding)
        }
    }

    private var controlBar: some View {
        AuditSearchControlBar(
            placeholder: AuditCopy.Reports.searchPlaceholder,
            query: $searchText,
            filter: $typeFilter,
            filters: AuditCopy.Reports.filterOptions
        ) {
            if canUseReports {
                Button(AuditCopy.Reports.createWeekly, action: onCreateWeekly)
                    .buttonStyle(AuditPrimaryButtonStyle())
                Button(AuditCopy.Reports.createMonthly, action: onCreateMonthly)
                    .buttonStyle(AuditPrimaryButtonStyle())
            }
        }
    }

    private var reportList: some View {
        VStack(spacing: 12) {
            ForEach(filteredReports) { report in
                AuditCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(report.title).font(.system(size: 20, weight: .bold))
                            Text(report.createdAt, format: .dateTime.year().month().day())
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(AuditTheme.textSecondary)
                        }
                        Spacer()
                        Text(report.type.rawValue).foregroundStyle(AuditTheme.gold)
                        Button(AuditCopy.Reports.open) { onOpen(report) }
                            .buttonStyle(AuditSecondaryButtonStyle())
                        Button(AuditCopy.Reports.export) { onExport(report) }
                            .buttonStyle(AuditSecondaryButtonStyle())
                        Button(role: .destructive) { onDelete(report.id) } label: { Text(AuditCopy.Reports.delete) }
                            .buttonStyle(AuditSecondaryButtonStyle())
                    }
                }
            }
        }
        .animation(.easeInOut(duration: AuditTheme.motionStandard), value: filteredReports.map(\.id))
    }

    private var filteredReports: [InvestmentReport] {
        reports.filter { report in
            let matchType: Bool
            switch typeFilter {
            case AuditCopy.Reports.filterWeeklyValue: matchType = report.type == .weekly
            case AuditCopy.Reports.filterMonthlyValue: matchType = report.type == .monthly
            default: matchType = true
            }
            let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchQuery = q.isEmpty
                || report.title.localizedCaseInsensitiveContains(q)
                || report.content.localizedCaseInsensitiveContains(q)
            return matchType && matchQuery
        }
    }
}

private struct ReportInsightPanel: View {
    let total: Int
    let weekly: Int
    let monthly: Int

    var body: some View {
        VStack(spacing: AuditTheme.cardGap) {
            AuditCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text(AuditCopy.Reports.statsTitle)
                        .font(.headline)
                    AuditStatRow(title: String(localized: "reports.stats.total"), value: "\(total)")
                    AuditStatRow(title: String(localized: "reports.stats.weekly"), value: "\(weekly)")
                    AuditStatRow(title: String(localized: "reports.stats.monthly"), value: "\(monthly)")
                }
            }
            AuditCard {
                VStack(spacing: 10) {
                    CircleGaugeView(
                        progress: total == 0 ? 0 : Double(weekly) / Double(total),
                        centerText: "\(total == 0 ? 0 : Int((Double(weekly) / Double(total)) * 100))%",
                        caption: String(localized: "reports.storage.weeklyRatio")
                    )
                    .frame(width: AuditMetrics.sideGauge, height: AuditMetrics.sideGauge)
                    Text(AuditCopy.Reports.storageRatioTitle)
                        .font(.headline)
                    Text(AuditCopy.Reports.storageRatioNote)
                        .font(.caption)
                        .foregroundStyle(AuditTheme.textSecondary)
                }
            }
        }
    }

}
