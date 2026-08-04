import Foundation

/// Deterministic per-day shuffle (SplitMix64) - not cryptographic, just needs
/// to be stable for a given seed. Chosen specifically (over e.g. xorshift)
/// because it decorrelates well for adjacent/sequential seeds, which matters
/// here: hadithOfTheDay, todaysSelection and featuredTopics all derive their
/// seed from the same day by adding a small offset (+1, +2, +3), and a
/// weaker generator produced near-identical shuffles for those neighboring
/// seeds - Today's Selection was rendering the exact same hadith as Hadith
/// of the Day.
struct DailySeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed))
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// Shared by HomeView (what's shown today) and NotificationStore (what gets
/// scheduled for upcoming days) so the notification always matches what the
/// app displays as "Hadith of the Day" once opened.
enum HadithOfDay {
    /// Year+day-of-year so the pick is stable within a day but changes daily.
    static func seed(for date: Date, offset: Int, calendar: Calendar = .current) -> Int {
        let year = calendar.component(.year, from: date)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        return year * 1000 + dayOfYear + offset
    }

    static func pick(from subjects: [HadithSubject], on date: Date) -> (subject: HadithSubject, entry: HadithEntry)? {
        let all = subjects.flatMap { subject in subject.hadiths.map { (subject, $0) } }
        guard !all.isEmpty else { return nil }
        var rng = DailySeededGenerator(seed: seed(for: date, offset: 1))
        return all.shuffled(using: &rng).first
    }
}
