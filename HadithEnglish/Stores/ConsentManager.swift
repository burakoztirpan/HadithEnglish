import Foundation
import GoogleMobileAds
import UserMessagingPlatform
import AppTrackingTransparency

/// Orchestrates the AdMob launch-time permission sequence in the order
/// Google recommends: UMP consent (shows the GDPR/IDFA form to EEA/UK users
/// when required) -> ATT permission -> Mobile Ads SDK start. Ad loading
/// (NativeAdCard, AdManager) only happens once the user navigates past the
/// home screen, so this chain reliably finishes first without needing a
/// shared "ads ready" flag threaded through every ad call site.
@MainActor
final class ConsentManager: NSObject, ObservableObject {
    static let shared = ConsentManager()

    @Published private(set) var isPrivacyOptionsRequired = false

    private var isMobileAdsStartCalled = false

    func requestConsentThenStartAds() {
        let parameters = UMPRequestParameters()
        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { [weak self] error in
            guard error == nil else {
                self?.requestATTThenStartAds()
                return
            }
            UMPConsentForm.loadAndPresentIfRequired(from: nil) { _ in
                self?.isPrivacyOptionsRequired =
                    UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus == .required
                self?.requestATTThenStartAds()
            }
        }
    }

    func presentPrivacyOptionsForm(completionHandler: @escaping (Error?) -> Void) {
        UMPConsentForm.presentPrivacyOptionsForm(from: nil, completionHandler: completionHandler)
    }

    private func requestATTThenStartAds() {
        ATTrackingManager.requestTrackingAuthorization { [weak self] _ in
            Task { @MainActor in
                self?.startMobileAdsSDK()
            }
        }
    }

    private func startMobileAdsSDK() {
        guard UMPConsentInformation.sharedInstance.canRequestAds, !isMobileAdsStartCalled else { return }
        isMobileAdsStartCalled = true
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
}
