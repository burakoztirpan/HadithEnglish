import SwiftUI

@main
struct HadithEnglishApp: App {
    @StateObject private var favorites = FavoritesStore()
    @StateObject private var languageStore = LanguageStore()
    @StateObject private var content = HadithContentStore()
    @StateObject private var streak = StreakStore()
    @StateObject private var lastRead = LastReadStore()
    @StateObject private var tabRouter = TabRouter()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            TabView(selection: $tabRouter.selectedTab) {
                HomeView(subjects: content.subjects)
                    .tabItem { Label(languageStore.strings.tabHome, systemImage: "house") }
                    .tag(AppTab.home)
                SubjectsListView(subjects: content.subjects)
                    .tabItem { Label(languageStore.strings.tabHadiths, systemImage: "book") }
                    .tag(AppTab.hadiths)
                FavoritesView(subjects: content.subjects)
                    .tabItem { Label(languageStore.strings.tabFavorites, systemImage: "star") }
                    .tag(AppTab.favorites)
                SettingsView()
                    .tabItem { Label(languageStore.strings.tabSetup, systemImage: "gearshape") }
                    .tag(AppTab.setup)
            }
            .id(languageStore.language)
            .environmentObject(favorites)
            .environmentObject(languageStore)
            .environmentObject(streak)
            .environmentObject(lastRead)
            .environmentObject(tabRouter)
            .environment(\.layoutDirection, languageStore.language.isRightToLeft ? .rightToLeft : .leftToRight)
            .accentColor(Color("AccentColor"))
            .onAppear { content.load(languageStore.language) }
            .onChange(of: languageStore.language) { newValue in
                content.load(newValue)
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    streak.evaluate()
                }
            }
        }
    }
}
