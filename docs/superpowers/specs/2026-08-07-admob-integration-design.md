# AdMob Integration Design

## Goal

Add Google AdMob monetization to Hadith Vault: native ad cards woven into
the hadith list, and interstitial ads gated by a category-navigation
counter, a dwell-time rule, and a cooldown — without ever showing an ad on
a user's very first category visit.

## Real IDs (already provisioned by the user)

- App ID: `ca-app-pub-4458416211971859~4811835333`
- Native ad unit ID: `ca-app-pub-4458416211971859/4748490256`
- Interstitial ad unit ID: `ca-app-pub-4458416211971859/1851819444`

These are real, live IDs — not test IDs. They go straight into the app;
there is no mock/swap-in-later phase for this feature (unlike RevenueCat's
gradual rollout in the other project).

## Dependency

Google Mobile Ads SDK via **Swift Package Manager**
(`https://github.com/googleads/swift-package-manager-google-mobile-ads`,
product `GoogleMobileAds`). No CocoaPods exists in this project today, and
this is Google's own supported SPM distribution.

**Risk:** the four interlinked pbxproj records an SPM dependency needs
(`XCRemoteSwiftPackageReference`, `XCSwiftPackageProductDependency`, the
project's `packageReferences` array, and the target's
`packageProductDependencies`) are more error-prone to hand-edit than a
plain source file. The implementation plan verifies with
`xcodebuild -resolvePackageDependencies` right after editing; if that
fails, the fallback is one manual step in Xcode's own UI (File → Add
Package Dependencies → paste the URL) with exact instructions handed to
the user.

## Components

### 1. `AdConfig.swift` (new, `HadithEnglish/Models/`)

Three constants: `appID`, `nativeAdUnitID`, `interstitialAdUnitID`. Single
place the real IDs live, so nothing else hardcodes them.

### 2. `Info.plist` changes

