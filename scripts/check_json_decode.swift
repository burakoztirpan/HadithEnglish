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

// Entries with zero text (46 in Turkish, 4 each in English/Arabic, 657 in
// Indonesian, 280 in Urdu - the source translation simply never covers these
// ids in that language) and, in Turkish only, 11 more whose narration
// genuinely cuts off mid-thought in the source (e.g. a promised dua/verse
// that never appears) are excluded during conversion - genuine gaps in the
// open-source translation, not something fixable - so expected totals
// differ per language.
let expectedTotals = ["en": 7248, "ar": 7248, "tr": 7195, "id": 6595, "ur": 6972]

for lang in ["en", "ar", "tr", "id", "ur"] {
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
