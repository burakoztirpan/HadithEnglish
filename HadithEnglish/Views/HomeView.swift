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
                            VStack(spacing: 12) {
                                ProgressView()
                                Text(languageStore.strings.loadingHadiths)
                                    .font(.subheadline)
                                    .foregroundColor(Color("SubtleText"))
                            }
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
                    .padding(.bottom, 100)
                }
            }
            .appScreenBackground()
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
            // Deliberately one step larger than the other section eyebrows
            // (Quick Access, Featured Topics, Today's Selection) - this is
            // the one daily ritual action, not a browse entry point, and it
            // should read as the primary section at a glance, not equal
            // weight with the other three.
            Text(languageStore.strings.hadithOfTheDay.uppercased())
                .font(.subheadline).bold()
                .foregroundColor(Color("HeadingText"))
            HadithCardView(entry: item.entry, subtitle: item.subject.trimmedName)
                .padding(12)
                .cardStyle()
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

                NavigationLink(destination: HadithDetailView(
                    subject: continueReadingSubject ?? subjects.first ?? subjects[0],
                    scrollToEntryID: continueReadingSubject != nil ? lastRead.entryID : nil
                )) {
                    quickAccessTile(
                        icon: "bookmark.fill",
                        label: languageStore.strings.continueReading,
                        isEnabled: continueReadingSubject != nil
                    )
                }
                // Only meaningful once there's an actual last-read subject -
                // otherwise it silently drops a first-time user into an
                // arbitrary subject that has nothing to do with "continuing."
                // isEnabled is passed explicitly to quickAccessTile above
                // rather than relied on via the environment - NavigationLink's
                // .disabled() does block the tap, but empirically (pixel-
                // sampled against an enabled tile) it does not reliably
                // propagate isEnabled to custom label content here.
                .disabled(continueReadingSubject == nil)

                NavigationLink(destination: HadithSearchView(subjects: subjects)) {
                    quickAccessTile(icon: "magnifyingglass", label: languageStore.strings.searchHadith)
                }
            }
        }
    }

    private func quickAccessTile(icon: String, label: String, isEnabled: Bool = true) -> some View {
        let tileForeground: Color = colorScheme == .light ? .white : Color("AccentColor")
        return HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(tileForeground)
            Text(label)
                .font(.subheadline)
                .foregroundColor(colorScheme == .light ? .white : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            if colorScheme == .light {
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    Rectangle().fill(Color("AccentColor").opacity(0.85))
                }
            } else {
                Color("CardBackground")
            }
        }
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .overlay {
            // A dimming .opacity() on the whole tile is unreliable here -
            // .ultraThinMaterial composites its own blur/vibrancy against
            // the real layer behind it and doesn't reliably fade the same
            // way a flat color does. A scrim drawn on top always reads as
            // "disabled" regardless of what's underneath.
            if !isEnabled {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.35))
            }
        }
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
                            .foregroundColor(colorScheme == .light ? Color("FeaturedTopicText") : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(colorScheme == .light ? Color("FeaturedTopicBackground") : Color("CardBackground"))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        colorScheme == .light ? Color("FeaturedTopicText").opacity(0.15) : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                            .accessibilityElement(children: .combine)
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
                        .padding(16)
                        .cardStyle()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
