import SwiftUI

struct AuditFilterOption: Identifiable {
    let value: String
    let title: LocalizedStringKey
    var id: String { value }
}

struct AuditSplitLayout<Left: View, Right: View>: View {
    let left: Left
    let right: Right
    var rightWidth: CGFloat = 300

    init(
        rightWidth: CGFloat = 300,
        @ViewBuilder left: () -> Left,
        @ViewBuilder right: () -> Right
    ) {
        self.rightWidth = rightWidth
        self.left = left()
        self.right = right()
    }

    var body: some View {
        HStack(alignment: .top, spacing: AuditTheme.cardGap) {
            left
                .frame(maxWidth: .infinity, alignment: .topLeading)
            right
                .frame(width: rightWidth, alignment: .top)
        }
    }
}

struct AuditSearchControlBar<Trailing: View>: View {
    let placeholder: LocalizedStringKey
    @Binding var query: String
    @Binding var filter: String
    let filters: [AuditFilterOption]
    var filterWidth: CGFloat = 220
    @ViewBuilder let trailing: Trailing

    var body: some View {
        AuditCard {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AuditTheme.textSecondary)
                TextField(placeholder, text: $query)
                    .textFieldStyle(.plain)
                    .frame(height: 34)
                Picker(String(localized: "common.filter"), selection: $filter) {
                    ForEach(filters) { item in
                        Text(item.title).tag(item.value)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: filterWidth)
                Spacer()
                trailing
            }
        }
    }
}

struct AuditStatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title).foregroundStyle(AuditTheme.textSecondary)
            Spacer()
            Text(value).foregroundStyle(AuditTheme.gold)
        }
    }
}
