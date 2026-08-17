import SwiftUI

struct HadithDetailView: View {
    let subject: HadithSubject
    var favoritesOnly: Bool = false
    /// Set when arriving from search - scrolls straight to the hadith that
    /// matched instead of leaving the user to hunt for it in a 90+ item list.
    var scrollToEntryID: Int? = nil
    @EnvironmentObject private var lastRead: LastReadStore
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var adManager: AdManager
    @EnvironmentObject private var removeAdsStore: RemoveAdsStore
    @EnvironmentObject private var consentManager: ConsentManager

    /// Live-filtered (not a snapshot) so swiping to remove a favorite here
    /// updates the list immediately, same as the old flat Favorites screen did.
    private var displayedHadiths: [HadithEntry] {
        guard favoritesOnly else { return subject.hadiths }
        return subject.hadiths.filter { favorites.isFavorite($0.id) }
    }

    var body: some View {
        ScrollViewReader { proxy in
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
                            .onAppear {
                                // Recorded per-row (not once for the whole
                                // view) so "Continue Reading" returns to the
                                // specific hadith the user actually scrolled
                                // to, not just the top of this subject.
                                lastRead.recordVisit(to: subject, entry: entry)
                            }
                        if !removeAdsStore.isPurchased && consentManager.canRequestAds && (index + 1) % 8 == 0 {
                            NativeAdCard()
                                .listRowBackground(Color("CardBackground"))
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .appScreenBackground()
            .navigationTitle(subject.trimmedName)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if !favoritesOnly, !removeAdsStore.isPurchased {
                    adManager.categoryEntered()
                }
                if let scrollToEntryID {
                    // A List with 90+ rows (plus the Material-heavy card
                    // style) doesn't always have the target row laid out
                    // yet at 0.1s - this is a known ScrollViewReader/List
                    // race, not a one-off. Two attempts a beat apart covers
                    // it without a visible double-jump (the first is a
                    // no-op when it fires too early).
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            proxy.scrollTo(scrollToEntryID, anchor: .top)
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        withAnimation {
                            proxy.scrollTo(scrollToEntryID, anchor: .top)
                        }
                    }
                }
            }
            .onDisappear {
                if !favoritesOnly && !removeAdsStore.isPurchased {
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
}
