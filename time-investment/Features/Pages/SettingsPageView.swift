import SwiftUI

/// 价值设置页：集中管理计价参数、追踪开关、效率系数。
/// 所有输入通过 Binding 连接到上层状态，点击保存后统一持久化。
struct SettingsPageView: View {
    let storageWarning: String?
    @Binding var hourlyRate: Double
    @Binding var autoTrack: Bool
    @Binding var trackApps: Bool
    @Binding var trackBrowsers: Bool
    let efficiencyValue: (RecordCategory) -> Double
    let setEfficiency: (RecordCategory, Double) -> Void
    let onSave: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AuditTheme.sectionGap) {
                AuditHeader(title: AuditCopy.Settings.title, subtitle: AuditCopy.Settings.subtitle)
                if let storageWarning {
                    // 存储降级提示：当 Core Data 回退到内存时提醒用户数据风险。
                    Text(storageWarning)
                        .font(.footnote)
                        .foregroundStyle(AuditTheme.red)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AuditTheme.cardHigh.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: AuditTheme.radiusPill))
                }
                AuditCard {
                    // 价值参数：时薪是所有价值计算的基线。
                    HStack {
                        Text(AuditCopy.Settings.pricingTitle)
                        Spacer()
                        Text("¥")
                        TextField(AuditCopy.Settings.hourlyRatePlaceholder, value: $hourlyRate, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                        Text("/hr")
                    }
                }
                HStack(alignment: .top, spacing: AuditTheme.cardGap) {
                    AuditCard {
                        VStack(alignment: .leading, spacing: 10) {
                            // 追踪行为开关：总开关 + 细分来源控制。
                            Toggle(AuditCopy.Settings.autoTrack, isOn: $autoTrack)
                            Toggle(AuditCopy.Settings.trackApps, isOn: $trackApps)
                            Toggle(AuditCopy.Settings.trackBrowsers, isOn: $trackBrowsers)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    AuditCard {
                        VStack(alignment: .leading, spacing: 10) {
                            // 分类效率系数：用于修正同等时长在不同类型下的价值权重。
                            ForEach(RecordCategory.allCases) { category in
                                HStack {
                                    Text(category.rawValue).frame(width: 64, alignment: .leading)
                                    Slider(
                                        value: Binding(
                                            get: { efficiencyValue(category) },
                                            set: { setEfficiency(category, $0) }
                                        ),
                                        in: 0.1...3.0,
                                        step: 0.1
                                    )
                                    Text("\(efficiencyValue(category), specifier: "%.1f")x")
                                        .foregroundStyle(AuditTheme.gold)
                                        .frame(width: 56, alignment: .trailing)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                HStack {
                    Spacer()
                    // 显式保存，避免用户误以为每次拖动都已落盘。
                    Button(AuditCopy.Settings.saveAgreement, action: onSave)
                        .buttonStyle(AuditPrimaryButtonStyle())
                }
            }
            .padding(AuditTheme.pagePadding)
            .animation(.easeInOut(duration: AuditTheme.motionStandard), value: autoTrack)
            .animation(.easeInOut(duration: AuditTheme.motionStandard), value: trackApps)
            .animation(.easeInOut(duration: AuditTheme.motionStandard), value: trackBrowsers)
        }
    }
}
