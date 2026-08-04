import Foundation

final class StreakStore: ObservableObject {
    private static let countKey = "StreakCount"
    private static let lastOpenDateKey = "StreakLastOpenDate"

    @Published private(set) var count: Int

    private let defaults: UserDefaults
    private let calendar = Calendar(identifier: .gregorian)

    init(defaults: UserDefaults = .standard, today: Date = Date()) {
        self.defaults = defaults
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
        case 0:
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
