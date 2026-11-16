# AGENTS.md — Chai Dhaba Empire (working title)

You are a coding agent building an **Android idle/incremental tycoon game** in **Flutter**.
Read this whole file before writing any code. Follow the milestones in order.

## 0. Owner settings (the owner edits these before starting)

- ORG_PREFIX: `com.chaidhaba`   <- Default testing prefix (change to your own reverse-domain before Play Store release).
- APP_NAME: `Chai Dhaba Empire`
- DART_PACKAGE_NAME: `chai_dhaba_empire`
- THEME: Pakistani chai dhaba -> empire (owner may swap to "kabari wala recycling tycoon"; if so, only the names/art/strings in `lib/data/balance.dart` and `lib/core/strings.dart` should need to change), Start from chai then gradually increase number of businesses, items and upgrades as player progresses in the game.

> ### Note for Owner: Testing & Self-Publishing Guide
> 
> **Current Mode:** Development & Testing (`ORG_PREFIX: com.chaidhaba`, AdMob Test IDs enabled). The owner will test the app first and handle the Google Play Store publication manually later.
> 
> **1. What is `ORG_PREFIX` and why is it needed?**
> - In Android and Flutter, `ORG_PREFIX` combined with the project name forms your app's unique **Application ID / Package Name** (e.g., `com.chaidhaba.chai_dhaba_empire`).
> - **Purpose:** It serves as the unique digital fingerprint for your application worldwide. Every Android phone, the operating system, and the Google Play Store use this identifier to differentiate your app from millions of others, manage sandbox storage, handle permissions, and route updates.
> - **Critical Rule:** Once you upload an APK/AAB to the Google Play Store with a specific package name, **it cannot be changed**. Changing the package name after release creates an entirely separate app listing, meaning you lose all existing installs, reviews, and store ranking.
> 
> **2. Why use AdMob Test IDs during testing?**
> - Clicking or generating impressions on your own live AdMob ads violates Google AdMob terms of service and can lead to permanent account suspension.
> - Development and local testing always use Google's official Test Ad IDs (`useTestAds = true` in `lib/services/ad_ids.dart`).
> 
> **3. How you can change the Package Name yourself before Play Store release:**
> When you are ready to publish under your own domain name (e.g., `com.yourcompany.chai_dhaba_empire`):
> - **Option A (Automated - Recommended):**
>   1. In `pubspec.yaml`, temporarily add `change_app_package_name` under `dev_dependencies`:
>      ```yaml
>      dev_dependencies:
>        change_app_package_name: ^1.4.0
>      ```
>   2. Run in terminal:
>      ```bash
>      dart run change_app_package_name:main com.yourcompany.chai_dhaba_empire
>      ```
>   3. It will automatically update `android/app/build.gradle`, `AndroidManifest.xml`, and the Kotlin folder hierarchy.
> - **Option B (Manual):**
>   1. Open `android/app/build.gradle` and change `applicationId "com.chaidhaba.chai_dhaba_empire"` to `applicationId "com.yourcompany.chai_dhaba_empire"`.
>   2. In `android/app/src/main/kotlin/`, update the folder directory path and the `package` line at the top of `MainActivity.kt`.
> 
> **4. How to switch from Test Ads to Live AdMob before release:**
> - In `android/app/src/main/AndroidManifest.xml`, replace the test App ID with your real AdMob App ID.
> - In `lib/services/ad_ids.dart`, set `useTestAds = false` and paste your real Rewarded and Interstitial Ad Unit IDs.
> - Configure release keystore signing in `android/key.properties` (as guided in Milestone M8).

## 1. Project goal

Publish a polished, addictive idle tycoon on Google Play. **Monetization is AdMob only** (no in-app purchases, no backend, no accounts in v1). The player starts with a tiny chai thela and grows it into a chai empire. Rewarded video ads are the main revenue source and must feel like optional power-ups, never forced.

Not a puzzle game. Not a runner. Everything works fully offline.

## 2. Environment (already installed)

