# AGENTS.md — Dhaba Tycoon: Arcade Idle (Chai & Burger Empire)

You are a coding agent building a 3D-feel **2D Top-Down / Isometric Arcade Idle Tycoon game** in **Flutter** (inspired by mobile hits like *Burger Please!*, *Burger Tycoon Idle*, and *My Perfect Hotel*).
Read this whole file before writing any code. Follow the milestones in order.

---

## 0. Owner settings (the owner edits these before starting)

- ORG_PREFIX: `com.chaidhaba`   <- Default testing prefix (change to your own reverse-domain before Play Store release).
- APP_NAME: `Dhaba Tycoon: Arcade Idle`
- DART_PACKAGE_NAME: `chai_dhaba_empire`
- THEME: Pakistani Chai & Burger Dhaba Arcade Idle. Start with a humble roadside chai stall, brew chai, stack cups on your head, serve customers, collect cash piles, unlock burger grills, hire chotus (workers), expand dining tables, and scale into a mega restaurant franchise!

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
> When you are ready to publish under your own domain name (e.g., `com.yourcompany.dhaba_tycoon`):
> - **Option A (Automated - Recommended):**
>   1. In `pubspec.yaml`, temporarily add `change_app_package_name` under `dev_dependencies`:
>      ```yaml
>      dev_dependencies:
>        change_app_package_name: ^1.4.0
>      ```
>   2. Run in terminal:
>      ```bash
>      dart run change_app_package_name:main com.yourcompany.dhaba_tycoon
>      ```
>   3. It will automatically update `android/app/build.gradle.kts`, `AndroidManifest.xml`, and Kotlin directory hierarchy.
> - **Option B (Manual):**
>   1. Open `android/app/build.gradle.kts` and change `applicationId "com.chaidhaba.chai_dhaba_empire"` to `applicationId "com.yourcompany.dhaba_tycoon"`.
>   2. In `android/app/src/main/kotlin/`, update the folder directory path and the `package` line at the top of `MainActivity.kt`.
> 
> **4. How to switch from Test Ads to Live AdMob before release:**
> - In `android/app/src/main/AndroidManifest.xml`, replace the test App ID with your real AdMob App ID.
> - In `lib/services/ad_ids.dart`, set `useTestAds = false` and paste your real Rewarded and Interstitial Ad Unit IDs.
> - Configure release keystore signing in `android/key.properties` (as guided in Milestone M8).

---

## 1. Project Goal & Game Overview

Publish a hyper-addictive, highly polished **Arcade Idle Tycoon** game on Google Play.
- **Genre**: Arcade Idle (Top-down character navigation, physical item stacking, customer queues, floor unlock pads, cash vacuuming, hiring workers).
- **Core Hook**: Physical interaction! You don't just tap spreadsheet buttons. You control the Dhaba Manager / Chotu directly with a virtual joystick, physically walking to the kitchen, stacking towering piles of steaming chai cups and burgers above your head, running to serve hungry customers, vacuuming up stacks of rupee notes, and standing on glowing floor unlock pads to pop new tables and grills into existence!
- **Monetization**: 100% AdMob (Rewarded ads for speed boosts, extra capacity, free instant workers, and 2x offline earnings). No forced paywalls, works fully offline.

---

## 2. Environment & Tech Stack

- Windows 10, VS Code, Flutter stable, Android SDK (NDK `27.1.12297006`), Git.
- Android only (`--platforms=android`, portrait orientation locked).
- High-Performance Flutter Rendering: `CustomPainter` with 60 FPS `TickerProvider` / `AnimationController` for silky smooth character movement, camera tracking, and entity rendering.
- State management: `provider` with `ChangeNotifier`.
- Allowed packages:
  - `provider`
  - `shared_preferences` (local save)
  - `google_mobile_ads` (AdMob official test IDs)
  - `audioplayers` (sound effects)
- All core game logic and physics simulation live in pure Dart (`lib/engine/`) with no Flutter UI dependencies so it is 100% unit-testable.

---

## 3. Game Design & Core Mechanics

### 3.1 Movement & Controls
- **Virtual Joystick**: Touch and drag anywhere on the bottom half of the screen to move the player character in 360 degrees.
- **Smooth Physics**: Velocity, acceleration, and crisp collision against walls and counters.
- **Camera Follow**: Smooth camera interpolating towards the player position as the dhaba expands.

### 3.2 Kitchen Preparation Stations
1. **Kadak Chai Kettle**: Produces steaming hot chai cups automatically every $T_{\text{brew}}$ seconds onto an output shelf (up to max shelf capacity).
2. **Burger & Shami Grill**: Unlocked later; sizzles and cooks delicious burgers/bun-kababs onto its output shelf.
- Each station has an interactive pickup zone marked on the floor.

