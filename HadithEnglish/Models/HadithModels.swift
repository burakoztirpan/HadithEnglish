import Foundation

struct HadithEntry: Codable, Identifiable {
    let id: Int
    let hadith: String

    var trimmedText: String {
        hadith.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct HadithSubject: Codable, Identifiable {
    let name: String
    let hadiths: [HadithEntry]

    var id: String { name }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }
}
