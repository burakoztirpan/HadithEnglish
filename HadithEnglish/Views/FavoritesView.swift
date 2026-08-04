import SwiftUI

struct FavoritesView: View {
    let subjects: [HadithSubject]
    @EnvironmentObject private var favorites: FavoritesStore

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
                        .swipeActions {
                            Button(role: .destructive) {
                                favorites.remove(entry.id)
                            } label: {
                                Label("Remove", systemImage: "star.slash")
                            }
                        }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Favorites")
            .overlay {
                if favoriteEntries.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "star")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No favorites yet")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
