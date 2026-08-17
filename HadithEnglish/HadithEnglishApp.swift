import SwiftUI
import UIKit
import GoogleMobileAds

@main
struct HadithEnglishApp: App {
    init() {
        let appearance = UITabBarAppearance()
        // Default (not opaque) background keeps the system's own translucent
        // blur/vibrancy material - the standard frosted tab bar look, matching
        // the rest of the app's glass surfaces instead of a flat cream block.
        appearance.configureWithDefaultBackground()
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(named: "AccentColor")
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(named: "AccentColor") ?? .systemGreen
        ]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(named: "TabBarInactive")
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(named: "TabBarInactive") ?? .darkGray
        ]
        appearance.selectionIndicatorTintColor = UIColor(named: "TabBarPill")
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    @StateObject private var favorites = FavoritesStore()
    @StateObject private var languageStore = LanguageStore()
    @StateObject private var content = HadithContentStore()
    @StateObject private var streak = StreakStore()
    @StateObject private var lastRead = LastReadStore()
    @StateObject private var tabRouter = TabRouter()
    @StateObject private var themeStore = ThemeStore()
    @StateObject private var notificationStore = NotificationStore()
    @StateObject private var typographyStore = TypographyStore()
    @StateObject private var toastCenter = ToastCenter()
    @StateObject private var adManager = AdManager()
    @StateObject private var removeAdsStore = RemoveAdsStore()
    @StateObject private var consentManager = ConsentManager.shared
    @StateObject private var reviewPromptManager = ReviewPromptManager()
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
            .toastOverlay()
            .id(languageStore.language)
            .environmentObject(favorites)
            .environmentObject(languageStore)
            .environmentObject(streak)
            .environmentObject(lastRead)
            .environmentObject(tabRouter)
            .environmentObject(themeStore)
            .environmentObject(notificationStore)
            .environmentObject(typographyStore)
            .environmentObject(toastCenter)
            .environmentObject(adManager)
            .environmentObject(removeAdsStore)
            .environmentObject(consentManager)
            .environmentObject(reviewPromptManager)
            .environment(\.layoutDirection, languageStore.language.isRightToLeft ? .rightToLeft : .leftToRight)
            .preferredColorScheme(themeStore.theme.colorScheme)
            .accentColor(Color("AccentColor"))
            .onAppear {
                content.load(languageStore.language)
                notificationStore.configure(subjects: content.subjects, title: languageStore.strings.hadithOfTheDay)
                consentManager.requestConsentThenStartAds()
            }
            .onChange(of: languageStore.language) { newValue in
                content.load(newValue)
                notificationStore.configure(subjects: content.subjects, title: newValue.strings.hadithOfTheDay)
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    streak.evaluate()
                    notificationStore.configure(subjects: content.subjects, title: languageStore.strings.hadithOfTheDay)
                }
            }
        }
    }
}
