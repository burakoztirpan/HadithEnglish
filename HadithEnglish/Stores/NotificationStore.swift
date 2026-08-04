import Foundation
import UserNotifications

/// Schedules a local notification carrying that day's "Hadith of the Day" at
/// a user-chosen time. iOS local notifications can't compute content at fire
/// time, so instead of one repeating notification we schedule one concrete
/// notification per upcoming day (using the same HadithOfDay pick the Home
/// screen shows), refreshed periodically so the window never runs out.
final class NotificationStore: ObservableObject {
    private static let enabledKey = "DailyHadithNotificationEnabled"
    private static let timeKey = "DailyHadithNotificationTime"
    private static let scheduledDaysAhead = 30
    private static let identifierPrefix = "hadithOfDay-"

    @Published var isEnabled: Bool {
        didSet {
            guard oldValue != isEnabled else { return }
            defaults.set(isEnabled, forKey: Self.enabledKey)
            if isEnabled {
                requestAuthorizationAndSchedule()
            } else {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
        }
    }

    @Published var time: Date {
        didSet {
            defaults.set(time, forKey: Self.timeKey)
            if isEnabled { reschedule() }
        }
    }

    private let defaults: UserDefaults
    private var subjects: [HadithSubject] = []
    private var notificationTitle = "Hadith of the Day"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isEnabled = defaults.bool(forKey: Self.enabledKey)
        if let storedTime = defaults.object(forKey: Self.timeKey) as? Date {
            time = storedTime
        } else {
            var comps = DateComponents()
            comps.hour = 8
            comps.minute = 0
            time = Calendar.current.date(from: comps) ?? Date()
        }
    }

    /// Called whenever the loaded hadith set or the active language changes,
    /// so a pending reschedule always reflects the current language's text.
    func configure(subjects: [HadithSubject], title: String) {
        self.subjects = subjects
        self.notificationTitle = title
        if isEnabled { reschedule() }
    }

    private func requestAuthorizationAndSchedule() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            guard granted else { return }
            DispatchQueue.main.async { self?.reschedule() }
        }
    }

    private func reschedule() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard !subjects.isEmpty else { return }

        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        let now = Date()

        for offset in 0..<Self.scheduledDaysAhead {
            guard let targetDay = calendar.date(byAdding: .day, value: offset, to: now),
                  let item = HadithOfDay.pick(from: subjects, on: targetDay) else { continue }

            var fireComponents = calendar.dateComponents([.year, .month, .day], from: targetDay)
            fireComponents.hour = timeComponents.hour
            fireComponents.minute = timeComponents.minute
            guard let fireDate = calendar.date(from: fireComponents), fireDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = notificationTitle
            content.body = String(item.entry.trimmedText.prefix(200))
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
                repeats: false
            )
            let request = UNNotificationRequest(identifier: "\(Self.identifierPrefix)\(offset)", content: content, trigger: trigger)
            center.add(request)
        }
    }
}
