import Foundation

protocol SubscriptionService {
    func currentTier() -> SubscriptionTier
    func updateTier(_ tier: SubscriptionTier)
}

final class LocalSubscriptionService: SubscriptionService {
    private let key = "time_investment.subscription_tier"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func currentTier() -> SubscriptionTier {
        let raw = defaults.string(forKey: key) ?? SubscriptionTier.free.rawValue
        return SubscriptionTier(rawValue: raw) ?? .free
    }

    func updateTier(_ tier: SubscriptionTier) {
        defaults.set(tier.rawValue, forKey: key)
    }
}

// StoreKit 接入预留：后续可替换 LocalSubscriptionService
final class StoreKitSubscriptionService: SubscriptionService {
    func currentTier() -> SubscriptionTier { .free }
    func updateTier(_ tier: SubscriptionTier) {}
}
