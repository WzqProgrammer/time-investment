//
//  ContentView.swift
//  time-investment
//
//  Created by wangzhengqing on 2026/4/20.
//

import SwiftUI
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

/// 主导航页签定义。
/// 使用稳定的英文 rawValue 作为内部标识，避免本地化文案变化影响状态恢复与逻辑判断。
private enum AuditPage: String, CaseIterable, Identifiable {
    case overview
    case ledger
    case analytics
    case reports
    case subscription
    case settings

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .ledger: return "list.bullet.rectangle.fill"
        case .analytics: return "waveform.path.ecg"
        case .reports: return "doc.richtext.fill"
        case .subscription: return "creditcard.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var titleKey: LocalizedStringKey {
        switch self {
        case .overview: return AuditCopy.Content.navOverview
        case .ledger: return AuditCopy.Content.navLedger
        case .analytics: return AuditCopy.Content.navAnalytics
        case .reports: return AuditCopy.Content.navReports
        case .subscription: return AuditCopy.Content.navSubscription
        case .settings: return AuditCopy.Content.navSettings
        }
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var container: AppContainer
    @StateObject private var dashboardViewModel: DashboardViewModel
    @StateObject private var recordsViewModel: RecordsViewModel
    @StateObject private var settingsViewModel: SettingsViewModel

    @State private var selectedPage: AuditPage = .overview
    @State private var searchText: String = ""
    @State private var reportSearchText: String = ""
    @State private var reportTypeFilter: String = AuditCopy.Reports.filterDefaultValue
    @State private var rangeStart = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var rangeEnd = Date()
    @State private var exportOptions = ExportOptions()
    @State private var exportMessage: String?
    @State private var selectedReport: InvestmentReport?
    @State private var reportActionMessage: String?
    @State private var lastExportedURL: URL?

    /// 在根视图初始化时创建并持有各页面 ViewModel。
    /// 使用 StateObject 保证生命周期稳定，避免页面切换时重复初始化。
    init(container: AppContainer) {
        self.container = container
        _dashboardViewModel = StateObject(wrappedValue: DashboardViewModel(repository: container.repository))
        _recordsViewModel = StateObject(
            wrappedValue: RecordsViewModel(
                repository: container.repository,
                settingsProvider: { container.settings },
                onRecordChanged: { container.reloadRecords() }
            )
        )
        _settingsViewModel = StateObject(
            wrappedValue: SettingsViewModel(
                settings: container.settings,
                onSave: { container.saveSettings($0) }
            )
        )
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            VStack(spacing: 0) {
                topbar
                Divider().background(Color.white.opacity(0.08))
                pageContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(AuditTheme.bg)
        }
        .background(AuditTheme.bg.ignoresSafeArea())
        .foregroundStyle(AuditTheme.textPrimary)
        .sheet(item: $selectedReport) { report in
            reportDetailSheet(report: report)
        }
        .onAppear {
            // 首次进入时完成基础数据与服务准备。
            container.reloadRecords()
            container.reloadReports()
            dashboardViewModel.refresh(with: container.todaySummary)
            container.startTrackingIfNeeded()
        }
        .onChange(of: container.todaySummary.totalValue) { _, _ in
            dashboardViewModel.refresh(with: container.todaySummary)
        }
        .onChange(of: scenePhase) { _, phase in
            // 场景切换时同步追踪状态，减少后台无效采样与权限噪声。
            if phase == .active {
                container.startTrackingIfNeeded()
            } else if phase == .background {
                container.stopTracking()
            }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CHRONOS")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AuditTheme.gold)
                Text("SOVEREIGN")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AuditTheme.gold)
                Text("ELITE AUDIT EDITION")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(AuditTheme.textSecondary.opacity(0.7))
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)

            VStack(spacing: 6) {
                ForEach(AuditPage.allCases) { page in
                    Button {
                        selectedPage = page
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: page.icon)
                            Text(page.titleKey)
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedPage == page ? AuditTheme.gold.opacity(0.15) : Color.clear)
                        )
                        .overlay(
                            Rectangle()
                                .fill(selectedPage == page ? AuditTheme.gold : Color.clear)
                                .frame(width: 2),
                            alignment: .leading
                        )
                        .foregroundStyle(selectedPage == page ? AuditTheme.gold : AuditTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)

