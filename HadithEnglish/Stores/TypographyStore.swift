import Foundation
import SwiftUI

/// Named font PostScript names verified against the actual installed iOS
/// runtime font list (UIFont.familyNames / UIFont.fontNames(forFamilyName:))
/// before use - a wrong PostScript name silently falls back to a generic
/// font instead of erroring, so guessing isn't safe here.
enum HadithFontDesign: String, CaseIterable, Identifiable {
    case serif, newYork, palatino, baskerville, sans, avenirNext, rounded, monospaced

    var id: String { rawValue }

    func font(size: CGFloat) -> Font {
        switch self {
        case .serif: return .custom("Georgia", size: size)
        case .newYork: return .system(size: size, design: .serif)
        case .palatino: return .custom("Palatino-Roman", size: size)
        case .baskerville: return .custom("Baskerville", size: size)
        case .sans: return .system(size: size, design: .default)
        case .avenirNext: return .custom("AvenirNext-Regular", size: size)
        case .rounded: return .system(size: size, design: .rounded)
        case .monospaced: return .system(size: size, design: .monospaced)
        }
    }
}

final class TypographyStore: ObservableObject {
    private static let fontDesignKey = "HadithFontDesign"
    private static let fontSizeKey = "HadithFontSize"

    static let minFontSize: Double = 14
    static let maxFontSize: Double = 26
    static let defaultFontSize: Double = 17

    @Published var fontDesign: HadithFontDesign {
        didSet { defaults.set(fontDesign.rawValue, forKey: Self.fontDesignKey) }
    }

    @Published var fontSize: Double {
        didSet { defaults.set(fontSize, forKey: Self.fontSizeKey) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let raw = defaults.string(forKey: Self.fontDesignKey), let stored = HadithFontDesign(rawValue: raw) {
            fontDesign = stored
        } else {
            fontDesign = .serif
        }
        // 0 means "never set" (UserDefaults.double(forKey:) returns 0 for a missing key).
        let storedSize = defaults.double(forKey: Self.fontSizeKey)
        fontSize = storedSize == 0 ? Self.defaultFontSize : storedSize
    }
}
