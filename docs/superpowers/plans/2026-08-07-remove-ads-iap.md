# Remove Ads In-App Purchase Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a one-time, non-consumable "Remove Ads" purchase (`com.hadithvault.adfree`, $2.99, already live in App Store Connect) that permanently hides both ad surfaces (native cards, interstitials) once bought, synced automatically across the user's devices via StoreKit 2.

**Architecture:** A new `RemoveAdsStore` (StoreKit 2, `Product`/`Transaction` async APIs) is the single source of truth for purchase state. `HadithDetailView`'s existing `favoritesOnly` gate — the same `if/else` that already decides "no ads for the favorites list" — gets one more condition added at its two existing ad call sites. `AdManager.swift` and `NativeAdCard.swift` are not touched at all.

**Tech Stack:** `StoreKit` (first-party, no SPM package needed — unlike the AdMob plan, there is no dependency-addition risk in this plan).

## Global Constraints

- Product ID `com.hadithvault.adfree`, price shown from `product.displayPrice` — never a hardcoded "$2.99" string anywhere in the code.
- iOS deployment target is 16.0 — no availability guards needed for any StoreKit 2 API used here (all available since iOS 15).
- `AdManager.swift` and `NativeAdCard.swift` must not change in this plan — the whole point of the gating design is that they don't need to.
- "Restore Purchases" must always be visible in Settings, regardless of purchase state — confirmed against App Store Review Guideline 3.1.1 during brainstorming (hiding a restore control once a device shows "purchased" is a documented, common rejection reason).
- No test target exists in this project (same pre-existing condition as the AdMob plan) — verification throughout is build + real device/simulator interaction.

**Deviation from the design spec's Testing section:** the spec suggested a local `.storekit` Testing Configuration file for simulator purchase testing. Investigating the actual project during planning found **no `.xcscheme` file exists at all** in this project (`HadithEnglish.xcodeproj/xcuserdata/.../xcschemes/` is empty — Xcode has always used its own silent auto-generated scheme, never an explicitly saved one). Setting a StoreKit Configuration is a `LaunchAction` property that only exists inside a real, saved `.xcscheme` XML file — there is nothing to hand-edit. Hand-authoring a complete `.xcscheme` from scratch (BuildableReference blocks, matching UUIDs, every action's required attributes) to add one setting is a materially bigger, higher-blast-radius risk than the AdMob plan's SPM pbxproj surgery, since a malformed scheme can break every future build in this project, not just this feature. Separately, credential entry (signing into a Sandbox Apple ID to complete a real test purchase) is something no agent should ever do — that's the user's own action regardless of tooling. Given both of these, this plan's final verification is scoped to what's honestly automatable without either risk: confirm the real product's price loads from Apple's servers and every UI state (loading/not-purchased/purchasing/purchased) renders correctly. **Completing an actual test purchase is a manual step for the user afterward**, using their own Sandbox Tester Apple ID signed into Settings → App Store → Sandbox Account on the test device — this is called out explicitly at the end of the plan, not silently skipped.

---

### Task 1: RemoveAdsStore — StoreKit 2 purchase state

**Files:**
- Create: `HadithEnglish/Stores/RemoveAdsStore.swift`
- Modify: `HadithEnglish.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces:
  ```swift
  @MainActor
  final class RemoveAdsStore: ObservableObject {
      static let productID = "com.hadithvault.adfree"
      @Published private(set) var isPurchased: Bool
      @Published private(set) var product: Product?
      @Published var isPurchasing: Bool
      @Published var errorMessage: String?
      init()
      func purchase() async
      func restore() async
  }
  ```
  Task 3 injects this via `.environmentObject`. Task 4 reads `isPurchased` from `HadithDetailView`.

- [ ] **Step 1: Create RemoveAdsStore.swift**

```swift
import Foundation
import StoreKit

