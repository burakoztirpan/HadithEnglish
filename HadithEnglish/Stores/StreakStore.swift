import Foundation

final class StreakStore: ObservableObject {
    private static let countKey = "StreakCount"
    private static let lastOpenDateKey = "StreakLastOpenDate"

    @Published private(set) var count: Int = 1

    private let defaults: UserDefaults
    private let calendar = Calendar(identifier: .gregorian)

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        evaluate()
    }

    /// Re-checks the day boundary. Called at init (cold launch) and whenever
    /// the app becomes active again (the app can sit backgrounded-but-alive
    /// overnight without a cold relaunch, and init() won't re-run for that -
    /// only a fresh evaluate() on foreground catches the day change).
    func evaluate(today: Date = Date()) {
        let storedCount = defaults.integer(forKey: Self.countKey)

        guard let lastOpenDate = defaults.object(forKey: Self.lastOpenDateKey) as? Date else {
            count = 1
            persist(count: 1, date: today)
            return
        }

        let daysBetween = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: lastOpenDate),
            to: calendar.startOfDay(for: today)
        ).day ?? 0

        switch daysBetween {
        case ...0:
            count = max(storedCount, 1)
        case 1:
            count = storedCount + 1
            persist(count: count, date: today)
        default:
            count = 1
            persist(count: 1, date: today)
        }
    }

    private func persist(count: Int, date: Date) {
        defaults.set(count, forKey: Self.countKey)
        defaults.set(date, forKey: Self.lastOpenDateKey)
    }
}
