import Foundation
import GoogleMobileAds
import UserMessagingPlatform
import AppTrackingTransparency

/// Orchestrates the AdMob launch-time permission sequence in the order
/// Google recommends: UMP consent (shows the GDPR/IDFA form to EEA/UK users
/// when required) -> ATT permission -> Mobile Ads SDK start. `canRequestAds`
/// mirrors UMPConsentInformation's own flag so every ad call site (not just
/// the SDK start call) can gate on it directly - if the UMP round-trip is
/// slow or errors, GADMobileAds.start() never fires, but nothing else stops
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
                self?.requestATTThenStartAds()
                return
            }
            UMPConsentForm.loadAndPresentIfRequired(from: nil) { _ in
                self?.isPrivacyOptionsRequired =
                    UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus == .required
                self?.refreshCanRequestAds()
                self?.requestATTThenStartAds()
            }
        }
    }

    private func refreshCanRequestAds() {
        canRequestAds = UMPConsentInformation.sharedInstance.canRequestAds
    }

    func presentPrivacyOptionsForm(completionHandler: @escaping (Error?) -> Void) {
        UMPConsentForm.presentPrivacyOptionsForm(from: nil, completionHandler: completionHandler)
    }

    private func requestATTThenStartAds() {
        // Only .notDetermined actually shows a prompt - already-decided status
        // is safe to skip straight past, and skipping the delay below for
        // that (by far the common) case avoids a pointless wait on every
        // later launch once the user has already answered once.
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            startMobileAdsSDK()
            return
        }
        // A short delay before the ATT prompt gives the window scene time to
        // finish becoming .active - requesting authorization while the scene
        // is still mid-activation is a known cause of the system silently
        // not presenting the dialog at all.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [weak self] in
            ATTrackingManager.requestTrackingAuthorization { _ in
                Task { @MainActor in
                    self?.startMobileAdsSDK()
                }
            }
        }
    }

    private func startMobileAdsSDK() {
        guard UMPConsentInformation.sharedInstance.canRequestAds, !isMobileAdsStartCalled else { return }
        isMobileAdsStartCalled = true
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
}
