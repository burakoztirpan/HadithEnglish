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
                        }
                    } header: {
                        HStack(spacing: 6) {
                            Image(systemName: group.subject.icon)
                            Text(group.subject.trimmedName)
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(Color("AccentColor"))
                        .textCase(nil)
                        .padding(.horizontal, 4)
                        .padding(.top, 8)
                        .padding(.bottom, 2)
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
