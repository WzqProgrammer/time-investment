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

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("time_investment.onboarding_completed") private var onboardingCompleted = false
    @ObservedObject var container: AppContainer
    @StateObject private var dashboardViewModel: DashboardViewModel
    @StateObject private var recordsViewModel: RecordsViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @State private var exportMessage: String?
    @State private var weeklyReportPreview: String = ""
    @State private var rangeStart = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var rangeEnd = Date()
    @State private var exportOptions = ExportOptions()
    @State private var selectedReport: InvestmentReport?
    @State private var reportActionMessage: String?
    @State private var lastExportedURL: URL?
    @State private var reportSearchText: String = ""
    @State private var reportTypeFilter: String = "全部"

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
        TabView {
            dashboardTab
                .tabItem { Label("今日", systemImage: "chart.bar.xaxis") }

            recordsTab
                .tabItem { Label("记录", systemImage: "list.bullet.rectangle") }

            statsTab
                .tabItem { Label("统计", systemImage: "chart.pie") }

            subscriptionTab
                .tabItem { Label("订阅", systemImage: "creditcard") }

            reportsTab
                .tabItem { Label("报告", systemImage: "doc.text") }

            settingsTab
                .tabItem { Label("设置", systemImage: "gearshape") }
        }
        .onAppear {
            container.reloadRecords()
            dashboardViewModel.refresh(with: container.todaySummary)
            container.startTrackingIfNeeded()
        }
        .onChange(of: container.todaySummary.totalValue) { _, _ in
            dashboardViewModel.refresh(with: container.todaySummary)
        }
        .onChange(of: container.todaySummary.totalSeconds) { _, _ in
            dashboardViewModel.refresh(with: container.todaySummary)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                container.startTrackingIfNeeded()
            } else if phase == .background {
                container.stopTracking()
            }
        }
        .sheet(isPresented: .constant(!onboardingCompleted)) {
            onboardingView
        }
        .sheet(item: $selectedReport) { report in
            reportDetailSheet(report: report)
        }
    }

    private var dashboardTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("今日时间价值")
                .font(.headline)
            Text("¥\(dashboardViewModel.summary.totalValue, specifier: "%.2f")")
                .font(.system(size: 34, weight: .bold))
            Text("今日时长：\(dashboardViewModel.summary.totalSeconds / 3600, specifier: "%.1f") 小时")
            Text("高价值占比：\(dashboardViewModel.summary.highValueSeconds / max(1, dashboardViewModel.summary.totalSeconds) * 100, specifier: "%.0f")%")
            Text("ROI：\(dashboardViewModel.roi * 100, specifier: "%.1f")%")
                .foregroundStyle(dashboardViewModel.roi >= 0 ? .green : .orange)
            Button("刷新数据") {
                recordsViewModel.reload()
                container.reloadRecords()
                dashboardViewModel.refresh(with: container.todaySummary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }

    private var recordsTab: some View {
        VStack(spacing: 12) {
            GroupBox("追踪状态") {
                VStack(alignment: .leading, spacing: 6) {
                    Text(container.trackingStatusText)
                        .font(.subheadline.weight(.medium))
                    if let start = container.trackingActiveSince {
                        TimelineView(.periodic(from: .now, by: 1)) { _ in
                            Text("持续时长：\(durationText(since: start))")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let warning = container.trackingWarning {
                        Text(warning)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                    if !container.recentTrackingErrors.isEmpty {
                        Divider()
                        Text("最近错误")
                            .font(.footnote.weight(.semibold))
                        ForEach(container.recentTrackingErrors, id: \.self) { message in
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Picker("分类", selection: $recordsViewModel.selectedCategory) {
                    ForEach(RecordCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.menu)

                TextField("备注（可选）", text: $recordsViewModel.note)
                Button("新增30分钟记录") {
                    recordsViewModel.addManualRecord(minutes: 30)
                    container.reloadRecords()
                    dashboardViewModel.refresh(with: container.todaySummary)
                }
            }
            HStack {
                Button("开始手动计时") {
                    container.startManualTracking(category: recordsViewModel.selectedCategory)
                }
                .buttonStyle(.bordered)

                Button("停止并保存") {
                    container.stopManualTracking(note: recordsViewModel.note)
                    recordsViewModel.reload()
                    container.reloadRecords()
                    dashboardViewModel.refresh(with: container.todaySummary)
                }
                .buttonStyle(.borderedProminent)
            }

            List {
                ForEach(recordsViewModel.records) { record in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(record.category.rawValue) · \(record.source)")
                            .font(.headline)
                        Text("\(record.duration / 60, specifier: "%.0f") 分钟")
                            .foregroundStyle(.secondary)
                        if !record.note.isEmpty {
                            Text(record.note)
                        }
                    }
                }
                .onDelete(perform: recordsViewModel.delete)
            }
        }
        .padding()
    }

    private var settingsTab: some View {
        GeometryReader { proxy in
            let isWide = proxy.size.width >= 920
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let warning = container.storageWarning {
                        GroupBox("存储状态") {
                            Text(warning)
                                .font(.footnote)
                                .foregroundStyle(.orange)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    if isWide {
                        HStack(alignment: .top, spacing: 16) {
                            VStack(spacing: 16) {
                                valueCard
                                trackingCard
                            }
                            .frame(maxWidth: .infinity)

                            efficiencyCard
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            valueCard
                            trackingCard
                            efficiencyCard
                        }
                    }

                    HStack {
                        Spacer()
                        Button("保存设置") {
                            settingsViewModel.save()
                            recordsViewModel.reload()
                            container.reloadRecords()
                            dashboardViewModel.refresh(with: container.todaySummary)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
        }
    }

    private var valueCard: some View {
        GroupBox("价值参数") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("基础时薪")
                            .font(.headline)
                        Text("用于计算时间价值与 ROI。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    TextField("时薪", value: $settingsViewModel.settings.hourlyRate, format: .number)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                }
            }
            .padding(.top, 4)
        }
    }

    private var trackingCard: some View {
        GroupBox("自动追踪") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("启用自动追踪", isOn: $settingsViewModel.settings.autoTrackingEnabled)
                Divider()
                Toggle("追踪应用使用", isOn: $settingsViewModel.settings.trackApps)
                Toggle("追踪浏览器访问", isOn: $settingsViewModel.settings.trackBrowsers)
                Text("提示：浏览器追踪属于 Pro 能力，且需系统权限。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
    }

    private var efficiencyCard: some View {
        GroupBox("分类效率系数") {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(RecordCategory.allCases) { category in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(category.rawValue)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(settingsViewModel.efficiencyBindingValue(for: category), specifier: "%.1f")")
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        Slider(
                            value: Binding(
                                get: { settingsViewModel.efficiencyBindingValue(for: category) },
                                set: { settingsViewModel.setEfficiency($0, for: category) }
                            ),
                            in: 0.1...3.0,
                            step: 0.1
                        )
                    }
                    if category.id != RecordCategory.allCases.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    private var statsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("统计分析")
                .font(.headline)
            Text("本周 ROI 与分类占比")
                .foregroundStyle(.secondary)
            Divider()
            let weekly = weeklySummary()
            let trend = monthlyTrend()
            Text("本周总价值：¥\(weekly.totalValue, specifier: "%.2f")")
            Text("本周总时长：\(weekly.totalSeconds / 3600, specifier: "%.1f") 小时")
            Text("本周 ROI：\(weekly.roi * 100, specifier: "%.1f")%")
                .foregroundStyle(weekly.roi >= 0 ? .green : .orange)

            Text("分类占比")
                .font(.subheadline.bold())
            ForEach(RecordCategory.allCases) { category in
                let seconds = weekly.categorySeconds[category, default: 0]
                if seconds > 0 {
                    let ratio = seconds / max(1, weekly.totalSeconds)
                    HStack {
                        Text(category.rawValue)
                        Spacer()
                        Text("\(ratio * 100, specifier: "%.0f")% · \(seconds / 3600, specifier: "%.1f")h")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()
            Text("月度趋势（最近7天）")
                .font(.subheadline.bold())
            ForEach(trend.suffix(7)) { point in
                HStack {
                    Text(point.date, format: .dateTime.month().day())
                    Spacer()
                    Text("¥\(point.totalValue, specifier: "%.0f") · \(point.totalSeconds / 3600, specifier: "%.1f")h")
                        .foregroundStyle(.secondary)
                }
            }

            Divider()
            if container.canUse(.advancedExport) {
                Button("导出最近7天 CSV") {
                    exportLast7DaysCSV()
                }
                Button("导出最近7天 JSON") {
                    exportLast7DaysJSON()
                }
                Button("导出最近7天 Markdown") {
                    exportLast7DaysMarkdown()
                }
            }

            Section("自定义时间范围导出") {
                DatePicker("开始", selection: $rangeStart, displayedComponents: .date)
                DatePicker("结束", selection: $rangeEnd, displayedComponents: .date)
                Toggle("包含应用名", isOn: $exportOptions.includeAppName)
                Toggle("包含网站URL", isOn: $exportOptions.includeWebsiteURL)
                Toggle("包含备注", isOn: $exportOptions.includeNote)
                Toggle("包含来源字段", isOn: $exportOptions.includeSource)

                if container.canUse(.advancedExport) {
                    HStack {
                        Button("导出 CSV") { exportCustomRangeCSV() }
                        Button("导出 JSON") { exportCustomRangeJSON() }
                        Button("导出 Markdown") { exportCustomRangeMarkdown() }
                    }
                } else {
                    Text("自定义导出属于 Pro 功能。")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
            if let exportMessage {
                Text(exportMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if !container.canUse(.reports) {
                Text("免费版仅展示基础统计。周报/月报与高级导出属于 Pro 功能。")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            } else {
                Divider()
                Text("周报预览（Pro）")
                    .font(.subheadline.bold())
                Text(weeklyReportPreview.isEmpty ? weeklyReport() : weeklyReportPreview)
                    .font(.footnote)
                    .textSelection(.enabled)
                Divider()
                Text("月报预览（Pro）")
                    .font(.subheadline.bold())
                Text(monthlyReport())
                    .font(.footnote)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }

    private var onboardingView: some View {
        NavigationStack {
            Form {
                Section("欢迎使用时间投资账本") {
                    Text("先设置基础时薪，后续系统会自动计算时间价值与 ROI。")
                    Text("自动追踪需要系统辅助功能权限，首次启用时请在 macOS 系统设置中授权。")
                        .foregroundStyle(.secondary)
                }

                Section("初始参数") {
                    HStack {
                        Text("基础时薪")
                        Spacer()
                        TextField("时薪", value: $settingsViewModel.settings.hourlyRate, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    Toggle("启用自动追踪", isOn: $settingsViewModel.settings.autoTrackingEnabled)
                }
            }
            .navigationTitle("首次设置")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        settingsViewModel.save()
                        onboardingCompleted = true
                        container.reloadRecords()
                        dashboardViewModel.refresh(with: container.todaySummary)
                    }
                }
            }
        }
    }

    private func weeklySummary() -> WeeklySummary {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weeklyRecords = container.records.filter { $0.startTime >= oneWeekAgo }
        return ValueCalculator.weeklySummary(for: weeklyRecords, baselineHourlyRate: container.settings.hourlyRate)
    }

    private func exportLast7DaysCSV() {
        guard container.canUse(.advancedExport) else {
            exportMessage = "当前为免费版，CSV 导出为 Pro 功能。"
            return
        }
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weeklyRecords = container.records.filter { $0.startTime >= oneWeekAgo }
        do {
            let fileURL = try ExportService.saveCSVToTemp(records: weeklyRecords, options: exportOptions)
            exportMessage = "导出成功：\(fileURL.path)"
        } catch {
            exportMessage = "导出失败：\(error.localizedDescription)"
        }
    }

    private func exportLast7DaysJSON() {
        guard container.canUse(.advancedExport) else {
            exportMessage = "当前为免费版，JSON 导出为 Pro 功能。"
            return
        }
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weeklyRecords = container.records.filter { $0.startTime >= oneWeekAgo }
        do {
            let fileURL = try ExportService.saveJSONToTemp(records: weeklyRecords, options: exportOptions)
            exportMessage = "导出成功：\(fileURL.path)"
        } catch {
            exportMessage = "导出失败：\(error.localizedDescription)"
        }
    }

    private func exportLast7DaysMarkdown() {
        guard container.canUse(.advancedExport) else {
            exportMessage = "当前为免费版，Markdown 导出为 Pro 功能。"
            return
        }
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weeklyRecords = container.records.filter { $0.startTime >= oneWeekAgo }
        do {
            let fileURL = try ExportService.saveMarkdownToTemp(
                records: weeklyRecords,
                hourlyRate: container.settings.hourlyRate,
                tone: container.settings.adviceTone,
                title: "时间投资周报"
            )
            weeklyReportPreview = ReportService.weeklyReportMarkdown(
                records: weeklyRecords,
                hourlyRate: container.settings.hourlyRate,
                tone: container.settings.adviceTone
            )
            exportMessage = "导出成功：\(fileURL.path)"
        } catch {
            exportMessage = "导出失败：\(error.localizedDescription)"
        }
    }

    private func weeklyReport() -> String {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weeklyRecords = container.records.filter { $0.startTime >= oneWeekAgo }
        return ReportService.weeklyReportMarkdown(
            records: weeklyRecords,
            hourlyRate: container.settings.hourlyRate,
            tone: container.settings.adviceTone
        )
    }

    private func monthlyReport() -> String {
        let oneMonthAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let monthlyRecords = container.records.filter { $0.startTime >= oneMonthAgo }
        return ReportService.monthlyReportMarkdown(
            records: monthlyRecords,
            hourlyRate: container.settings.hourlyRate,
            tone: container.settings.adviceTone
        )
    }

    private func monthlyTrend() -> [MonthlyTrendPoint] {
        ValueCalculator.monthlyTrend(records: container.records, days: 30)
    }

    private func customRangeRecords() -> [TimeRecord] {
        let start = Calendar.current.startOfDay(for: min(rangeStart, rangeEnd))
        let endDate = max(rangeStart, rangeEnd)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: endDate)) ?? endDate
        return container.records.filter { $0.startTime >= start && $0.startTime < end }
    }

    private func exportCustomRangeCSV() {
        let records = customRangeRecords()
        do {
            let fileURL = try ExportService.saveCSVToTemp(records: records, options: exportOptions)
            exportMessage = "导出成功：\(fileURL.path)"
        } catch {
            exportMessage = "导出失败：\(error.localizedDescription)"
        }
    }

    private func exportCustomRangeJSON() {
        let records = customRangeRecords()
        do {
            let fileURL = try ExportService.saveJSONToTemp(records: records, options: exportOptions)
            exportMessage = "导出成功：\(fileURL.path)"
        } catch {
            exportMessage = "导出失败：\(error.localizedDescription)"
        }
    }

    private func exportCustomRangeMarkdown() {
        let records = customRangeRecords()
        do {
            let title = "时间投资区间报告"
            let fileURL = try ExportService.saveMarkdownToTemp(
                records: records,
                hourlyRate: container.settings.hourlyRate,
                tone: container.settings.adviceTone,
                title: title
            )
            weeklyReportPreview = ExportService.makeMarkdown(
                records: records,
                hourlyRate: container.settings.hourlyRate,
                tone: container.settings.adviceTone,
                title: title
            )
            exportMessage = "导出成功：\(fileURL.path)"
        } catch {
            exportMessage = "导出失败：\(error.localizedDescription)"
        }
    }

    private var subscriptionTab: some View {
        Form {
            Section("当前订阅") {
                Picker("版本", selection: $settingsViewModel.settings.subscriptionTier) {
                    Text("免费版").tag(SubscriptionTier.free)
                    Text("Pro").tag(SubscriptionTier.pro)
                }
                .pickerStyle(.segmented)
            }
            Section("报告语气模板") {
                Picker("语气", selection: $settingsViewModel.settings.adviceTone) {
                    ForEach(AdviceTone.allCases) { tone in
                        Text(tone.rawValue).tag(tone)
                    }
                }
                .pickerStyle(.menu)
            }
            Section("说明") {
                Text("该页面当前为开发阶段订阅中心，后续将接入 StoreKit 实际购买流程。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Button("保存订阅与语气设置") {
                settingsViewModel.save()
            }
        }
    }

    private var reportsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("报告中心")
                    .font(.title3.bold())
                Spacer()
                if container.canUse(.reports) {
                    Button("生成周报") {
                        container.createWeeklyReport()
                    }
                    Button("生成月报") {
                        container.createMonthlyReport()
                    }
                }
            }

            if !container.canUse(.reports) {
                Text("报告中心属于 Pro 功能，请在订阅页切换到 Pro 体验。")
                    .foregroundStyle(.orange)
            }

            HStack {
                TextField("搜索标题或内容", text: $reportSearchText)
                    .textFieldStyle(.roundedBorder)
                Picker("类型", selection: $reportTypeFilter) {
                    Text("全部").tag("全部")
                    Text("周报").tag("周报")
                    Text("月报").tag("月报")
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            }

            List {
                ForEach(filteredReports()) { report in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(report.title)
                                .font(.headline)
                            Spacer()
                            Text(report.type.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(report.createdAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(report.content)
                            .font(.footnote)
                            .lineLimit(6)
                            .textSelection(.enabled)
                        HStack {
                            Button("查看详情") {
                                selectedReport = report
                            }
                            .buttonStyle(.bordered)
                            Button("快速导出") {
                                exportSingleReport(report)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { offsets in
                    for index in offsets {
                        container.deleteReport(id: container.reports[index].id)
                    }
                }
            }
            if let reportActionMessage {
                Text(reportActionMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if let url = lastExportedURL {
                Button("在系统中打开导出文件") {
                    openInSystem(url)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .onAppear {
            container.reloadReports()
        }
    }

    private func reportDetailSheet(report: InvestmentReport) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(report.title)
                        .font(.title3.bold())
                    Text(report.createdAt, format: .dateTime.year().month().day().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Divider()
                    Text(report.content)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
            .navigationTitle("报告详情")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("复制Markdown") {
                        copyToClipboard(report.content)
                        reportActionMessage = "已复制报告内容到剪贴板。"
                    }
                    Button("导出") {
                        exportSingleReport(report)
                    }
                }
            }
        }
    }

    private func exportSingleReport(_ report: InvestmentReport) {
        do {
            let url = try ExportService.saveReportToTemp(report)
            lastExportedURL = url
            reportActionMessage = "导出成功：\(url.path)"
        } catch {
            reportActionMessage = "导出失败：\(error.localizedDescription)"
        }
    }

    private func filteredReports() -> [InvestmentReport] {
        container.reports.filter { report in
            let matchesType: Bool
            switch reportTypeFilter {
            case "周报":
                matchesType = report.type == .weekly
            case "月报":
                matchesType = report.type == .monthly
            default:
                matchesType = true
            }

            let q = reportSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = q.isEmpty
                || report.title.localizedCaseInsensitiveContains(q)
                || report.content.localizedCaseInsensitiveContains(q)
            return matchesType && matchesSearch
        }
    }

    private func durationText(since date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private func openInSystem(_ url: URL) {
#if os(macOS)
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