- `GADApplicationIdentifier` = the App ID.
- `NSUserTrackingUsageDescription` — a short, honest string ("This
  identifier will be used to deliver personalized ads to you."),
  localized the same way other user-facing strings are (`AppLanguage.swift`
  already covers 5 languages — this one string is app-metadata, not a
  `Strings` struct field, so it goes directly into each language's
  `InfoPlist.strings` — see Localization below).
- `SKAdNetworkItems` — Google's current published list of ad-network IDs
  for AdMob mediation (a fixed array Apple requires for any app showing
  ads, independent of ATT permission status).

### 3. App Tracking Transparency

A new `TrackingPermissionRequester` (or inlined into `HadithEnglishApp`'s
`onAppear`) calls `ATTrackingManager.requestTrackingAuthorization` once,
after a short delay on first launch (Apple's guidance: don't fire it
before the user has seen anything of the app). AdMob serves
non-personalized ads regardless of the answer — the prompt is an Apple
policy requirement for any IDFA-capable ad SDK, not a gate on ads working
at all.

### 4. `AdManager` (new, `HadithEnglish/Stores/AdManager.swift`)

`final class AdManager: NSObject, ObservableObject`, constructed once in
`HadithEnglishApp` and injected via `.environmentObject` like the other
stores.

**Persisted state** (UserDefaults, same pattern as `StreakStore`):
- `hasEnteredFirstCategory: Bool`
- `categoryChangeCount: Int`
- `nextInterstitialThreshold: Int` (3 or 4, re-rolled after every shown ad)
- `lastInterstitialShownAt: Date?`

**In-memory state:**
- `currentCategoryEnteredAt: Date?` — set by `categoryEntered()`, read by
  `categoryExited()` to compute dwell time, then cleared.
- A preloaded `GADInterstitialAd?` — loaded eagerly (see Error Handling)
  so `maybeShowInterstitial` can present immediately when a trigger fires,
  instead of showing nothing while a fresh load is in flight.

**Public API:**
```swift
func categoryEntered()   // call from HadithDetailView.onAppear (favoritesOnly == false only)
func categoryExited()    // call from HadithDetailView.onDisappear (favoritesOnly == false only)
```

Both are self-contained — `categoryExited()` runs the full trigger
decision below and, if it decides to show, presents the ad itself. It
finds a presenting `UIViewController` internally (via the active
`UIWindowScene`'s `rootViewController`) rather than taking one as a
parameter, so call sites never touch UIKit.

**Resolved ambiguity:** the user's rule says the dwell-time trigger fires
on pressing "Geri" specifically. SwiftUI's `onDisappear` fires for any
exit from the detail view (back-swipe, back button, or a push replacing
it) with no clean way to distinguish "explicit back tap" from those other
paths without deeper UIKit hooking. Since the goal is "don't interrupt an
engaged 60+-second read," any exit path qualifies equally — `onDisappear`
is used as-is, not narrowed to one specific gesture.

**Trigger logic** (`categoryExited`):
1. If `!hasEnteredFirstCategory`: set it `true`, return — never show on the
   very first category ever visited, full stop.
2. `categoryChangeCount += 1`.
3. Compute `dwell = Date().timeIntervalSince(currentCategoryEnteredAt)`.
4. `countTriggered = categoryChangeCount >= nextInterstitialThreshold`;
   `timeTriggered = dwell >= 60`.
5. If neither triggered, persist the incremented count and return.
6. If (`countTriggered` or `timeTriggered`) and cooldown has elapsed
   (`lastInterstitialShownAt == nil || now - lastInterstitialShownAt >= 180`):
   show the interstitial, reset `categoryChangeCount = 0`, re-roll
   `nextInterstitialThreshold` to a fresh random 3 or 4, set
   `lastInterstitialShownAt = now`.
7. If a trigger fired but cooldown blocked it: do **not** reset the
   counter — leave it incremented so the next qualifying exit (once
   cooldown clears) can fire immediately rather than waiting for a whole
   new threshold's worth of navigation.

Showing requires a presenting `UIViewController` — SwiftUI has no native
one, so a small private helper reads it off the active `UIWindowScene`'s
`rootViewController` at call time (a common, narrow, well-contained use of
UIKit interop for exactly this SDK requirement).

### 5. `NativeAdCard.swift` (new, `HadithEnglish/Views/`)

A `UIViewRepresentable` wrapping `GADNativeAdView`, styled to match
`HadithCardView`: same `Color("CardBackground")`, same corner radius (12),
same padding (12), same `Theme.of`-driven type sizes pulled from
`TypographyStore` so it doesn't look like a foreign element dropped into
the list. Loads its own native ad instance independently (each card in
the list gets a fresh `GADAdLoader` call) — native ads are not reusable
across positions the way a single interstitial instance is.

### 6. `HadithDetailView` changes

- `onAppear`/`onDisappear` call `adManager.categoryEntered()` /
  `.categoryExited()` — but **only when `!favoritesOnly`**, matching the
  "no ads in the favorites list" decision.
- The `List(displayedHadiths)` gets a native ad card injected after every
  8th row, only when `!favoritesOnly`: iterate with index, and after
  `(index + 1) % 8 == 0`, emit a `NativeAdCard()` alongside the
  `HadithCardView`.
- The interstitial is triggered by `HadithDetailView.onDisappear` calling
  `adManager.categoryExited()` directly — `AdManager` (injected via
  `.environmentObject`) owns the entire decide-and-present flow, including
  finding its own presenting `UIViewController`, so `HadithDetailView`
  never touches UIKit.

## Error Handling

- Interstitial: if the eager load fails (network, no fill), `maybeShowInterstitial`
  is a no-op — the user simply continues, no error UI, no retry loop. The
  next `categoryEntered()` call kicks off a fresh preload attempt.
- Native ad: if a card's load fails, `NativeAdCard` renders nothing (zero
  height) rather than a broken placeholder box — the list just has 7 or 9
  real rows between ads that visit instead of 8, which is invisible to
  the user.
- Both paths log via `print`/`os_log` for debugging, never surface an
  alert or crash — ad failures are routine and must never degrade the
  reading experience.

## Testing

- Unit tests for `AdManager`'s trigger logic (`categoryEntered`/
  `categoryExited` sequences → does it decide to show or not), using an
  injected `UserDefaults` suite and an injectable "now" clock, exactly
  like `StreakStore`'s existing test pattern — no real ad SDK calls in
  tests.
- No widget test for `NativeAdCard` itself (it wraps a third-party SDK
  view with no meaningful state to assert on) — a manual simulator check
  after implementation confirms it renders and matches the card style.

## Localization

The ATT usage string needs an `InfoPlist.strings` per supported locale
(`en`, `ar`, `tr`, `id`, `ur`) — this is the first Info.plist-level
localized string in the project (everything else routes through
`AppLanguage.strings`), since ATT's system dialog reads directly from the
Info.plist/InfoPlist.strings pair, not from in-app state.
