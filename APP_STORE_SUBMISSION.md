# A440 — App Store Submission Guide

Everything needed to fill out App Store Connect for the 2.0.0 release, in the order
the fields appear. Copy-paste ready. Character limits are noted where they matter.

**Live URLs (already deployed on nathanfennel.com):**

| Field in App Store Connect | URL |
|---|---|
| Marketing URL | `https://nathanfennel.com/a440` |
| Support URL | `https://nathanfennel.com/a440/support` |
| Privacy Policy URL | `https://nathanfennel.com/a440/privacy` |

---

## 1. App Information (applies to all versions)

- **Name** (30 chars max): `A440`
- **Subtitle** (30 chars max): `Concert pitch in one tap` *(24 chars)*
- **Bundle ID:** `com.nathanfennel.A440` (unchanged since 2015 — this updates the existing listing)
- **Primary Category:** Music
- **Secondary Category:** Utilities
- **Content Rights:** Does not contain, show, or access third-party content
- **Age Rating:** answer **No** to every question → rates **4+**
- **License Agreement:** standard Apple EULA (leave custom EULA empty)

## 2. Pricing and Availability

- **Price:** Free (Tier 0)
- **No in-app purchases, no subscriptions, no ads**
- **Availability:** all territories

## 3. App Privacy

The app is fully offline — zero networking code, no third-party SDKs, no microphone,
no data of any kind leaves the device (verified in source, July 2026).

- Privacy Policy URL: `https://nathanfennel.com/a440/privacy`
- Questionnaire: **"Do you or your third-party partners collect data from this app?" → No.**
- Resulting label: **Data Not Collected**. There are no follow-up questions.

## 4. Version Information (2.0.0)

### Promotional Text (170 chars max — can be changed without review)

```
Completely redesigned. The same instant 440 Hz concert A — now with a fresh look, Dark Mode, and VoiceOver. Shake to revisit the original 2015 design.
```
*(150 chars)*

### Description (4000 chars max)

```
Concert pitch, ready in one tap.

A440 plays a clean 440 Hz concert A the moment you need it. Tap an instrument to start the tone, tap again to stop — that's the whole app. No menus, no setup, no clutter between you and being in tune.

FOUR VOICES FOR ONE NOTE
The same A sounds different on different instruments, and many musicians find it easier to tune to a timbre close to their own. Choose the voice that blends with what you play:

• Piano
• Violin
• French Horn
• Sine Wave — mathematically pure, just the fundamental

BUILT FOR REHEARSAL ROOMS
• The tone plays even when your phone is on silent — rehearsal rooms are exactly where phones are muted.
• Calls, alarms, and FaceTime interrupt cleanly; the app is ready again the moment they end.
• Your last instrument is remembered, so the note you want is one tap away next time.
• The tone keeps sounding until you stop it, leaving both hands free for your instrument.

A LITTLE HISTORY, BUILT IN
A440 first shipped in 2015. Shake your device and the app swaps to the original design, exactly as it looked back then — photographic instrument buttons, day and night backgrounds, and all. Shake again to come back.

MADE FOR EVERYONE
• Full VoiceOver support — every instrument reads as a labeled button.
• Dark Mode, with a rich spruce look of its own.
• Haptic feedback on every tap.
• A layout that adapts from the smallest iPhone to the largest iPad Pro.

COMPLETELY PRIVATE
A440 never connects to the internet. No accounts, no ads, no analytics, no tracking, no third-party code — the app collects nothing at all. It's a tuning fork, not a data pipeline.

Free, with no ads and no in-app purchases.
```

### Keywords (100 chars max, comma-separated, no spaces after commas)

```
tuning,tuner,440hz,concert pitch,tuning fork,reference,tone,violin,piano,orchestra,band,note,pitch
```
*(98 chars)*

### What's New in This Version (release notes for 2.0.0)

```
A440 has been completely rebuilt for modern iPhones and iPads:

• New design: instrument cards with crisp vector artwork, a live status header, and a rich spruce Dark Mode.
• Shake to time-travel: swap to the original 2015 design (and back) with a shake.
• Full VoiceOver support and haptic feedback.
• The tone now plays even with the silent switch on, and recovers cleanly from calls and alarms.
• Full-screen layout on modern devices, from iPhone SE to iPad Pro.
• Faster, smaller, and rebuilt for the latest iOS.
```

### URLs for this version

- **Marketing URL:** `https://nathanfennel.com/a440`
- **Support URL:** `https://nathanfennel.com/a440/support`
- **Copyright:** `© 2026 Nathan Fennel`

### App Review Information

- Contact: Nathan Fennel · `support@100apps.studio`
- Sign-in required: **No** (no accounts)
- Notes for review:

```
A440 is a fully offline reference-tone app. Tap any instrument card to play a 440 Hz concert A; tap again (or long-press) to stop. Shake the device to toggle between the current design and the original 2015 design — this is a deliberate feature, not a debug tool. The app uses no network, no microphone, and collects no data.
```

## 5. Screenshots

All sets live in `App Store Previews/2026/`, already at exact App Store Connect pixel
sizes, 9 images per device (limit is 10). **Upload the `framed/` sets** — they carry the
marketing captions and device frames; the `raw/` sets are unframed originals kept as source.

Upload in numeric order (01 → 09):

| App Store Connect slot | Required? | Folder | Pixels |
|---|---|---|---|
| iPhone 6.9" Display | **Required** | `2026/iphone-6.9/framed` | 1320 × 2868 |
| iPhone 6.7" Display | Optional | `2026/iphone-6.7/framed` | 1290 × 2796 |
| iPhone 6.5" Display | Optional | `2026/iphone-6.5/framed` | 1242 × 2688 |
| iPhone 5.5" Display | Optional | `2026/iphone-5.5/framed` | 1242 × 2208 |
| iPad 13" Display | **Required** | `2026/ipad-13/framed` | 2064 × 2752 |
| iPad 12.9" Display | Optional | `2026/ipad-12.9/framed` | 2048 × 2732 |

App previews (video) are optional and not prepared; the listing is complete without them.

## 6. Build & Upload

The project is ready to archive — Release builds compile with zero warnings, all 14 unit
tests pass, and export compliance is pre-answered in the Info.plist
(`ITSAppUsesNonExemptEncryption = NO`, so no encryption questions at upload time).

1. Open `A440.xcodeproj` in Xcode.
2. Select the **A440** scheme and destination **Any iOS Device (arm64)**.
3. Set your signing team under *Signing & Capabilities* (bundle ID stays `com.nathanfennel.A440`).
4. **Product → Archive**, then **Distribute App → App Store Connect → Upload**.
5. In App Store Connect, select the build for version **2.0.0**, fill the fields above, and **Submit for Review**.

Version/build in the project: **2.0.0 (1)**. Bump `CFBundleVersion` if you re-upload.

## 7. Backend

There is none, deliberately. The app contains no networking code at all (no
NSURLSession/NSURLConnection, no analytics SDKs), so there is nothing to deploy,
monitor, or maintain — the only "infrastructure" is the three static pages on
nathanfennel.com listed above.