### 3.3 Towering Item Stacks (Above-Head Carrying)
- Walking into a station's pickup zone transfers items to the character.
- Items stack vertically on top of the character's head with a slight cartoon wobble physics effect as the player walks and turns!
- **Carry Capacity**: Limits how many items can be carried at once (base 3 items; upgradable in HR to 5, 8, 12, 16+).
- If capacity is full, a bouncy `"MAX"` badge appears above the stack.

### 3.4 Customer AI & Serving System
- **Customer Spawning**: Diverse cartoon characters (Office Babus, Students, Rickshaw Walas, Families) enter through the entrance.
- **Queuing**: Customers line up behind order spots at the front counter.
- **Order Speech Bubbles**: Above each customer's head, an order bubble displays what they want (e.g. ☕ Chai $\times 1$, or 🍔 Burger $\times 2$).
- **Serving**: When the player or an AI worker stands behind the counter adjacent to a customer, items transfer from the head stack into the customer's hands with a satisfying pop sound.
- **Cash Dropping**: Once served, customers drop green bundles of Rupee notes on the counter, take their order, and either exit (takeaway) or proceed to a dining table.

### 3.5 Cash Collection (Magnet Vacuum)
- Customers leave stacks of green rupee cash bundles on the counter and dining tables.
- Walking close to cash triggers a magnetic suction effect: rupee bundles fly into the player's wallet accompanied by snappy coin sounds, light haptics, and floating `+Rs X` numbers.

### 3.6 Ground Unlock Pads (Physical Upgrades)
- Stations, dining tables, trash bins, and new zones are locked behind circular glowing pads painted on the dhaba floor (e.g., `[ 100 Rs : Table 1 ]`, `[ 350 Rs : Burger Grill ]`, `[ 500 Rs : Hire Chotu ]`).
- **Interactive Pour Mechanic**: Walking onto the pad smoothly drains cash from the player's wallet into the pad counter (e.g. 50 Rs / sec).
- When the required amount is reached: **BOOM!** The pad disappears, and the new table/station bursts into existence with celebratory confetti and haptic feedback!

### 3.7 Dine-In Tables & Cleaning
- Unlocked tables have seats where customers sit down to enjoy their chai and burgers.
- When done, customers leave larger cash payments (including tips!) and dirty trays.
- Cleaning up dirty trays returns plates to the washing sink and frees up the table for new paying customers.

### 3.8 HR Office & Automated Helpers (Chotus)
- An in-game HR Desk / Clipboard allows upgrading stats:
  - **Player Move Speed**: Increase player walk velocity by $+15\%$ per level.
  - **Player Capacity**: Increase max carried stack $+2$ items per level.
  - **Hire Workers (Chotu 1, Chotu 2, Waiter)**: Autonomous AI helpers who carry items from kitchen to counter/tables and clean up dirty trays automatically!
  - **Worker Speed & Capacity**: Upgrade worker efficiency.
  - **Kitchen Cooking Speed**: Reduces brew/cook time by $-15\%$ per level.

### 3.9 Rewarded Ad Power-Ups
- **Chai Rush (2x Speed & 2x Cash)**: 3 minutes of blazing fast turbo speed and double cash drops.
- **VIP Chotu**: Hires a super-fast temporary helper for 5 minutes.
- **Offline Earnings 2x**: Doubles the money collected while away.

---

## 4. Architecture & File Structure

```
lib/
  main.dart                 # Orientation, binding initialization
  app.dart                  # MaterialApp, Provider setup, theme
  core/
    number_format.dart      # Currency & count formatting (K, M, B)
    strings.dart            # English with lively Roman Urdu flavour
    theme.dart              # Dhaba cartoon color palette & styling
  data/
    balance.dart            # Prices, speeds, capacities, upgrade curves
  engine/                   # Pure Dart simulation (zero Flutter imports)
    entities.dart           # Player, Customer, Worker, Item, CashBundle
    stations.dart           # Station, Table, UnlockPad definitions
    customer_ai.dart        # State machine: Arrive -> Queue -> Order -> Eat -> Pay -> Leave
    game_world.dart         # Full world simulation, collisions, tick logic
  services/
    ad_ids.dart             # Official Google AdMob test IDs
    ads_service.dart        # Rewarded and interstitial wrapper
    save_service.dart       # JSON persistence via SharedPreferences
    audio_service.dart      # Sound effects & feedback
  state/
    game_controller.dart    # ChangeNotifier binding GameWorld to 60 FPS tick
  ui/
    game/                   # CustomPainter rendering engine
      game_viewport.dart    # Touch listener, virtual joystick, canvas viewport
      world_painter.dart    # 60 FPS painter with Y-depth sorting
      sprite_renderer.dart  # Character, items, stations, cash stacks, shadows
    overlays/               # HUD, Joystick, HR upgrade sheet, ad popups
      hud_overlay.dart      # Cash display, boost buttons, speed indicator
      joystick_widget.dart  # Floating virtual joystick
      hr_upgrade_sheet.dart # Clipboard popup for speed/capacity/worker upgrades
      offline_popup.dart    # Welcome back offline cash collection
test/
  number_format_test.dart
  world_simulation_test.dart
  customer_ai_test.dart
```

