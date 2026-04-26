import SwiftUI

/// 通用记录表格卡片：
/// 在概览页与账本页复用，统一展示“时间-分类-时长-价值”四列。
struct RecordTableCard: View {
    let records: [TimeRecord]

    var body: some View {
        AuditCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(AuditCopy.Table.ledgerTitle)
                        .font(.headline)
                    Spacer()
                    Text(AuditCopy.Table.viewAll)
                        .font(.footnote.bold())
                        .foregroundStyle(AuditTheme.gold)
                }

                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                    // 表头
                    GridRow {
                        Text(AuditCopy.Table.timeColumn).foregroundStyle(AuditTheme.textSecondary).font(.caption)
                        Text(AuditCopy.Table.categoryColumn).foregroundStyle(AuditTheme.textSecondary).font(.caption)
                        Text(AuditCopy.Table.durationColumn).foregroundStyle(AuditTheme.textSecondary).font(.caption)
                        Text(AuditCopy.Table.valueColumn).foregroundStyle(AuditTheme.textSecondary).font(.caption)
                    }
                    ForEach(records) { record in
                        // 每条记录对应一行，行内自行计算并格式化价值金额。
                        RecordGridRow(record: record)
                    }
                }
            }
        }
    }
}

private struct RecordGridRow: View {
    let record: TimeRecord
    @State private var isHovered = false

    var body: some View {
        GridRow {
            Text(record.startTime, format: .dateTime.hour().minute().second())
                .font(.subheadline)
            Text(record.category.rawValue)
                .font(.subheadline)
            Text(String(format: "%.2fh", record.duration / 3600))
                .font(.subheadline)
            let value = ValueCalculator.timeValue(
                hourlyRate: record.hourlyRateSnapshot,
                duration: record.duration,
                efficiency: record.efficiencyScore
            )
            Text(String(format: "%@¥%.0f", value >= 0 ? "+" : "", value))
                .font(.subheadline.bold())
                .foregroundStyle(value >= 0 ? AuditTheme.green : AuditTheme.red)
        }
        // hover 反馈用于增强桌面端可点击感和审计“行扫描”体验。
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AuditTheme.cardHigh.opacity(isHovered ? 0.42 : 0.18))
        )
        .overlay(alignment: .bottom) {
            Divider().opacity(0.14)
        }
        .scaleEffect(isHovered ? 1.005 : 1)
        .animation(.easeOut(duration: AuditTheme.motionQuick), value: isHovered)
#if os(macOS)
        .onHover { hovering in
            isHovered = hovering
        }
#endif
    }
}
