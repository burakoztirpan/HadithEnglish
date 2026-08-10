import Foundation

final class HadithContentStore: ObservableObject {
    @Published private(set) var subjects: [HadithSubject] = []
    private var cache: [AppLanguage: [HadithSubject]] = [:]

    func load(_ language: AppLanguage) {
        if let cached = cache[language] {
            subjects = cached
            return
        }
        guard let url = Bundle.main.url(forResource: "\(language.hadithResourceName).json", withExtension: "zlib"),
              let compressed = try? Data(contentsOf: url),
              let data = try? (compressed as NSData).decompressed(using: .zlib) as Data,
              let decoded = try? JSONDecoder().decode([HadithSubject].self, from: data)
        else {
            subjects = []
            return
        }
        let sorted = Self.sortedAlphabetically(decoded, for: language)
        cache[language] = sorted
        subjects = sorted
    }

    /// Sorted per the language's own collation rules (not a fixed locale) -
    /// e.g. Turkish dotted/dotless I only sorts correctly against a "tr"
    /// locale, and this must match whatever language the subjects were
    /// loaded in, not the device's system locale.
    private static func sortedAlphabetically(_ subjects: [HadithSubject], for language: AppLanguage) -> [HadithSubject] {
        let locale = Locale(identifier: language.rawValue)
        return subjects.sorted {
            $0.trimmedName.compare($1.trimmedName, options: [], range: nil, locale: locale) == .orderedAscending
        }
    }
}
