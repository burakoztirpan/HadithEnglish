# Hadith Vault iPhone App Store Media Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Capture the current Hadith Vault SwiftUI experience and produce a conversion-focused set of eight 1284 × 2778 iPhone App Store screenshots with large readable headlines, realistic device framing and the real production icon.

**Architecture:** Work from a temporary copy of the user's current dirty working tree so uncommitted UI changes are included without modifying production source. Add a temporary launch-argument capture router only inside that copy, capture eight deterministic real app states on the existing iPhone 14 Plus simulator, then use one reusable Pillow compositor and one validator in the real repository to generate and verify the final `marketing-v2` package.

**Tech Stack:** SwiftUI, `xcodebuild`, `xcrun simctl`, Python 3, Pillow, App Store PNG assets.

## Global Constraints

- Final upload files are exactly 1284 × 2778 px, portrait, RGB PNG with no alpha channel.
- Work only on the English iPhone set; iPad is out of scope until the iPhone set is approved.
- Preserve `store_assets/ios/iphone/6.7-inch/en-US/marketing/` byte-for-byte.
- Include the user's current uncommitted `HomeView.swift` and `LaunchScreen.storyboard` changes in captures, but do not stage or commit those files.
- Every in-device screen is a real capture from the current SwiftUI application; no UI regeneration inside the device frame.
- Hide consent prompts, ads, debug banners, loading states, toasts and system sheets.
- Use `HadithEnglish/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` as the only marketing logo mark.
- Primary headlines use 96–116 px display type and no more than two lines.
- Existing factual claims are limited to verified bundled data: 97 books, 7,248 English hadiths, and five bundled languages.

---

## File Structure

**Create:**

- `scripts/store_media/generate_iphone_store_v2.py` — deterministic compositor for all eight marketing images, contact sheet and search-scale preview.
- `scripts/store_media/validate_iphone_store_v2.py` — dimension, mode, filename, real-icon and legacy-hash checks.
- `scripts/store_media/README.md` — reproduction commands and capture-state map.
- `store_assets/ios/iphone/6.7-inch/en-US/raw-v2/*.png` — eight real simulator captures.
- `store_assets/ios/iphone/6.7-inch/en-US/marketing-v2/*.png` — eight App Store upload files.
- `store_assets/ios/iphone/6.7-inch/en-US/marketing-v2/ios_iphone_store_contact-sheet.jpg` — internal visual QA only.
- `store_assets/ios/iphone/6.7-inch/en-US/marketing-v2/ios_iphone_store_search-preview.jpg` — internal first-three readability QA only.
- `store_assets/ios/iphone/6.7-inch/en-US/marketing-v2/README.md` — upload order and usage notes.

**Temporary only, under `/private/tmp/hadith-vault-store-capture/`:**

- Complete working-tree snapshot excluding `.git`, `build` and existing store outputs.
- Capture-only edits to `HadithEnglish/HadithEnglishApp.swift` implementing `--store-capture-mode`.
- Xcode DerivedData.

**Do not modify:**

- Production Swift source in `/Users/burakmacminim4/Desktop/hadiths app/HadithEnglish/`.
- Existing `store_assets/ios/iphone/6.7-inch/en-US/marketing/` images.

---

### Task 1: Baseline, legacy hashes and isolated capture copy

**Files:**
- Read: `HadithEnglish/Views/*.swift`
- Read: `store_assets/ios/iphone/6.7-inch/en-US/marketing/*.png`
- Create temporary: `/private/tmp/hadith-vault-store-capture/project/`

**Interfaces:**
- Consumes: current working tree and the iPhone 14 Plus simulator UDID `E85BD386-57B7-4CAA-BFC9-9B0F7183AB9A`.
- Produces: isolated source snapshot and `/private/tmp/hadith-vault-store-capture/legacy-sha256.txt`.

- [ ] **Step 1: Record the current repository state without changing it**

Run:

```bash
git status --short
git rev-parse HEAD
```

Expected: `HomeView.swift` and `LaunchScreen.storyboard` remain visible as user changes; no store-media-v2 files exist yet.

- [ ] **Step 2: Hash the existing upload set**

Run:

