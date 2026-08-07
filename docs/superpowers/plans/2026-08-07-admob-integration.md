# AdMob Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add real AdMob monetization to Hadith Vault — native ad cards every 8 hadiths in the main reading list, and interstitial ads gated by a persisted category-navigation counter, a 60s dwell-time rule, and a 180s cooldown, never on the very first category a user ever visits.

**Architecture:** A new `AdManager` (ObservableObject, injected via `.environmentObject`) owns all interstitial trigger state and decision logic behind two calls (`categoryEntered()`/`categoryExited()`) that `HadithDetailView` makes on appear/disappear. A new `NativeAdCard` (`UIViewRepresentable` wrapping `GADNativeAdView`) is interleaved into `HadithDetailView`'s hadith list every 8th row. The Google Mobile Ads SDK is added via Swift Package Manager and initialized once at app launch alongside an App Tracking Transparency permission request.

**Tech Stack:** SwiftUI, Google Mobile Ads SDK (`GoogleMobileAds`, added via SPM), `AppTrackingTransparency`, UIKit interop (`UIViewRepresentable`) for the two ad surfaces that have no native SwiftUI equivalent.

## Global Constraints

- Real AdMob IDs (not test IDs) — App ID `ca-app-pub-4458416211971859~4811835333`, native ad unit `ca-app-pub-4458416211971859/4748490256`, interstitial ad unit `ca-app-pub-4458416211971859/1851819444`.
- iOS deployment target is 16.0 (confirmed in `project.pbxproj` — `IPHONEOS_DEPLOYMENT_TARGET = 16.0`), so no `#available` guards are needed for App Tracking Transparency (iOS 14+) or anything else in this plan.
- No ads anywhere in the favorites-filtered list (`HadithDetailView(favoritesOnly: true)`) — neither native cards nor interstitial triggers.
- Ad failures (load errors, no fill) must never crash, alert, or block the reading experience — silent no-op, log only.
- **Deviation from the design spec's Testing section:** this project has no XCTest target at all (`xcodebuild -list` shows a single `HadithEnglish` scheme, no test target — confirmed during planning). Adding one is a separate, disproportionately risky pbxproj change (a new `PBXNativeTarget` plus build configs plus a test-host wiring) that isn't in scope here. Every task below is verified by building, installing to a simulator, seeding `UserDefaults` for the specific scenario, and visually/behaviorally confirming — the same verification method already used for every other change in this project's history. `AdManager`'s trigger logic is still written as a pure, side-effect-free function of explicit inputs so it's unit-testable the day a test target does get added.
- **Deviation from the design spec's Localization section:** the spec assumed a per-language `InfoPlist.strings` setup for `NSUserTrackingUsageDescription`. This project has no `.lproj` localization infrastructure at all (only `Base.lproj/LaunchScreen.storyboard`) — its 5-language support is entirely a custom in-app `AppLanguage` picker (`AppLanguage.swift`), orthogonal to the OS's own language/region setting that `NSUserTrackingUsageDescription` actually reads from. Adding a whole new `PBXVariantGroup`-based localization mechanism for one system-dialog string would be a disproportionate, unprecedented pbxproj change. This plan ships a single English `NSUserTrackingUsageDescription` (matching the fact every other Info.plist string in this project is already single-language).

---

### Task 1: Add the Google Mobile Ads SDK via Swift Package Manager

**Files:**
- Modify: `HadithEnglish.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces: the `GoogleMobileAds` module becomes importable from any Swift file in the target — this is what every later task's `import GoogleMobileAds` depends on.

This is the highest-risk step in the plan: it's the first time this project has ever added a Swift Package dependency by hand-editing `project.pbxproj` (every prior addition in this project's history has been a plain source file). It needs five new/modified pbxproj records instead of the two a plain file needs, including a `PBXFrameworksBuildPhase` that doesn't exist yet at all (the target's `buildPhases` currently only lists `Sources` and `Resources` — confirmed by reading the file during planning).

- [ ] **Step 1: Add the remote package reference**

Open `HadithEnglish.xcodeproj/project.pbxproj`. Find this exact block (the end of `PBXBuildFile` immediately followed by `PBXFileReference`):

```
		C7797AB83FA868F309A3C6E4 /* ToastCenter.swift in Sources */ = {isa = PBXBuildFile; fileRef = D1DF5EBF25D412D9AF42022A /* ToastCenter.swift */; };
		B6C117FD8B2821FAC8048A9E /* ToastView.swift in Sources */ = {isa = PBXBuildFile; fileRef = C3AF9ED2E1D7DC8013E32223 /* ToastView.swift */; };
/* End PBXBuildFile section */
```

Replace it with (adds one new `PBXBuildFile` entry for the package product, referenced by `productRef` instead of `fileRef` — that's how a package product differs from a plain file in this section):

```
		C7797AB83FA868F309A3C6E4 /* ToastCenter.swift in Sources */ = {isa = PBXBuildFile; fileRef = D1DF5EBF25D412D9AF42022A /* ToastCenter.swift */; };
		B6C117FD8B2821FAC8048A9E /* ToastView.swift in Sources */ = {isa = PBXBuildFile; fileRef = C3AF9ED2E1D7DC8013E32223 /* ToastView.swift */; };
		0D2668A4B66298DE5DE21DB3 /* GoogleMobileAds in Frameworks */ = {isa = PBXBuildFile; productRef = 9F5B0ED11955BDD9A78FDC90 /* GoogleMobileAds */; };
