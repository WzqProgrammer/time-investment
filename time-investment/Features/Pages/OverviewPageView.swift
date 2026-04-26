import SwiftUI

/// 今日概览页：聚合展示“价值结果 + 时间投入 + 最近记录”。
/// 本页只消费外部传入的数据，不直接改写业务状态。
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
                        // 左卡：展示“收益率 + 绝对价值”两个最关键经营指标。
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
                        // 右卡：将今日总时长映射到固定目标（10h）进度，便于快速判断投入强度。
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
                // 只展示最近 6 条，保证概览页信息密度可控；完整流水在账本页查看。
            }
            .padding(AuditTheme.pagePadding)
        }
    }
}