```bash
mkdir -p /private/tmp/hadith-vault-store-capture
shasum -a 256 store_assets/ios/iphone/6.7-inch/en-US/marketing/ios_iphone_store_0*.png > /private/tmp/hadith-vault-store-capture/legacy-sha256.txt
```

Expected: eight hash lines.

- [ ] **Step 3: Copy the current working tree into an isolated capture project**

Run:

```bash
rsync -a --delete --exclude=.git --exclude=build --exclude=store_assets '/Users/burakmacminim4/Desktop/hadiths app/' /private/tmp/hadith-vault-store-capture/project/
```

Expected: the temporary copy contains the current uncommitted `HomeView.swift`, while the real repository remains unchanged.

- [ ] **Step 4: Confirm capture simulator and target dimensions**

Run:

```bash
xcrun simctl list devices available
```

Expected: `iPhone 14 Plus (Screenshots)` with UDID `E85BD386-57B7-4CAA-BFC9-9B0F7183AB9A` is available.

---

### Task 2: Temporary deterministic capture router

**Files:**
- Modify temporary only: `/private/tmp/hadith-vault-store-capture/project/HadithEnglish/HadithEnglishApp.swift`

**Interfaces:**
- Consumes: launch argument `--store-capture-mode <mode>` where mode is `home`, `reader`, `subjects`, `favorites`, `share`, `settings`, `arabic`, or `dark`.
- Produces: real production views rendered directly in deterministic states without interactive navigation.

- [ ] **Step 1: Add capture-mode parsing in the temporary app**

Add this temporary type above `HadithEnglishApp`:

```swift
private enum StoreCaptureMode: String {
    case home, reader, subjects, favorites, share, settings, arabic, dark

    static var current: StoreCaptureMode? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "--store-capture-mode"),
              arguments.indices.contains(index + 1)
        else { return nil }
        return StoreCaptureMode(rawValue: arguments[index + 1])
    }
}
```

- [ ] **Step 2: Add a capture-only root using actual application views**

Add a `StoreCaptureRoot` whose `@ViewBuilder` returns:

```swift
private struct StoreCaptureRoot: View {
    let mode: StoreCaptureMode
    let subjects: [HadithSubject]
    @EnvironmentObject private var favorites: FavoritesStore
    @State private var didSeedFavorites = false

    private var readerSubject: HadithSubject? {
        subjects.first { $0.trimmedName == "Invocations" } ?? subjects.first
    }

    private var shareEntry: (HadithSubject, HadithEntry)? {
        for subject in subjects {
            if let entry = subject.hadiths.first(where: { $0.trimmedText.count >= 180 && $0.trimmedText.count <= 420 }) {
                return (subject, entry)
            }
        }
        return nil
    }

    @ViewBuilder var body: some View {
        if subjects.isEmpty {
            ProgressView()
        } else {
            switch mode {
            case .home, .arabic, .dark:
                HomeView(subjects: subjects)
            case .reader:
                NavigationView {
                    HadithDetailView(subject: readerSubject ?? subjects[0])
                }
                .navigationViewStyle(.stack)
            case .subjects:
                SubjectsListView(subjects: subjects)
            case .favorites:
                FavoritesView(subjects: subjects)
                    .onAppear {
                        guard !didSeedFavorites else { return }
                        didSeedFavorites = true
                        let ids = subjects.prefix(8).compactMap { $0.hadiths.first?.id }
                        for id in ids where !favorites.isFavorite(id) { favorites.toggle(id) }
                    }
            case .share:
                if let (subject, entry) = shareEntry,
                   let size = ShareCardFit.fittingFontSize(for: entry.trimmedText, subtitle: subject.trimmedName) {
                    NavigationView {
                        ShareCardPreviewView(
                            text: entry.trimmedText,
                            subtitle: subject.trimmedName,
                            background: .navyGold,
                            fontSize: size,
                            onShared: {}
                        )
                    }
                    .navigationViewStyle(.stack)
                }
            case .settings:
                SettingsView()
            }
        }
    }
}
```

- [ ] **Step 3: Branch the temporary `WindowGroup` before the production `TabView`**