/* End PBXBuildFile section */
```

- [ ] **Step 2: Add the Frameworks build phase (doesn't exist yet)**

Find this exact block:

```
/* Begin PBXGroup section */
```

Insert *before* it (this creates the missing `PBXFrameworksBuildPhase` — every Xcode app target normally has one; this project's never needed it until now because it's never linked a binary framework):

```
/* Begin PBXFrameworksBuildPhase section */
		9B47905DE29CEF79FFF0593C /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
				0D2668A4B66298DE5DE21DB3 /* GoogleMobileAds in Frameworks */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
```

- [ ] **Step 3: Register the Frameworks phase on the target**

Find this exact block:

```
			buildPhases = (
				63B2E4C52049A9AD001513AD /* Sources */,
				63B2E4C72049A9AD001513AD /* Resources */,
			);
```

Replace with:

```
			buildPhases = (
				63B2E4C52049A9AD001513AD /* Sources */,
				63B2E4C72049A9AD001513AD /* Resources */,
				9B47905DE29CEF79FFF0593C /* Frameworks */,
			);
```

- [ ] **Step 4: Add the package product dependency to the target**

Find this exact block (the end of the `PBXNativeTarget` entry):

```
			name = HadithEnglish;
			productName = HadithEnglish;
			productReference = 63B2E4C92049A9AD001513AD /* HadithEnglish.app */;
			productType = "com.apple.product-type.application";
		};
```

Replace with:

```
			name = HadithEnglish;
			packageProductDependencies = (
				9F5B0ED11955BDD9A78FDC90 /* GoogleMobileAds */,
			);
			productName = HadithEnglish;
			productReference = 63B2E4C92049A9AD001513AD /* HadithEnglish.app */;
			productType = "com.apple.product-type.application";
		};
```

- [ ] **Step 5: Register the package reference on the project object**

Find this exact block:

```
			mainGroup = 63B2E4C02049A9AD001513AD;
			productRefGroup = 63B2E4CA2049A9AD001513AD /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				63B2E4C82049A9AD001513AD /* HadithEnglish */,
			);
```

Replace with:

```
			mainGroup = 63B2E4C02049A9AD001513AD;
			packageReferences = (
				0A5C3D0D4B62075004EDD573 /* XCRemoteSwiftPackageReference "swift-package-manager-google-mobile-ads" */,
			);
			productRefGroup = 63B2E4CA2049A9AD001513AD /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				63B2E4C82049A9AD001513AD /* HadithEnglish */,
			);
```

- [ ] **Step 6: Add the XCRemoteSwiftPackageReference and XCSwiftPackageProductDependency sections**

Find this exact block:

```
/* Begin XCBuildConfiguration section */
```

Insert *before* it:

```
/* Begin XCRemoteSwiftPackageReference section */
		0A5C3D0D4B62075004EDD573 /* XCRemoteSwiftPackageReference "swift-package-manager-google-mobile-ads" */ = {
			isa = XCRemoteSwiftPackageReference;
			repositoryURL = "https://github.com/googleads/swift-package-manager-google-mobile-ads";
			requirement = {
				kind = upToNextMajorVersion;
				minimumVersion = 11.0.0;
			};
		};
/* End XCRemoteSwiftPackageReference section */

/* Begin XCSwiftPackageProductDependency section */
		9F5B0ED11955BDD9A78FDC90 /* GoogleMobileAds */ = {
			isa = XCSwiftPackageProductDependency;
			package = 0A5C3D0D4B62075004EDD573 /* XCRemoteSwiftPackageReference "swift-package-manager-google-mobile-ads" */;
			productName = GoogleMobileAds;
		};
/* End XCSwiftPackageProductDependency section */

/* Begin XCBuildConfiguration section */
```

- [ ] **Step 7: Resolve and verify the package**

```bash
cd "/Users/burakmacminim4/Desktop/hadiths app"
xcodebuild -resolvePackageDependencies -project HadithEnglish.xcodeproj -scheme HadithEnglish
```

Expected: `Resolved source packages:` followed by a line naming
`swift-package-manager-google-mobile-ads` and a version. If this fails
with a pbxproj parse error or "package not found," **stop and use the
fallback**: open `HadithEnglish.xcodeproj` in Xcode, File → Add Package
Dependencies, paste `https://github.com/googleads/swift-package-manager-google-mobile-ads`,
add the `GoogleMobileAds` product to the `HadithEnglish` target, save,
and re-run the resolve command to confirm before continuing — the manual
Xcode add is safe to run even after a failed hand-edit; Xcode repairs the
project file on save.

- [ ] **Step 8: Build to confirm the framework links**

```bash
xcodebuild -scheme HadithEnglish -configuration Debug -destination "generic/platform=iOS Simulator" build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`. (No code imports `GoogleMobileAds` yet,
so this only proves the dependency resolves and links — Task 2 proves it
actually works.)

- [ ] **Step 9: Commit**

```bash
cd "/Users/burakmacminim4/Desktop/hadiths app"
git add HadithEnglish.xcodeproj/project.pbxproj
git commit -m "Add Google Mobile Ads SDK via Swift Package Manager"
```

---

### Task 2: Info.plist, AdConfig, SDK init, and App Tracking Transparency

**Files:**
- Create: `HadithEnglish/Models/AdConfig.swift`
- Modify: `HadithEnglish/Info.plist`
- Modify: `HadithEnglish/HadithEnglishApp.swift`
- Modify: `HadithEnglish.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `import GoogleMobileAds` (Task 1).
- Produces: `AdConfig.appID`, `AdConfig.nativeAdUnitID`, `AdConfig.interstitialAdUnitID` (`String` constants) — every later task that needs an ad unit ID reads them from here, never hardcodes the literal.

- [ ] **Step 1: Create AdConfig.swift**

```swift
import Foundation

