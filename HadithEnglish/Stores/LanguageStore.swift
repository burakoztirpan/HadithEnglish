import Foundation
import Combine

final class LanguageStore: ObservableObject {
    private static let defaultsKey = "AppLanguage"

    @Published var language: AppLanguage {
        didSet { persist() }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let raw = defaults.string(forKey: Self.defaultsKey), let stored = AppLanguage(rawValue: raw) {
            self.language = stored
        } else {
            self.language = Self.preferredSupportedLanguage()
        }
    }

    var strings: Strings { language.strings }

    private func persist() {
        defaults.set(language.rawValue, forKey: Self.defaultsKey)
    }

    /// First-launch default: the user's own device language if the app
    /// supports it, English otherwise. `Locale.preferredLanguages` is
    /// ordered by the user's actual preference (e.g. ["tr-TR", "en-US"]),
    /// so this picks the first entry the app has a translation for.
    private static func preferredSupportedLanguage(preferredLanguages: [String] = Locale.preferredLanguages) -> AppLanguage {
        for preferred in preferredLanguages {
            let code = preferred.split(separator: "-").first.map(String.init) ?? preferred
            if let match = AppLanguage(rawValue: code) {
                return match
            }
        }
        return .en
    }
}
