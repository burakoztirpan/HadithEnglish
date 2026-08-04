import Foundation

enum AppTab: Int {
    case home, hadiths, favorites, setup
}

final class TabRouter: ObservableObject {
    @Published var selectedTab: AppTab = .home
}