/// The one place the real AdMob IDs live — nothing else hardcodes them.
enum AdConfig {
    static let appID = "ca-app-pub-4458416211971859~4811835333"
    static let nativeAdUnitID = "ca-app-pub-4458416211971859/4748490256"
    static let interstitialAdUnitID = "ca-app-pub-4458416211971859/1851819444"
}
```

Save to `HadithEnglish/Models/AdConfig.swift`.

- [ ] **Step 2: Register AdConfig.swift in the Xcode project**

In `HadithEnglish.xcodeproj/project.pbxproj`, find:

```
		0D2668A4B66298DE5DE21DB3 /* GoogleMobileAds in Frameworks */ = {isa = PBXBuildFile; productRef = 9F5B0ED11955BDD9A78FDC90 /* GoogleMobileAds */; };
/* End PBXBuildFile section */
```

Replace with:

```
		0D2668A4B66298DE5DE21DB3 /* GoogleMobileAds in Frameworks */ = {isa = PBXBuildFile; productRef = 9F5B0ED11955BDD9A78FDC90 /* GoogleMobileAds */; };
		B14899FC74F2DBE066D3A4EB /* AdConfig.swift in Sources */ = {isa = PBXBuildFile; fileRef = BAD09F3DE24955F9A184B234 /* AdConfig.swift */; };
/* End PBXBuildFile section */
```

Find:

```
		C3AF9ED2E1D7DC8013E32223 /* ToastView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = ToastView.swift; path = HadithEnglish/Views/ToastView.swift; sourceTree = SOURCE_ROOT; };
/* End PBXFileReference section */
```

Replace with:

```
		C3AF9ED2E1D7DC8013E32223 /* ToastView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = ToastView.swift; path = HadithEnglish/Views/ToastView.swift; sourceTree = SOURCE_ROOT; };
		BAD09F3DE24955F9A184B234 /* AdConfig.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = AdConfig.swift; path = HadithEnglish/Models/AdConfig.swift; sourceTree = SOURCE_ROOT; };
/* End PBXFileReference section */
```

Find:

```
				D1DF5EBF25D412D9AF42022A /* ToastCenter.swift */,
				C3AF9ED2E1D7DC8013E32223 /* ToastView.swift */,
```

Replace with:

```
				D1DF5EBF25D412D9AF42022A /* ToastCenter.swift */,
				C3AF9ED2E1D7DC8013E32223 /* ToastView.swift */,
				BAD09F3DE24955F9A184B234 /* AdConfig.swift */,
```

Find:

```
				C7797AB83FA868F309A3C6E4 /* ToastCenter.swift in Sources */,
				B6C117FD8B2821FAC8048A9E /* ToastView.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */
```

Replace with:

```
				C7797AB83FA868F309A3C6E4 /* ToastCenter.swift in Sources */,
				B6C117FD8B2821FAC8048A9E /* ToastView.swift in Sources */,
				B14899FC74F2DBE066D3A4EB /* AdConfig.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */
```

- [ ] **Step 3: Add AdMob keys to Info.plist**

In `HadithEnglish/Info.plist`, find:

```
	<key>ITSAppUsesNonExemptEncryption</key>
	<false/>
```

Replace with:

```
	<key>ITSAppUsesNonExemptEncryption</key>
	<false/>
	<key>GADApplicationIdentifier</key>
	<string>ca-app-pub-4458416211971859~4811835333</string>
	<key>NSUserTrackingUsageDescription</key>
	<string>This identifier will be used to deliver personalized ads to you.</string>
	<key>SKAdNetworkItems</key>
	<array>
		<dict><key>SKAdNetworkIdentifier</key><string>cstr6suwn9.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>4fzdc2evr5.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>2fnua5tdw4.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>ydx93a7ass.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>p78axxw29g.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>v72qych5uu.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>ludvb6z3bs.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>cp8zw746q7.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>3sh42y64q3.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>c6k4g5qg8m.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>s39g8k73mm.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>wg4vff78zm.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>3qy4746246.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>f38h382jlk.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>hs6bdukanm.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>mlmmfzh3r3.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>v4nxqhlyqp.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>wzmmz9fp6w.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>su67r6k2v3.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>yclnxrl5pm.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>t38b2kh725.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>7ug5zh24hu.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>gta9lk7p23.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>vutu7akeur.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>y5ghdn5j9k.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>v9wttpbfk9.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>n38lu8286q.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>47vhws6wlr.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>kbd757ywx3.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>9t245vhmpl.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>a2p9lx4jpn.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>22mmun2rn5.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>44jx6755aq.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>k674qkevps.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>4468km3ulz.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>2u9pt9hc89.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>8s468mfl3y.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>klf5c3l5u5.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>ppxm28t8ap.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>kbmxgpxpgc.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>uw77j35x4d.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>578prtvx9j.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>4dzt52r2t5.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>tl55sbb4fm.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>c3frkrj4fj.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>e5fvkxwrpn.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>8c4e2ghe7u.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>3rd42ekr43.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>97r2b46745.skadnetwork</string></dict>
		<dict><key>SKAdNetworkIdentifier</key><string>3qcr597p9d.skadnetwork</string></dict>
	</array>