/// Single source of truth for the "Remove Ads" one-time purchase.
/// `isPurchased` becoming true is what every ad surface in the app checks
/// before doing anything - see HadithDetailView, which is the only other
/// file that reads this store.
@MainActor
final class RemoveAdsStore: ObservableObject {
    static let productID = "com.hadithvault.adfree"

    @Published private(set) var isPurchased = false
    @Published private(set) var product: Product?
    @Published var isPurchasing = false
    @Published var errorMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        // Catches purchases/renewals that complete outside a direct
        // purchase() call on this device (e.g. Ask to Buy approval,
        // or a purchase made on another device syncing in).
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
        Task { [weak self] in
            await self?.loadProduct()
            await self?.refreshEntitlements()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        for await result in Transaction.currentEntitlements {
            await handle(result)
        }
    }

    func purchase() async {
        guard let product else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handle(verification)
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        // StoreKit 2's own cryptographic signature check is the only
        // trust boundary here - .unverified results are treated as not
        // purchased, never as a fallback "probably fine."
        guard case .verified(let transaction) = result else { return }
        if transaction.productID == Self.productID {
            isPurchased = true
        }
        await transaction.finish()
    }
}
```

Save to `HadithEnglish/Stores/RemoveAdsStore.swift`.

- [ ] **Step 2: Register RemoveAdsStore.swift in the Xcode project**

In `HadithEnglish.xcodeproj/project.pbxproj`, find:

```
		7F4D1D7169BE3317664EBF2D /* NativeAdCard.swift in Sources */ = {isa = PBXBuildFile; fileRef = C8797FBFC6E2B343F6974BBD /* NativeAdCard.swift */; };
```

This line may not sit immediately before `/* End PBXBuildFile section */` — this project's `PBXBuildFile`/`PBXFileReference` sections are UUID-ordered, not insertion-ordered (confirmed across every file added this session). Insert the new line directly after the line above, wherever it actually sits in the file:

```
		7F4D1D7169BE3317664EBF2D /* NativeAdCard.swift in Sources */ = {isa = PBXBuildFile; fileRef = C8797FBFC6E2B343F6974BBD /* NativeAdCard.swift */; };
		510D4DFC7F4806BDFE4BE3B4 /* RemoveAdsStore.swift in Sources */ = {isa = PBXBuildFile; fileRef = C802E6CE92C7E83E04DBEA81 /* RemoveAdsStore.swift */; };
```

Find:

```
		C8797FBFC6E2B343F6974BBD /* NativeAdCard.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = NativeAdCard.swift; path = HadithEnglish/Views/NativeAdCard.swift; sourceTree = SOURCE_ROOT; };
```

Insert directly after it (same non-adjacency caveat as above):

```
		C8797FBFC6E2B343F6974BBD /* NativeAdCard.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = NativeAdCard.swift; path = HadithEnglish/Views/NativeAdCard.swift; sourceTree = SOURCE_ROOT; };
		C802E6CE92C7E83E04DBEA81 /* RemoveAdsStore.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = RemoveAdsStore.swift; path = HadithEnglish/Stores/RemoveAdsStore.swift; sourceTree = SOURCE_ROOT; };
```

Find:

```
				C8797FBFC6E2B343F6974BBD /* NativeAdCard.swift */,
```

Replace with:

```
				C8797FBFC6E2B343F6974BBD /* NativeAdCard.swift */,
				C802E6CE92C7E83E04DBEA81 /* RemoveAdsStore.swift */,
```

Find:

```
				7F4D1D7169BE3317664EBF2D /* NativeAdCard.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */
```

Replace with:

```
				7F4D1D7169BE3317664EBF2D /* NativeAdCard.swift in Sources */,
				510D4DFC7F4806BDFE4BE3B4 /* RemoveAdsStore.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */
