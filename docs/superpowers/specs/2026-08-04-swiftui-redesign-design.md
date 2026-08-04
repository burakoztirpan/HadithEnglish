# HadithEnglish: SwiftUI rewrite + App Store re-submission readiness

## Context

HadithEnglish is a 2018 UIKit/Storyboard iOS app (Swift 4.0, deployment target iOS 11.2) that
was previously published to the App Store and needs to go live again. It reads 88 hadith
subjects with translated text from a bundled JSON file, lets users mark favorites (stored in
`UserDefaults`), and has an empty, never-implemented "Setup" tab.

Verified before design work started:
- The existing project **builds and runs** on current Xcode (26.3) / iOS 26 SDK with zero
  changes, targeting a real iPhone 17 Pro simulator.
- **Dark mode is broken**: hadith detail text is fully invisible. Root cause is 2018-era
  storyboard colors — `nil` textColor (resolves to a non-adaptive black) combined with a
  hardcoded opaque white `UILabel.backgroundColor` (`calibratedRGB red=1 green=1 blue=1`,
  Main.storyboard line 151) that never got updated for iOS 13's dark mode (2019).
- **`AppIcon.appiconset` has a `Contents.json` but zero actual image files.** The app currently
  has no icon at all — this alone blocks App Store submission regardless of anything else.
- Core Data (`AppDelegate.persistentContainer`) is unused boilerplate: the `.xcdatamodeld` has
  zero entities (`<elements/>`) and nothing in the codebase references
  `NSManagedObject`/`NSFetchRequest`/`viewContext`. Favorites are actually persisted via
  `UserDefaults` under the key `"FavoriteIndex"`.
- `hadithSubject` (Model/hadithSubject.swift) is a dead class, never instantiated anywhere.
- Only `newHadithJson.json` is loaded at runtime. `hadithJson.json` and `hadithJson2.json` are
  unused leftover files.
- No `PrivacyInfo.xcprivacy` exists. The app uses `UserDefaults`, which is an Apple "required
  reason API" — App Store Connect has rejected/flagged uploads without a declared reason since
  2024.

## Decision: full SwiftUI rewrite

Given the small surface area (4 screens, ~500 lines of Swift, no third-party dependencies, no
networking), rebuilding in SwiftUI is less total work than patching the storyboard-era code
piecemeal, and produces something maintainable going forward. Storyboards, `UITableViewController`
subclasses, and the unused Core Data stack are removed entirely, not preserved for compatibility.

**Minimum deployment target: iOS 15.0.** This rules out `NavigationStack` (iOS 16+), so
navigation uses `NavigationView` — still fully functional and supported through iOS 26, just
soft-deprecated. Not worth the complexity of an `@available` branch for one API.

**Bundle ID and team stay the same** (`nelibula.HadithEnglish`, team `R83CBV3LY4`) — this is an
update to the existing App Store listing, not a new app.

## Architecture

- Pure SwiftUI app lifecycle: `@main struct HadithEnglishApp: App`, no `AppDelegate`/
  `SceneDelegate`.
- **Models** (`Models/HadithSubject.swift`): `Codable` structs matching the existing JSON shape
  unchanged — `HadithSubject { name: String, hadiths: [HadithEntry] }`,
  `HadithEntry { id: Int, hadith: String }`. Decoded once at launch from `newHadithJson.json`
  bundled in the app.
- **FavoritesStore** (`Stores/FavoritesStore.swift`): `ObservableObject` wrapping the same
  `UserDefaults` key (`"FavoriteIndex"`, `[String]` of hadith IDs) the old app used, so no data
  migration is needed for existing installs. Exposes `toggle(_ id:)`, `isFavorite(_ id:) -> Bool`,
  and a `@Published` set for reactive updates. Injected as an `EnvironmentObject` so the
  Subjects, Detail, and Favorites screens all reflect changes instantly — fixes a real staleness
  bug in the old app where the Favorites tab only refreshed via `viewWillAppear`.
- No networking, no Core Data, no third-party dependencies — matches the original app's actual
  capabilities.

## Design system

- **Colors** defined as Asset Catalog color sets with explicit Any/Dark variants (not manual
  `UITraitCollection` checks) so adaptivity is structural, not something that can be forgotten
  again:
  - Background: warm cream (light) / deep charcoal-green (dark)
  - Accent: deep calm green, used for the tab selection, favorite star, and links
  - Card/row background and separator colors follow suit
- **Typography**: Dynamic Type text styles throughout (`.title2`, `.headline`, `.body`,
  `.footnote`) so the app respects the user's accessibility text size. Hadith body text uses
  `Font.system(.body, design: .serif)` for a reading feel; UI chrome (nav titles, tab labels,
  buttons) stays system sans.
- **Layout**: native `List`/`NavigationView` components with card-style rows, consistent 16pt
  horizontal padding. No custom chrome — inherits system materials, safe area handling, and dark
  mode for free.

## Screens

1. **Subjects** (`Hadiths` tab) — `List` of the 88 subject names from the JSON, `.searchable`
   added (new — 88 items is a lot to scroll blind), `NavigationLink` to detail.
2. **Hadith Detail** — subject name as nav title, hadith entries as cards (id badge + serif body
   text). One-tap favorite star button replaces the old 3-tap `UIAlertController` action sheet.
   `ShareLink` (system share sheet) replaces the old share action that only printed to console.
3. **Favorites** — same card style, list pulled reactively from `FavoritesStore`, swipe-to-remove
   via native `.swipeActions`.
4. **Setup → Settings** (new content for a tab that has been an empty, unconnected
   `UINavigationController` since 2018): app version/build number, "Rate on the App Store",
   "Share this app" (`ShareLink` to the App Store URL), Privacy Policy link, short About text.
   **Privacy Policy URL is a placeholder** (`TODO` clearly marked in code) — no URL exists yet;
   user will supply one before App Store Connect submission.

## App Store compliance

- Generate a real `AppIcon.appiconset`: a simple icon in the new palette (not a professional
  logo — a clean minimal mark), full required size set including the 1024×1024 marketing icon.
- Add `PrivacyInfo.xcprivacy` declaring `UserDefaults` usage with reason code `CA92.1` (app
  accesses UserDefaults it created itself — matches actual usage).
- Bump `IPHONEOS_DEPLOYMENT_TARGET` to 15.0, `SWIFT_VERSION` to 5.0.
- Remove the legacy `UIRequiredDeviceCapabilities: [armv7]` key (meaningless on arm64-only
  builds).
- Delete `hadithJson.json`, `hadithJson2.json` (unused), the Core Data stack and `.xcdatamodeld`,
  and `Model/hadithSubject.swift` (dead code) rather than carrying them forward unused.

## Testing

- Unit tests for `FavoritesStore` (add/remove/toggle, persistence round-trip through
  `UserDefaults`) and for JSON decoding of `newHadithJson.json` into `[HadithSubject]`.
- No UI test suite — matches the project's actual complexity; manual simulator verification
  (light/dark mode, favorite/unfavorite flow, search) is sufficient for 4 screens with no complex
  state machines.

## Out of scope

- No new features beyond what's listed (no notifications, no additional hadith collections, no
  localization/Turkish translation — the app is English-only hadith content, matching the
  original).
- No change to the underlying hadith data/content.
