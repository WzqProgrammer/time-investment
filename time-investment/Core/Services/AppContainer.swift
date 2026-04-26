import Foundation
import Combine

/// Pro 功能门禁点。
/// 统一在容器层做授权判断，避免页面和服务层重复编码会员逻辑。
enum ProFeature {
    case browserTracking
    case advancedExport
    case reports
}

@MainActor
final class AppContainer: ObservableObject {
    let repository: TimeRecordRepository
    let trackingService: TrackingService
    let reportRepository: ReportRepository
    private let settingsStore: SettingsStore
    private let subscriptionService: SubscriptionService
    @Published var settings = UserSettings()
    @Published private(set) var records: [TimeRecord] = []
    @Published private(set) var todaySummary = DailySummary(totalSeconds: 0, totalValue: 0, highValueSeconds: 0)
    @Published private(set) var reports: [InvestmentReport] = []
    @Published private(set) var storageWarning: String?
    @Published private(set) var trackingStatusText: String = String(localized: "tracking.status.idle")
    @Published private(set) var trackingWarning: String?
    @Published private(set) var trackingActiveSince: Date?
    @Published private(set) var recentTrackingErrors: [String] = []

    private var currentTrackedApp: String?
    private var currentTrackedURL: String?
    private var trackingStartAt: Date?
    private var manualTrackingStartAt: Date?
    private var manualTrackingCategory: RecordCategory?

    /// 应用级依赖注入入口。
    /// 默认提供可运行实现，同时保留测试替身注入能力。
    init(
        repository: TimeRecordRepository = CoreDataTimeRecordRepository(),
        trackingService: TrackingService = TrackingService(),
        reportRepository: ReportRepository = UserDefaultsReportRepository(),
        settingsStore: SettingsStore = UserDefaultsSettingsStore(),
        subscriptionService: SubscriptionService = LocalSubscriptionService()
    ) {
        self.repository = repository
        self.trackingService = trackingService
        self.reportRepository = reportRepository
        self.settingsStore = settingsStore
        self.subscriptionService = subscriptionService
        self.settings = settingsStore.load()
        self.settings.subscriptionTier = subscriptionService.currentTier()
        if let coreRepo = repository as? CoreDataTimeRecordRepository {
            storageWarning = coreRepo.storageWarningMessage
        } else {
            storageWarning = nil
        }
        self.repository.observeChanges { [weak self] in
            Task { @MainActor in
                self?.reloadRecords()
            }
        }
        setupTrackingPipeline()
        reloadRecords()
        reloadReports()
    }

    func reloadRecords() {
        // 容器统一维护“全量记录 + 今日汇总”，页面只消费派生状态。
        records = repository.fetchAll()
        let todayRecords = records.filter { Calendar.current.isDateInToday($0.startTime) }
        todaySummary = ValueCalculator.dailySummary(for: todayRecords)
    }

    func reloadReports() {
        reports = reportRepository.fetchAll()
    }

    func startTrackingIfNeeded() {
        // 自动追踪受“开关 + 系统权限”双重约束。
        guard settings.autoTrackingEnabled else {
            trackingStatusText = String(localized: "tracking.status.idle")
            trackingWarning = nil
            return
        }
        trackingService.start()
        if trackingService.isTracking {
            trackingStatusText = String(localized: "tracking.status.running")
            trackingWarning = nil
        } else {
            trackingStatusText = String(localized: "tracking.status.startFailed")
            trackingWarning = String(localized: "tracking.warning.permission")
            appendTrackingError(String(localized: "tracking.error.startFailedNoPermission"))
        }
    }

    func stopTracking() {
        finalizeCurrentTrack()
        trackingService.stop()
        trackingStatusText = String(localized: "tracking.status.stopped")
        trackingWarning = nil
        trackingActiveSince = nil
    }

    func saveSettings(_ newSettings: UserSettings) {
        // 保存设置后立即驱动追踪状态切换，保证行为与用户预期一致。
        settings = newSettings
        settingsStore.save(newSettings)
        subscriptionService.updateTier(newSettings.subscriptionTier)
        if settings.autoTrackingEnabled {
            startTrackingIfNeeded()
        } else {
            stopTracking()
        }
    }

    func canUse(_ feature: ProFeature) -> Bool {
        // 先走全局 Pro 快路径，减少后续 feature 分支判断。
        if settings.isPro { return true }
        switch feature {
        case .browserTracking, .advancedExport, .reports:
            return false
        }
    }

    func startManualTracking(category: RecordCategory) {
        guard manualTrackingStartAt == nil else { return }
        manualTrackingStartAt = Date()
        manualTrackingCategory = category
        trackingActiveSince = manualTrackingStartAt
        trackingStatusText = String(
            format: String(localized: "tracking.status.manualRunning"),
            locale: Locale.current,
            category.rawValue
        )
    }

