import SwiftUI

struct FavoritesView: View {
    let subjects: [HadithSubject]
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var languageStore: LanguageStore

    private var favoriteEntries: [HadithEntry] {
        subjects
            .flatMap(\.hadiths)
            .filter { favorites.isFavorite($0.id) }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(favoriteEntries) { entry in
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
            }
            .listStyle(.plain)
            .navigationTitle(languageStore.strings.favoritesTitle)
            .overlay {
                if favoriteEntries.isEmpty {
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
