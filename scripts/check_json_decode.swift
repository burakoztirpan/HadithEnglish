import Foundation

struct HadithEntry: Codable {
    let id: Int
    let hadith: String
}
struct HadithSubject: Codable {
    let name: String
    let hadiths: [HadithEntry]
}

let url = URL(fileURLWithPath: CommandLine.arguments[1])
let data = try! Data(contentsOf: url)
let subjects = try! JSONDecoder().decode([HadithSubject].self, from: data)

assert(subjects.count == 88, "FAIL: expected 88 subjects, got \(subjects.count)")
assert(
    subjects[0].name.trimmingCharacters(in: .whitespaces) == "Revelation",
    "FAIL: first subject should be Revelation, got \(subjects[0].name)"
)
assert(subjects[0].hadiths.first?.id == 0, "FAIL: first hadith id should be 0")

print("OK: JSON decode checks passed (\(subjects.count) subjects)")