```

- [ ] **Step 3: Build**

```bash
cd "/Users/burakmacminim4/Desktop/hadiths app"
xcodebuild -scheme HadithEnglish -configuration Debug -destination "generic/platform=iOS Simulator" build 2>&1 | tail -30
```

Expected: `** BUILD SUCCEEDED **`. `RemoveAdsStore` isn't wired into the app yet (Task 3 does that) — this only proves it compiles standalone.

- [ ] **Step 4: Commit**

```bash
git add HadithEnglish/Stores/RemoveAdsStore.swift HadithEnglish.xcodeproj/project.pbxproj
git commit -m "Add RemoveAdsStore: StoreKit 2 non-consumable purchase state"
```

---

### Task 2: Localization strings

**Files:**
- Modify: `HadithEnglish/Models/AppLanguage.swift`

**Interfaces:**
- Produces: 6 new `Strings` fields — `removeAdsTitle`, `removeAdsDescription`, `removeAdsButtonTitle`, `removeAdsPurchasedLabel`, `restorePurchasesButtonTitle`, `removeAdsToastMessage`. Task 3's `SettingsView` edit reads all 6 by these exact names.

- [ ] **Step 1: Add the 6 fields to the Strings struct**

Find:

```swift
    let hadithTooLongForCard: String
    let sharedConfirmation: String
}
```

Replace with:

```swift
    let hadithTooLongForCard: String
    let sharedConfirmation: String
    let removeAdsTitle: String
    let removeAdsDescription: String
    let removeAdsButtonTitle: String
    let removeAdsPurchasedLabel: String
    let restorePurchasesButtonTitle: String
    let removeAdsToastMessage: String
}
```

- [ ] **Step 2: Add English values**

Find:

```swift
                hadithTooLongForCard: "This hadith is too long to fit on an image card. You can still share it as text.",
                sharedConfirmation: "Shared"
            )
```

Replace with:

```swift
                hadithTooLongForCard: "This hadith is too long to fit on an image card. You can still share it as text.",
                sharedConfirmation: "Shared",
                removeAdsTitle: "Remove Ads",
                removeAdsDescription: "Support the app and enjoy an ad-free reading experience.",
                removeAdsButtonTitle: "Remove Ads",
                removeAdsPurchasedLabel: "Ads Removed",
                restorePurchasesButtonTitle: "Restore Purchases",
                removeAdsToastMessage: "Ads removed!"
            )
```

- [ ] **Step 3: Add Arabic values**

Find:

```swift
                hadithTooLongForCard: "هذا الحديث طويل جدًا ليتناسب مع بطاقة الصورة. يمكنك مشاركته كنص بدلاً من ذلك.",
                sharedConfirmation: "تمت المشاركة"
            )
```

Replace with:

```swift
                hadithTooLongForCard: "هذا الحديث طويل جدًا ليتناسب مع بطاقة الصورة. يمكنك مشاركته كنص بدلاً من ذلك.",
                sharedConfirmation: "تمت المشاركة",
                removeAdsTitle: "إزالة الإعلانات",
                removeAdsDescription: "ادعم التطبيق واستمتع بتجربة قراءة خالية من الإعلانات.",
                removeAdsButtonTitle: "إزالة الإعلانات",
                removeAdsPurchasedLabel: "تمت إزالة الإعلانات",
                restorePurchasesButtonTitle: "استعادة المشتريات",
                removeAdsToastMessage: "تمت إزالة الإعلانات!"
            )
```

- [ ] **Step 4: Add Turkish values**

Find:

```swift
                hadithTooLongForCard: "Bu hadis görsel bir karta sığmayacak kadar uzun. Bunun yerine metin olarak paylaşabilirsiniz.",
                sharedConfirmation: "Paylaşıldı"
            )
```

Replace with:

```swift
                hadithTooLongForCard: "Bu hadis görsel bir karta sığmayacak kadar uzun. Bunun yerine metin olarak paylaşabilirsiniz.",
                sharedConfirmation: "Paylaşıldı",
                removeAdsTitle: "Reklamları Kaldır",
                removeAdsDescription: "Uygulamayı destekleyin ve reklamsız bir okuma deneyiminin tadını çıkarın.",
                removeAdsButtonTitle: "Reklamları Kaldır",
                removeAdsPurchasedLabel: "Reklamlar Kaldırıldı",
                restorePurchasesButtonTitle: "Satın Alımları Geri Yükle",
                removeAdsToastMessage: "Reklamlar kaldırıldı!"
            )