Inside the temporary app's `WindowGroup`, use a `Group` that renders `StoreCaptureRoot` when `StoreCaptureMode.current` is non-nil and the unchanged production `TabView` otherwise. Apply the existing environment objects and `.preferredColorScheme(themeStore.theme.colorScheme)` to the outer `Group`. Move content loading to the outer group's `.onAppear` so capture roots receive real decoded content.

- [ ] **Step 4: Force deterministic language and appearance from the capture mode**

In the outer `.onAppear`, before `content.load(languageStore.language)`, set:

```swift
if StoreCaptureMode.current == .arabic {
    languageStore.language = .ar
} else {
    languageStore.language = .en
}
themeStore.theme = StoreCaptureMode.current == .dark ? .dark : .light
content.load(languageStore.language)
```

Do not call `consentManager.requestConsentThenStartAds()` when a capture mode is active.

- [ ] **Step 5: Build the isolated project**

Run:

```bash
xcodebuild -project HadithEnglish.xcodeproj -scheme HadithEnglish -configuration Debug -destination 'platform=iOS Simulator,id=E85BD386-57B7-4CAA-BFC9-9B0F7183AB9A' -derivedDataPath /private/tmp/hadith-vault-store-capture/DerivedData build
```

Expected: `** BUILD SUCCEEDED **`.

---

### Task 3: Capture eight real application states

**Files:**
- Create: `store_assets/ios/iphone/6.7-inch/en-US/raw-v2/ios_iphone_raw_01-home.png`
- Create: `store_assets/ios/iphone/6.7-inch/en-US/raw-v2/ios_iphone_raw_02-reader.png`
- Create: `store_assets/ios/iphone/6.7-inch/en-US/raw-v2/ios_iphone_raw_03-subjects.png`
- Create: `store_assets/ios/iphone/6.7-inch/en-US/raw-v2/ios_iphone_raw_04-favorites.png`
- Create: `store_assets/ios/iphone/6.7-inch/en-US/raw-v2/ios_iphone_raw_05-share-preview.png`
- Create: `store_assets/ios/iphone/6.7-inch/en-US/raw-v2/ios_iphone_raw_06-settings.png`
- Create: `store_assets/ios/iphone/6.7-inch/en-US/raw-v2/ios_iphone_raw_07-arabic-home.png`
- Create: `store_assets/ios/iphone/6.7-inch/en-US/raw-v2/ios_iphone_raw_08-dark-home.png`

**Interfaces:**
- Consumes: the isolated build and capture-mode launch argument.
- Produces: eight 1284 × 2778 simulator screenshots.

- [ ] **Step 1: Boot, configure and install**

Run:

```bash
xcrun simctl boot E85BD386-57B7-4CAA-BFC9-9B0F7183AB9A
open -a Simulator
xcrun simctl status_bar E85BD386-57B7-4CAA-BFC9-9B0F7183AB9A override --time 9:41 --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4
xcrun simctl install E85BD386-57B7-4CAA-BFC9-9B0F7183AB9A /private/tmp/hadith-vault-store-capture/DerivedData/Build/Products/Debug-iphonesimulator/HadithEnglish.app
mkdir -p 'store_assets/ios/iphone/6.7-inch/en-US/raw-v2'
```

Expected: simulator is booted and the app is installed.

- [ ] **Step 2: Reset persistent state once**

Run:

```bash
xcrun simctl spawn E85BD386-57B7-4CAA-BFC9-9B0F7183AB9A defaults delete nelibula.HadithEnglish
```

Expected: command succeeds or reports that the domain did not exist.

- [ ] **Step 3: Capture each mode after stable rendering**

For every mapping below, run the launch command, wait two seconds, then capture:

```bash
xcrun simctl launch --terminate-running-process E85BD386-57B7-4CAA-BFC9-9B0F7183AB9A nelibula.HadithEnglish --store-capture-mode <mode>
sleep 2
xcrun simctl io E85BD386-57B7-4CAA-BFC9-9B0F7183AB9A screenshot --type=png '<output>'
```

Mappings:

```text
home      -> ios_iphone_raw_01-home.png
reader    -> ios_iphone_raw_02-reader.png
subjects  -> ios_iphone_raw_03-subjects.png
favorites -> ios_iphone_raw_04-favorites.png
share     -> ios_iphone_raw_05-share-preview.png
settings  -> ios_iphone_raw_06-settings.png
arabic    -> ios_iphone_raw_07-arabic-home.png
dark      -> ios_iphone_raw_08-dark-home.png
```

