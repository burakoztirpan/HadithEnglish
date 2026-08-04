import Foundation

struct HadithEntry: Codable, Identifiable {
    let id: Int
    let hadith: String

    var trimmedText: String {
        hadith.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct HadithSubject: Codable, Identifiable {
    let bookNumber: Int
    let name: String
    let hadiths: [HadithEntry]

    var id: String { name }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    var icon: String {
        BookIcons.icons[bookNumber] ?? "book.closed"
    }
}