    func stopManualTracking(note: String = "") {
        guard let start = manualTrackingStartAt, let category = manualTrackingCategory else { return }
        let end = Date()
        // 过滤误触：小于 5 秒的手动计时不落库。
        guard end.timeIntervalSince(start) >= 5 else {
            manualTrackingStartAt = nil
            manualTrackingCategory = nil
            return
        }
        let record = TimeRecord(
            id: UUID(),
            startTime: start,
            endTime: end,
            category: category,
            appName: nil,
            websiteURL: nil,
            note: note.isEmpty ? String(localized: "tracking.note.manual") : note,
            hourlyRateSnapshot: settings.hourlyRate,
            efficiencyScore: settings.efficiency(for: category),
            source: "manual-timer"
        )
        repository.save(record)
        manualTrackingStartAt = nil
        manualTrackingCategory = nil
        trackingActiveSince = nil
        trackingStatusText = String(localized: "tracking.status.manualSaved")
    }

    func createWeeklyReport() {
        guard canUse(.reports) else { return }
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weeklyRecords = records.filter { $0.startTime >= oneWeekAgo }
        let content = ReportService.weeklyReportMarkdown(
            records: weeklyRecords,
            hourlyRate: settings.hourlyRate,
            tone: settings.adviceTone
        )
        let report = InvestmentReport(
            id: UUID(),
            createdAt: Date(),
            type: .weekly,
            title: String(localized: "report.title.weekly"),
            content: content
        )
        reportRepository.save(report)
        reloadReports()
    }

    func createMonthlyReport() {
        guard canUse(.reports) else { return }
        let oneMonthAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let monthlyRecords = records.filter { $0.startTime >= oneMonthAgo }
        let content = ReportService.monthlyReportMarkdown(
            records: monthlyRecords,
            hourlyRate: settings.hourlyRate,
            tone: settings.adviceTone
        )
        let report = InvestmentReport(
            id: UUID(),
            createdAt: Date(),
            type: .monthly,
            title: String(localized: "report.title.monthly"),
            content: content
        )
        reportRepository.save(report)
        reloadReports()
    }

    func deleteReport(id: UUID) {
        reportRepository.delete(id: id)
        reloadReports()
    }

    private func setupTrackingPipeline() {
        // TrackingService 回调可能来自 Timer；统一跳回主线程更新 UI 状态。
        trackingService.onSample = { [weak self] sample in
            Task { @MainActor in
                self?.handleTrackingSample(sample: sample)
            }
        }
        trackingService.onError = { [weak self] message in
            Task { @MainActor in
                self?.trackingWarning = message
                self?.appendTrackingError(message)
            }
        }
    }

    private func handleTrackingSample(sample: TrackingSample) {
        guard settings.autoTrackingEnabled else { return }
        guard let appName = sample.appName, !appName.isEmpty else { return }
        let isBrowser = sample.websiteURL != nil
        // 浏览器 URL 采样属于 Pro 能力，且受用户细分开关控制。
        if isBrowser && !canUse(.browserTracking) { return }
        if isBrowser && !settings.trackBrowsers { return }
        if !isBrowser && !settings.trackApps { return }

        if currentTrackedApp == nil {
            currentTrackedApp = appName
            currentTrackedURL = sample.websiteURL
            trackingStartAt = Date()
            trackingActiveSince = trackingStartAt
            trackingStatusText = sample.websiteURL == nil
                ? String(format: String(localized: "tracking.status.appOnly"), locale: Locale.current, appName)
                : String(
                    format: String(localized: "tracking.status.appAndURL"),
                    locale: Locale.current,
                    appName,
                    sample.websiteURL ?? ""
                )
            return
        }

        guard currentTrackedApp != appName || currentTrackedURL != sample.websiteURL else { return }
        // 前台上下文变化时先结算上一段，再开启新段，形成自然切片。
        finalizeCurrentTrack()
        currentTrackedApp = appName
        currentTrackedURL = sample.websiteURL
        trackingStartAt = Date()
        trackingActiveSince = trackingStartAt
    }

    private func finalizeCurrentTrack() {
        guard let app = currentTrackedApp, let start = trackingStartAt else { return }
        let end = Date()
        // 与手动计时一致，忽略短抖动采样。
        guard end.timeIntervalSince(start) >= 5 else { return }

        let record = TimeRecord(
            id: UUID(),
            startTime: start,
            endTime: end,
            category: settings.defaultCategory,
            appName: app,
            websiteURL: currentTrackedURL,
            note: currentTrackedURL == nil
                ? String(format: String(localized: "tracking.note.autoApp"), locale: Locale.current, app)
                : String(
                    format: String(localized: "tracking.note.autoAppURL"),
                    locale: Locale.current,
                    app,
                    currentTrackedURL ?? ""
                ),
            hourlyRateSnapshot: settings.hourlyRate,
            efficiencyScore: settings.efficiency(for: settings.defaultCategory),
            source: "auto"
        )
        repository.save(record)
        currentTrackedApp = nil
        currentTrackedURL = nil
        trackingStartAt = nil
        trackingActiveSince = nil
        trackingStatusText = trackingService.isTracking
            ? String(localized: "tracking.status.running")
            : String(localized: "tracking.status.stopped")
    }

    private func appendTrackingError(_ message: String) {
        // 错误列表仅保留最近 5 条，保证侧边提示可读性。
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        recentTrackingErrors.insert("[\(timestamp)] \(message)", at: 0)
        if recentTrackingErrors.count > 5 {
            recentTrackingErrors = Array(recentTrackingErrors.prefix(5))
        }
    }
}
