import Foundation

struct HadithEntry: Codable {
    let id: Int
    let hadith: String
}
struct HadithSubject: Codable {
    let bookNumber: Int
    let name: String
    let hadiths: [HadithEntry]
}

// Entries with zero text (46 in Turkish, 4 each in English/Arabic - genuine
// gaps in the open-source translations, not something fixable) are excluded
// during conversion, so expected totals differ slightly per language.
let expectedTotals = ["en": 7248, "ar": 7248, "tr": 7206]

for lang in ["en", "ar", "tr"] {
    let url = URL(fileURLWithPath: "HadithEnglish/hadith_\(lang).json.zlib")
    let compressed = try! Data(contentsOf: url)
    let data = try! (compressed as NSData).decompressed(using: .zlib) as Data
    let subjects = try! JSONDecoder().decode([HadithSubject].self, from: data)

    assert(subjects.count == 97, "FAIL(\(lang)): expected 97 subjects, got \(subjects.count)")
    assert(!subjects[0].name.isEmpty, "FAIL(\(lang)): first subject name is empty")
    assert(subjects[0].bookNumber == 1, "FAIL(\(lang)): first subject bookNumber should be 1")
    assert(subjects[0].hadiths.first?.id == 1, "FAIL(\(lang)): first hadith id should be 1")

    let total = subjects.reduce(0) { $0 + $1.hadiths.count }
    assert(total == expectedTotals[lang], "FAIL(\(lang)): expected \(expectedTotals[lang]!) total hadiths, got \(total)")

    let emptyCount = subjects.flatMap { $0.hadiths }.filter { $0.hadith.trimmingCharacters(in: .whitespaces).isEmpty }.count
    assert(emptyCount == 0, "FAIL(\(lang)): \(emptyCount) hadiths have empty text")

    print("OK(\(lang)): \(subjects.count) subjects, \(total) hadiths, \(compressed.count) compressed bytes")
}
