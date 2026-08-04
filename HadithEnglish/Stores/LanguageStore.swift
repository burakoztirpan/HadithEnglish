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
            self.language = .en
        }
    }

    var strings: Strings { language.strings }

    private func persist() {
        defaults.set(language.rawValue, forKey: Self.defaultsKey)
    }
}