- [ ] **Step 4: Verify raw dimensions and visually inspect all eight captures**

Run:

```bash
file store_assets/ios/iphone/6.7-inch/en-US/raw-v2/*.png
```

Expected: every file reports `1284 x 2778`. Inspect one contact sheet before composition; if any capture contains a prompt, ad, loading state or empty data, fix the temporary capture state and recapture only that mode.

- [ ] **Step 5: Commit raw captures only**

```bash
git add store_assets/ios/iphone/6.7-inch/en-US/raw-v2
git commit -m "Add refreshed Hadith Vault iPhone captures"
```

---

### Task 4: Build the Editorial Premium compositor

**Files:**
- Create: `scripts/store_media/generate_iphone_store_v2.py`
- Create: `scripts/store_media/README.md`

**Interfaces:**
- Consumes: `raw-v2/*.png`, production `AppIcon-1024.png`, `ShareBackgrounds/share_bg_01_emerald.png`, and the slide specification below.
- Produces: eight marketing PNGs, a contact sheet and a 390 px-wide first-three preview.

- [ ] **Step 1: Define the slide data model and exact copy**

Use this immutable specification:

```python
SLIDES = (
    ("01-one-hadith-every-day", "ios_iphone_raw_01-home.png", "One hadith for every day", "A quiet daily ritual"),
    ("02-complete-sahih-al-bukhari", "ios_iphone_raw_02-reader.png", "The complete Sahih al-Bukhari", "97 books • 7,248 hadiths"),
    ("03-find-guidance", "ios_iphone_raw_03-subjects.png", "Find guidance for every moment", "Search by book or subject"),
    ("04-keep-what-moves-you", "ios_iphone_raw_04-favorites.png", "Keep what moves you", "Return to saved hadiths anytime"),
    ("05-share-words-that-matter", "ios_iphone_raw_05-share-preview.png", "Share words that matter", "Beautiful cards, ready to send"),
    ("06-read-your-way", "ios_iphone_raw_06-settings.png", "Read your way", "Your language, type and appearance"),
    ("07-five-languages", "ios_iphone_raw_07-arabic-home.png", "Five languages. One timeless collection.", "English • Arabic • Turkish • Indonesian • Urdu"),
    ("08-light-and-dark", "ios_iphone_raw_08-dark-home.png", "Beautiful in light and dark", "Comfortable reading, day or night"),
)
```

- [ ] **Step 2: Implement deterministic rendering helpers**

The script must expose these exact interfaces: `load_font(size: int, weight: str) -> ImageFont.FreeTypeFont`, `wrap_text(draw, text: str, face, max_width: int) -> list[str]`, `build_pattern(size: tuple[int, int], color: tuple[int, int, int, int]) -> Image.Image`, `build_brand_lockup(icon: Image.Image, light: bool) -> Image.Image`, `frame_phone(raw: Image.Image, screen_size: tuple[int, int]) -> Image.Image`, `render_slide(spec: tuple[str, str, str, str]) -> Path`, `build_contact_sheet(paths: list[Path]) -> Path`, and `build_search_preview(paths: list[Path]) -> Path`.

Rendering constants:

```python
CANVAS = (1284, 2778)
SCREEN = (900, 1948)
SCREEN_ORIGIN = (192, 790)
HEADLINE_SIZE = 108
SUPPORT_SIZE = 46
HEADLINE_MAX_WIDTH = 1110
BACKGROUND_EMERALD = "#145E4B"
BACKGROUND_CHARCOAL = "#17211F"
BACKGROUND_PARCHMENT = "#F4EDDD"
TEXT_DARK = "#17211F"
TEXT_LIGHT = "#FFFFFF"
```

Use the real app icon at 68 × 68 px in the top lockup. Give the phone a 24 px dark bezel, 68 px outer corner radius, 52 px screen corner radius, a centered Dynamic Island and a soft downward shadow. Do not skew or perspective-warp the raw screenshot.

- [ ] **Step 3: Render the complete set and QA derivatives**

Run:

```bash
python3 scripts/store_media/generate_iphone_store_v2.py
```