```

**Note for whoever submits to App Store Connect:** this SKAdNetwork list
was fetched from Google's published AdMob documentation during planning
(2026-08-07). Google adds new mediation-partner IDs periodically — before
final submission, cross-check this array against Google's current live
page (search "AdMob SKAdNetworkItems Info.plist") and add any new entries.
Missing a *new* entry doesn't break the build or get the app rejected; it
just means that one specific ad network's attribution is incomplete.

- [ ] **Step 4: Initialize the SDK and request ATT in HadithEnglishApp**

Read the current `HadithEnglish/HadithEnglishApp.swift`, then make these
two changes.

Add the import at the top:

```swift
import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency
```

Find:

```swift
            .onAppear {
                content.load(languageStore.language)
                notificationStore.configure(subjects: content.subjects, title: languageStore.strings.hadithOfTheDay)
                tabRouter.selectedTab = .home
            }
```

Wait — this project's actual current file does **not** have the
`tabRouter.selectedTab = .home` line (that was a temporary marketing-
screenshot edit, already reverted). Find the real current block instead:

```swift
            .onAppear {
                content.load(languageStore.language)
                notificationStore.configure(subjects: content.subjects, title: languageStore.strings.hadithOfTheDay)
            }
```

Replace with:

```swift
            .onAppear {
                content.load(languageStore.language)
                notificationStore.configure(subjects: content.subjects, title: languageStore.strings.hadithOfTheDay)
                GADMobileAds.sharedInstance().start(completionHandler: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    ATTrackingManager.requestTrackingAuthorization { _ in }
                }
            }
```

- [ ] **Step 5: Build**

```bash
cd "/Users/burakmacminim4/Desktop/hadiths app"
xcodebuild -scheme HadithEnglish -configuration Debug -destination "generic/platform=iOS Simulator" build 2>&1 | tail -30
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 6: Verify on a simulator**

```bash
cd "/Users/burakmacminim4/Desktop/hadiths app"
SIM=$(xcrun simctl list devices | grep -m1 "Booted" | grep -oE '[0-9A-F-]{36}')
if [ -z "$SIM" ]; then
  SIM=$(xcrun simctl list devicetypes | grep -m1 "iPhone 1[5-7]" | true)
  # No device booted - boot the first available iPhone simulator instead:
  SIM=$(xcrun simctl list devices available | grep -m1 "iPhone" | grep -oE '[0-9A-F-]{36}')
  xcrun simctl boot $SIM
  sleep 5
fi
DERIVED="/tmp/admob_task2_build"
xcodebuild -scheme HadithEnglish -configuration Debug -destination "id=$SIM" -derivedDataPath "$DERIVED" build 2>&1 | tail -20
xcrun simctl install $SIM "$DERIVED/Build/Products/Debug-iphonesimulator/HadithEnglish.app"
xcrun simctl launch $SIM nelibula.HadithEnglish
sleep 4
xcrun simctl io $SIM screenshot /tmp/admob_task2_check.png
```

