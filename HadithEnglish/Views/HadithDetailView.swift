import SwiftUI

struct HadithDetailView: View {
    let subject: HadithSubject
    var favoritesOnly: Bool = false
    @EnvironmentObject private var lastRead: LastReadStore
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var adManager: AdManager

    /// Live-filtered (not a snapshot) so swiping to remove a favorite here
    /// updates the list immediately, same as the old flat Favorites screen did.
    private var displayedHadiths: [HadithEntry] {
        guard favoritesOnly else { return subject.hadiths }
        return subject.hadiths.filter { favorites.isFavorite($0.id) }
    }

    var body: some View {
        List {
            ForEach(Array(displayedHadiths.enumerated()), id: \.element.id) { index, entry in
                if favoritesOnly {
                    HadithCardView(entry: entry)
                        .padding(12)
                        .background(Color("CardBackground"))
                        .cornerRadius(12)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .swipeActions {
                            Button(role: .destructive) {
                                favorites.remove(entry.id)
                            } label: {
                                Label(languageStore.strings.removeAction, systemImage: "star.slash")
                            }
                        }
                } else {
                    HadithCardView(entry: entry)
                        .listRowBackground(Color("CardBackground"))
                    if (index + 1) % 8 == 0 {
                        NativeAdCard()
                            .listRowBackground(Color("CardBackground"))
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(subject.trimmedName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !favoritesOnly {
                lastRead.recordVisit(to: subject)
                adManager.categoryEntered()
            }
        }
        .onDisappear {
            if !favoritesOnly {
                adManager.categoryExited()
            }
        }
        .overlay {
            if favoritesOnly && displayedHadiths.isEmpty {
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
}
