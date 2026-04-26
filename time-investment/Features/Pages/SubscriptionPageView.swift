import SwiftUI

/// 订阅中心页：管理会员档位与报告语气偏好。
/// 语气配置会影响报告建议文案前缀，不改变核心计算结果。
struct SubscriptionPageView: View {
    @Binding var tier: SubscriptionTier
    @Binding var tone: AdviceTone
    let onSave: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AuditTheme.sectionGap) {
                AuditHeader(title: AuditCopy.Subscription.title, subtitle: AuditCopy.Subscription.subtitle)
                AuditCard {
                    // 会员计划切换（free / pro）。
                    HStack {
                        Text(AuditCopy.Subscription.currentPlan)
                        Spacer()
                        Picker(AuditCopy.Subscription.planPicker, selection: $tier) {
                            Text(AuditCopy.Subscription.freePlan).tag(SubscriptionTier.free)
                            Text(AuditCopy.Subscription.proPlan).tag(SubscriptionTier.pro)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 280)
                    }
                }
                AuditCard {
                    // 建议语气切换（顾问 / 教练 / 中性）。
                    HStack {
                        Text(AuditCopy.Subscription.toneLabel)
                        Spacer()
                        Picker(AuditCopy.Subscription.tonePicker, selection: $tone) {
                            ForEach(AdviceTone.allCases) { t in
                                Text(AuditCopy.Subscription.tone(t)).tag(t)
                            }
                        }
                    }
                }
                Button(AuditCopy.Subscription.save, action: onSave)
                    .buttonStyle(AuditPrimaryButtonStyle())
            }
            .padding(AuditTheme.pagePadding)
            .animation(.easeInOut(duration: AuditTheme.motionStandard), value: tier)
            .animation(.easeInOut(duration: AuditTheme.motionStandard), value: tone)
        }
    }
}