Read `/tmp/admob_task2_check.png`. Expected: no crash, and the App
Tracking Transparency system dialog appears about a second after launch
(grant or deny either way — this only proves the prompt fires, not real
ad delivery, since ads aren't shown by this task yet). If the dialog
already has "Allow"/"Ask App Not to Track" answered from a prior test on
this simulator, ATT won't re-prompt — that's expected OS behavior, not a
bug; reset with `xcrun simctl privacy $SIM reset all nelibula.HadithEnglish`
and relaunch if you need to see the prompt again.

- [ ] **Step 7: Commit**

```bash
git add HadithEnglish/Models/AdConfig.swift HadithEnglish/Info.plist HadithEnglish/HadithEnglishApp.swift HadithEnglish.xcodeproj/project.pbxproj
git commit -m "Wire AdMob SDK init, App Tracking Transparency, and Info.plist keys"
```

---

### Task 3: AdManager — persisted interstitial trigger logic

**Files:**
- Create: `HadithEnglish/Stores/AdManager.swift`
- Modify: `HadithEnglish.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `AdConfig.interstitialAdUnitID` (Task 2).
- Produces:
  ```swift
  final class AdManager: NSObject, ObservableObject {
      init(defaults: UserDefaults = .standard)
      func categoryEntered()
      func categoryExited(now: Date = Date())
  }
  ```
  Task 5 calls `categoryEntered()`/`categoryExited()` from
  `HadithDetailView`. Task 4/5 do **not** call anything else on
  `AdManager` — the native ad card loads its own ad independently.

- [ ] **Step 1: Create AdManager.swift**

```swift
import Foundation
import UIKit
import GoogleMobileAds

/// Owns the interstitial ad's trigger rules and lifecycle. Everything a
/// caller needs is two calls: `categoryEntered()` on appear,
/// `categoryExited()` on disappear — the decision of whether that exit
/// should show an ad, and the ad's load/present mechanics, all live here.
final class AdManager: NSObject, ObservableObject {
    private static let hasEnteredFirstCategoryKey = "AdManager.hasEnteredFirstCategory"
    private static let categoryChangeCountKey = "AdManager.categoryChangeCount"
    private static let nextThresholdKey = "AdManager.nextInterstitialThreshold"
    private static let lastShownAtKey = "AdManager.lastInterstitialShownAt"

    private static let dwellTriggerSeconds: TimeInterval = 60
    private static let cooldownSeconds: TimeInterval = 180

    private let defaults: UserDefaults
    private var currentCategoryEnteredAt: Date?
    private var preloadedInterstitial: GADInterstitialAd?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        super.init()
        if defaults.object(forKey: Self.nextThresholdKey) == nil {
            defaults.set(Self.rollThreshold(), forKey: Self.nextThresholdKey)
        }
    }

    // MARK: - Public API

    func categoryEntered() {
        currentCategoryEnteredAt = Date()
        preloadInterstitialIfNeeded()
    }

    func categoryExited(now: Date = Date()) {
        defer { currentCategoryEnteredAt = nil }

        guard defaults.bool(forKey: Self.hasEnteredFirstCategoryKey) else {
            defaults.set(true, forKey: Self.hasEnteredFirstCategoryKey)
            return
        }

        let dwell = currentCategoryEnteredAt.map { now.timeIntervalSince($0) } ?? 0
        let newCount = defaults.integer(forKey: Self.categoryChangeCountKey) + 1
        let threshold = defaults.integer(forKey: Self.nextThresholdKey)

        let countTriggered = newCount >= threshold
        let timeTriggered = dwell >= Self.dwellTriggerSeconds
        guard countTriggered || timeTriggered else {
            defaults.set(newCount, forKey: Self.categoryChangeCountKey)
            return
        }

        guard isCooldownElapsed(now: now) else {
            // A trigger fired but cooldown blocked it - keep the count so
            // the very next qualifying exit can fire without waiting for
            // a whole new threshold's worth of navigation.
            defaults.set(newCount, forKey: Self.categoryChangeCountKey)
            return
        }

        presentInterstitialIfLoaded(now: now)
        defaults.set(0, forKey: Self.categoryChangeCountKey)
        defaults.set(Self.rollThreshold(), forKey: Self.nextThresholdKey)
        defaults.set(now, forKey: Self.lastShownAtKey)
    }

    // MARK: - Cooldown

    private func isCooldownElapsed(now: Date) -> Bool {
        guard let lastShown = defaults.object(forKey: Self.lastShownAtKey) as? Date else {
            return true
        }
        return now.timeIntervalSince(lastShown) >= Self.cooldownSeconds
    }

    // MARK: - Threshold

    private static func rollThreshold() -> Int {
        Bool.random() ? 3 : 4
    }

    // MARK: - Ad lifecycle

    private func preloadInterstitialIfNeeded() {
        guard preloadedInterstitial == nil else { return }
        GADInterstitialAd.load(withAdUnitID: AdConfig.interstitialAdUnitID, request: GADRequest()) { [weak self] ad, error in
            if let error {
                print("AdManager: interstitial preload failed: \(error.localizedDescription)")
                return
            }
            self?.preloadedInterstitial = ad
        }
    }

    private func presentInterstitialIfLoaded(now: Date) {
        guard let ad = preloadedInterstitial, let rootVC = Self.topViewController() else {
            print("AdManager: interstitial not ready, skipping this trigger")
            return
        }
        ad.present(fromRootViewController: rootVC)
        preloadedInterstitial = nil
        preloadInterstitialIfNeeded()
    }

    private static func topViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
```

- [ ] **Step 2: Register AdManager.swift in the Xcode project**

In `HadithEnglish.xcodeproj/project.pbxproj`, find:

```
		B14899FC74F2DBE066D3A4EB /* AdConfig.swift in Sources */ = {isa = PBXBuildFile; fileRef = BAD09F3DE24955F9A184B234 /* AdConfig.swift */; };
/* End PBXBuildFile section */
```

Replace with:

```
		B14899FC74F2DBE066D3A4EB /* AdConfig.swift in Sources */ = {isa = PBXBuildFile; fileRef = BAD09F3DE24955F9A184B234 /* AdConfig.swift */; };
		D8BF15C2C5471CFCB4340807 /* AdManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = 044F2884988C01F4FD460A1E /* AdManager.swift */; };
/* End PBXBuildFile section */
```

Find:

```
		BAD09F3DE24955F9A184B234 /* AdConfig.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = AdConfig.swift; path = HadithEnglish/Models/AdConfig.swift; sourceTree = SOURCE_ROOT; };
/* End PBXFileReference section */
```

Replace with:

```
		BAD09F3DE24955F9A184B234 /* AdConfig.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = AdConfig.swift; path = HadithEnglish/Models/AdConfig.swift; sourceTree = SOURCE_ROOT; };
		044F2884988C01F4FD460A1E /* AdManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = AdManager.swift; path = HadithEnglish/Stores/AdManager.swift; sourceTree = SOURCE_ROOT; };
/* End PBXFileReference section */
```

Find:

```
				C3AF9ED2E1D7DC8013E32223 /* ToastView.swift */,
				BAD09F3DE24955F9A184B234 /* AdConfig.swift */,
```

Replace with:

```
				C3AF9ED2E1D7DC8013E32223 /* ToastView.swift */,
				BAD09F3DE24955F9A184B234 /* AdConfig.swift */,
				044F2884988C01F4FD460A1E /* AdManager.swift */,
```

Find:

```
				B6C117FD8B2821FAC8048A9E /* ToastView.swift in Sources */,
				B14899FC74F2DBE066D3A4EB /* AdConfig.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */
```

Replace with:

```
				B6C117FD8B2821FAC8048A9E /* ToastView.swift in Sources */,
				B14899FC74F2DBE066D3A4EB /* AdConfig.swift in Sources */,
				D8BF15C2C5471CFCB4340807 /* AdManager.swift in Sources */,
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

Expected: `** BUILD SUCCEEDED **`. `AdManager` isn't wired into the app
yet (Task 5 does that), so this only proves it compiles standalone.

