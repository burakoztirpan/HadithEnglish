import Foundation

final class LastReadStore: ObservableObject {
    private static let defaultsKey = "LastReadSubjectName"

    @Published private(set) var subjectName: String?

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        subjectName = defaults.string(forKey: Self.defaultsKey)
    }

    func recordVisit(to subject: HadithSubject) {
        subjectName = subject.name
        defaults.set(subject.name, forKey: Self.defaultsKey)
    }
}
