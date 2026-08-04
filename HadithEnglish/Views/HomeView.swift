import SwiftUI

struct HomeView: View {
    let subjects: [HadithSubject]
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var streak: StreakStore
    @EnvironmentObject private var lastRead: LastReadStore
    @EnvironmentObject private var tabRouter: TabRouter

    private static let featuredBookNumbers: [Int] = [2, 3, 78, 80] // Belief, Knowledge, Good Manners, Invocations

    private var allEntries: [(subject: HadithSubject, entry: HadithEntry)] {
        subjects.flatMap { subject in subject.hadiths.map { (subject, $0) } }
    }

    private var dayOfYear: Int {
        Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
    }

    private var hadithOfTheDay: (subject: HadithSubject, entry: HadithEntry)? {
        let all = allEntries
        guard !all.isEmpty else { return nil }
        return all[dayOfYear % all.count]
    }

    private var todaysSelection: [(subject: HadithSubject, entry: HadithEntry)] {
        let all = allEntries
        guard all.count > 1 else { return [] }
        let first = (dayOfYear * 7 + 3) % all.count
        let second = (dayOfYear * 13 + 11) % all.count
        return [all[first], all[second]]
    }

    private var featuredTopics: [HadithSubject] {
        Self.featuredBookNumbers.compactMap { number in
            subjects.first { $0.bookNumber == number }
        }
    }

    private var continueReadingSubject: HadithSubject? {
        guard let name = lastRead.subjectName else { return nil }
        return subjects.first { $0.name == name }
    }

    private var greeting: (text: String, icon: String) {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return (languageStore.strings.goodMorning, "sun.max.fill")
        case 12..<18: return (languageStore.strings.goodAfternoon, "cloud.sun.fill")
        default: return (languageStore.strings.goodEvening, "moon.stars.fill")
        }
    }

    private var hijriDateText: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.locale = Locale(identifier: languageStore.language.rawValue)
        formatter.dateFormat = "d MMMM y"
        return formatter.string(from: Date())
    }

    private var gregorianDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageStore.language.rawValue)
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    headerSection
                    if subjects.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else {
                        if let today = hadithOfTheDay {
                            hadithOfTheDaySection(today)
                        }
                        quickAccessSection
                        if !featuredTopics.isEmpty {
                            featuredTopicsSection
                        }
                        if !todaysSelection.isEmpty {
                            todaysSelectionSection
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle(languageStore.strings.tabHome)
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(verbatim: greeting.text)
                        .font(.title2).bold()
                    Image(systemName: greeting.icon)
                        .foregroundColor(Color("AccentColor"))
                }
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(Color("AccentColor"))
                    Text(verbatim: "\(streak.count) \(languageStore.strings.dayStreak)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(hijriDateText)
                    .font(.subheadline)
                Text(gregorianDateText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func hadithOfTheDaySection(_ item: (subject: HadithSubject, entry: HadithEntry)) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(languageStore.strings.hadithOfTheDay.uppercased())
                .font(.caption).bold()
                .foregroundColor(.secondary)
            HadithCardView(entry: item.entry, subtitle: item.subject.trimmedName)
                .padding(12)
                .background(Color("CardBackground"))
                .cornerRadius(12)
        }
    }

    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(languageStore.strings.quickAccess.uppercased())
                .font(.caption).bold()
                .foregroundColor(.secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink(destination: HadithDetailView(subject: subjects.randomElement() ?? subjects[0])) {
                    quickAccessTile(icon: "shuffle", label: languageStore.strings.randomHadith)
                }
                .disabled(subjects.isEmpty)

                Button {
                    tabRouter.selectedTab = .favorites
                } label: {
                    quickAccessTile(icon: "heart.fill", label: languageStore.strings.myFavorites)
                }

                NavigationLink(destination: HadithDetailView(subject: continueReadingSubject ?? subjects.first ?? subjects[0])) {
                    quickAccessTile(icon: "bookmark.fill", label: languageStore.strings.continueReading)
                }
                .disabled(subjects.isEmpty)

                Button {
                    tabRouter.selectedTab = .hadiths
                } label: {
                    quickAccessTile(icon: "magnifyingglass", label: languageStore.strings.searchHadith)
                }
            }
        }
    }

    private func quickAccessTile(icon: String, label: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color("AccentColor"))
            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(12)
        .background(Color("CardBackground"))
        .cornerRadius(12)
    }

    private var featuredTopicsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(languageStore.strings.featuredTopics.uppercased())
                .font(.caption).bold()
                .foregroundColor(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(featuredTopics) { topic in
                        NavigationLink(destination: HadithDetailView(subject: topic)) {
                            HStack(spacing: 6) {
                                Image(systemName: topic.icon)
                                Text(topic.trimmedName)
                            }
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color("CardBackground"))
                            .cornerRadius(20)
                        }
                    }
                }
            }
        }
    }

    private var todaysSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(languageStore.strings.todaysSelection.uppercased())
                .font(.caption).bold()
                .foregroundColor(.secondary)
            VStack(spacing: 0) {
                ForEach(Array(todaysSelection.enumerated()), id: \.offset) { _, item in
                    NavigationLink(destination: HadithDetailView(subject: item.subject)) {
                        HStack(alignment: .top, spacing: 8) {
                            Text(verbatim: "#\(item.entry.id)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(item.entry.trimmedText)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
    }
}
