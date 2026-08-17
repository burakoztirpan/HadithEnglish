import SwiftUI

struct FavoritesView: View {
    let subjects: [HadithSubject]
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var languageStore: LanguageStore

    private var favoritedSubjects: [(subject: HadithSubject, count: Int)] {
        subjects.compactMap { subject in
            let count = subject.hadiths.filter { favorites.isFavorite($0.id) }.count
            return count > 0 ? (subject, count) : nil
        }
    }

    private var isEmpty: Bool {
        favoritedSubjects.isEmpty
    }

    var body: some View {
        NavigationView {
            List(favoritedSubjects, id: \.subject.id) { item in
                NavigationLink(destination: HadithDetailView(subject: item.subject, favoritesOnly: true)) {
                    HStack(spacing: 10) {
                        Image(systemName: item.subject.icon)
                            .foregroundColor(Color("AccentColor"))
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.subject.trimmedName)
                                .font(.body)
                            Text(verbatim: "\(item.count) \(languageStore.strings.hadithsSuffix)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .appScreenBackground()
            .navigationTitle(languageStore.strings.favoritesTitle)
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "star")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text(languageStore.strings.noFavoritesYet)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