- Windows 10, VS Code (Flutter + Dart extensions), Flutter stable, Android SDK, Git/GitHub.
- Test targets: BlueStacks emulator (connect with `adb connect 127.0.0.1:5555`, check with `flutter devices`) and a real Android phone.
- `flutter doctor` shows a missing **Visual Studio** warning. **Ignore it.** This is Android only. Never add or build the Windows, web, or iOS targets.
- Do not ask the owner to install new tools unless truly unavoidable. Prefer pure Flutter/Dart solutions.

## 3. Tech stack and rules

- Language: Dart, null-safe. State management: `provider` with `ChangeNotifier` (keep it simple).
- Allowed packages (add others only with a one-line justification to the owner):
  - `provider`
  - `shared_preferences` (save data)
  - `google_mobile_ads` (AdMob, official)
  - `audioplayers` (sound, added in M7)
  - `flutter_launcher_icons` (dev dependency, M8)
- No Firebase, no analytics, no in-app purchases, no network calls except ads (v1).
- Haptics: use Flutter's built-in `HapticFeedback` (no extra package).
- Android only: `flutter create --project-name chai_dhaba_empire --org <ORG_PREFIX> --platforms=android .`
- All game logic must live in plain Dart classes with **no Flutter imports** (`lib/engine/`) so it can be unit tested. Widgets only display state and call engine methods.
- All user-visible text goes in `lib/core/strings.dart` (English with light Roman Urdu flavour). No hardcoded strings in widgets.
- All balance numbers go in `lib/data/balance.dart` as typed `const` values, so the owner can tune them in one place.
- Keep the UI smooth: tick the game at 10 Hz with a single `Timer.periodic`, use delta time (never assume exactly 100 ms), and rebuild only what changed (`Selector` / `ValueListenableBuilder`). Do not rebuild the entire business list on every tick.

## 4. Working agreement

1. Work on **one milestone at a time** (section 9). At the end of each milestone:
   - run `flutter analyze` (must be clean) and `flutter test` (must pass),
   - `git add -A && git commit -m "M<n>: <summary>"`,
   - give the owner a short summary and exact steps to test on the emulator/phone,
   - **stop and wait** for the owner to say "next".
2. Do not start features from a later milestone early.
3. Never use real AdMob IDs. Use Google's official test IDs (section 7). The owner replaces them at release time.
4. Never commit secrets, keystores, or `key.properties`. Make sure `.gitignore` covers them.
5. Do not edit or delete files the owner created without asking. Do not edit this file unless asked.
6. If something is ambiguous, pick the simplest reasonable option, note the assumption in your summary, and continue. Ask the owner only for real blockers.
7. Placeholder art first: use Material icons, emoji, and colored shapes. The game must be fully playable before real art exists. Real art goes in `assets/images/` later.
8. If a build error appears, fix the root cause. Do not suppress warnings or lint rules to make it pass.

## 5. Game design

### 5.1 Core loop

1. Businesses earn Rupees (Rs) automatically every second.
2. Player taps the big chai cup for extra Rs.
3. Player spends Rs to buy more businesses and upgrades, which increases income.
4. When growth slows down, player **prestiges** ("Shohrat") to reset and gain a permanent income bonus.
5. Rewarded ads give optional boosts (2x offline earnings, income boost, parcels, daily reward doubling).

### 5.2 Currency

- **Rs (Rupees)**: main soft currency. Stored as `double`.
- **Shohrat (fame)**: prestige currency. Stored as `int`.
- Guard against `NaN` / `Infinity`: clamp values and never let a calculation crash the game.

### 5.3 Number formatting (`lib/core/number_format.dart`)

Show at most 3 significant digits plus a suffix:
`999` -> `999`, `1234` -> `1.23K`, `1.5e6` -> `1.50M`, `12.3e9` -> `12.3B`.
Suffix order: K, M, B, T, Qa, Qi, Sx, Sp, Oc, No, Dc. Above that, use scientific style like `1.23e36`.
Money below 1000 shows no decimals (below 10 show 1 decimal). Write unit tests for this.

### 5.4 Businesses (10 tiers)

Income is per second **per unit owned**, before multipliers.

