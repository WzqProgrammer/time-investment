import SwiftUI

/// 搜索/筛选控件的数据模型：
/// - value: 内部稳定值（不随语言变化）
/// - title: 对用户展示的本地化文案
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
        // 通用双栏布局：左侧主内容自适应，右侧固定宽度信息面板。
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
                    // 过滤项值使用 value 绑定，标题仅用于显示，避免多语言导致逻辑漂移。
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
        // 统一“左标题-右数值”排版，减少各页面重复样式代码。
        HStack {
            Text(title).foregroundStyle(AuditTheme.textSecondary)
            Spacer()
            Text(value).foregroundStyle(AuditTheme.gold)
        }
    }
}
