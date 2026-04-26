import SwiftUI

/// 审计账本页：负责“状态可见 + 手动补录 + 流水查看”三件事。
/// 自动追踪异常时，用户可通过手动计时兜底完成记录闭环。
struct LedgerPageView: View {
    let trackingStatusText: String
    let trackingWarning: String?
    let trackingActiveSince: Date?
    let recentTrackingErrors: [String]
    let records: [TimeRecord]
    let selectedCategory: RecordCategory
    @Binding var note: String
    let onSelectCategory: (RecordCategory) -> Void
    let onAdd30Min: () -> Void
    let onStartManual: () -> Void
    let onStopManual: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AuditTheme.sectionGap) {
                AuditHeader(title: AuditCopy.Ledger.title, subtitle: AuditCopy.Ledger.subtitle)
                AuditCard {
                    // 追踪状态卡：实时展示当前状态、持续时长、警告与最近错误。
                    VStack(alignment: .leading, spacing: 6) {
                        Text(trackingStatusText)
                            .font(.subheadline.weight(.medium))
                        if let start = trackingActiveSince {
                            // 每秒刷新一次，仅用于显示层；不影响底层记录落库节奏。
                            TimelineView(.periodic(from: .now, by: 1)) { _ in
                                Text("\(String(localized: AuditCopy.Ledger.durationPrefix))\(durationText(since: start))")
                                    .font(.footnote)
                                    .foregroundStyle(AuditTheme.textSecondary)
                            }
                        }
                        if let warning = trackingWarning {
                            Text(warning)
                                .font(.footnote)
                                .foregroundStyle(.orange)
                        }
                        if !recentTrackingErrors.isEmpty {
                            Divider()
                            ForEach(recentTrackingErrors, id: \.self) { msg in
                                Text(msg)
                                    .font(.caption)
                                    .foregroundStyle(AuditTheme.textSecondary)
                            }
                        }
                    }
                }

                HStack {
                    // 操作区：分类 + 备注 + 快捷补录 + 手动计时启停。
                    Picker(AuditCopy.Ledger.categoryPicker, selection: Binding(get: { selectedCategory }, set: onSelectCategory)) {
                        ForEach(RecordCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    TextField(AuditCopy.Ledger.notePlaceholder, text: $note)
                    Button(AuditCopy.Ledger.addThirtyMinutes, action: onAdd30Min)
                        .buttonStyle(AuditSecondaryButtonStyle())
                    Button(AuditCopy.Ledger.startManual, action: onStartManual)
                        .buttonStyle(AuditSecondaryButtonStyle())
                    Button(AuditCopy.Ledger.stopAndSave, action: onStopManual)
                        .buttonStyle(AuditPrimaryButtonStyle())
                }

                RecordTableCard(records: Array(records.prefix(12)))
            }
            .padding(AuditTheme.pagePadding)
        }
    }

    private func durationText(since date: Date) -> String {
        // 将秒数格式化为 HH:mm:ss，供状态卡直观显示。
        let seconds = max(0, Int(Date().timeIntervalSince(date)))
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }
}