| # | Name | Base cost (Rs) | Base income (Rs/s) |
|---|------|---------------:|-------------------:|
| 1 | Chai Thela | 10 | 0.5 |
| 2 | Paratha Stall | 120 | 6 |
| 3 | Roadside Dhaba | 1,500 | 70 |
| 4 | Family Restaurant | 20,000 | 900 |
| 5 | Food Street Franchise | 300,000 | 12,000 |
| 6 | Chai Packaging Factory | 5,000,000 | 170,000 |
| 7 | Highway Hotel Chain | 90,000,000 | 2,500,000 |
| 8 | Tea Export House | 1,800,000,000 | 40,000,000 |
| 9 | Mall Food Court | 40,000,000,000 | 700,000,000 |
| 10 | Chai Empire Inc. | 1,000,000,000,000 | 15,000,000,000 |

Formulas (cost growth `g = 1.13` for all tiers, defined in balance.dart):

- Cost of next unit: `baseCost * g^owned`
- Cost of buying `n` units: `baseCost * g^owned * (g^n - 1) / (g - 1)`
- Max affordable units: `floor( ln( cash * (g - 1) / (baseCost * g^owned) + 1 ) / ln(g) )`
- Business income/s: `baseIncome * owned * milestoneMultiplier * upgradeMultiplier`
- **Total income/s** = `sum(all businesses) * (1 + 0.03 * shohrat) * boostMultiplier`

Unlocking: business N+1 is visible as a locked silhouette (showing its cost) and becomes buyable once the player owns at least 1 of business N and can afford it.

Buy modes: **x1, x10, x100, Max** (toggle button). Buying less than the requested amount is not allowed except in Max mode.

**Milestones**: when a business reaches 25, 50, 100, 200, 300, 400, 500 owned (and every +100 after), its income is **x2** (cumulative). Show a small celebratory animation/toast when reached.

### 5.5 Tap mechanic

Tapping the cup gives `1 + 0.02 * totalIncomePerSecond` Rs (affected by boost multiplier). Show a floating "+Rs" text at the tap point, light haptic, small cup bounce animation. No tap limit, but throttle haptics to max 10 per second.

### 5.6 Upgrades (Upgrades tab)

Each business has 3 one-time upgrades:

| Upgrade | Unlock (owned) | Cost | Income multiplier |
|---------|---------------:|-----:|------------------:|
| 1 | 10 | baseCost * 60 | x2 |
| 2 | 50 | baseCost * 1,500 | x3 |
| 3 | 150 | baseCost * 40,000 | x5 |

Names are funny and themed (e.g. Chai Thela: "Doodh Patti Special", "Kadak Pati", "Pehalwan Chai"). Define all 30 names in strings.dart. Locked upgrades are shown greyed out with their unlock requirement.

### 5.7 Offline earnings

- On app start/resume, compute time away: `now - lastSeen`. If less than 60 seconds, show nothing.
- Offline earnings = `incomePerSecond * min(secondsAway, 8 hours) * 0.5`.
- Show a "Welcome back!" popup with the amount and two buttons: **Collect** (50%) and **Collect 2x (watch ad)** (100%).
- If the device clock went backwards (`now < lastSeen`), grant nothing and just update `lastSeen`.
- Chai Rush boost does not apply to offline earnings.

### 5.8 Prestige — "Shohrat"

- Available when `shohratGain >= 5`, where `shohratGain = floor( sqrt( runEarnings / 1e7 ) )` and `runEarnings` is total Rs earned since the last prestige. (First prestige is therefore around 2.5e8 earned; tune in balance.dart.)
- On prestige: Rs, businesses, and upgrades reset. Shohrat, settings, daily reward streak, and achievements are kept.
- Each Shohrat gives **+3%** total income (additive), as in the total income formula.
- Prestige screen shows: current Shohrat, gain if prestiging now, resulting income bonus, a confirmation dialog, and an optional "Claim 1.5x Shohrat (watch ad)" button.
- After the prestige confirmation, an interstitial may show (see ad rules).

### 5.9 Boosts and rewarded-ad features

