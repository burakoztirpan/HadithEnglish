import Foundation
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

final class ThemeStore: ObservableObject {
    private static let defaultsKey = "AppTheme"

    @Published var theme: AppTheme {
        didSet { persist() }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let raw = defaults.string(forKey: Self.defaultsKey), let stored = AppTheme(rawValue: raw) {
            self.theme = stored
        } else {
            self.theme = .system
        }
    }

    private func persist() {
        defaults.set(theme.rawValue, forKey: Self.defaultsKey)
    }
}
