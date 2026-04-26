import SwiftUI

struct AnalyticsPageView: View {
    let weekly: WeeklySummary
    let trend: [MonthlyTrendPoint]
    @Binding var rangeStart: Date
    @Binding var rangeEnd: Date
    @Binding var options: ExportOptions
    let onGenerate: () -> Void
    let exportMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AuditTheme.sectionGap) {
                AuditHeader(title: AuditCopy.Analytics.title, subtitle: AuditCopy.Analytics.subtitle)
                AuditSplitLayout(rightWidth: AuditMetrics.analyticsRightWidth) {
                    categoryCard
                } right: {
                    trendCard
                }

                AuditCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(AuditCopy.Analytics.exportTitle).font(.headline)
                        HStack(spacing: 16) {
                            DatePicker(AuditCopy.Analytics.rangeStart, selection: $rangeStart, displayedComponents: .date)
                            DatePicker(AuditCopy.Analytics.rangeEnd, selection: $rangeEnd, displayedComponents: .date)
                        }
                        HStack(spacing: 16) {
                            Toggle(AuditCopy.Analytics.includeAppName, isOn: $options.includeAppName)
                            Toggle(AuditCopy.Analytics.includeURL, isOn: $options.includeWebsiteURL)
                            Toggle(AuditCopy.Analytics.includeNote, isOn: $options.includeNote)
                            Toggle(AuditCopy.Analytics.includeSource, isOn: $options.includeSource)
                        }
                        Button(AuditCopy.Analytics.generateAction, action: onGenerate)
                            .buttonStyle(AuditPrimaryButtonStyle())
                        if let exportMessage {
                            Text(exportMessage).font(.footnote).foregroundStyle(AuditTheme.textSecondary)
                        }
                    }
                }
            }
            .padding(AuditTheme.pagePadding)
            .animation(.easeInOut(duration: AuditTheme.motionStandard), value: options.includeAppName)
            .animation(.easeInOut(duration: AuditTheme.motionStandard), value: options.includeWebsiteURL)
            .animation(.easeInOut(duration: AuditTheme.motionStandard), value: options.includeNote)
            .animation(.easeInOut(duration: AuditTheme.motionStandard), value: options.includeSource)
        }
    }

    private var categoryCard: some View {
        AuditCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(AuditCopy.Analytics.categoryTitle).font(.headline)
                CircleGaugeView(progress: 1, centerText: "100%", caption: String(localized: "analytics.category.main"))
                    .frame(width: AuditMetrics.gaugeLarge - 20, height: AuditMetrics.gaugeLarge - 20)
                ForEach(RecordCategory.allCases, id: \.id) { category in
                    let seconds = weekly.categorySeconds[category, default: 0]
                    if seconds > 0 {
                        AuditStatRow(
                            title: category.rawValue,
                            value: String(format: "%.1fh", seconds / 3600)
                        )
                    }
                }
            }
        }
    }

    private var trendCard: some View {
        AuditCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(AuditCopy.Analytics.trendTitle).font(.headline)
                ForEach(trend.suffix(7)) { p in
                    HStack {
                        Text(p.date, format: .dateTime.month().day())
                        Spacer()
                        Text(String(format: "¥%.0f", p.totalValue))
                    }
                    .padding(.vertical, 6)
                    .overlay(alignment: .bottom) {
                        Divider().opacity(0.18)
                    }
                }
            }
        }
    }
}