All of these use the rewarded ad flow in section 7. If an ad is not available, show a friendly message ("Ad abhi available nahi, thori dair baad try karo") and do **not** grant the reward.

| Feature | Behaviour |
|---------|-----------|
| Offline 2x | See 5.7 |
| **Chai Rush** | x2 total income for 4 minutes per ad. Stacks, up to 20 minutes remaining. Counts down only while the app is open. Persisted in save. Visible timer on Home. |
| **Rider ka Parcel** | A delivery bike crosses the Home screen every 120-240 s (random) while Home is visible, for 8 s. Tap -> popup: **Claim** (free: 2 minutes of income, min Rs 100) or **Claim 5x (watch ad)**. |
| **Daily reward** | Once per local calendar day, 7-day streak: rewards in minutes of income `[5, 10, 15, 20, 30, 45, 60]` (min Rs 100 each). Missing a day resets to day 1. Optional "2x (watch ad)" on claim. |
| Prestige 1.5x | See 5.8 |

### 5.10 Screens and navigation

Bottom navigation with 5 tabs:

1. **Dhaba** (Home): Rs counter, income/s, big cup to tap, scrollable business list, buy mode toggle, Chai Rush timer, parcel bike.
2. **Upgrades**: list of upgrades (affordable ones highlighted, red dot on tab when something is affordable).
3. **Boosts**: Chai Rush, daily reward, and other ad-based options.
4. **Shohrat**: prestige screen.
5. **Settings**: sound on/off, vibration on/off, privacy policy link (placeholder), app version, "reset progress" (double confirmation).

Also: splash screen, Welcome-back popup, daily reward popup, milestone toast.

### 5.11 Look and feel

- Warm, friendly 2D cartoon style. Palette: chai brown, cream, saffron orange, with **Pakistani truck-art** inspired accents (borders, decorative patterns, bright colors).
- Tone: funny, light, family-friendly, with Roman Urdu phrases ("Paisa hi paisa!", "Kadak chai, kadak kamai"). No real brands or logos. No tobacco, gambling, or offensive stereotypes. The app is **not directed at children**.
- Use large tap targets, clear numbers, and responsive layouts that work on small and large phones. Support portrait only.

## 6. Architecture

```
lib/
  main.dart
  app.dart                  # MaterialApp, providers, lifecycle observer
  core/
    number_format.dart
    strings.dart
    theme.dart
  data/
    balance.dart            # all tuning numbers, business and upgrade definitions
  engine/                   # pure Dart, no Flutter imports, unit tested
    game_engine.dart        # tick, buy, income, prestige, boosts, offline calc
    models.dart             # GameState, BusinessState, SaveData
  services/
    save_service.dart       # shared_preferences JSON, versioned
    ads_service.dart        # AdMob wrapper
    audio_service.dart
  state/
    game_controller.dart    # ChangeNotifier wrapping the engine + services
  ui/
    screens/                # dhaba, upgrades, boosts, shohrat, settings, splash
    widgets/                # business_tile, cup_button, popups, floating_text...
test/
  number_format_test.dart
  engine_test.dart          # costs, bulk buy, income, milestones, offline, prestige
```

### Save system

- Store one JSON string under key `save_v1` with a `version` field (add simple migration hooks).
- Auto-save every 10 seconds and on app pause (`WidgetsBindingObserver.didChangeAppLifecycleState`).
- If the save is corrupted or fails to parse, start a fresh game instead of crashing (keep the broken string under `save_v1_corrupt` for debugging).
- Save: Rs, lifetime and run earnings, owned counts, purchased upgrades, Shohrat, boost time remaining, daily reward state, settings, `lastSeen` (UTC).

## 7. Ads (AdMob) — rules

Use `google_mobile_ads`. Always use these **official Google test IDs** during development:

- Android App ID: `ca-app-pub-3940256099942544~3347511713` (goes in `AndroidManifest.xml` meta-data `com.google.android.gms.ads.APPLICATION_ID`)
- Rewarded: `ca-app-pub-3940256099942544/5224354917`
- Interstitial: `ca-app-pub-3940256099942544/1033173712`
- Banner (not used in v1): `ca-app-pub-3940256099942544/6300978111`

