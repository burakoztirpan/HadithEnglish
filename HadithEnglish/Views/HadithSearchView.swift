import SwiftUI

/// Full-text search across every hadith's actual content (and subject
/// name, as a bonus match), not just subject names the way SubjectsListView's
/// own search bar works - that's what "search hadith" from Home implies,
/// and browsing 90+ category names to find one hadith isn't a real search.
struct HadithSearchView: View {
    let subjects: [HadithSubject]
    @EnvironmentObject private var languageStore: LanguageStore
    @State private var searchText = ""

    private var results: [(subject: HadithSubject, entry: HadithEntry)] {
        guard !searchText.isEmpty else { return [] }
        return subjects.flatMap { subject in
            subject.hadiths.compactMap { entry in
                let matches = entry.trimmedText.localizedCaseInsensitiveContains(searchText)
                    || subject.trimmedName.localizedCaseInsensitiveContains(searchText)
                return matches ? (subject, entry) : nil
            }
        }
    }

    var body: some View {
        List(Array(results.enumerated()), id: \.offset) { _, item in
            NavigationLink(destination: HadithDetailView(subject: item.subject, scrollToEntryID: item.entry.id)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: "\(item.subject.trimmedName) · #\(item.entry.id)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(item.entry.trimmedText)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
        .overlay {
            if !searchText.isEmpty && results.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text(languageStore.strings.noSearchResults)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(languageStore.strings.searchHadith)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: languageStore.strings.searchHadithsPrompt)
    }
}
