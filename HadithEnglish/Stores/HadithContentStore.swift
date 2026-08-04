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
        cache[language] = decoded
        subjects = decoded
    }
}
