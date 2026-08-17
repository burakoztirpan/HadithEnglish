import Foundation
import StoreKit
import UIKit

/// Prompts the App Store review dialog once a user shows real engagement -
/// reaching 3 unique favorited hadiths - gated by a 30-day cooldown so it
/// can only ever interrupt the same person about once a month (StoreKit
/// itself separately caps the dialog to 3 actual appearances per year).
final class ReviewPromptManager: ObservableObject {
    private static let favoritesThreshold = 3
    private static let cooldownDays = 30
    private static let lastPromptDateKey = "ReviewPromptManager.lastPromptDate"
    private static let postFavoriteDelay: TimeInterval = 0.5

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Call right after a favorite is *added* (not removed) with the
    /// resulting unique favorite count. Fires ~500ms later so the tap's own
    /// feedback isn't interrupted, and cancels any interstitial that would
    /// otherwise compete with the review dialog for the screen.
    func favoriteAdded(uniqueFavoritesCount: Int, adManager: AdManager) {
        guard uniqueFavoritesCount >= Self.favoritesThreshold, isCooldownElapsed() else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.postFavoriteDelay) { [weak self] in
            self?.requestReview(adManager: adManager)
        }
    }

    private func isCooldownElapsed() -> Bool {
        guard let last = defaults.object(forKey: Self.lastPromptDateKey) as? Date else { return true }
        let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        return days >= Self.cooldownDays
    }

    private func requestReview(adManager: AdManager) {
        // A review dialog and an interstitial both wanting the screen at the
        // same moment is exactly the double-modal collision Apple's review
        // guidelines (and users) don't tolerate - whichever one the app
        // wasn't already mid-transition to loses.
        adManager.suppressNextInterstitial()

        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else { return }

        defaults.set(Date(), forKey: Self.lastPromptDateKey)
        SKStoreReviewController.requestReview(in: scene)
    }
}