```

- [ ] **Step 5: Add Indonesian values**

Find:

```swift
                hadithTooLongForCard: "Hadis ini terlalu panjang untuk kartu gambar. Anda tetap bisa membagikannya sebagai teks.",
                sharedConfirmation: "Berhasil dibagikan"
            )
```

Replace with:

```swift
                hadithTooLongForCard: "Hadis ini terlalu panjang untuk kartu gambar. Anda tetap bisa membagikannya sebagai teks.",
                sharedConfirmation: "Berhasil dibagikan",
                removeAdsTitle: "Hapus Iklan",
                removeAdsDescription: "Dukung aplikasi ini dan nikmati pengalaman membaca tanpa iklan.",
                removeAdsButtonTitle: "Hapus Iklan",
                removeAdsPurchasedLabel: "Iklan Dihapus",
                restorePurchasesButtonTitle: "Pulihkan Pembelian",
                removeAdsToastMessage: "Iklan berhasil dihapus!"
            )
```

- [ ] **Step 6: Add Urdu values**

Find:

```swift
                hadithTooLongForCard: "یہ حدیث تصویری کارڈ میں سمانے کے لیے بہت طویل ہے۔ آپ اسے متن کے طور پر شیئر کر سکتے ہیں۔",
                sharedConfirmation: "شیئر ہو گیا"
            )
```

Replace with:

```swift
                hadithTooLongForCard: "یہ حدیث تصویری کارڈ میں سمانے کے لیے بہت طویل ہے۔ آپ اسے متن کے طور پر شیئر کر سکتے ہیں۔",
                sharedConfirmation: "شیئر ہو گیا",
                removeAdsTitle: "اشتہارات ہٹائیں",
                removeAdsDescription: "ایپ کو سپورٹ کریں اور اشتہارات کے بغیر پڑھنے کا تجربہ حاصل کریں۔",
                removeAdsButtonTitle: "اشتہارات ہٹائیں",
                removeAdsPurchasedLabel: "اشتہارات ہٹا دیے گئے",
                restorePurchasesButtonTitle: "خریداری بحال کریں",
                removeAdsToastMessage: "اشتہارات ہٹا دیے گئے!"
            )
```

- [ ] **Step 7: Build**

```bash
cd "/Users/burakmacminim4/Desktop/hadiths app"
xcodebuild -scheme HadithEnglish -configuration Debug -destination "generic/platform=iOS Simulator" build 2>&1 | tail -30
```

Expected: `** BUILD SUCCEEDED **`. If it fails with "missing argument" for any of the 5 `Strings(...)` call sites, one of the 5 language cases was missed — every case must supply all 6 new fields since `Strings` has no default values.

- [ ] **Step 8: Commit**

```bash
git add HadithEnglish/Models/AppLanguage.swift
git commit -m "Add Remove Ads strings in all 5 languages"
```

---

### Task 3: Wire RemoveAdsStore into the app and Settings UI

**Files:**
- Modify: `HadithEnglish/HadithEnglishApp.swift`
- Modify: `HadithEnglish/Views/SettingsView.swift`

**Interfaces:**
- Consumes: `RemoveAdsStore` (Task 1), the 6 new `Strings` fields (Task 2), `ToastCenter` (already exists, from the share-confirmation feature).
- Produces: nothing new for later tasks — Task 4 reads `RemoveAdsStore` directly via its own `@EnvironmentObject`, not through anything this task adds.

- [ ] **Step 1: Inject RemoveAdsStore as an environment object**

In `HadithEnglish/HadithEnglishApp.swift`, find:

```swift
    @StateObject private var adManager = AdManager()
    @Environment(\.scenePhase) private var scenePhase