Expected: eight `ios_iphone_store_0*.png` files plus contact sheet and search preview are written under `marketing-v2/`.

- [ ] **Step 4: Document reproduction**

In `scripts/store_media/README.md`, document the simulator UDID, capture modes, raw/marketing paths, generator command and validator command. State that capture-only Swift changes live only in the temporary project and are never copied back.

- [ ] **Step 5: Commit the compositor**

```bash
git add scripts/store_media
git commit -m "Add Hadith Vault App Store media generator"
```

---

### Task 5: Package notes and automated validation

**Files:**
- Create: `scripts/store_media/validate_iphone_store_v2.py`
- Create: `store_assets/ios/iphone/6.7-inch/en-US/marketing-v2/README.md`

**Interfaces:**
- Consumes: final marketing files, raw captures and `/private/tmp/hadith-vault-store-capture/legacy-sha256.txt`.
- Produces: exit code 0 only when dimensions, modes, filenames, first-three ordering and legacy preservation pass.

- [ ] **Step 1: Write the validator**

The validator must assert:

```python
expected_slugs = [
    "01-one-hadith-every-day",
    "02-complete-sahih-al-bukhari",
    "03-find-guidance",
    "04-keep-what-moves-you",
    "05-share-words-that-matter",
    "06-read-your-way",
    "07-five-languages",
    "08-light-and-dark",
]
```

For each marketing PNG, open it with Pillow, assert `size == (1284, 2778)` and `mode == "RGB"`, call `verify()`, and confirm the filename order matches `expected_slugs`. For each raw PNG, assert `(1284, 2778)`. Re-run `shasum -a 256 -c /private/tmp/hadith-vault-store-capture/legacy-sha256.txt` to prove the prior set is unchanged.

- [ ] **Step 2: Write the upload README**

List the eight upload files in order. Mark the contact sheet, search preview and `raw-v2` files as internal-only. Record `1284 × 2778`, RGB PNG, English locale and real iPhone 14 Plus simulator capture source.

- [ ] **Step 3: Run automated validation**

Run:

```bash
python3 scripts/store_media/validate_iphone_store_v2.py
shasum -a 256 -c /private/tmp/hadith-vault-store-capture/legacy-sha256.txt
```

Expected: validator prints eight marketing passes, eight raw passes, and legacy hashes report `OK`.

---

### Task 6: Bounded visual QA and final delivery

**Files:**
- Inspect: `store_assets/ios/iphone/6.7-inch/en-US/marketing-v2/ios_iphone_store_contact-sheet.jpg`
- Inspect: `store_assets/ios/iphone/6.7-inch/en-US/marketing-v2/ios_iphone_store_search-preview.jpg`
- Modify only if defects are found: `scripts/store_media/generate_iphone_store_v2.py`

**Interfaces:**
- Consumes: generated set and QA derivatives.
- Produces: approved iPhone media package ready for App Store upload.

- [ ] **Step 1: First visual inspection pass**

Inspect all eight at full size and the first three at simulated 390 px App Store width. Check headline legibility, icon authenticity, device scale, safe margins, Dynamic Island alignment, shadow clipping, true RTL, dark-mode authenticity and repeated visual rhythm.

- [ ] **Step 2: Apply one consolidated correction batch**

If defects are present, change only the relevant constants or slide-specific offsets in the generator, regenerate all derivatives once, and record the reason in the marketing README. Do not repeatedly polish without a concrete defect.

- [ ] **Step 3: Final confirmation pass**

Re-run:

```bash
python3 scripts/store_media/validate_iphone_store_v2.py
git status --short
```

Expected: validation exits 0; user-owned `HomeView.swift` and `LaunchScreen.storyboard` remain unstaged and unchanged by this work.

- [ ] **Step 4: Commit final outputs**

```bash
git add scripts/store_media/validate_iphone_store_v2.py store_assets/ios/iphone/6.7-inch/en-US/raw-v2 store_assets/ios/iphone/6.7-inch/en-US/marketing-v2
git commit -m "Refresh Hadith Vault iPhone App Store media"
```

- [ ] **Step 5: Deliver for iPhone approval**

Show the contact sheet, search-scale preview and direct links to all eight upload images. Wait for explicit iPhone approval before creating any iPad assets.
