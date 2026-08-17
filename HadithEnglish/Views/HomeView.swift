import SwiftUI

struct HomeView: View {
    let subjects: [HadithSubject]
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var streak: StreakStore
    @EnvironmentObject private var lastRead: LastReadStore
    @EnvironmentObject private var tabRouter: TabRouter
    @Environment(\.colorScheme) private var colorScheme

    private var allEntries: [(subject: HadithSubject, entry: HadithEntry)] {
        subjects.flatMap { subject in subject.hadiths.map { (subject, $0) } }
    }

    private var daySeed: Int {
        HadithOfDay.seed(for: Date(), offset: 0)
    }

    private var hadithOfTheDay: (subject: HadithSubject, entry: HadithEntry)? {
        HadithOfDay.pick(from: subjects, on: Date())
    }

    private var todaysSelection: [(subject: HadithSubject, entry: HadithEntry)] {
        let all = allEntries
        guard all.count > 1 else { return [] }
        var rng = DailySeededGenerator(seed: daySeed &+ 2)
        return Array(all.shuffled(using: &rng).prefix(2))
    }

    private var featuredTopics: [HadithSubject] {
        guard !subjects.isEmpty else { return [] }
        var rng = DailySeededGenerator(seed: daySeed &+ 3)
        return Array(subjects.shuffled(using: &rng).prefix(4))
    }

    private var continueReadingSubject: HadithSubject? {
        guard let name = lastRead.subjectName else { return nil }
        return subjects.first { $0.name == name }
    }

    /// Picked uniformly across every hadith (not subject-then-entry, which
    /// would over-favor hadiths in small subjects) so "Random Hadith" means
    /// what it says - a random hadith, not just a random category.
    private var randomEntry: (subject: HadithSubject, entry: HadithEntry)? {
        allEntries.randomElement()
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
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
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
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .background(Color("AppBackground").ignoresSafeArea())
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
                        .foregroundColor(Color("HeadingText"))
                    Image(systemName: greeting.icon)
                        .foregroundColor(Color("AccentColor"))
                }
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(Color("AccentColor"))
                    Text(verbatim: "\(streak.count) \(languageStore.strings.dayStreak)")
                        .font(.subheadline)
                        .foregroundColor(Color("SubtleText"))
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(hijriDateText)
                    .font(.subheadline)
                    .foregroundColor(Color("HeadingText"))
                Text(gregorianDateText)
                    .font(.caption)
                    .foregroundColor(Color("SubtleText"))
            }
        }
    }

    private func hadithOfTheDaySection(_ item: (subject: HadithSubject, entry: HadithEntry)) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(languageStore.strings.hadithOfTheDay.uppercased())
                .font(.caption).bold()
                .foregroundColor(Color("HeadingText"))
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
                .foregroundColor(Color("HeadingText"))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink(destination: HadithDetailView(subject: randomEntry?.subject ?? subjects[0], scrollToEntryID: randomEntry?.entry.id)) {
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

                NavigationLink(destination: HadithSearchView(subjects: subjects)) {
                    quickAccessTile(icon: "magnifyingglass", label: languageStore.strings.searchHadith)
                }
            }
        }
    }

    private func quickAccessTile(icon: String, label: String) -> some View {
        let tileForeground: Color = colorScheme == .light ? .white : Color("AccentColor")
        return HStack {
            Image(systemName: icon)
                .foregroundColor(tileForeground)
            Text(label)
                .font(.subheadline)
                .foregroundColor(colorScheme == .light ? .white : .primary)
            Spacer()
        }
        .padding(12)
        .background(colorScheme == .light ? Color("AccentColor") : Color("CardBackground"))
        .cornerRadius(12)
    }

    private var featuredTopicsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(languageStore.strings.featuredTopics.uppercased())
                .font(.caption).bold()
                .foregroundColor(Color("HeadingText"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(featuredTopics) { topic in
                        NavigationLink(destination: HadithDetailView(subject: topic)) {
                            HStack(spacing: 6) {
                                Image(systemName: topic.icon)
                                Text(topic.trimmedName)
                            }
                            .font(.subheadline)
                            .foregroundColor(colorScheme == .light ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(colorScheme == .light ? Color("AccentColor") : Color("CardBackground"))
                            .cornerRadius(12)
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
                .foregroundColor(Color("HeadingText"))
            VStack(spacing: 10) {
                ForEach(Array(todaysSelection.enumerated()), id: \.offset) { _, item in
                    NavigationLink(destination: HadithDetailView(subject: item.subject)) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: item.subject.icon)
                                .foregroundColor(Color("AccentColor"))
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(verbatim: "\(item.subject.trimmedName) · #\(item.entry.id)")
                                    .font(.caption)
                                    .foregroundColor(Color("SubtleText"))
                                Text(item.entry.trimmedText)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color("CardBackground"))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