- [ ] **Step 4: Commit**

```bash
git add HadithEnglish/Stores/AdManager.swift HadithEnglish.xcodeproj/project.pbxproj
git commit -m "Add AdManager: persisted interstitial trigger logic"
```

---

### Task 4: NativeAdCard — styled native ad view

**Files:**
- Create: `HadithEnglish/Views/NativeAdCard.swift`
- Modify: `HadithEnglish.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `AdConfig.nativeAdUnitID` (Task 2).
- Produces: `struct NativeAdCard: View` (SwiftUI `View`, zero-config —
  Task 5 drops `NativeAdCard()` straight into a `List` like any other row).

**Design correction from the spec (visual style):** the spec described
matching `HadithCardView`'s *floating rounded-card* look
(`.cornerRadius(12)`, explicit `.padding(12)`,
`.background(Color("CardBackground"))`) — that's actually how
`HadithCardView` looks in `HomeView` and in the `favoritesOnly` list,
**not** in the plain (non-favorites) list this ad card is going into. In
that list, `HadithDetailView` uses `.listRowBackground(Color("CardBackground"))`
on plain `List` rows with no per-row rounding — a flatter look.
`NativeAdCard` matches *that* specific row style since that's the list it
actually appears in.

**Correction from the spec (rendering mechanism):** the spec described a
`UIViewRepresentable` wrapping `GADNativeAdView` but didn't specify
*how* — rendering a native ad's text via plain SwiftUI `Text` views
(reading `nativeAd.headline`/`.body`/`.callToAction` as strings, no
`GADNativeAdView` involved) would look correct but is an AdMob policy
violation and a functional bug: click/impression tracking only registers
when the ad's asset views are UIKit views actually assigned to
`GADNativeAdView`'s `headlineView`/`bodyView`/`callToActionView`
properties *before* `nativeAdView.nativeAd` is set. Skipping that wrapper
means the ad displays but taps are never attributed — it would show
impressions with near-zero revenue. This plan builds the real
`GADNativeAdView` wrapper.

- [ ] **Step 1: Create NativeAdCard.swift**

```swift
import SwiftUI
import UIKit
import GoogleMobileAds

/// A native AdMob ad styled as a plain List row, matching how
/// HadithDetailView's non-favorites list actually looks (a flat row on
/// Color("CardBackground"), not the floating rounded card HadithCardView
/// uses elsewhere) - so it reads as part of the list, not a foreign
/// element dropped in.
struct NativeAdCard: View {
    @StateObject private var loader = NativeAdLoader()

    var body: some View {
        Group {
            if let nativeAd = loader.nativeAd {
                NativeAdContainerView(nativeAd: nativeAd)
                    .frame(minHeight: 96)
                    .padding(.vertical, 8)
            } else {
                EmptyView()
            }
        }
        .onAppear { loader.load() }
    }
}

/// Wraps a real GADNativeAdView (UIKit) - AdMob requires the ad's asset
/// views (headline, body, call-to-action) to be registered on the SDK's
/// own container for click/impression tracking to work at all. See the
/// plan's "Correction from the spec" note for why this can't just be
/// plain SwiftUI Text views reading the ad's strings.
private struct NativeAdContainerView: UIViewRepresentable {
    let nativeAd: GADNativeAd

    func makeUIView(context: Context) -> GADNativeAdView {
        let adView = GADNativeAdView()
        adView.backgroundColor = UIColor(named: "CardBackground")

        let sponsoredLabel = UILabel()
        sponsoredLabel.font = .preferredFont(forTextStyle: .caption1)
        sponsoredLabel.textColor = .secondaryLabel
        sponsoredLabel.text = "Ad"

        let headlineLabel = UILabel()
        headlineLabel.font = .preferredFont(forTextStyle: .body)
        headlineLabel.numberOfLines = 0
        adView.headlineView = headlineLabel

        let bodyLabel = UILabel()
        bodyLabel.font = .preferredFont(forTextStyle: .subheadline)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 3
        adView.bodyView = bodyLabel

        let ctaButton = UIButton(type: .system)
        ctaButton.titleLabel?.font = .boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption1).pointSize)
        ctaButton.contentHorizontalAlignment = .leading
        ctaButton.tintColor = UIColor(named: "AccentColor")
        adView.callToActionView = ctaButton

        let stack = UIStackView(arrangedSubviews: [sponsoredLabel, headlineLabel, bodyLabel, ctaButton])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: adView.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -16),
        ])

        return adView
    }

    func updateUIView(_ adView: GADNativeAdView, context: Context) {
        (adView.headlineView as? UILabel)?.text = nativeAd.headline
        (adView.bodyView as? UILabel)?.text = nativeAd.body
        (adView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        // Must be set last, after every asset view above is assigned -
        // this is what actually activates AdMob's click/impression
        // tracking on the views just registered.
        adView.nativeAd = nativeAd
    }
}

/// Loads one GADNativeAd per card instance - native ads aren't reusable
/// across positions the way a single interstitial instance is.
private final class NativeAdLoader: NSObject, ObservableObject, GADNativeAdLoaderDelegate {
    @Published var nativeAd: GADNativeAd?
    private var adLoader: GADAdLoader?
    private var didLoad = false