```

Replace with:

```swift
    @StateObject private var adManager = AdManager()
    @StateObject private var removeAdsStore = RemoveAdsStore()
    @Environment(\.scenePhase) private var scenePhase
```

Find:

```swift
            .environmentObject(adManager)
            .environment(\.layoutDirection, languageStore.language.isRightToLeft ? .rightToLeft : .leftToRight)
```

Replace with:

```swift
            .environmentObject(adManager)
            .environmentObject(removeAdsStore)
            .environment(\.layoutDirection, languageStore.language.isRightToLeft ? .rightToLeft : .leftToRight)
```

- [ ] **Step 2: Add the Remove Ads section to SettingsView**

Read the current `HadithEnglish/Views/SettingsView.swift` in full first — it may have picked up edits since this plan was written. Then apply these changes.

Add two environment objects alongside the existing ones:

```swift
struct SettingsView: View {
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var notificationStore: NotificationStore
    @EnvironmentObject private var typographyStore: TypographyStore
    @EnvironmentObject private var removeAdsStore: RemoveAdsStore
    @EnvironmentObject private var toastCenter: ToastCenter
```

Add two new private methods (place them near `appVersion`/`buildNumber`):

```swift
    private var removeAdsButtonLabel: String {
        if let price = removeAdsStore.product?.displayPrice {
            return "\(languageStore.strings.removeAdsButtonTitle) – \(price)"
        }
        return languageStore.strings.removeAdsButtonTitle
    }

    private func purchaseRemoveAds() async {
        await removeAdsStore.purchase()
        if removeAdsStore.isPurchased {
            toastCenter.show(languageStore.strings.removeAdsToastMessage)
        } else if let error = removeAdsStore.errorMessage {
            toastCenter.show(error)
        }
    }

