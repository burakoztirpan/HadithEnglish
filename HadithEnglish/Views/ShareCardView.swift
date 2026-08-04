import SwiftUI

/// The postcard-style layout rendered to a UIImage for sharing. Text sits in
/// a translucent panel over the lower half of the background - a fixed
/// panel (rather than e.g. a gradient) so contrast holds regardless of
/// which of the 10 backgrounds (some light, some dark) is picked.
struct ShareCardView: View {
    let text: String
    let subtitle: String
    let background: ShareCardBackground
    let appName: String

    static let size = CGSize(width: 1080, height: 1920)
    private static let textCharacterLimit = 260

    private var displayText: String {
        if text.count > Self.textCharacterLimit {
            return String(text.prefix(Self.textCharacterLimit)) + "…"
        }
        return text
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
                Spacer(minLength: Self.size.height * 0.42)
                VStack(spacing: 22) {
                    Text(displayText)
                        .font(.system(size: 42, weight: .medium, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                    Text(subtitle)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                }
                .padding(52)
                .background(RoundedRectangle(cornerRadius: 28).fill(Color.black.opacity(0.45)))
                .padding(.horizontal, 64)
                Spacer(minLength: 56)
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
    static func render(text: String, subtitle: String, background: ShareCardBackground, appName: String) -> UIImage? {
        let view = ShareCardView(text: text, subtitle: subtitle, background: background, appName: appName)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        return renderer.uiImage
    }
}