    func load() {
        guard !didLoad else { return }
        didLoad = true
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController
        else { return }

        let loader = GADAdLoader(
            adUnitID: AdConfig.nativeAdUnitID,
            rootViewController: rootVC,
            adTypes: [.native],
            options: nil
        )
        loader.delegate = self
        adLoader = loader
        loader.load(GADRequest())
    }

    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        self.nativeAd = nativeAd
    }

    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        print("NativeAdCard: load failed: \(error.localizedDescription)")
    }
}
```

- [ ] **Step 2: Register NativeAdCard.swift in the Xcode project**

In `HadithEnglish.xcodeproj/project.pbxproj`, find:

```
		D8BF15C2C5471CFCB4340807 /* AdManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = 044F2884988C01F4FD460A1E /* AdManager.swift */; };
/* End PBXBuildFile section */
```

Replace with:

```
		D8BF15C2C5471CFCB4340807 /* AdManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = 044F2884988C01F4FD460A1E /* AdManager.swift */; };
		7F4D1D7169BE3317664EBF2D /* NativeAdCard.swift in Sources */ = {isa = PBXBuildFile; fileRef = C8797FBFC6E2B343F6974BBD /* NativeAdCard.swift */; };
/* End PBXBuildFile section */
```

Find:

```
		044F2884988C01F4FD460A1E /* AdManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = AdManager.swift; path = HadithEnglish/Stores/AdManager.swift; sourceTree = SOURCE_ROOT; };
/* End PBXFileReference section */
```

Replace with:

```
		044F2884988C01F4FD460A1E /* AdManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = AdManager.swift; path = HadithEnglish/Stores/AdManager.swift; sourceTree = SOURCE_ROOT; };
		C8797FBFC6E2B343F6974BBD /* NativeAdCard.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = NativeAdCard.swift; path = HadithEnglish/Views/NativeAdCard.swift; sourceTree = SOURCE_ROOT; };
/* End PBXFileReference section */
```

Find:

```
				BAD09F3DE24955F9A184B234 /* AdConfig.swift */,
				044F2884988C01F4FD460A1E /* AdManager.swift */,
```

Replace with:

```
				BAD09F3DE24955F9A184B234 /* AdConfig.swift */,
				044F2884988C01F4FD460A1E /* AdManager.swift */,
				C8797FBFC6E2B343F6974BBD /* NativeAdCard.swift */,
```

Find:

```
				B14899FC74F2DBE066D3A4EB /* AdConfig.swift in Sources */,
				D8BF15C2C5471CFCB4340807 /* AdManager.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */
```

Replace with:

```
				B14899FC74F2DBE066D3A4EB /* AdConfig.swift in Sources */,
				D8BF15C2C5471CFCB4340807 /* AdManager.swift in Sources */,
				7F4D1D7169BE3317664EBF2D /* NativeAdCard.swift in Sources */,
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

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add HadithEnglish/Views/NativeAdCard.swift HadithEnglish.xcodeproj/project.pbxproj
git commit -m "Add NativeAdCard styled to match the hadith list's row look"
```

---

### Task 5: Wire AdManager and NativeAdCard into the app

**Files:**
- Modify: `HadithEnglish/HadithEnglishApp.swift`
- Modify: `HadithEnglish/Views/HadithDetailView.swift`

**Interfaces:**
- Consumes: `AdManager` (Task 3), `NativeAdCard` (Task 4).
- Produces: the finished feature — nothing downstream depends on this task.

- [ ] **Step 1: Inject AdManager as an environment object**

In `HadithEnglish/HadithEnglishApp.swift`, find:

```swift
    @StateObject private var toastCenter = ToastCenter()
    @Environment(\.scenePhase) private var scenePhase
```

Replace with:

```swift
    @StateObject private var toastCenter = ToastCenter()
    @StateObject private var adManager = AdManager()
    @Environment(\.scenePhase) private var scenePhase
```

Find:

```swift
            .environmentObject(toastCenter)
            .environment(\.layoutDirection, languageStore.language.isRightToLeft ? .rightToLeft : .leftToRight)
```

Replace with:

```swift
            .environmentObject(toastCenter)
            .environmentObject(adManager)
            .environment(\.layoutDirection, languageStore.language.isRightToLeft ? .rightToLeft : .leftToRight)
