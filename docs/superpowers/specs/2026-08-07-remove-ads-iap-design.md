# Remove Ads In-App Purchase Design

## Goal

Add a one-time, non-consumable "Remove Ads" purchase ($2.99, product ID
`com.hadithvault.adfree`, already created in App Store Connect) so a user
who buys it never sees a native or interstitial ad again — on this device
or any other device signed into the same Apple ID, automatically.

## Dependency

`StoreKit` (first-party, `import StoreKit`) via StoreKit 2's `Product`/
`Transaction` async APIs. No SPM package needed — unlike AdMob, this
requires zero pbxproj surgery.

## Components

### 1. `RemoveAdsStore` (new, `HadithEnglish/Stores/RemoveAdsStore.swift`)

```swift
@MainActor
final class RemoveAdsStore: ObservableObject {
    static let productID = "com.hadithvault.adfree"

    @Published private(set) var isPurchased = false
    @Published private(set) var product: Product?
    @Published var isPurchasing = false
    @Published var errorMessage: String?
}
```

- `init()` starts two things: a long-running `Task` consuming
  `Transaction.updates` (catches purchases/renewals that complete outside
  the direct `purchase()` call — e.g. Ask to Buy approval), and a one-shot
  `Task` that loads the `Product` and calls `refreshEntitlements()`.
- `func purchase() async` — calls `product.purchase()`, handles
  `.success`/`.userCancelled`/`.pending`.
- `func restore() async` — calls `AppStore.sync()` then
  `refreshEntitlements()`.
- `refreshEntitlements()` iterates `Transaction.currentEntitlements` and
  sets `isPurchased = true` if `com.hadithvault.adfree` is found verified.
- Every verified transaction is `.finish()`ed. Unverified
  (`.unverified`) results are ignored, not treated as purchased — StoreKit
  2's own signature check is the only trust boundary; no server call.
- This is the app's first async/StoreKit-backed store — every other store
  is synchronous UserDefaults-backed. `@MainActor` on the whole class is
  what keeps its `@Published` mutations safe to observe from SwiftUI
  despite the async StoreKit calls underneath.

### 2. Gating — one touch point, no changes to AdManager or NativeAdCard

Both already-shipped, already-reviewed ad surfaces stay untouched.
`HadithDetailView`'s existing `if favoritesOnly { ... } else { ... }`
block (the same place that already decides "no ads for the favorites
list") gets one more condition in its `else` branch: skip the native ad
row injection AND skip both `adManager.categoryEntered()`/
`.categoryExited()` calls when `removeAdsStore.isPurchased`. This was
flagged as a Minor observation in the AdMob feature's final review ("native
ads aren't centralized behind AdManager the way interstitials are") — it
turns out to need zero rework, just one boolean added at the one call site
that already exists for the identical purpose.

### 3. Settings UI (`HadithEnglish/Views/SettingsView.swift`)

A new `Section` between the notification section and the Typography
section (visible without scrolling past unrelated settings, not buried at
the bottom near Terms/About):

- **Not purchased:** a row showing `languageStore.strings.removeAdsTitle`
  as the section header, `removeAdsDescription` as body text, and a button
  labeled `"\(removeAdsButtonTitle) – \(product.displayPrice)"` (the
  product's real, localized price — never a hardcoded "$2.99", since
  currency/price varies by App Store storefront). The button is disabled
  while `product == nil` (still loading) or `isPurchasing == true`
  (shows a `ProgressView` in that state instead of the label).
- **Purchased:** the button is replaced by a static
  `removeAdsPurchasedLabel` row ("Ads Removed", with a checkmark).
- **`Restore Purchases`:** always present in this section regardless of
  purchase state — confirmed against Apple's App Store Review Guideline
  3.1.1 during brainstorming: a restorable purchase's restore mechanism
  must stay discoverable in Settings and/or the paywall; hiding it once
  locally marked "purchased" is a documented, common rejection reason
  (a reviewer's test device may show a different state than what the
  button's visibility implies).
- On successful purchase, call `toastCenter.show(languageStore.strings.removeAdsToastMessage)`
  — reuses the existing `ToastCenter` from the share-confirmation feature,
  no new UI mechanism.
- `errorMessage`, if set, surfaces as the same toast mechanism (a failed
  purchase/restore is not a crash-worthy event, same "never block the
  experience" principle the AdMob work already established for ad
  failures).

### 4. Localization

6 new `Strings` fields (`removeAdsTitle`, `removeAdsDescription`,
`removeAdsButtonTitle`, `removeAdsPurchasedLabel`,
`restorePurchasesButtonTitle`, `removeAdsToastMessage`), translated in all
5 languages (`en`/`ar`/`tr`/`id`/`ur`), same pattern as `sharedConfirmation`
added for the share-toast feature.

### 5. What does NOT change

- Terms & Conditions / Privacy Policy links — already present in
  `SettingsView`, already correct, no new work.
- Apple's default EULA applies automatically since no custom EULA is
  configured in App Store Connect — nothing to add here.
- `AdManager.swift`, `NativeAdCard.swift` — zero changes.

## Error Handling

- `purchase()`/`restore()` failures set `errorMessage`, surfaced via the
  existing toast — never an alert, never a crash, matching the AdMob
  feature's established error-handling principle in this codebase.
- `.userCancelled` is not an error — no toast, no state change, silent
  return (same as declining the OS share sheet in the earlier toast
  feature: cancelling is a normal, silent outcome, not a failure).
- If `Product.products(for:)` fails to load (e.g. no network on first
  Settings visit), the button stays disabled/shows a loading state rather
  than a broken "$0.00" — retried automatically next time `RemoveAdsStore`
  is constructed (app relaunch) since there's no manual retry button in
  scope for a v1.

## Testing

Same deviation as the AdMob plan: no XCTest target exists in this
project. Verification is build + real simulator interaction — StoreKit 2
purchases can be tested in the simulator via a local
`.storekit` configuration file (Xcode's StoreKit Testing feature) without
hitting real App Store servers or requiring a sandbox account, which the
implementation plan will set up as part of verification.
