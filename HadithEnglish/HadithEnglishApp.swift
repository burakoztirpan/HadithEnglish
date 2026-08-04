import SwiftUI

@main
struct HadithEnglishApp: App {
    @StateObject private var favorites = FavoritesStore()
    @StateObject private var languageStore = LanguageStore()
    @StateObject private var content = HadithContentStore()

    var body: some Scene {
        WindowGroup {
            TabView {
                SubjectsListView(subjects: content.subjects)
                    .tabItem { Label(languageStore.strings.tabHadiths, systemImage: "book") }
                FavoritesView(subjects: content.subjects)
                    .tabItem { Label(languageStore.strings.tabFavorites, systemImage: "star") }
                SettingsView()
                    .tabItem { Label(languageStore.strings.tabSetup, systemImage: "gearshape") }
            }
            .environmentObject(favorites)
            .environmentObject(languageStore)
            .environment(\.layoutDirection, languageStore.language.isRightToLeft ? .rightToLeft : .leftToRight)
            .accentColor(Color("AccentColor"))
            .onAppear { content.load(languageStore.language) }
            .onChange(of: languageStore.language) { newValue in
                content.load(newValue)
            }
        }
    }
}