    private func restorePurchases() async {
        await removeAdsStore.restore()
        if removeAdsStore.isPurchased {
            toastCenter.show(languageStore.strings.removeAdsToastMessage)
        } else if let error = removeAdsStore.errorMessage {
            toastCenter.show(error)
        }
    }
```

Add a new `Section` in `body`. Find:

```swift
                Section(languageStore.strings.typographyLabel) {
```

Insert directly before it:

```swift
                Section {
                    if removeAdsStore.isPurchased {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color("AccentColor"))
                            Text(languageStore.strings.removeAdsPurchasedLabel)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(languageStore.strings.removeAdsDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Button {
                                Task { await purchaseRemoveAds() }
                            } label: {
                                if removeAdsStore.isPurchasing {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Text(removeAdsButtonLabel)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(removeAdsStore.product == nil || removeAdsStore.isPurchasing)
                        }
                        .padding(.vertical, 4)
                    }
                    // Always visible regardless of purchase state - App Store
                    // Review Guideline 3.1.1 requires a discoverable restore
                    // mechanism; hiding it once "purchased" is a documented,
                    // common rejection reason.
                    Button(languageStore.strings.restorePurchasesButtonTitle) {
                        Task { await restorePurchases() }
                    }
                } header: {
                    Text(languageStore.strings.removeAdsTitle)
                }
                Section(languageStore.strings.typographyLabel) {
```

(This produces one `Section(languageStore.strings.typographyLabel) {` line at the end — the original line stays, only a new full `Section { ... }` block is inserted before it.)

- [ ] **Step 3: Build**

```bash
cd "/Users/burakmacminim4/Desktop/hadiths app"
xcodebuild -scheme HadithEnglish -configuration Debug -destination "generic/platform=iOS Simulator" build 2>&1 | tail -30
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Verify the product price loads on a simulator**

```bash
cd "/Users/burakmacminim4/Desktop/hadiths app"
SIM=$(xcrun simctl list devices | grep -m1 "Booted" | grep -oE '[0-9A-F-]{36}')
if [ -z "$SIM" ]; then
  SIM=$(xcrun simctl list devices available | grep -m1 "iPhone" | grep -oE '[0-9A-F-]{36}')
  xcrun simctl boot $SIM
  sleep 5
fi
DERIVED="/tmp/removeads_task3_build"
xcodebuild -scheme HadithEnglish -configuration Debug -destination "id=$SIM" -derivedDataPath "$DERIVED" build 2>&1 | tail -20
xcrun simctl install $SIM "$DERIVED/Build/Products/Debug-iphonesimulator/HadithEnglish.app"
xcrun simctl launch $SIM nelibula.HadithEnglish
sleep 3
```

Navigate to the Setup/Settings tab. Wait a couple seconds for the network
fetch, then:

```bash
xcrun simctl io $SIM screenshot /tmp/removeads_task3_check.png
```

Read `/tmp/removeads_task3_check.png`. Expected: a "Remove Ads" section
with a button reading "Remove Ads – $2.99" (or whatever the real App
Store Connect price is — this is fetched live from Apple's servers using
the real `com.hadithvault.adfree` product ID, no sandbox account needed
just to read price metadata) and a separate "Restore Purchases" row below
it. If the button instead shows a spinner or is disabled after several
seconds, check `xcrun simctl spawn $SIM log stream --predicate
'eventMessage contains "RemoveAdsStore"'` — there is no `print`/log
statement in `RemoveAdsStore` itself, so if the product genuinely fails
to load, add a temporary print in `loadProduct()`'s catch block to see
the actual error, remove it before committing.

- [ ] **Step 5: Commit**

```bash
git add HadithEnglish/HadithEnglishApp.swift HadithEnglish/Views/SettingsView.swift
git commit -m "Add Remove Ads purchase UI to Settings"
```

---

### Task 4: Gate both ad surfaces on purchase state, final device verification

**Files:**
- Modify: `HadithEnglish/Views/HadithDetailView.swift`

**Interfaces:**
- Consumes: `RemoveAdsStore.isPurchased` (Task 1).
- Produces: the finished feature — nothing downstream depends on this task.

- [ ] **Step 1: Add the purchase gate to HadithDetailView**

Read the current `HadithEnglish/Views/HadithDetailView.swift` in full first — confirm it still matches the state below (it was last touched by the AdMob plan's Task 5).

Add `@EnvironmentObject private var removeAdsStore: RemoveAdsStore` alongside the view's other environment objects:

```swift
struct HadithDetailView: View {
    let subject: HadithSubject
    var favoritesOnly: Bool = false
    @EnvironmentObject private var lastRead: LastReadStore
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var adManager: AdManager
    @EnvironmentObject private var removeAdsStore: RemoveAdsStore
```

Find:

```swift
                } else {
                    HadithCardView(entry: entry)
                        .listRowBackground(Color("CardBackground"))
                    if (index + 1) % 8 == 0 {
                        NativeAdCard()
                            .listRowBackground(Color("CardBackground"))
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(subject.trimmedName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !favoritesOnly {
                lastRead.recordVisit(to: subject)
                adManager.categoryEntered()
            }
        }
        .onDisappear {
            if !favoritesOnly {
                adManager.categoryExited()
            }
        }
```

Replace with:

```swift
                } else {
                    HadithCardView(entry: entry)
                        .listRowBackground(Color("CardBackground"))
                    if !removeAdsStore.isPurchased && (index + 1) % 8 == 0 {
                        NativeAdCard()
                            .listRowBackground(Color("CardBackground"))
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(subject.trimmedName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !favoritesOnly {
                lastRead.recordVisit(to: subject)
                if !removeAdsStore.isPurchased {
                    adManager.categoryEntered()
                }
            }
        }
        .onDisappear {
            if !favoritesOnly && !removeAdsStore.isPurchased {
                adManager.categoryExited()
            }
        }
```

- [ ] **Step 2: Build**

```bash
cd "/Users/burakmacminim4/Desktop/hadiths app"
xcodebuild -scheme HadithEnglish -configuration Debug -destination "generic/platform=iOS Simulator" build 2>&1 | tail -30
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Verify native ad injection stops when purchased (simulator)**

```bash
cd "/Users/burakmacminim4/Desktop/hadiths app"
SIM=$(xcrun simctl list devices | grep -m1 "Booted" | grep -oE '[0-9A-F-]{36}')
DERIVED="/tmp/removeads_task4_build"
xcodebuild -scheme HadithEnglish -configuration Debug -destination "id=$SIM" -derivedDataPath "$DERIVED" build 2>&1 | tail -20
xcrun simctl install $SIM "$DERIVED/Build/Products/Debug-iphonesimulator/HadithEnglish.app"
```

There is no code path to *complete* a real purchase without a signed-in
Apple ID (out of scope, see the plan's Global Constraints), so directly
observing "no ad after purchase" isn't possible here. Instead, verify the
gate itself is correctly wired by reading the diff you just wrote in Step
1 against this checklist — confirm by inspection, not by exercising a
real purchase:
1. The native ad `if` condition now starts with `!removeAdsStore.isPurchased &&` — the ORIGINAL `(index + 1) % 8 == 0` condition is still there, unchanged, just AND'ed with the new one.
2. Both `adManager.categoryEntered()` and `adManager.categoryExited()` calls are now behind an additional `!removeAdsStore.isPurchased` check, nested inside the existing `!favoritesOnly` check (not replacing it).
3. `favoritesOnly` behavior (the branch that shows the swipe-to-remove card style) is completely untouched by this diff.

Also launch and screenshot once, unpurchased, to confirm nothing broke:

```bash
xcrun simctl launch $SIM nelibula.HadithEnglish
sleep 3
xcrun simctl io $SIM screenshot /tmp/removeads_task4_check.png
```

Read `/tmp/removeads_task4_check.png` — expected: app launches normally,
no crash. Navigate to a long subject's detail list and confirm the native
ad card still appears every 8th row (unpurchased state, so the new
condition should have no visible effect) — this proves the added `&&`
didn't accidentally break the pre-existing behavior.

- [ ] **Step 4: Build and install to the physical device for the user**

```bash
cd "/Users/burakmacminim4/Desktop/hadiths app"
xcodebuild -scheme HadithEnglish -configuration Debug -destination "id=00008110-00145830010BA01E" -allowProvisioningUpdates build 2>&1 | tail -20
DERIVED="/Users/burakmacminim4/Library/Developer/Xcode/DerivedData/HadithEnglish-eqlxusulikuopheqouozmgpeuexh"
xcrun devicectl device install app --device 00008110-00145830010BA01E "$DERIVED/Build/Products/Debug-iphoneos/HadithEnglish.app"
xcrun devicectl device process launch --device 00008110-00145830010BA01E nelibula.HadithEnglish
```

Expected: `** BUILD SUCCEEDED **`, `App installed:` confirmation, and
`Launched application with nelibula.HadithEnglish bundle identifier.`
This is the same device (Burak's iPhone 13) and the same command sequence
already used successfully earlier in this session for the AdMob feature.

- [ ] **Step 5: Commit**

```bash
git add HadithEnglish/Views/HadithDetailView.swift
git commit -m "Gate native ads and interstitial triggers on Remove Ads purchase"
```

- [ ] **Step 6: Tell the user what manual testing remains**

This plan's automation stops at "the purchase button shows the real price
and both ad surfaces are provably gated by inspection." Completing an
actual purchase to see `isPurchased` flip to `true` on the real device
requires the user's own Sandbox Tester Apple ID
(App Store Connect → Users and Access → Sandbox Testers → create one if
none exists) signed into the test device's Settings → App Store →
Sandbox Account. No agent should ever enter Apple ID credentials on the
user's behalf — this step is the user's alone. Report this clearly as
the final message of this task, not as a silent gap.
