import Foundation

final class LastReadStore: ObservableObject {
    private static let subjectKey = "LastReadSubjectName"
    private static let entryIDKey = "LastReadEntryID"

    @Published private(set) var subjectName: String?
    @Published private(set) var entryID: Int?

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        subjectName = defaults.string(forKey: Self.subjectKey)
        entryID = defaults.object(forKey: Self.entryIDKey) != nil ? defaults.integer(forKey: Self.entryIDKey) : nil
    }

    /// Records the specific hadith the user actually scrolled to, not just
    /// which subject they opened - "Continue Reading" should return to the
    /// exact spot, not just the top of a 90+ item list.
    func recordVisit(to subject: HadithSubject, entry: HadithEntry) {
        subjectName = subject.name
        entryID = entry.id
        defaults.set(subject.name, forKey: Self.subjectKey)
        defaults.set(entry.id, forKey: Self.entryIDKey)
    }
}
