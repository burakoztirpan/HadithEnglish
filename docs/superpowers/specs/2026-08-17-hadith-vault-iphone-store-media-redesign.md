# Hadith Vault iPhone App Store Media Redesign

**Date:** 2026-08-17  
**Platform:** iPhone App Store screenshots  
**Output:** 1284 × 2778 px, portrait, RGB PNG  
**Scope:** English (`en-US`) iPhone set only; iPad follows only after approval

## Objective

Replace the current low-conversion iPhone screenshot presentation with a more legible, emotionally resonant and product-specific set. The new media must improve the path from App Store impression to product-page visit and download by communicating Hadith Vault's value within the first three screenshots.

The app UI shown inside every device must come from the current production SwiftUI app. Marketing composition may frame, scale and mask those captures, but must not regenerate or falsify the in-app interface.

## Positioning

The first three screenshots combine two complementary promises:

1. A calm daily hadith habit.
2. A complete, trustworthy Sahih al-Bukhari reading collection.
3. Fast discovery of guidance for a particular moment or subject.

Together they form the conversion story:

**Return daily → Read the complete collection → Find what you need**

## Visual Direction: Editorial Premium

The visual world combines Hadith Vault's deep green identity with warm parchment surfaces and restrained Islamic geometric linework. It should feel contemplative, trustworthy and contemporary—not ornamental, generic or game-like.

### Palette

- Vault Emerald: existing app accent/deep green, dominant brand field.
- Deep Charcoal Green: contrast surface for selected slides.
- Warm Parchment: reading and light-theme supporting field.
- Clean White: primary type and device surface.
- Soft Gold: limited accent for favorites or share-card moments only.

No neon colors, glossy 3D effects, fake metallic treatments or decorative gradients unrelated to the app.

### Typography

- Large, high-contrast sans-serif display headlines.
- Headlines use one or two lines and remain legible when three screenshots are displayed side-by-side in App Store search results.
- Target headline size: approximately 96–116 px on the 1284 px canvas, adjusted only to preserve a clean two-line maximum.
- Supporting copy is optional. When used, it is a single short line at approximately 42–48 px. It must never carry information required to understand the slide.
- No paragraph copy on the marketing canvas.

### Brand Mark

Use the real production AppIcon from:

`HadithEnglish/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`

The prior generic book logo must not appear. The real icon may be shown at small brand-lockup size with “Hadith Vault,” preserving its square shape and artwork without redrawing the calligraphy.

### Device Presentation

- Use a current, realistic iPhone silhouette with Dynamic Island, restrained bezel and a physically plausible soft shadow.
- Device width should be materially larger than the previous set so the UI remains recognizable at App Store scale.
- Prefer a straight or very subtle perspective presentation. Do not distort screenshots or use dramatic floating-phone angles.
- Preserve the captured screenshot's aspect ratio. No horizontal stretching.
- App UI remains the visual evidence; background patterning supports it and never competes with it.

## Screenshot Sequence

### 01 — One hadith for every day

- Source: updated light-theme Home screen.
- Must show: greeting, daily hadith card, streak and useful quick access.
- Job: establish the daily ritual and calm product experience.

### 02 — The complete Sahih al-Bukhari

- Source: current card-feed reading screen with genuine English hadith content.
- Must show: multiple readable cards, subject context, favorite/share affordances.
- Job: prove depth and reading quality.

### 03 — Find guidance for every moment

- Source: subjects/search experience using current production data.
- Must show: searchable subject organization and meaningful book/topic names.
- Job: prove that the collection is usable, not merely large.

### 04 — Keep what moves you

- Source: populated Favorites screen.
- Must show: realistic saved items grouped or presented by subject.
- Job: communicate personal continuity and return value.

### 05 — Share words that matter

- Source: current share-card preview using a genuine hadith and one of the app's production share backgrounds.
- Must show: a polished share card and the real Share action.
- Job: provide the most visually expressive slide in the set.

### 06 — Read your way

- Source: current Settings screen.
- Must show: typography, appearance, notification or language controls without purchase/error/loading states.
- Job: communicate personalization without becoming a settings inventory.

### 07 — Five languages. One timeless collection.

- Source: real English and Arabic/RTL app captures, optionally composed as a restrained two-device or split-device scene.
- Must show: authentic localized UI and correct RTL layout.
- Job: prove localization visually.

### 08 — Beautiful in light and dark

- Source: the same meaningful screen captured in both light and dark appearance.
- Must show: real adaptive UI, not a recolored screenshot.
- Job: close with visual polish and reading comfort.

## Capture Requirements

- Build the current working tree without modifying or committing the user's in-progress UI changes.
- Use an iPhone simulator whose capture can be cleanly placed in the 1284 × 2778 final canvas.
- Capture deterministic English demo states with realistic content.
- Hide or prevent consent prompts, debug overlays, test banners, advertisements, interstitials, loading indicators and transient toasts.
- Populate favorites and continuation state only through reversible simulator/test state; do not add production-only screenshot code unless unavoidable.
- Capture Arabic and dark mode from real app configuration.
- Respect safe areas and ensure no clipped text, horizontal overflow or incomplete transition state.

## File Organization

Preserve the existing media set unchanged during production.

Create:

```text
store_assets/ios/iphone/6.7-inch/en-US/marketing-v2/
  ios_iphone_store_01-one-hadith-every-day.png
  ios_iphone_store_02-complete-sahih-al-bukhari.png
  ios_iphone_store_03-find-guidance.png
  ios_iphone_store_04-keep-what-moves-you.png
  ios_iphone_store_05-share-words-that-matter.png
  ios_iphone_store_06-read-your-way.png
  ios_iphone_store_07-five-languages.png
  ios_iphone_store_08-light-and-dark.png
  ios_iphone_store_contact-sheet.jpg
  README.md

store_assets/ios/iphone/6.7-inch/en-US/raw-v2/
  ios_iphone_raw_01-home.png
  ...
```

The README must identify upload files, source states, dimensions and the files that are internal-only.

## Quality and Conversion Checks

Before delivery:

1. Verify every upload file is exactly 1284 × 2778 px, RGB PNG, with no alpha channel.
2. Create a simulated 390 px-wide App Store search-results preview of screenshots 01–03.
3. Confirm every primary headline remains readable in that preview without zooming.
4. Confirm each screenshot contains current, real app UI and the real Hadith Vault icon.
5. Inspect all eight images together for a coherent story, alternating rhythm and unnecessary repetition.
6. Confirm the previous media set and the user's current source changes remain untouched.

## Out of Scope

- iPad media generation until the iPhone set is reviewed and approved.
- Changes to production app UI, app content, localization or business logic.
- New marketing claims that cannot be demonstrated by the current application.
- App Store metadata, description, keywords, promotional text or preview video.