---

## 5. Working Agreement

1. Work on **one milestone at a time**. At the end of each milestone:
   - Run `flutter analyze` (must have 0 errors, 0 warnings).
   - Run `flutter test` (all unit and simulation tests must pass).
   - `git add -A && git commit -m "M<n>: <summary>"`
   - Give the owner a short summary and exact steps to test on their phone/emulator.
   - **Stop and wait** for the owner to say "next".
2. Do not start features from later milestones early.
3. Keep art stylized, clean, vibrant, and fun using high-performance vector rendering on the Canvas before custom sprite assets.
4. AdMob test IDs only during testing.

---

## 6. Implementation Milestones

### **M0 — Arcade Engine & Canvas Loop**
Set up the 60 FPS CustomPainter game loop, coordinate space, camera follow system, Dhaba tiled floor arena with boundary walls, and floating virtual joystick touch controls.
*Done when: Player character moves smoothly around the Dhaba floor in 360 degrees using the joystick.*

### **M1 — Kitchen Station & Item Stacking Physics**
Add the Chai Brewing Kettle station producing hot chai cups onto an output shelf. When the player steps into the pickup zone, cups stack vertically above the player's head with wobble physics and capacity limit (with `"MAX"` badge when full).
*Done when: Player can walk to the kettle, watch cups brew, and carry a towering stack of chai cups above their head.*

### **M2 — Counter Service, Cash Drops & Magnet Vacuum**
Add the Front Serving Counter and Trash Bin. Player can stand at the counter to deliver chai from their head stack. Served items drop 3D green Rupee cash bundles onto the floor/counter. Walking near cash magnets it into the player's wallet with haptics and floating `+Rs X` numbers.
*Done when: Player can deliver chai to the counter, generate cash bundles, and vacuum them up to grow their wallet.*

### **M3 — Customer AI & Queue System**
Implement full Customer AI: Customers spawn outside, walk in through the entrance, queue up in line at the counter with order speech bubbles (`☕ x1`), wait for their order, receive chai, drop cash, and exit.
*Done when: A continuous flow of customers queues up, gets served, pays cash, and leaves happily.*

### **M4 — Ground Unlock Pads & Dynamic Shop Expansion**
Implement interactive circular ground pads (e.g. `[ Rs 50 : Table 1 ]`, `[ Rs 250 : Unlock Burger Grill ]`). Standing on a pad smoothly pours cash from the player's wallet into the pad until complete, popping the new station/table into existence with confetti and bounce animation!
*Done when: Player uses earned cash to physically unlock new tables and kitchen stations on the floor.*

### **M5 — Dine-In Dining Tables & Cleaning**
Add customer dine-in behavior: Customers can choose to sit at unlocked dining tables, enjoy their meal, leave bigger cash tips on the table, and leave dirty trays. Player cleans trays to keep tables open for new customers.
*Done when: Customers sit at tables, eat, tip, and tables require cleaning.*

### **M6 — HR Office & Autonomous Workers (Chotus)**
Add the HR Clipboard upgrade zone. Player can open the HR menu to upgrade Player Move Speed, Player Carry Capacity, Kitchen Brew Speed, and **Hire Workers (Chotus)**. Hired workers move autonomously to brew chai, serve customers, and clean tables!
*Done when: You can hire a worker who serves customers automatically while you manage and expand.*

### **M7 — Food Variety (Burger Station) & Audio Polish**
Unlock the Burger Grill station producing delicious burgers. Customers place mixed orders (`☕ + 🍔`). Add truck-art decorative elements, lively sound effects (sizzling grill, pouring tea, cha-ching cash pickup), and haptic vibrations.
*Done when: Both Chai and Burgers are in full production with rich sound effects and Pakistani Dhaba aesthetic.*

### **M8 — AdMob Rewarded Power-Ups, Offline Earnings & Release Prep**
Add AdMob Rewarded Ads for instant boosts (Chai Rush 2x Speed, Free VIP Helper, 2x Offline Earnings on game launch), full SharedPreferences persistence (save & load), and final Google Play release readiness.
*Done when: Full game saves/resumes, rewarded ads trigger power-ups, and the release build is ready.*

---

## 7. Start Here

Milestone **M0 — Arcade Engine & Canvas Loop** is the immediate next step. Proceed when approved.
