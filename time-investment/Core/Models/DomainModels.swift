import Foundation

enum SubscriptionTier: String, Codable {
    case free
    case pro
}

enum AdviceTone: String, Codable, CaseIterable, Identifiable {
    case advisor = "投资顾问"
    case coach = "教练"
    case neutral = "中性"

    var id: String { rawValue }
}

enum RecordCategory: String, CaseIterable, Codable, Identifiable {
    case work = "工作"
    case study = "学习"
    case exercise = "运动"
    case entertainment = "娱乐"
    case life = "生活"

    var id: String { rawValue }

    var defaultEfficiency: Double {
        switch self {
        case .work: return 1.0
        case .study: return 1.2
        case .exercise: return 1.1
        case .entertainment: return 0.5
        case .life: return 0.8
        }
    }
}

struct TimeRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var startTime: Date
    var endTime: Date
    var category: RecordCategory
    var appName: String?
    var websiteURL: String?
    var note: String
    var hourlyRateSnapshot: Double
    var efficiencyScore: Double
    var source: String

    var duration: TimeInterval {
        max(0, endTime.timeIntervalSince(startTime))
    }
}

struct UserSettings: Codable {
    var hourlyRate: Double = 100
    var autoTrackingEnabled: Bool = false
    var trackApps: Bool = true
    var trackBrowsers: Bool = true
    var trackDocuments: Bool = false
    var defaultCategory: RecordCategory = .work
    var categoryEfficiencyOverrides: [String: Double] = [:]
    var subscriptionTier: SubscriptionTier = .free
    var adviceTone: AdviceTone = .advisor

    func efficiency(for category: RecordCategory) -> Double {
        if let custom = categoryEfficiencyOverrides[category.rawValue] {
            return custom
        }
        return category.defaultEfficiency
    }

    mutating func setEfficiency(_ value: Double, for category: RecordCategory) {
        categoryEfficiencyOverrides[category.rawValue] = value
    }

    var isPro: Bool {
        subscriptionTier == .pro
    }
}

struct DailySummary {
    var totalSeconds: TimeInterval
    var totalValue: Double
    var highValueSeconds: TimeInterval
}

struct WeeklySummary {
    var totalSeconds: TimeInterval
    var totalValue: Double
    var roi: Double
    var categorySeconds: [RecordCategory: TimeInterval]
}

struct MonthlyTrendPoint: Identifiable {
    let date: Date
    let totalValue: Double
    let totalSeconds: TimeInterval

    var id: Date { date }
}

enum InvestmentReportType: String, Codable, CaseIterable, Identifiable {
    case weekly = "周报"
    case monthly = "月报"

    var id: String { rawValue }
}

struct InvestmentReport: Identifiable, Codable, Hashable {
    let id: UUID
    var createdAt: Date
    var type: InvestmentReportType
    var title: String
    var content: String
}
