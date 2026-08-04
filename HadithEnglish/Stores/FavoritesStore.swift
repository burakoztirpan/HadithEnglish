import Foundation
import Combine

final class FavoritesStore: ObservableObject {
    private static let defaultsKey = "FavoriteIndex"

    @Published private(set) var favoriteIDs: Set<Int>

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.stringArray(forKey: Self.defaultsKey) ?? []
        self.favoriteIDs = Set(stored.compactMap { Int($0) })
    }

    func isFavorite(_ id: Int) -> Bool {
        favoriteIDs.contains(id)
    }

    func toggle(_ id: Int) {
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
        } else {
            favoriteIDs.insert(id)
        }
        persist()
    }

    func remove(_ id: Int) {
        favoriteIDs.remove(id)
        persist()
    }

    private func persist() {
        defaults.set(favoriteIDs.map(String.init), forKey: Self.defaultsKey)
    }
}
