# HadithEnglish SwiftUI Rewrite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task (inline execution — not subagent-per-task). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite HadithEnglish from its 2018 UIKit/Storyboard codebase into a pure SwiftUI app with an adaptive dark-mode-safe design system, a working app icon, and App Store compliance (privacy manifest), ready to resubmit under the existing App Store listing.

**Architecture:** Pure SwiftUI `@main` App lifecycle (no AppDelegate/storyboards except a minimal LaunchScreen). Two Codable models, one `ObservableObject` favorites store backed by the same `UserDefaults` key/format the 2018 app used (no data migration needed), four SwiftUI views wired into a `TabView`. All UI colors come from two new adaptive Asset Catalog color sets so dark mode is structurally correct, not manually patched.

**Tech Stack:** Swift 5, SwiftUI, Foundation/Combine only. No third-party dependencies, no networking, no Core Data. Project file (`.pbxproj`) edits are made with the `pbxproj` Python CLI tool (installed into a project-local venv in Task 1) for adding/removing source files, and direct text edits (verified by `xcodebuild build`) for build-setting and Info.plist changes.

## Global Constraints

- Minimum deployment target: iOS 15.0 (bumped from 11.2).
- `SWIFT_VERSION`: 5.0 (bumped from 4.0).
- Bundle identifier stays `nelibula.HadithEnglish`, `DEVELOPMENT_TEAM` stays `R83CBV3LY4` — this updates the existing App Store listing, not a new app.
- No third-party dependencies (no CocoaPods/SPM external packages) — matches the original app's actual capabilities and the spec's explicit scope.
- Favorites persistence must remain byte-compatible with the 2018 app: `UserDefaults.standard`, key `"FavoriteIndex"`, value `[String]` of hadith ID integers as strings. No migration step — existing installs must keep their favorites after the update.
- Only `HadithEnglish/newHadithJson.json` is real data (88 subjects, globally-unique hadith IDs 0...N across the whole file, confirmed by inspection). `hadithJson.json`, `hadithJson2.json`, and the `Assets.xcassets/hadithJson.dataset` copy are unused leftovers and get deleted, not carried forward.
- Privacy Policy URL and App Store URL are not yet known — mark clearly with `// TODO` in `SettingsView.swift` per explicit user decision during brainstorming (spec: "Privacy Policy URL is a placeholder"). Do not block the rest of the plan on getting real URLs.

---

## File Structure

