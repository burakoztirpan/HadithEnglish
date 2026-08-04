import Foundation

let suiteName = "com.hadithenglish.favoritesstorecheck"
let defaults = UserDefaults(suiteName: suiteName)!
defaults.removePersistentDomain(forName: suiteName)

func loadIDs() -> Set<Int> {
    let stored = defaults.stringArray(forKey: "FavoriteIndex") ?? []
    return Set(stored.compactMap { Int($0) })
}

func toggle(_ id: Int) {
    var ids = loadIDs()
    if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
    defaults.set(ids.map(String.init), forKey: "FavoriteIndex")
}

// Simulate a favorite already written by the 2018 app before this update installs.
defaults.set(["42"], forKey: "FavoriteIndex")
assert(loadIDs() == [42], "FAIL: did not read legacy-format favorite id 42")

toggle(7)
assert(loadIDs() == [42, 7], "FAIL: toggle(7) should add 7, got \(loadIDs())")

toggle(42)
assert(loadIDs() == [7], "FAIL: toggle(42) should remove 42, got \(loadIDs())")

defaults.removePersistentDomain(forName: suiteName)
print("OK: favorites persistence checks passed")
