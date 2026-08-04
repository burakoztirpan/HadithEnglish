import Foundation
import SwiftUI

enum HadithFontDesign: String, CaseIterable, Identifiable {
    case serif, sans, rounded, monospaced

    var id: String { rawValue }

    var design: Font.Design {
        switch self {
        case .serif: return .serif
        case .sans: return .default
        case .rounded: return .rounded
        case .monospaced: return .monospaced
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
