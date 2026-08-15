import Foundation
import GoogleMobileAds
import UserMessagingPlatform

/// Orchestrates the AdMob launch-time permission sequence: UMP consent
/// (shows the GDPR form to EEA/UK users when required) -> Mobile Ads SDK
/// start. The app does not request App Tracking Transparency or use IDFA -
/// AdMob serves non-personalized ads automatically when IDFA access was
/// never requested, no extra configuration needed. `canRequestAds` mirrors
/// UMPConsentInformation's own flag so every ad call site (not just the SDK
/// start call) can gate on it directly - if the UMP round-trip is slow or
/// errors, GADMobileAds.start() never fires, but nothing else stops
/// AdManager/NativeAdCard from calling GADInterstitialAd.load /
/// GADAdLoader.load on their own, so they need the same guard.
@MainActor
final class ConsentManager: NSObject, ObservableObject {
    static let shared = ConsentManager()

    @Published private(set) var isPrivacyOptionsRequired = false
    @Published private(set) var canRequestAds = false

    private var isMobileAdsStartCalled = false
    private var isConsentFlowStarted = false

    func requestConsentThenStartAds() {
        guard !isConsentFlowStarted else { return }
        isConsentFlowStarted = true

        // Reflects consent already gathered in a previous session immediately,
        // rather than making a returning user wait on a fresh network round-trip.
        refreshCanRequestAds()

        let parameters = UMPRequestParameters()
        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { [weak self] error in
            guard error == nil else {
                self?.refreshCanRequestAds()
                self?.startMobileAdsSDK()
                return
            }
            UMPConsentForm.loadAndPresentIfRequired(from: nil) { _ in
                self?.isPrivacyOptionsRequired =
                    UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus == .required
                self?.refreshCanRequestAds()
                self?.startMobileAdsSDK()
            }
        }
    }

    private func refreshCanRequestAds() {
        canRequestAds = UMPConsentInformation.sharedInstance.canRequestAds
    }

    func presentPrivacyOptionsForm(completionHandler: @escaping (Error?) -> Void) {
        UMPConsentForm.presentPrivacyOptionsForm(from: nil, completionHandler: completionHandler)
    }

    private func startMobileAdsSDK() {
        guard UMPConsentInformation.sharedInstance.canRequestAds, !isMobileAdsStartCalled else { return }
        isMobileAdsStartCalled = true
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
}