**New files:**
- `HadithEnglish/HadithEnglishApp.swift` — `@main` App entry point, loads JSON once, builds the `TabView`.
- `HadithEnglish/Models/HadithModels.swift` — `HadithSubject`, `HadithEntry` Codable structs.
- `HadithEnglish/Stores/FavoritesStore.swift` — `ObservableObject` wrapping `UserDefaults["FavoriteIndex"]`.
- `HadithEnglish/Views/SubjectsListView.swift` — Hadiths tab: searchable list of 88 subjects.
- `HadithEnglish/Views/HadithDetailView.swift` — per-subject hadith list with favorite/share.
- `HadithEnglish/Views/FavoritesView.swift` — Favorites tab.
- `HadithEnglish/Views/SettingsView.swift` — Setup tab (new content for a previously-empty tab).
- `HadithEnglish/Views/ActivityShareSheet.swift` — `UIActivityViewController` wrapper used by
  the two share buttons above (`ShareLink` needs iOS 16+; this project's floor is iOS 15).
- `HadithEnglish/PrivacyInfo.xcprivacy` — Apple-mandated privacy manifest declaring UserDefaults usage.
- `HadithEnglish/Assets.xcassets/AccentColor.colorset/Contents.json` — adaptive accent color (deep green).
- `HadithEnglish/Assets.xcassets/CardBackground.colorset/Contents.json` — adaptive card tint (cream/charcoal-green).
- `HadithEnglish/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` — generated app icon image.
- `scripts/check_favorites_store.swift`, `scripts/check_json_decode.swift` — standalone `swift`-interpreter checks (no XCTest target; see rationale below).
- `scripts/generate_app_icon.py` — one-off PIL script that produces `AppIcon-1024.png`.
- `.gitignore` — excludes the venv and `.DS_Store`.

**Modified files:**
- `HadithEnglish/Info.plist` — remove `UIMainStoryboardFile`, remove `UIRequiredDeviceCapabilities`.
- `HadithEnglish/Base.lproj/LaunchScreen.storyboard` — hardcoded white background → adaptive `systemBackgroundColor`.
- `HadithEnglish/Assets.xcassets/AppIcon.appiconset/Contents.json` — switch to single-size (1024×1024 universal) format.
- `HadithEnglish.xcodeproj/project.pbxproj` — file references added/removed, `IPHONEOS_DEPLOYMENT_TARGET` and `SWIFT_VERSION` bumped.

**Deleted files:**
- `HadithEnglish/AppDelegate.swift`
- `HadithEnglish/Controller/ViewController.swift`
- `HadithEnglish/Controller/HadithsTable.swift`
- `HadithEnglish/Controller/FavoritesTable.swift`
- `HadithEnglish/View/HadithCell.swift`
- `HadithEnglish/View/FavoriteCell.swift`
- `HadithEnglish/View/hadithDetailCell.swift`
- `HadithEnglish/Model/hadithSubject.swift` (dead class, never instantiated)
- `HadithEnglish/hadithTableView.swift` (dead `UITableView` subclass, never used as a custom class)
- `HadithEnglish/Base.lproj/Main.storyboard`
- `HadithEnglish/HadithEnglish.xcdatamodeld/` (empty Core Data model, zero entities, never used)
- `HadithEnglish/hadithJson.json`, `HadithEnglish/hadithJson2.json` (unused; only `newHadithJson.json` is loaded)
- `HadithEnglish/Assets.xcassets/hadithJson.dataset/` (unused duplicate of `hadithJson.json`, never read via `NSDataAsset`)
- `HadithEnglish/File` (stray 0-byte file, no reference anywhere)

**Why no XCTest target:** creating a new unit test target requires either hand-authoring a `PBXNativeTarget` in `project.pbxproj` (fragile, easy to corrupt the build) or GUI automation — disproportionate for a 4-screen hobby app with no such existing convention. Instead, the two pieces of logic worth checking (JSON decoding, favorites persistence compatibility with the 2018 format) get standalone `swift <file>.swift` scripts using `assert()` — runnable in seconds, zero project-file risk, no new build target.

---

### Task 1: Tooling setup and baseline build check

**Files:**
- Create: `.tooling/` (venv, gitignored)
- Create: `.gitignore`

- [ ] **Step 1: Create the venv and install `pbxproj`**

```bash
cd ~/Desktop/"hadiths app"
python3 -m venv .tooling/pbxproj-venv
.tooling/pbxproj-venv/bin/pip install pbxproj
```

Expected: ends with `Successfully installed ... pbxproj-4.3.0 ...` (or similar version).

- [ ] **Step 2: Add `.gitignore`**

```
.tooling/
.DS_Store
```

- [ ] **Step 3: Confirm the `pbxproj` CLI works against this project**

```bash
cd ~/Desktop/"hadiths app"
.tooling/pbxproj-venv/bin/pbxproj show HadithEnglish.xcodeproj 2>&1 | head -10
```

Expected: prints target/configuration info without an error (confirms the tool can parse this project's `project.pbxproj`).

- [ ] **Step 4: Confirm baseline build still succeeds**

```bash
cd ~/Desktop/"hadiths app"
xcodebuild -project HadithEnglish.xcodeproj -scheme HadithEnglish \
  -destination 'platform=iOS Simulator,id=627059B0-3713-4F4A-8AC1-FBB0E1A4BE56' \
  -configuration Debug build 2>&1 | tail -5
```

Expected: last line is `** BUILD SUCCEEDED **`. (If that simulator UDID no longer exists, run
`xcrun simctl list devices available | grep -i iphone` and substitute a current iPhone
simulator's UDID — use the same one for every build/run step in this plan.)

- [ ] **Step 5: Commit**

```bash
cd ~/Desktop/"hadiths app"
git add .gitignore
git commit -m "Add pbxproj tooling venv (gitignored) for project file edits"
```

---

### Task 2: Data models

**Files:**
- Create: `HadithEnglish/Models/HadithModels.swift`
- Create: `scripts/check_json_decode.swift`

**Interfaces:**
- Produces: `struct HadithEntry: Codable, Identifiable { let id: Int; let hadith: String; var trimmedText: String }`, `struct HadithSubject: Codable, Identifiable { let name: String; let hadiths: [HadithEntry]; var id: String; var trimmedName: String }`

- [ ] **Step 1: Write `HadithEnglish/Models/HadithModels.swift`**

```swift
import Foundation

struct HadithEntry: Codable, Identifiable {
    let id: Int
    let hadith: String

    var trimmedText: String {
        hadith.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct HadithSubject: Codable, Identifiable {
    let name: String
    let hadiths: [HadithEntry]

    var id: String { name }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }
}
```

- [ ] **Step 2: Add the file to the Xcode project**

```bash
cd ~/Desktop/"hadiths app"
.tooling/pbxproj-venv/bin/pbxproj file HadithEnglish.xcodeproj \
  HadithEnglish/Models/HadithModels.swift --target HadithEnglish
```

Expected: exits with no error (silent success).

- [ ] **Step 3: Write the standalone JSON-decode check**

```swift
// scripts/check_json_decode.swift
import Foundation

struct HadithEntry: Codable {
    let id: Int
    let hadith: String
}
struct HadithSubject: Codable {
    let name: String
    let hadiths: [HadithEntry]
}

let url = URL(fileURLWithPath: CommandLine.arguments[1])
let data = try! Data(contentsOf: url)
let subjects = try! JSONDecoder().decode([HadithSubject].self, from: data)

assert(subjects.count == 88, "FAIL: expected 88 subjects, got \(subjects.count)")
assert(
    subjects[0].name.trimmingCharacters(in: .whitespaces) == "Revelation",
    "FAIL: first subject should be Revelation, got \(subjects[0].name)"
)
assert(subjects[0].hadiths.first?.id == 0, "FAIL: first hadith id should be 0")

print("OK: JSON decode checks passed (\(subjects.count) subjects)")
```

This mirrors the real `HadithModels.swift` field-for-field; keep them in sync if the JSON shape
ever changes.

- [ ] **Step 4: Run the check**

```bash
cd ~/Desktop/"hadiths app"
swift scripts/check_json_decode.swift "HadithEnglish/newHadithJson.json"
```

Expected: `OK: JSON decode checks passed (88 subjects)`

- [ ] **Step 5: Verify the app still builds**

```bash
cd ~/Desktop/"hadiths app"
xcodebuild -project HadithEnglish.xcodeproj -scheme HadithEnglish \
  -destination 'platform=iOS Simulator,id=627059B0-3713-4F4A-8AC1-FBB0E1A4BE56' \
  -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **` (the new file is additive and unused by the old entry point
so far — this just confirms it compiles cleanly).

- [ ] **Step 6: Commit**

```bash
cd ~/Desktop/"hadiths app"
git add HadithEnglish/Models/HadithModels.swift scripts/check_json_decode.swift \
  HadithEnglish.xcodeproj/project.pbxproj
git commit -m "Add HadithSubject/HadithEntry models"
```

---

### Task 3: Favorites store

> **Execution note (discovered during implementation):** adding this file surfaced an ordering
> bug in the plan — `ObservableObject`/`@Published` need iOS 13+, but the deployment target
> bump was originally scheduled as Task 8, long after this task. Task 8's Steps 1–2
> (`IPHONEOS_DEPLOYMENT_TARGET` → 15.0, `SWIFT_VERSION` → 5.0) were pulled forward and run here
> instead. That in turn broke three still-present 2018-era files that only compiled under
> Swift 4 rules: `AppDelegate.swift` (`UIApplicationLaunchOptionsKey` →
> `UIApplication.LaunchOptionsKey`) and `Controller/FavoritesTable.swift` +
> `Controller/HadithsTable.swift` (`UITableViewAutomaticDimension` →
> `UITableView.automaticDimension`, one line each). All three are throwaway patches — those
> files are deleted outright in Task 6 — made only to keep the build green in the meantime.
> When executing Task 8 later, skip Steps 1–2 (already done) and only run Step 3 (verify) as a
> confirmation, not a fresh change.

**Files:**
- Create: `HadithEnglish/Stores/FavoritesStore.swift`
- Create: `scripts/check_favorites_store.swift`

**Interfaces:**
- Consumes: nothing from Task 2 (standalone).
- Produces: `final class FavoritesStore: ObservableObject { func isFavorite(_ id: Int) -> Bool; func toggle(_ id: Int); func remove(_ id: Int); @Published private(set) var favoriteIDs: Set<Int> }`

- [ ] **Step 1: Write `HadithEnglish/Stores/FavoritesStore.swift`**

```swift
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
```

- [ ] **Step 2: Add the file to the Xcode project**

```bash
cd ~/Desktop/"hadiths app"
.tooling/pbxproj-venv/bin/pbxproj file HadithEnglish.xcodeproj \
  HadithEnglish/Stores/FavoritesStore.swift --target HadithEnglish
```

Expected: silent success.

- [ ] **Step 3: Write the standalone favorites-compatibility check**

```swift
// scripts/check_favorites_store.swift
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
```

This exercises the same `UserDefaults["FavoriteIndex"] = [String]` shape `FavoritesStore` reads
and writes; keep the two in sync if the storage format ever changes.

- [ ] **Step 4: Run the check**

```bash
cd ~/Desktop/"hadiths app"
swift scripts/check_favorites_store.swift
```

Expected: `OK: favorites persistence checks passed`

- [ ] **Step 5: Verify the app still builds**

```bash
cd ~/Desktop/"hadiths app"
xcodebuild -project HadithEnglish.xcodeproj -scheme HadithEnglish \
  -destination 'platform=iOS Simulator,id=627059B0-3713-4F4A-8AC1-FBB0E1A4BE56' \
  -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
cd ~/Desktop/"hadiths app"
git add HadithEnglish/Stores/FavoritesStore.swift scripts/check_favorites_store.swift \
  HadithEnglish.xcodeproj/project.pbxproj
git commit -m "Add FavoritesStore backed by the existing UserDefaults format"
```

---

### Task 4: Adaptive color assets

**Files:**
- Create: `HadithEnglish/Assets.xcassets/AccentColor.colorset/Contents.json`
- Create: `HadithEnglish/Assets.xcassets/CardBackground.colorset/Contents.json`

**Interfaces:**
- Produces: `Color("AccentColor")`, `Color("CardBackground")` usable from any SwiftUI view.

Asset catalog contents don't need individual `pbxproj` entries — the catalog folder itself
(`Assets.xcassets`) is already referenced as a single unit in the project, and Xcode's asset
compiler picks up new colorset/imageset subfolders automatically.

- [ ] **Step 1: Create `AccentColor.colorset`**

```bash
mkdir -p ~/Desktop/"hadiths app"/HadithEnglish/Assets.xcassets/AccentColor.colorset
```

Write `HadithEnglish/Assets.xcassets/AccentColor.colorset/Contents.json`:

```json
{
  "colors" : [
    {
      "idiom" : "universal",
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "red" : "0.184",
          "green" : "0.420",
          "blue" : "0.310",
          "alpha" : "1.000"
        }
      }
    },
    {
      "idiom" : "universal",
      "appearances" : [
        { "appearance" : "luminosity", "value" : "dark" }
      ],
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "red" : "0.435",
          "green" : "0.784",
          "blue" : "0.596",
          "alpha" : "1.000"
        }
      }
    }
  ],
  "info" : { "version" : 1, "author" : "xcode" }
}
```

- [ ] **Step 2: Create `CardBackground.colorset`**

```bash
mkdir -p ~/Desktop/"hadiths app"/HadithEnglish/Assets.xcassets/CardBackground.colorset
```

Write `HadithEnglish/Assets.xcassets/CardBackground.colorset/Contents.json`:

```json
{
  "colors" : [
    {
      "idiom" : "universal",
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "red" : "0.965",
          "green" : "0.937",
          "blue" : "0.882",
          "alpha" : "1.000"
        }
      }
    },
    {
      "idiom" : "universal",
      "appearances" : [
        { "appearance" : "luminosity", "value" : "dark" }
      ],
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "red" : "0.118",
          "green" : "0.141",
          "blue" : "0.125",
          "alpha" : "1.000"
        }
      }
    }
  ],
  "info" : { "version" : 1, "author" : "xcode" }
}
```

- [ ] **Step 3: Verify the app still builds**

```bash
cd ~/Desktop/"hadiths app"
xcodebuild -project HadithEnglish.xcodeproj -scheme HadithEnglish \
  -destination 'platform=iOS Simulator,id=627059B0-3713-4F4A-8AC1-FBB0E1A4BE56' \
  -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
cd ~/Desktop/"hadiths app"
git add HadithEnglish/Assets.xcassets/AccentColor.colorset HadithEnglish/Assets.xcassets/CardBackground.colorset
git commit -m "Add adaptive AccentColor and CardBackground color sets"
```

---

### Task 5: SwiftUI views

> **Execution note (discovered during implementation):** the original `HadithDetailView.swift`
> and `SettingsView.swift` used `ShareLink`, which needs iOS 16+ — but this project's floor is
> iOS 15 (Global Constraints). Added `HadithEnglish/Views/ActivityShareSheet.swift`, a small
> `UIViewControllerRepresentable` wrapping `UIActivityViewController` (the standard iOS
> 15-compatible share mechanism), and both views present it via `.sheet(isPresented:)` instead
> of calling `ShareLink` directly. The code below reflects the corrected version.

**Files:**
- Create: `HadithEnglish/Views/SubjectsListView.swift`
- Create: `HadithEnglish/Views/HadithDetailView.swift`
- Create: `HadithEnglish/Views/FavoritesView.swift`
- Create: `HadithEnglish/Views/SettingsView.swift`
- Create: `HadithEnglish/Views/ActivityShareSheet.swift`

**Interfaces:**
- Consumes: `HadithSubject`, `HadithEntry` (Task 2), `FavoritesStore` (Task 3), `Color("AccentColor")`/`Color("CardBackground")` (Task 4).
- Produces: `SubjectsListView(subjects: [HadithSubject])`, `HadithDetailView(subject: HadithSubject)`, `FavoritesView(subjects: [HadithSubject])`, `SettingsView()`, `ActivityShareSheet(items: [Any])` — the first four expect a `FavoritesStore` in the environment.

- [ ] **Step 1: Write `HadithEnglish/Views/SubjectsListView.swift`**

```swift
import SwiftUI

struct SubjectsListView: View {
    let subjects: [HadithSubject]
    @State private var searchText = ""

    private var filteredSubjects: [HadithSubject] {
        guard !searchText.isEmpty else { return subjects }
        return subjects.filter {
            $0.trimmedName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            List(filteredSubjects) { subject in
                NavigationLink(destination: HadithDetailView(subject: subject)) {
                    Text(subject.trimmedName)
                        .font(.body)
                        .padding(.vertical, 6)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Hadith Subjects")
            .searchable(text: $searchText, prompt: "Search subjects")
        }
        .navigationViewStyle(.stack)
    }
}
```

- [ ] **Step 2: Write `HadithEnglish/Views/HadithDetailView.swift`**

```swift
import SwiftUI

struct HadithDetailView: View {
    let subject: HadithSubject

    var body: some View {
        List(subject.hadiths) { entry in
            HadithCardView(entry: entry)
        }
        .listStyle(.plain)
        .navigationTitle(subject.trimmedName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HadithCardView: View {
    let entry: HadithEntry
    @EnvironmentObject private var favorites: FavoritesStore
    @State private var isSharePresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("#\(entry.id)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    favorites.toggle(entry.id)
                } label: {
                    Image(systemName: favorites.isFavorite(entry.id) ? "star.fill" : "star")
                        .foregroundColor(Color("AccentColor"))
                }
                .buttonStyle(.plain)
                Button {
                    isSharePresented = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Color("AccentColor"))
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $isSharePresented) {
                    ActivityShareSheet(items: [entry.trimmedText])
                }
            }
            Text(entry.trimmedText)
                .font(.system(.body, design: .serif))
        }
        .padding(.vertical, 8)
        .listRowBackground(Color("CardBackground"))
    }
}
```

- [ ] **Step 3: Write `HadithEnglish/Views/FavoritesView.swift`**

```swift
import SwiftUI

struct FavoritesView: View {
    let subjects: [HadithSubject]
    @EnvironmentObject private var favorites: FavoritesStore

    private var favoriteEntries: [HadithEntry] {
        subjects
            .flatMap(\.hadiths)
            .filter { favorites.isFavorite($0.id) }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(favoriteEntries) { entry in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("#\(entry.id)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(entry.trimmedText)
                            .font(.system(.body, design: .serif))
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color("CardBackground"))
                    .swipeActions {
                        Button(role: .destructive) {
                            favorites.remove(entry.id)
                        } label: {
                            Label("Remove", systemImage: "star.slash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Favorites")
            .overlay {
                if favoriteEntries.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "star")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No favorites yet")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
```

- [ ] **Step 4: Write `HadithEnglish/Views/SettingsView.swift`**

```swift
import SwiftUI

struct SettingsView: View {
    // TODO: replace with the real privacy policy URL before submitting to App Store Connect.
    private let privacyPolicyURL = URL(string: "https://example.com/hadithenglish/privacy")!
    // TODO: replace with the real App Store URL once known (this is a re-submission of an
    // existing 2019 listing, so check App Store Connect for the existing app URL).
    private let appStoreURL = URL(string: "https://apps.apple.com/app/id0000000000")!

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    @State private var isSharePresented = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    Link("Rate on the App Store", destination: appStoreURL)
                    Button("Share this app") {
                        isSharePresented = true
                    }
                    .sheet(isPresented: $isSharePresented) {
                        ActivityShareSheet(items: [appStoreURL])
                    }
                    Link("Privacy Policy", destination: privacyPolicyURL)
                }
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(appVersion) (\(buildNumber))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Setup")
        }
        .navigationViewStyle(.stack)
    }
}
```

- [ ] **Step 4b: Write `HadithEnglish/Views/ActivityShareSheet.swift`**

```swift
import SwiftUI
import UIKit

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
```

- [ ] **Step 5: Add all five files to the Xcode project**

```bash
cd ~/Desktop/"hadiths app"
.tooling/pbxproj-venv/bin/pbxproj file HadithEnglish.xcodeproj \
  HadithEnglish/Views/SubjectsListView.swift --target HadithEnglish
.tooling/pbxproj-venv/bin/pbxproj file HadithEnglish.xcodeproj \
  HadithEnglish/Views/HadithDetailView.swift --target HadithEnglish
.tooling/pbxproj-venv/bin/pbxproj file HadithEnglish.xcodeproj \
  HadithEnglish/Views/FavoritesView.swift --target HadithEnglish
.tooling/pbxproj-venv/bin/pbxproj file HadithEnglish.xcodeproj \
  HadithEnglish/Views/SettingsView.swift --target HadithEnglish
.tooling/pbxproj-venv/bin/pbxproj file HadithEnglish.xcodeproj \
  HadithEnglish/Views/ActivityShareSheet.swift --target HadithEnglish
```

Expected: each command exits silently with no error.

- [ ] **Step 6: Verify the app still builds**

```bash
cd ~/Desktop/"hadiths app"
xcodebuild -project HadithEnglish.xcodeproj -scheme HadithEnglish \
  -destination 'platform=iOS Simulator,id=627059B0-3713-4F4A-8AC1-FBB0E1A4BE56' \
  -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **` (still additive — the old `AppDelegate`/storyboard entry
point is still what actually runs at this point).

- [ ] **Step 7: Commit**

```bash
cd ~/Desktop/"hadiths app"
git add HadithEnglish/Views HadithEnglish.xcodeproj/project.pbxproj
git commit -m "Add SwiftUI views for subjects, detail, favorites, and settings"
```

---

### Task 6: Cutover to the SwiftUI app lifecycle

This is the one task that can't stay buildable mid-way through: a project can't have both the
old `@UIApplicationMain` `AppDelegate` and a new `@main` App struct at once. Everything in this
task lands together, then gets verified as a whole.

**Files:**
- Create: `HadithEnglish/HadithEnglishApp.swift`
- Delete: `HadithEnglish/AppDelegate.swift`, `HadithEnglish/Controller/ViewController.swift`,
  `HadithEnglish/Controller/HadithsTable.swift`, `HadithEnglish/Controller/FavoritesTable.swift`,
  `HadithEnglish/View/HadithCell.swift`, `HadithEnglish/View/FavoriteCell.swift`,
  `HadithEnglish/View/hadithDetailCell.swift`, `HadithEnglish/Model/hadithSubject.swift`,
  `HadithEnglish/hadithTableView.swift`, `HadithEnglish/Base.lproj/Main.storyboard`,
  `HadithEnglish/HadithEnglish.xcdatamodeld/`, `HadithEnglish/hadithJson.json`,
  `HadithEnglish/hadithJson2.json`, `HadithEnglish/Assets.xcassets/hadithJson.dataset/`,
  `HadithEnglish/File`
- Modify: `HadithEnglish/Info.plist`

**Interfaces:**
- Consumes: `HadithSubject` (Task 2), `FavoritesStore` (Task 3), `SubjectsListView`/
  `FavoritesView`/`SettingsView` (Task 5).

- [ ] **Step 1: Write `HadithEnglish/HadithEnglishApp.swift`**

```swift
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
```

- [ ] **Step 2: Add it to the Xcode project**

```bash
cd ~/Desktop/"hadiths app"
.tooling/pbxproj-venv/bin/pbxproj file HadithEnglish.xcodeproj \
  HadithEnglish/HadithEnglishApp.swift --target HadithEnglish
```

- [ ] **Step 3: Remove `UIMainStoryboardFile` and `UIRequiredDeviceCapabilities` from Info.plist**

In `HadithEnglish/Info.plist`, delete these two key/value pairs entirely:

```xml
	<key>UIMainStoryboardFile</key>
	<string>Main</string>
```

and

```xml
	<key>UIRequiredDeviceCapabilities</key>
	<array>
		<string>armv7</string>
	</array>
```

Keep `UILaunchStoryboardName` / `LaunchScreen` — that storyboard stays (fixed for dark mode in
Task 7).

- [ ] **Step 4: Delete the old files (both the pbxproj reference and the file on disk)**

```bash
cd ~/Desktop/"hadiths app"
for f in \
  HadithEnglish/AppDelegate.swift \
  HadithEnglish/Controller/ViewController.swift \
  HadithEnglish/Controller/HadithsTable.swift \
  HadithEnglish/Controller/FavoritesTable.swift \
  HadithEnglish/View/HadithCell.swift \
  HadithEnglish/View/FavoriteCell.swift \
  HadithEnglish/View/hadithDetailCell.swift \
  HadithEnglish/Model/hadithSubject.swift \
  HadithEnglish/hadithTableView.swift \
  HadithEnglish/Base.lproj/Main.storyboard \
  HadithEnglish/hadithJson.json \
  HadithEnglish/hadithJson2.json \
  HadithEnglish/File \
; do
  .tooling/pbxproj-venv/bin/pbxproj file --delete HadithEnglish.xcodeproj "$f"
  rm -f "$f"
done

rm -rf HadithEnglish/HadithEnglish.xcdatamodeld
rm -rf HadithEnglish/Assets.xcassets/hadithJson.dataset
rmdir HadithEnglish/Controller HadithEnglish/View HadithEnglish/Model 2>/dev/null
```

Expected: no errors from the `pbxproj` calls. `HadithEnglish.xcdatamodeld` and
`hadithJson.dataset` are removed with plain `rm -rf` because they were never individually
referenced in `project.pbxproj` (folder-type references cover their own contents), so there's
no pbxproj entry to delete for them.

- [ ] **Step 5: Verify the build succeeds**

```bash
cd ~/Desktop/"hadiths app"
xcodebuild -project HadithEnglish.xcodeproj -scheme HadithEnglish \
  -destination 'platform=iOS Simulator,id=627059B0-3713-4F4A-8AC1-FBB0E1A4BE56' \
  -configuration Debug build 2>&1 | tail -30
```

Expected: `** BUILD SUCCEEDED **`. If it fails with "multiple @main" or similar, confirm
`AppDelegate.swift` was actually deleted from disk (Step 4) — a stray copy left on disk but
removed only from the pbxproj reference would not cause this, but a copy left in the pbxproj
reference while still on disk would.

- [ ] **Step 6: Install and launch on the simulator, confirm no crash, screenshot light and dark mode**

```bash
UDID=627059B0-3713-4F4A-8AC1-FBB0E1A4BE56
xcrun simctl boot $UDID 2>&1 || true
open -a Simulator
sleep 3
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "HadithEnglish.app" -path "*Debug-iphonesimulator*" -newer HadithEnglish.xcodeproj/project.pbxproj | head -1)
xcrun simctl install $UDID "$APP_PATH"
xcrun simctl launch $UDID nelibula.HadithEnglish
sleep 2
xcrun simctl ui $UDID appearance light
sleep 1
xcrun simctl io $UDID screenshot /tmp/hadith_cutover_light.png
xcrun simctl ui $UDID appearance dark
sleep 1
xcrun simctl io $UDID screenshot /tmp/hadith_cutover_dark.png
```

Expected: `xcrun simctl launch` prints a PID with no crash, and both PNGs are written. Read
both screenshots and visually confirm: the subjects list renders, tab bar shows Hadiths/
Favorites/Setup, and nothing is invisible in dark mode (this is the direct regression check for
the original dark-mode bug — text should now be visibly readable in both screenshots since the
old hardcoded-white-label-background code that caused it no longer exists).

- [ ] **Step 7: Commit**

```bash
cd ~/Desktop/"hadiths app"
git add -A
git commit -m "Cut over to pure SwiftUI app lifecycle, remove UIKit/Storyboard/Core Data code"
```

---

### Task 7: Adaptive launch screen

**Files:**
- Modify: `HadithEnglish/Base.lproj/LaunchScreen.storyboard`

- [ ] **Step 1: Replace the hardcoded white background color**

Find this line in `HadithEnglish/Base.lproj/LaunchScreen.storyboard`:

```xml
                        <color key="backgroundColor" red="1" green="1" blue="1" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
```

Replace it with:

```xml
                        <color key="backgroundColor" systemColor="systemBackgroundColor"/>
```

- [ ] **Step 2: Verify the app still builds**

```bash
cd ~/Desktop/"hadiths app"
xcodebuild -project HadithEnglish.xcodeproj -scheme HadithEnglish \
  -destination 'platform=iOS Simulator,id=627059B0-3713-4F4A-8AC1-FBB0E1A4BE56' \
  -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
cd ~/Desktop/"hadiths app"
git add HadithEnglish/Base.lproj/LaunchScreen.storyboard
git commit -m "Make launch screen background adapt to dark mode"
```

---

### Task 8: Build settings

**Files:**
- Modify: `HadithEnglish.xcodeproj/project.pbxproj`

- [ ] **Step 1: Bump the deployment target**

```bash
cd ~/Desktop/"hadiths app"
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 11.2;/IPHONEOS_DEPLOYMENT_TARGET = 15.0;/g' \
  HadithEnglish.xcodeproj/project.pbxproj
grep -c "IPHONEOS_DEPLOYMENT_TARGET = 15.0;" HadithEnglish.xcodeproj/project.pbxproj
grep -c "IPHONEOS_DEPLOYMENT_TARGET = 11.2;" HadithEnglish.xcodeproj/project.pbxproj
```

Expected: first `grep -c` prints a count ≥ 1 (matches replaced), second `grep -c` prints `0`
(no `11.2` occurrences left — confirms every build configuration was updated, not just the
first match).

- [ ] **Step 2: Bump the Swift version**

```bash
cd ~/Desktop/"hadiths app"
sed -i '' 's/SWIFT_VERSION = 4.0;/SWIFT_VERSION = 5.0;/g' \
  HadithEnglish.xcodeproj/project.pbxproj
grep -c "SWIFT_VERSION = 5.0;" HadithEnglish.xcodeproj/project.pbxproj
grep -c "SWIFT_VERSION = 4.0;" HadithEnglish.xcodeproj/project.pbxproj
```

Expected: first `grep -c` prints a count ≥ 1, second prints `0`.

- [ ] **Step 3: Verify the build succeeds with no deployment-target warning**

```bash
cd ~/Desktop/"hadiths app"
xcodebuild -project HadithEnglish.xcodeproj -scheme HadithEnglish \
  -destination 'platform=iOS Simulator,id=627059B0-3713-4F4A-8AC1-FBB0E1A4BE56' \
  -configuration Debug build 2>&1 | tail -10
```

Expected: `** BUILD SUCCEEDED **` and no `"The iOS Simulator deployment target ... is set to
11.2"` warning line anywhere in the output.

- [ ] **Step 4: Commit**

```bash
cd ~/Desktop/"hadiths app"
git add HadithEnglish.xcodeproj/project.pbxproj
git commit -m "Bump deployment target to iOS 15.0 and Swift version to 5.0"
```

---

### Task 9: Privacy manifest

**Files:**
- Create: `HadithEnglish/PrivacyInfo.xcprivacy`

- [ ] **Step 1: Write `HadithEnglish/PrivacyInfo.xcprivacy`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSPrivacyTracking</key>
	<false/>
	<key>NSPrivacyTrackingDomains</key>
	<array/>
	<key>NSPrivacyCollectedDataTypes</key>
	<array/>
	<key>NSPrivacyAccessedAPITypes</key>
	<array>
		<dict>
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategoryUserDefaults</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array>
				<string>CA92.1</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
```

Reason `CA92.1` = "Access info from same app" — matches the app's actual `UserDefaults` usage
(favorites storage, read/written only by this app).

- [ ] **Step 2: Add it to the Xcode project**

```bash
cd ~/Desktop/"hadiths app"
.tooling/pbxproj-venv/bin/pbxproj file HadithEnglish.xcodeproj \
  HadithEnglish/PrivacyInfo.xcprivacy --target HadithEnglish
```

- [ ] **Step 3: Verify the build succeeds and the manifest is in the built app bundle**

```bash
cd ~/Desktop/"hadiths app"
xcodebuild -project HadithEnglish.xcodeproj -scheme HadithEnglish \
  -destination 'platform=iOS Simulator,id=627059B0-3713-4F4A-8AC1-FBB0E1A4BE56' \
  -configuration Debug build 2>&1 | tail -5
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "HadithEnglish.app" -path "*Debug-iphonesimulator*" -newer HadithEnglish.xcodeproj/project.pbxproj | head -1)
ls "$APP_PATH/PrivacyInfo.xcprivacy"
```

Expected: `** BUILD SUCCEEDED **` and the `ls` prints the file path with no "No such file" error.

- [ ] **Step 4: Commit**

```bash
cd ~/Desktop/"hadiths app"
git add HadithEnglish/PrivacyInfo.xcprivacy HadithEnglish.xcodeproj/project.pbxproj
git commit -m "Add privacy manifest declaring UserDefaults usage"
```

---

### Task 10: App icon

**Files:**
- Create: `scripts/generate_app_icon.py`
- Create: `HadithEnglish/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`
- Modify: `HadithEnglish/Assets.xcassets/AppIcon.appiconset/Contents.json`

- [ ] **Step 1: Write `scripts/generate_app_icon.py`**

```python
from PIL import Image, ImageDraw

SIZE = 1024
BG = (0x2F, 0x6B, 0x4F)   # deep calm green — matches AccentColor light value
FG = (0xF6, 0xEF, 0xE1)   # warm cream — matches CardBackground light value

img = Image.new("RGB", (SIZE, SIZE), BG)
draw = ImageDraw.Draw(img)

cx, cy = SIZE // 2, SIZE // 2
half_w = 300
half_h = 220
spine_gap = 14

left_page = [
    (cx - spine_gap - half_w, cy - half_h + 40),
    (cx - spine_gap, cy - half_h),
    (cx - spine_gap, cy + half_h),
    (cx - spine_gap - half_w, cy + half_h - 40),
]
right_page = [
    (cx + spine_gap + half_w, cy - half_h + 40),
    (cx + spine_gap, cy - half_h),
    (cx + spine_gap, cy + half_h),
    (cx + spine_gap + half_w, cy + half_h - 40),
]

draw.polygon(left_page, fill=FG)
draw.polygon(right_page, fill=FG)
draw.line([(cx, cy - half_h), (cx, cy + half_h)], fill=BG, width=10)

img.save("HadithEnglish/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
print("OK: wrote AppIcon-1024.png")
```

- [ ] **Step 2: Run it**

```bash
cd ~/Desktop/"hadiths app"
python3 scripts/generate_app_icon.py
```

Expected: `OK: wrote AppIcon-1024.png`

- [ ] **Step 3: Replace `AppIcon.appiconset/Contents.json` with the single-size format**

```json
{
  "images" : [
    {
      "filename" : "AppIcon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 4: Verify the build succeeds and install to confirm the icon shows on the springboard**

```bash
cd ~/Desktop/"hadiths app"
xcodebuild -project HadithEnglish.xcodeproj -scheme HadithEnglish \
  -destination 'platform=iOS Simulator,id=627059B0-3713-4F4A-8AC1-FBB0E1A4BE56' \
  -configuration Debug build 2>&1 | tail -5
UDID=627059B0-3713-4F4A-8AC1-FBB0E1A4BE56
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "HadithEnglish.app" -path "*Debug-iphonesimulator*" -newer HadithEnglish.xcodeproj/project.pbxproj | head -1)
xcrun simctl install $UDID "$APP_PATH"
xcrun simctl terminate $UDID nelibula.HadithEnglish 2>&1 || true
```

Expected: `** BUILD SUCCEEDED **`, `simctl install` exits with no error. Press the home button
in Simulator (or `xcrun simctl launch $UDID com.apple.springboard` isn't needed — just switch
the Simulator app to the home screen manually / via the hardware home button) and take a
screenshot to visually confirm the new icon appears instead of a blank/default icon.

- [ ] **Step 5: Commit**

```bash
cd ~/Desktop/"hadiths app"
git add scripts/generate_app_icon.py HadithEnglish/Assets.xcassets/AppIcon.appiconset
git commit -m "Generate app icon in the new color palette"
```

---

### Task 11: Final end-to-end verification

**Files:** none (verification only).

**Tooling note:** the executing agent has `xcrun simctl` for install/launch/screenshot, but no
touch-input mechanism (no `cliclick`, no `idb`, `simctl` has no tap/touch subcommand — confirmed
by checking `xcrun simctl help` during planning). It can screenshot whatever is already on
screen and drive the app's *data* directly (e.g. editing the simulator's UserDefaults plist on
disk), but it cannot tap tab bar items, buttons, or type into the search field. Steps below are
split accordingly: steps the agent can run itself, and steps that need a human tapping in the
Simulator window (or a session with real touch-input tooling available).

- [ ] **Step 1: Fresh install and launch (agent-runnable)**

```bash
UDID=627059B0-3713-4F4A-8AC1-FBB0E1A4BE56
cd ~/Desktop/"hadiths app"
xcrun simctl uninstall $UDID nelibula.HadithEnglish 2>&1 || true
xcodebuild -project HadithEnglish.xcodeproj -scheme HadithEnglish \
  -destination 'platform=iOS Simulator,id='$UDID \
  -configuration Debug build 2>&1 | tail -5
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "HadithEnglish.app" -path "*Debug-iphonesimulator*" -newer HadithEnglish.xcodeproj/project.pbxproj | head -1)
xcrun simctl install $UDID "$APP_PATH"
xcrun simctl launch $UDID nelibula.HadithEnglish
```

Expected: launches with a PID, no crash.

- [ ] **Step 2: Screenshot the landing tab in light and dark mode (agent-runnable)**

```bash
UDID=627059B0-3713-4F4A-8AC1-FBB0E1A4BE56
xcrun simctl ui $UDID appearance light
sleep 1
xcrun simctl io $UDID screenshot /tmp/final_hadiths_light.png
xcrun simctl ui $UDID appearance dark
sleep 1
xcrun simctl io $UDID screenshot /tmp/final_hadiths_dark.png
```

Read both screenshots. This only covers the default landing tab (Hadiths/Subjects list) since
reaching the other tabs needs a tap — that's the direct regression check for the original
invisible-text bug already done in Task 6 Step 6; this step just re-confirms it on a clean
install.

- [ ] **Step 3: Verify favorites persistence logic without tapping (agent-runnable)**

The UI flow (tap a star, background the app, relaunch, confirm it's still favorited) needs taps
the agent can't send. But the underlying persistence claim — a value written to
`UserDefaults["FavoriteIndex"]` survives a process relaunch — is exactly what
`scripts/check_favorites_store.swift` (Task 3) already proves outside the simulator, and can be
re-confirmed against the *actual installed app's* defaults file directly:

```bash
UDID=627059B0-3713-4F4A-8AC1-FBB0E1A4BE56
PREFS=$(find ~/Library/Developer/CoreSimulator/Devices/$UDID/data/Containers/Data/Application \
  -path "*/Library/Preferences/nelibula.HadithEnglish.plist" 2>/dev/null | head -1)
xcrun simctl terminate $UDID nelibula.HadithEnglish 2>&1 || true
plutil -replace FavoriteIndex -json '["42"]' "$PREFS"
xcrun simctl launch $UDID nelibula.HadithEnglish
sleep 1
plutil -extract FavoriteIndex json -o - "$PREFS"
```

Expected: the final `plutil -extract` prints `["42"]` — the value survived app launch (SwiftUI
didn't overwrite it with an empty default on startup), confirming `FavoritesStore`'s init reads
existing data correctly rather than resetting it.

- [ ] **Step 4: Hand off to a human for interactive UI verification**

The following need an actual finger/cursor tap in the Simulator window and should be done by
whoever has hands-on access to it (the user, or an agent session with real touch-input tooling
— e.g. `mcp__claude-in-chrome`-style automation does not apply here since this is a native
Simulator window, not a browser tab):

1. Tap the Favorites tab and the Setup tab — confirm both render (readable text, correct icons,
   Setup shows version/rate/share/privacy rows) in both light and dark mode.
2. Open any subject, tap a hadith's star to favorite it, switch to the Favorites tab, confirm it
   appears there.
3. Background the app (swipe up) and relaunch it from the springboard — confirm the favorite
   from step 2 is still marked (this is the full UI-level version of Step 3 above).
4. Swipe-to-remove a favorite from the Favorites tab, confirm it disappears.
5. On the Hadiths tab, pull down to reveal the search bar, type "prayer", confirm the list
   filters to subjects containing "Prayer" (e.g. "Times of the Prayers", "Friday Prayer").
6. Tap "Share" on a hadith entry and on the Setup tab's "Share this app" row — confirm the
   system share sheet opens (content doesn't matter yet since the App Store URL is still a
   placeholder).

- [ ] **Step 5: Final commit**

If any of the checks above required a fix, commit that fix now with a descriptive message. If
everything passed with no changes needed, there is nothing to commit for this task — it's
verification-only.