            Spacer()
        }
        .frame(width: 230)
        .background(AuditTheme.bg.opacity(0.98))
    }

    private var topbar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AuditTheme.textSecondary.opacity(0.7))
                TextField(AuditCopy.Content.topbarSearchPlaceholder, text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AuditTheme.cardHigh.opacity(0.65))
            .clipShape(Capsule())
            .frame(maxWidth: 420)

            Spacer()

            Image(systemName: "bell.fill")
            Image(systemName: "clock.arrow.circlepath")
            Image(systemName: "person.crop.circle")
        }
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(AuditTheme.textSecondary)
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(AuditTheme.bg)
    }

    @ViewBuilder
    private var pageContent: some View {
        // 页面切换仅负责“组装依赖 + 回调”，核心业务逻辑仍留在容器和 ViewModel。
        switch selectedPage {
        case .overview:
            OverviewPageView(
                roi: dashboardViewModel.roi,
                totalValue: dashboardViewModel.summary.totalValue,
                totalSeconds: dashboardViewModel.summary.totalSeconds,
                records: recordsViewModel.records
            )
        case .ledger:
            LedgerPageView(
                trackingStatusText: container.trackingStatusText,
                trackingWarning: container.trackingWarning,
                trackingActiveSince: container.trackingActiveSince,
                recentTrackingErrors: container.recentTrackingErrors,
                records: recordsViewModel.records,
                selectedCategory: recordsViewModel.selectedCategory,
                note: $recordsViewModel.note,
                onSelectCategory: { recordsViewModel.selectedCategory = $0 },
                onAdd30Min: {
                    recordsViewModel.addManualRecord(minutes: 30)
                    container.reloadRecords()
                },
                onStartManual: { container.startManualTracking(category: recordsViewModel.selectedCategory) },
                onStopManual: {
                    container.stopManualTracking(note: recordsViewModel.note)
                    recordsViewModel.reload()
                    container.reloadRecords()
                }
            )
        case .analytics:
            AnalyticsPageView(
                weekly: weeklySummary(),
                trend: monthlyTrend(),
                rangeStart: $rangeStart,
                rangeEnd: $rangeEnd,
                options: $exportOptions,
                onGenerate: { exportCustomRangeMarkdown() },
                exportMessage: exportMessage
            )
        case .reports:
            ReportsPageView(
                canUseReports: container.canUse(.reports),
                reports: container.reports,
                searchText: $reportSearchText,
                typeFilter: $reportTypeFilter,
                message: reportActionMessage,
                lastExportURL: lastExportedURL,
                onCreateWeekly: { container.createWeeklyReport() },
                onCreateMonthly: { container.createMonthlyReport() },
                onOpen: { selectedReport = $0 },
                onExport: { exportSingleReport($0) },
                onDelete: { container.deleteReport(id: $0) },
                onOpenExportURL: { openInSystem($0) }
            )
        case .subscription:
            SubscriptionPageView(
                tier: $settingsViewModel.settings.subscriptionTier,
                tone: $settingsViewModel.settings.adviceTone,
                onSave: { settingsViewModel.save() }
            )
        case .settings:
            SettingsPageView(
                storageWarning: container.storageWarning,
                hourlyRate: $settingsViewModel.settings.hourlyRate,
                autoTrack: $settingsViewModel.settings.autoTrackingEnabled,
                trackApps: $settingsViewModel.settings.trackApps,
                trackBrowsers: $settingsViewModel.settings.trackBrowsers,
                efficiencyValue: { settingsViewModel.efficiencyBindingValue(for: $0) },
                setEfficiency: { settingsViewModel.setEfficiency($1, for: $0) },
                onSave: {
                    settingsViewModel.save()
                    container.reloadRecords()
                }
            )
        }
    }

    private func weeklySummary() -> WeeklySummary {
        // 统计窗口固定为“最近 7 天”，与页面设计及报告口径保持一致。
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weeklyRecords = container.records.filter { $0.startTime >= oneWeekAgo }
        return ValueCalculator.weeklySummary(for: weeklyRecords, baselineHourlyRate: container.settings.hourlyRate)
    }

    private func monthlyTrend() -> [MonthlyTrendPoint] {
        ValueCalculator.monthlyTrend(records: container.records, days: 30)
    }

    private func customRangeRecords() -> [TimeRecord] {
        // 用户可能输入反向区间，这里统一归一化后再过滤，保证导出稳定。
        let start = Calendar.current.startOfDay(for: min(rangeStart, rangeEnd))
        let endDate = max(rangeStart, rangeEnd)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: endDate)) ?? endDate
        return container.records.filter { $0.startTime >= start && $0.startTime < end }
    }

    private func exportCustomRangeMarkdown() {
        let records = customRangeRecords()
        do {
            // 直接导出到临时目录，减少用户首次配置路径的摩擦。
            let fileURL = try ExportService.saveMarkdownToTemp(
                records: records,
                hourlyRate: container.settings.hourlyRate,
                tone: container.settings.adviceTone,
                title: String(localized: AuditCopy.Content.customRangeReportTitle)
            )
            exportMessage = String(
                format: String(localized: AuditCopy.Content.exportSuccess),
                locale: Locale.current,
                fileURL.path
            )
        } catch {
            exportMessage = String(
                format: String(localized: AuditCopy.Content.exportFailure),
                locale: Locale.current,
                error.localizedDescription
            )
        }
    }

    private func reportDetailSheet(report: InvestmentReport) -> some View {
        // 报告详情以 Sheet 呈现，保持主界面上下文连续，不打断筛选与浏览流程。
        NavigationStack {
            ScrollView {
                Text(report.content)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .textSelection(.enabled)
            }
            .navigationTitle(report.title)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(AuditCopy.Content.toolbarCopy) {
                        copyToClipboard(report.content)
                        reportActionMessage = String(localized: AuditCopy.Content.copiedReport)
                    }
                    Button(AuditCopy.Content.toolbarExport) { exportSingleReport(report) }
                }
            }
        }
    }

    private func exportSingleReport(_ report: InvestmentReport) {
        do {
            let url = try ExportService.saveReportToTemp(report)
            lastExportedURL = url
            reportActionMessage = String(
                format: String(localized: AuditCopy.Content.exportSuccess),
                locale: Locale.current,
                url.path
            )
        } catch {
            reportActionMessage = String(
                format: String(localized: AuditCopy.Content.exportFailure),
                locale: Locale.current,
                error.localizedDescription
            )
        }
    }

    private func openInSystem(_ url: URL) {
#if os(macOS)
        // macOS 使用 Finder 定位导出文件，便于后续二次分享或归档。
        NSWorkspace.shared.activateFileViewerSelecting([url])
#elseif os(iOS)
        UIApplication.shared.open(url)
#endif
    }

    private func copyToClipboard(_ text: String) {
#if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
#elseif os(iOS)
        UIPasteboard.general.string = text
#endif
    }
}

#Preview {
    ContentView(container: AppContainer())
}
