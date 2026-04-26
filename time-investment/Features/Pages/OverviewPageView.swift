import SwiftUI

struct OverviewPageView: View {
    let roi: Double
    let totalValue: Double
    let totalSeconds: TimeInterval
    let records: [TimeRecord]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AuditTheme.sectionGap) {
                AuditHeader(title: AuditCopy.Overview.title, subtitle: AuditCopy.Overview.subtitle)
                HStack(alignment: .top, spacing: AuditTheme.cardGap) {
                    AuditCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(AuditCopy.Overview.roiLabel)
                                .font(.headline)
                                .foregroundStyle(AuditTheme.textSecondary)
                            HStack(alignment: .lastTextBaseline, spacing: 8) {
                                Text("+\(roi * 100, specifier: "%.1f")%")
                                    .font(.system(size: AuditMetrics.heroStatSize, weight: .bold))
                                    .foregroundStyle(AuditTheme.gold)
                                Text("+¥\(totalValue, specifier: "%.2f")")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(AuditTheme.green)
                            }
                            Text(AuditCopy.Overview.roiHint)
                                .font(.body)
                                .foregroundStyle(AuditTheme.textSecondary)
                        }
                    }

                    AuditCard {
                        VStack(spacing: 12) {
                            CircleGaugeView(
                                progress: min(1, totalSeconds / 36000),
                                centerText: String(format: "%.1fh", totalSeconds / 3600),
                                caption: String(localized: "overview.gauge.caption")
                            )
                            .frame(width: AuditMetrics.gaugeLarge, height: AuditMetrics.gaugeLarge)
                            Text(AuditCopy.Overview.gaugeTitle)
                                .font(.headline)
                        }
                    }
                    .frame(width: 280)
                }

                RecordTableCard(records: Array(records.prefix(6)))
            }
            .padding(AuditTheme.pagePadding)
        }
    }
}
