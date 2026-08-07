import SwiftUI
import UIKit
import GoogleMobileAds

/// A native AdMob ad styled as a plain List row, matching how
/// HadithDetailView's non-favorites list actually looks (a flat row on
/// Color("CardBackground"), not the floating rounded card HadithCardView
/// uses elsewhere) - so it reads as part of the list, not a foreign
/// element dropped in.
struct NativeAdCard: View {
    @StateObject private var loader = NativeAdLoader()

    var body: some View {
        Group {
            if let nativeAd = loader.nativeAd {
                NativeAdContainerView(nativeAd: nativeAd)
                    .frame(minHeight: 96)
                    .padding(.vertical, 8)
            } else {
                EmptyView()
            }
        }
        .onAppear { loader.load() }
    }
}

/// Wraps a real GADNativeAdView (UIKit) - AdMob requires the ad's asset
/// views (headline, body, call-to-action) to be registered on the SDK's
/// own container for click/impression tracking to work at all. See the
/// plan's "Correction from the spec" note for why this can't just be
/// plain SwiftUI Text views reading the ad's strings.
private struct NativeAdContainerView: UIViewRepresentable {
    let nativeAd: GADNativeAd

    func makeUIView(context: Context) -> GADNativeAdView {
        let adView = GADNativeAdView()
        adView.backgroundColor = UIColor(named: "CardBackground")

        let sponsoredLabel = UILabel()
        sponsoredLabel.font = .preferredFont(forTextStyle: .caption1)
        sponsoredLabel.textColor = .secondaryLabel
        sponsoredLabel.text = "Ad"

        let headlineLabel = UILabel()
        headlineLabel.font = .preferredFont(forTextStyle: .body)
        headlineLabel.numberOfLines = 0
        adView.headlineView = headlineLabel

        let bodyLabel = UILabel()
        bodyLabel.font = .preferredFont(forTextStyle: .subheadline)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 3
        adView.bodyView = bodyLabel

        let ctaButton = UIButton(type: .system)
        ctaButton.titleLabel?.font = .boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption1).pointSize)
        ctaButton.contentHorizontalAlignment = .leading
        ctaButton.tintColor = UIColor(named: "AccentColor")
        adView.callToActionView = ctaButton

        let stack = UIStackView(arrangedSubviews: [sponsoredLabel, headlineLabel, bodyLabel, ctaButton])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: adView.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -16),
        ])

        return adView
    }

    func updateUIView(_ adView: GADNativeAdView, context: Context) {
        (adView.headlineView as? UILabel)?.text = nativeAd.headline
        (adView.bodyView as? UILabel)?.text = nativeAd.body
        (adView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        // Must be set last, after every asset view above is assigned -
        // this is what actually activates AdMob's click/impression
        // tracking on the views just registered.
        adView.nativeAd = nativeAd
    }
}

/// Loads one GADNativeAd per card instance - native ads aren't reusable
/// across positions the way a single interstitial instance is.
private final class NativeAdLoader: NSObject, ObservableObject, GADNativeAdLoaderDelegate {
    @Published var nativeAd: GADNativeAd?
    private var adLoader: GADAdLoader?
    private var didLoad = false

    func load() {
        guard !didLoad else { return }
        didLoad = true
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController
        else { return }

        let loader = GADAdLoader(
            adUnitID: AdConfig.nativeAdUnitID,
            rootViewController: rootVC,
            adTypes: [.native],
            options: nil
        )
        loader.delegate = self
        adLoader = loader
        loader.load(GADRequest())
    }

    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        self.nativeAd = nativeAd
    }

    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        print("NativeAdCard: load failed: \(error.localizedDescription)")
    }
}