```

- [ ] **Step 2: Wire category entered/exited and native ad injection into HadithDetailView**

Read the current `HadithEnglish/Views/HadithDetailView.swift` in full
first (it may have picked up unrelated edits since this plan was
written). Then apply these changes:

Add `@EnvironmentObject private var adManager: AdManager` alongside the
view's other environment objects:

```swift
struct HadithDetailView: View {
    let subject: HadithSubject
    var favoritesOnly: Bool = false
    @EnvironmentObject private var lastRead: LastReadStore
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var adManager: AdManager
```

Replace the `List` body and `onAppear` with a version that (a) injects a
`NativeAdCard` after every 8th row when `!favoritesOnly`, and (b) calls
`adManager.categoryEntered()`/`.categoryExited()` around the existing
`onAppear` logic:

```swift
    var body: some View {
        List {
            ForEach(Array(displayedHadiths.enumerated()), id: \.element.id) { index, entry in
                if favoritesOnly {
                    HadithCardView(entry: entry)
                        .padding(12)
                        .background(Color("CardBackground"))
                        .cornerRadius(12)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .swipeActions {
                            Button(role: .destructive) {
                                favorites.remove(entry.id)
                            } label: {
                                Label(languageStore.strings.removeAction, systemImage: "star.slash")
                            }
                        }
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
        .overlay {
            if favoritesOnly && displayedHadiths.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "star")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text(languageStore.strings.noFavoritesYet)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
```

- [ ] **Step 3: Build**

```bash
cd "/Users/burakmacminim4/Desktop/hadiths app"
xcodebuild -scheme HadithEnglish -configuration Debug -destination "generic/platform=iOS Simulator" build 2>&1 | tail -30
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Build and install for manual verification**

```bash
cd "/Users/burakmacminim4/Desktop/hadiths app"
SIM=$(xcrun simctl list devices | grep -m1 "Booted" | grep -oE '[0-9A-F-]{36}')
if [ -z "$SIM" ]; then
  SIM=$(xcrun simctl list devices available | grep -m1 "iPhone" | grep -oE '[0-9A-F-]{36}')
  xcrun simctl boot $SIM
  sleep 5
fi
DERIVED="/tmp/admob_task5_build"
xcodebuild -scheme HadithEnglish -configuration Debug -destination "id=$SIM" -derivedDataPath "$DERIVED" build 2>&1 | tail -20
xcrun simctl install $SIM "$DERIVED/Build/Products/Debug-iphonesimulator/HadithEnglish.app"
```

Keep `$SIM` and `$DERIVED` set in this shell — Steps 5-7 reuse them.

- [ ] **Step 5: Verify the native ad card**

```bash
xcrun simctl launch $SIM nelibula.HadithEnglish
```

Navigate: Hadiths tab → any subject with 9+ hadiths (e.g. "Ablutions
(Wudu')", "Prayers (Salat)" — both have 100+ per the app's own subject
list). Scroll to the 9th row.

```bash
xcrun simctl io $SIM screenshot /tmp/admob_native_ad_check.png
```

Read `/tmp/admob_native_ad_check.png`. Expected: a card labeled "Ad"
appears between the 8th and 9th real hadith rows, styled as a flat row on
the same card background color as the surrounding hadith rows (not a
floating rounded card). If the "Ad" row never appears after a few
seconds, that's a real AdMob no-fill (common in a simulator on a fresh
AdMob account with little traffic history) — not necessarily a bug;
confirm via `xcrun simctl spawn $SIM log stream --predicate 'eventMessage
contains "NativeAdCard"'` (run in a separate terminal while the list is
on screen) whether a `NativeAdCard: load failed` line appears.

- [ ] **Step 6: Verify the interstitial trigger rules**

Seed `UserDefaults` to sit one exit away from the count threshold, then
confirm an interstitial fires on the next category exit:

```bash
xcrun simctl terminate $SIM nelibula.HadithEnglish
xcrun simctl spawn $SIM defaults write nelibula.HadithEnglish "AdManager.hasEnteredFirstCategory" -bool true
xcrun simctl spawn $SIM defaults write nelibula.HadithEnglish "AdManager.categoryChangeCount" -int 2
xcrun simctl spawn $SIM defaults write nelibula.HadithEnglish "AdManager.nextInterstitialThreshold" -int 3
xcrun simctl spawn $SIM defaults delete nelibula.HadithEnglish "AdManager.lastInterstitialShownAt" 2>/dev/null
```

Relaunch the app, enter any category, exit it (back button). Expected:
a full-screen interstitial appears (or, on a fresh AdMob account with no
fill yet, the `AdManager: interstitial not ready` log line — check via
the same `log stream` command as Step 5, filtering for `AdManager`
instead of `NativeAdCard`).

Then confirm the cooldown suppresses a second immediate trigger: without
waiting, re-enter and exit another category (count is now back at 0/3,
won't count-trigger) but seed a stale count to test cooldown specifically:

```bash
xcrun simctl spawn $SIM defaults write nelibula.HadithEnglish "AdManager.categoryChangeCount" -int 3
xcrun simctl spawn $SIM defaults write nelibula.HadithEnglish "AdManager.lastInterstitialShownAt" -date "$(date -u +"%Y-%m-%d %H:%M:%S +0000")"
```

Relaunch, enter/exit a category. Expected: no interstitial (cooldown
active), and the `categoryChangeCount` in defaults is still incremented
(read it back with `defaults read` to confirm it moved from 3 to 4, not
reset to 0 — that's the "cooldown blocked, don't lose the trigger" rule
from `AdManager.categoryExited`).

- [ ] **Step 7: Verify no ads in the favorites list**

Star a couple of hadiths, open Favorites tab, drill into a favorited
subject. Expected: plain list, no "Ad" row, and no interstitial fires on
exiting it (confirm `AdManager.categoryChangeCount` in defaults is
unchanged before/after visiting the favorites-filtered detail view).

- [ ] **Step 8: Clean up test UserDefaults overrides on the simulator**

```bash
xcrun simctl spawn $SIM defaults delete nelibula.HadithEnglish "AdManager.hasEnteredFirstCategory"
xcrun simctl spawn $SIM defaults delete nelibula.HadithEnglish "AdManager.categoryChangeCount"
xcrun simctl spawn $SIM defaults delete nelibula.HadithEnglish "AdManager.nextInterstitialThreshold"
xcrun simctl spawn $SIM defaults delete nelibula.HadithEnglish "AdManager.lastInterstitialShownAt"
```

(This is simulator-device state, not project files — nothing to `git
status` check here, just leaves the simulator clean for future work.)

- [ ] **Step 9: Commit**

```bash
cd "/Users/burakmacminim4/Desktop/hadiths app"
git add HadithEnglish/HadithEnglishApp.swift HadithEnglish/Views/HadithDetailView.swift
git commit -m "Wire AdManager and NativeAdCard into HadithDetailView"
```
