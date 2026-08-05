import UIKit

/// Decides whether a hadith fits the shared card layout (same panel
/// geometry for all 10 backgrounds, so this check only needs to run once
/// per hadith, not per background) and at what font size. Measured with
/// UIKit's NSString boundingRect rather than guessed, since ShareCardView's
/// panel has a hard height budget it must not overflow.
enum ShareCardFit {
    static let minFontSize: CGFloat = 24
    // Was capped at 42, which left short hadiths using only a fraction of
    // the panel's available height - readability (particularly for older
    // users) matters more than restraint here, so this uses whatever room
    // the card actually has.
    static let maxFontSize: CGFloat = 72
    static let subtitleFontSize: CGFloat = 26
    static let panelPadding: CGFloat = 52
    static let panelSpacing: CGFloat = 22
    static let lineSpacing: CGFloat = 8
    static let outerHorizontalPadding: CGFloat = 64

    /// The top 42% of the card is reserved for the background's motif and
    /// the panel must never cover it.
    static var motifBoundary: CGFloat {
        ShareCardView.size.height * 0.42
    }

    /// Vertical budget for the text panel: card height minus the top motif
    /// area, the bottom spacer, the watermark line, and a safety margin for
    /// measurement differences between UIKit's boundingRect and SwiftUI's
    /// actual text layout.
    static var maxPanelHeight: CGFloat {
        let cardHeight = ShareCardView.size.height
        let bottomReserved: CGFloat = 56 + 30 + 48
        let safetyMargin: CGFloat = 40
        return cardHeight - motifBoundary - bottomReserved - safetyMargin
    }

    static var textWidth: CGFloat {
        ShareCardView.size.width - 2 * outerHorizontalPadding - 2 * panelPadding
    }

    /// Largest font size in [minFontSize, maxFontSize] at which `text` +
    /// `subtitle` fit the panel, or nil if even the minimum overflows -
    /// meaning this hadith can't be offered as an image card at all.
    static func fittingFontSize(for text: String, subtitle: String) -> CGFloat? {
        var size = maxFontSize
        while size >= minFontSize {
            if panelHeight(text: text, subtitle: subtitle, fontSize: size) <= maxPanelHeight {
                return size
            }
            size -= 2
        }
        return nil
    }

    /// Exposed (not just used internally by fittingFontSize) so
    /// ShareCardView can position the panel using its exact height instead
    /// of guessing via flexible-space layout tricks.
    static func panelHeight(text: String, subtitle: String, fontSize: CGFloat) -> CGFloat {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.alignment = .center

        let baseDescriptor = UIFont.systemFont(ofSize: fontSize, weight: .medium).fontDescriptor
        let serifDescriptor = baseDescriptor.withDesign(.serif) ?? baseDescriptor
        let textFont = UIFont(descriptor: serifDescriptor, size: fontSize)
        let textHeight = boundingHeight(for: text, font: textFont, paragraphStyle: paragraphStyle)

        let subtitleFont = UIFont.systemFont(ofSize: subtitleFontSize, weight: .semibold)
        let subtitleHeight = boundingHeight(for: subtitle, font: subtitleFont, paragraphStyle: nil)

        return panelPadding * 2 + textHeight + panelSpacing + subtitleHeight
    }

    private static func boundingHeight(for string: String, font: UIFont, paragraphStyle: NSParagraphStyle?) -> CGFloat {
        var attributes: [NSAttributedString.Key: Any] = [.font: font]
        if let paragraphStyle {
            attributes[.paragraphStyle] = paragraphStyle
        }
        let rect = (string as NSString).boundingRect(
            with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        return ceil(rect.height)
    }
}
