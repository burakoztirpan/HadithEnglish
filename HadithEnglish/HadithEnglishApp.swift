import SwiftUI

@main
struct HadithEnglishApp: App {
    @StateObject private var favorites = FavoritesStore()
    private let subjects: [HadithSubject]

    init() {
        subjects = Self.loadSubjects()
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                SubjectsListView(subjects: subjects)
                    .tabItem { Label("Hadiths", systemImage: "book") }
                FavoritesView(subjects: subjects)
                    .tabItem { Label("Favorites", systemImage: "star") }
                SettingsView()
                    .tabItem { Label("Setup", systemImage: "gearshape") }
            }
            .environmentObject(favorites)
            .accentColor(Color("AccentColor"))
        }
    }

    private static func loadSubjects() -> [HadithSubject] {
        guard let url = Bundle.main.url(forResource: "newHadithJson", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let subjects = try? JSONDecoder().decode([HadithSubject].self, from: data)
        else {
            return []
        }
        return subjects
    }
}
