import SwiftUI

struct FavoritesView: View {
    let subjects: [HadithSubject]
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var languageStore: LanguageStore

    private var favoritesBySubject: [(subject: HadithSubject, entries: [HadithEntry])] {
        subjects.compactMap { subject in
            let entries = subject.hadiths.filter { favorites.isFavorite($0.id) }
            return entries.isEmpty ? nil : (subject, entries)
        }
    }

    private var isEmpty: Bool {
        favoritesBySubject.isEmpty
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(favoritesBySubject, id: \.subject.id) { group in
                    Section {
                        ForEach(group.entries) { entry in
                            HadithCardView(entry: entry)
                                .listRowBackground(Color("CardBackground"))
                                .swipeActions {
                                    Button(role: .destructive) {
                                        favorites.remove(entry.id)
                                    } label: {
                                        Label(languageStore.strings.removeAction, systemImage: "star.slash")
                                    }
                                }
                        }
                    } header: {
                        Label(group.subject.trimmedName, systemImage: group.subject.icon)
                    }
                }
            }
            .listStyle(.plain)
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
