import Foundation

struct HadithEntry: Codable {
    let id: Int
    let hadith: String
}
struct HadithSubject: Codable {
    let name: String
    let hadiths: [HadithEntry]
}

for lang in ["en", "ar", "tr"] {
    let url = URL(fileURLWithPath: "HadithEnglish/hadith_\(lang).json")
    let data = try! Data(contentsOf: url)
    let subjects = try! JSONDecoder().decode([HadithSubject].self, from: data)

    assert(subjects.count == 97, "FAIL(\(lang)): expected 97 subjects, got \(subjects.count)")
    assert(!subjects[0].name.isEmpty, "FAIL(\(lang)): first subject name is empty")
    assert(subjects[0].hadiths.first?.id == 1, "FAIL(\(lang)): first hadith id should be 1")
    assert(subjects[0].hadiths.count == 7, "FAIL(\(lang)): Revelation should have 7 hadiths")

    let total = subjects.reduce(0) { $0 + $1.hadiths.count }
    assert(total == 7252, "FAIL(\(lang)): expected 7252 total hadiths, got \(total)")

    print("OK(\(lang)): \(subjects.count) subjects, \(total) hadiths")
}
