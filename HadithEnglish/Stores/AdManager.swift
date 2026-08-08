import Foundation
import UIKit
import GoogleMobileAds
import UserMessagingPlatform

/// Owns the interstitial ad's trigger rules and lifecycle. Everything a
/// caller needs is two calls: `categoryEntered()` on appear,
/// `categoryExited()` on disappear — the decision of whether that exit
/// should show an ad, and the ad's load/present mechanics, all live here.
final class AdManager: NSObject, ObservableObject {
    private static let hasEnteredFirstCategoryKey = "AdManager.hasEnteredFirstCategory"
    private static let categoryChangeCountKey = "AdManager.categoryChangeCount"
    private static let nextThresholdKey = "AdManager.nextInterstitialThreshold"
    private static let lastShownAtKey = "AdManager.lastInterstitialShownAt"

    private static let dwellTriggerSeconds: TimeInterval = 60
    private static let cooldownSeconds: TimeInterval = 180

    private let defaults: UserDefaults
    private var currentCategoryEnteredAt: Date?
    private var preloadedInterstitial: GADInterstitialAd?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        super.init()
        if defaults.object(forKey: Self.nextThresholdKey) == nil {
            defaults.set(Self.rollThreshold(), forKey: Self.nextThresholdKey)
        }
    }

    // MARK: - Public API

    func categoryEntered() {
        currentCategoryEnteredAt = Date()
        preloadInterstitialIfNeeded()
    }

    func categoryExited(now: Date = Date()) {
        defer { currentCategoryEnteredAt = nil }

        guard defaults.bool(forKey: Self.hasEnteredFirstCategoryKey) else {
            defaults.set(true, forKey: Self.hasEnteredFirstCategoryKey)
            return
        }

        let dwell = currentCategoryEnteredAt.map { now.timeIntervalSince($0) } ?? 0
        let newCount = defaults.integer(forKey: Self.categoryChangeCountKey) + 1
        let threshold = defaults.integer(forKey: Self.nextThresholdKey)

        let countTriggered = newCount >= threshold
        let timeTriggered = dwell >= Self.dwellTriggerSeconds
        guard countTriggered || timeTriggered else {
            defaults.set(newCount, forKey: Self.categoryChangeCountKey)
            return
        }

        guard isCooldownElapsed(now: now) else {
            // A trigger fired but cooldown blocked it - keep the count so
            // the very next qualifying exit can fire without waiting for
            // a whole new threshold's worth of navigation.
            defaults.set(newCount, forKey: Self.categoryChangeCountKey)
            return
        }

        guard presentInterstitialIfLoaded() else {
            // A trigger qualified and cooldown was clear, but no ad was
            // actually ready to show (still loading, or a prior load
            // failed) - same as the cooldown-blocked case above, keep the
            // count so the next qualifying exit retries. Do NOT start the
            // cooldown or reset the count for an ad the user never saw.
            defaults.set(newCount, forKey: Self.categoryChangeCountKey)
            return
        }

        defaults.set(0, forKey: Self.categoryChangeCountKey)
        defaults.set(Self.rollThreshold(), forKey: Self.nextThresholdKey)
        defaults.set(now, forKey: Self.lastShownAtKey)
    }

    // MARK: - Cooldown

    private func isCooldownElapsed(now: Date) -> Bool {
        guard let lastShown = defaults.object(forKey: Self.lastShownAtKey) as? Date else {
            return true
        }
        return now.timeIntervalSince(lastShown) >= Self.cooldownSeconds
    }

    // MARK: - Threshold

    private static func rollThreshold() -> Int {
        Bool.random() ? 3 : 4
    }

    // MARK: - Ad lifecycle

    private func preloadInterstitialIfNeeded() {
        guard preloadedInterstitial == nil, UMPConsentInformation.sharedInstance.canRequestAds else { return }
        GADInterstitialAd.load(withAdUnitID: AdConfig.interstitialAdUnitID, request: GADRequest()) { [weak self] ad, error in
            if let error {
                print("AdManager: interstitial preload failed: \(error.localizedDescription)")
                return
            }
            self?.preloadedInterstitial = ad
        }
    }

    @discardableResult
    private func presentInterstitialIfLoaded() -> Bool {
        guard let ad = preloadedInterstitial, let rootVC = Self.topViewController() else {
            print("AdManager: interstitial not ready, skipping this trigger")
            return false
        }
        ad.present(fromRootViewController: rootVC)
        preloadedInterstitial = nil
        preloadInterstitialIfNeeded()
        return true
    }

    private static func topViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
