import SwiftUI

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
                    VStack(alignment: .leading, spacing: 6) {
                        Text(trackingStatusText)
                            .font(.subheadline.weight(.medium))
                        if let start = trackingActiveSince {
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
        let seconds = max(0, Int(Date().timeIntervalSince(date)))
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }
}
