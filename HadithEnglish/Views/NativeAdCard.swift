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
                    .frame(height: Self.cardHeight(for: nativeAd))
                    .padding(.vertical, 8)
            } else {
                // ponytail: EmptyView() here collapses this List row to a
                // zero-size cell, and List never instantiates (or calls
                // onAppear on) a zero-size row - so the ad load never
                // started. Color.clear with a real, if tiny, frame keeps
                // this a genuine row so onAppear fires and load() runs.
                Color.clear.frame(height: 1)
            }
        }
        .onAppear { loader.load() }
    }

    /// A List row's UIViewRepresentable content doesn't self-size from its
    /// UIKit content's real Auto Layout needs - it's capped to whatever
    /// SwiftUI frame it's given, full stop. A too-small `minHeight` here
    /// (96pt, measured on-device) squeezed GADMediaView down to ~56pt
    /// tall - both "the banner looks tiny" and AdMob's own "MediaView too
    /// small for video" validator warning were the same root cause. This
    /// computes real room for the loaded ad's actual aspect ratio instead
    /// of guessing a fixed height, clamped so one unusually tall/wide ad
    /// can't blow out the list's rhythm.
    private static func cardHeight(for nativeAd: GADNativeAd) -> CGFloat {
        let ratio = nativeAd.mediaContent.aspectRatio > 0 ? CGFloat(nativeAd.mediaContent.aspectRatio) : 16.0 / 9.0
        let rowWidth = UIScreen.main.bounds.width - 32 // matches the 16pt List-row insets on each side
        let mediaWidth = rowWidth - 32 // stack's own 16pt leading/trailing margins
        let mediaHeight = min(max(mediaWidth / ratio, 120), 220)
        let chromeHeight: CGFloat = 150 // sponsored label + headline + body + CTA + spacing + top/bottom margins
        return mediaHeight + chromeHeight
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

        // AdMob's own native ad policy requires a clearly visible, high-
        // contrast "Ad" attribution badge - not just a plain caption in
        // the same muted secondary color as everything else on the card.
        let sponsoredLabel = UILabel()
        sponsoredLabel.font = .boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption2).pointSize)
        sponsoredLabel.textColor = .white
        sponsoredLabel.backgroundColor = UIColor(named: "AccentColor") ?? .systemGreen
        sponsoredLabel.text = "  Ad  "
        sponsoredLabel.layer.cornerRadius = 3
        sponsoredLabel.layer.masksToBounds = true
        sponsoredLabel.setContentHuggingPriority(.required, for: .horizontal)

        let headlineLabel = UILabel()
        headlineLabel.font = .preferredFont(forTextStyle: .body)
        headlineLabel.numberOfLines = 0
        adView.headlineView = headlineLabel

        let bodyLabel = UILabel()
        bodyLabel.font = .preferredFont(forTextStyle: .subheadline)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 3
        adView.bodyView = bodyLabel

        // Some inventory (video-enabled native ads) requires a registered
        // media view to render its required media asset at all - AdMob's
        // own on-device validator flags a missing mediaView as an
        // implementation issue.
        //
        // Google's own sample (developers.google.com/admob/ios/native/advanced)
        // pins mediaView with real Auto Layout and derives its HEIGHT from
        // the loaded ad's mediaContent.aspectRatio, added once that's known
        // (updateUIView) - a fixed guessed height can end up narrower than
        // the ad's actual video needs, which is what the validator was
        // flagging here even after mediaView itself was correctly in the
        // view hierarchy. See updateUIView for the aspect-ratio constraint.
        let mediaView = GADMediaView()
        mediaView.contentMode = .scaleAspectFit
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        let mediaContainer = UIView()
        mediaContainer.addSubview(mediaView)
        NSLayoutConstraint.activate([
            mediaView.topAnchor.constraint(equalTo: mediaContainer.topAnchor),
            mediaView.bottomAnchor.constraint(equalTo: mediaContainer.bottomAnchor),
            mediaView.leadingAnchor.constraint(equalTo: mediaContainer.leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor),
        ])
        adView.mediaView = mediaView

        let ctaButton = UIButton(type: .system)
        ctaButton.titleLabel?.font = .boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption1).pointSize)
        ctaButton.contentHorizontalAlignment = .leading
        ctaButton.tintColor = UIColor(named: "AccentColor")
        adView.callToActionView = ctaButton

        // sponsoredLabel needs to hug its own text width (a compact chip),
        // not stretch to the full row width like the vertical stack's
        // .fill alignment would otherwise force on every arranged
        // subview - wrapping it with a flexible spacer in its own
        // horizontal row is the reliable way to left-align just this one
        // item without fighting the outer stack's alignment.
        let badgeRow = UIStackView(arrangedSubviews: [sponsoredLabel, UIView()])
        badgeRow.axis = .horizontal

        let stack = UIStackView(arrangedSubviews: [badgeRow, headlineLabel, mediaContainer, bodyLabel, ctaButton])
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
        if let mediaView = adView.mediaView {
            // mediaView's width comes for free from its container filling
            // the row's width (via the outer stack view). Height is
            // derived from the real ad's aspect ratio - a guessed fixed
            // height can be narrower than the actual video needs, which is
            // what the validator was flagging even with mediaView correctly
            // in the hierarchy. Only one of these should be active at a
            // time if this view is ever reused for a different ad.
            context.coordinator.aspectConstraint?.isActive = false
            let ratio = nativeAd.mediaContent.aspectRatio > 0 ? CGFloat(nativeAd.mediaContent.aspectRatio) : 16.0 / 9.0
            let constraint = mediaView.widthAnchor.constraint(equalTo: mediaView.heightAnchor, multiplier: ratio)
            constraint.isActive = true
            context.coordinator.aspectConstraint = constraint
            mediaView.mediaContent = nativeAd.mediaContent
        }
        // Must be set last, after every asset view above is assigned -
        // this is what actually activates AdMob's click/impression
        // tracking on the views just registered.
        adView.nativeAd = nativeAd
    }

    final class Coordinator {
        var aspectConstraint: NSLayoutConstraint?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
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
