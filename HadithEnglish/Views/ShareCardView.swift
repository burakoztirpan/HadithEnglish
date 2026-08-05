import SwiftUI

/// The postcard-style layout rendered to a UIImage for sharing. Text sits in
/// a translucent panel over the lower half of the background - a fixed
/// panel (rather than e.g. a gradient) so contrast holds regardless of
/// which of the 10 backgrounds (some light, some dark) is picked.
///
/// Font size is provided by the caller (see ShareCardFit) rather than fixed
/// or truncated here: the full, untruncated text is always shown, sized to
/// fit the panel's height budget. If the caller can't find a size that fits
/// even at ShareCardFit.minFontSize, the hadith isn't offered as a card at
/// all - that decision happens before this view is ever built.
struct ShareCardView: View {
    let text: String
    let subtitle: String
    let background: ShareCardBackground
    let appName: String
    let fontSize: CGFloat

    static let size = CGSize(width: 1080, height: 1920)

    /// Vertically centers the panel in the whole card - unless that would
    /// put its top edge above the motif-safe boundary (ShareCardFit.
    /// motifBoundary), in which case it's pinned right below the motif
    /// instead. True whole-card centering alone isn't safe: for a panel
    /// near ShareCardFit.maxPanelHeight, the center point sits well above
    /// the boundary and would overlap the background's artwork.
    private var panelTop: CGFloat {
        let panelHeight = ShareCardFit.panelHeight(text: text, subtitle: subtitle, fontSize: fontSize)
        let trueCenterTop = (Self.size.height - panelHeight) / 2
        return max(trueCenterTop, ShareCardFit.motifBoundary)
    }

    var body: some View {
        ZStack {
            if let uiImage = background.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: Self.size.width, height: Self.size.height)
                    .clipped()
            } else {
                Color.black
            }

            VStack(spacing: 0) {
                Color.clear.frame(height: panelTop)
                VStack(spacing: ShareCardFit.panelSpacing) {
                    Text(text)
                        .font(.system(size: fontSize, weight: .medium, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(ShareCardFit.lineSpacing)
                    Text(subtitle)
                        .font(.system(size: ShareCardFit.subtitleFontSize, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                }
                .padding(ShareCardFit.panelPadding)
                .background(RoundedRectangle(cornerRadius: 28).fill(Color.black.opacity(0.45)))
                .padding(.horizontal, ShareCardFit.outerHorizontalPadding)
                Spacer(minLength: 0)
                Text(appName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.bottom, 48)
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
    }
}

@MainActor
enum ShareCardRenderer {
    static func render(text: String, subtitle: String, background: ShareCardBackground, appName: String, fontSize: CGFloat) -> UIImage? {
        let view = ShareCardView(text: text, subtitle: subtitle, background: background, appName: appName, fontSize: fontSize)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        return renderer.uiImage
    }
}