Keep all IDs in one file `lib/services/ad_ids.dart` with a single constant `useTestAds = true`. Release IDs are placeholders (`REPLACE_ME`). The owner fills them in at release. Never hardcode IDs anywhere else.

`AdsService` API:

- `Future<void> init()`: initialise the SDK and preload one rewarded and one interstitial ad.
- `Future<bool> showRewarded()`: returns `true` **only** if the user earned the reward. Reload the next ad right after one is shown or fails (retry with exponential backoff, max 60 s).
- `Future<void> maybeShowInterstitial(String reason)`: obeys the rules below.

Rules:

- **Rewarded ads are always optional** and always user-initiated (button press). Clearly label buttons with what the reward is.
- **Interstitials**: only at natural breaks (after prestige confirmation, after claiming the daily reward). Never on app open, never during tapping, never within 5 minutes of install/first launch session start, minimum 180 seconds between interstitials, and never right after a rewarded ad.
- **No banner ads in v1.**
- Pause the game tick and mute audio while a full-screen ad is showing.
- Never click or trigger ads on the owner's behalf; test with test IDs only.
- Handle ad load failure and no-fill gracefully (no crashes, no stuck loading spinners, no free rewards).
- Do not mark the app as child-directed. Release checklist (M8) includes adding the **UMP consent** flow for EEA/UK users.

## 8. Quality bar

- `flutter analyze` has zero warnings. Code is formatted (`dart format .`).
- Unit tests cover: number formatting, cost and bulk-cost formulas, max affordable, income with all multipliers, milestones, offline earnings (including clock going backwards and 8h cap), prestige gain and reset, and save/load round trip.
- No game logic in widgets. No magic numbers (use balance.dart).
- Small, readable files. Short comments explaining *why*, not *what*.
- The app must survive: rotation lock, backgrounding, killing the process, and re-opening with an old save.

## 9. Milestones

**M0 — Project setup**
`flutter create` (Android only), folder structure from section 6, packages, `.gitignore`, `git init`, first commit. App shows a placeholder Home screen and runs on the emulator/phone.
Done when: `flutter run` works on a connected device and `flutter analyze` is clean.

**M1 — Core loop**
Rs counter, tick loop (10 Hz, delta-time), first 3 businesses, buy x1, tap the cup, number formatting + tests.
Done when: owner can tap, buy, and watch income grow; unit tests pass.

**M2 — Full economy**
All 10 businesses, locked silhouettes, buy modes (x1/x10/x100/Max), milestones with toast, config-driven from balance.dart, engine tests for formulas.

**M3 — Save and offline**
Save/load, autosave, lifecycle handling, offline earnings popup (the "2x" button calls a stub `showRewarded()` that returns true for now, clearly marked TODO), corrupted-save handling.

**M4 — Upgrades**
Upgrades tab with all 30 upgrades, multipliers wired into income, red dot on tab when affordable.

**M5 — Ads**
`AdsService` with test IDs, Android manifest setup, rewarded flow for: offline 2x, Chai Rush, Rider ka Parcel. Interstitial rules. Graceful failure messages. Replace the M3 stub.

**M6 — Prestige**
Shohrat screen, formula, reset logic, confirmation, 1.5x ad option, interstitial after prestige.

**M7 — Retention and polish**
Daily reward, Boosts tab, Settings (sound, vibration, reset progress), `AudioService` (silent if no asset files yet), haptics, tap animations, floating numbers.

**M8 — Release prep**
Real app icon and splash, final package name/app name check, app version, UMP consent flow, AD_ID permission check, signing config template (`key.properties.example`, never commit real keys), `flutter build appbundle --release`, privacy-policy placeholder, and a short Play Store checklist (data safety form notes, closed-testing steps, store listing text and screenshot list).
Done when: a signed `.aab` builds successfully (owner supplies the keystore).

## 10. Start here

Begin with **M0** now. After finishing it, report back and wait for the owner's "next".
