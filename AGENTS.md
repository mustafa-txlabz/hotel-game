# AGENTS.md — Dhaba Tycoon: Arcade Idle (Chai & Burger Empire)

You are a coding agent building a 3D-feel **2D Top-Down / Isometric Arcade Idle Tycoon game** in **Flutter** (inspired by mobile hits like *Burger Please!*, *Burger Tycoon Idle*, and *My Perfect Hotel*).
Read this whole file before writing any code. Follow the milestones in order.

---

## 0. Owner settings (the owner edits these before starting)

- ORG_PREFIX: `com.chaidhaba`   <- Default testing prefix (change to your own reverse-domain before Play Store release).
- APP_NAME: `Dhaba Tycoon: Arcade Idle`
- DART_PACKAGE_NAME: `chai_dhaba_empire`
- THEME: Pakistani Chai & Burger Dhaba Arcade Idle. You control the Owner / Dhaba Manager directly with a virtual joystick, brew kadak chai, stack food on your head, deposit food onto counter towers, attend the cashier station, vacuum up cash towers, upgrade machines via floor pads, hire staff (cashiers & helpers/waiters), and expand the empire!

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
> - In `lib/services/ad_ids.dart`, set `useTestAds = false` and paste your real Banner, Rewarded, and Interstitial Ad Unit IDs.
> - Configure release keystore signing in `android/key.properties` (as guided in Milestone M8).

---

## 1. Project Goal & Game Overview

Publish a hyper-addictive, highly polished **Arcade Idle Tycoon** game on Google Play.
- **Genre**: Arcade Idle (Top-down character navigation, physical item stacking, multi-part service counters, customer queues, floor unlock/upgrade pads, cash vacuuming, hiring staff).
- **Core Hook**: Physical interaction! You control the Owner / Dhaba Manager directly with a virtual joystick:
  - Physically walk to kitchen machines to pick up items onto your head stack.
  - Unload food onto the **Counter Food Storage** forming tall item towers.
  - Stand in the **Center Cashier Green Zone** to actively serve queued customers (or hire a permanent Cashier).
  - Customers pay money that stacks into neat **Cash Towers** on the right side of the counter.
  - Step onto the cash area to vacuum piles of green Rupee bundles into your wallet!
  - Step on in-place machine pads to pour cash and upgrade capacity/speed or unlock new stations.

---

## 2. Environment & Tech Stack

- Windows 10, VS Code, Flutter stable, Android SDK (NDK `27.1.12297006`), Git.
- Android only (`--platforms=android`, portrait orientation locked).
- High-Performance Flutter Rendering: `CustomPainter` with 60 FPS `TickerProvider` for silky smooth character movement, camera tracking, and entity rendering.
- State management: `provider` with `ChangeNotifier`.
- Allowed packages:
  - `provider`
  - `shared_preferences` (local save)
  - `google_mobile_ads` (AdMob official test IDs)
  - `audioplayers` (sound effects)
- All core game logic and physics simulation live in pure Dart (`lib/engine/`) with no Flutter UI dependencies so it is 100% unit-testable.

---

## 3. Game Design & Detailed Architecture

### 3.1 Movement & Controls
- **Virtual Joystick**: Touch and drag anywhere on the screen to move the Owner character in 360 degrees.
- **Smooth Physics**: Velocity, acceleration, and crisp sliding collision against walls, counters, and stations.
- **Camera Follow**: Smooth camera interpolating towards the Owner position as the dhaba expands.

### 3.2 Kitchen Preparation Machines & In-Place Ground Pads
1. **Kadak Chai Kettle**: Produces steaming hot chai cups automatically onto its output shelf (up to max shelf capacity, e.g. 8 base).
2. **Burger Grill & Samosa Fryer**: Unlocked later for food variety.
- **In-Place Floor Pads**: Next to each kitchen machine, a rectangle ground pad with a cash icon and price amount:
  - **Locked State (Unlock Pad)**: Shows remaining cost. Standing on it drains money from the Owner's wallet into the pad (e.g. 50 Rs/sec), reducing the displayed price. If money runs out, it stops and preserves the partial progress. When it reaches 0: **BOOM!** The machine unlocks!
  - **Unlocked State (Upgrade Pad)**: The pad remains active to upgrade that machine! Upgrading increases storage capacity ($+1$ or $+2$ items per level) and speeds up preparation time up to max level.

### 3.3 Towering Item Stacks (Above-Head Carrying)
- Walking into a machine's pickup zone transfers items to the Owner's head stack.
- Items stack vertically on top of the character's head with cartoon wobble physics as the player turns and runs.
- **Carry Capacity**: Limits how many items can be carried at once (base 3 items; upgradable in HR to 5, 8, 12, 16+).
- When full, a bouncy `"MAX"` badge appears above the stack.

### 3.4 Three-Part Front Serving Counter
The front counter is split into three dedicated functional areas:
1. **Left Section (Food Deposit & Item Towers)**:
   - When the Owner stands in the drop zone behind this section, carried items unload onto the counter.
   - On the counter, items form **Towers**! (Each tower has a max capacity, e.g. 10 items, and subsequent items start the next tower in a neat grid).
   - **Strict Single-Item Rule**: Each tower contains ONLY ONE type of item (Chai tower holds only Chai cups; Samosa tower holds only Samosas).
2. **Center Section (Cashier Station - Green Zone)**:
   - Features the cash register and a green designated standing zone behind the counter.
   - **Crucial Rule**: Customers are **ONLY served if someone is standing in this green cashier spot** (either the Owner or a hired Cashier worker)!
   - If nobody is in the cashier zone, customers wait in line. The first customer has a background patience timer. If unattended for too long, they leave disappointed, and the next customer moves up.
3. **Right Section (Money Stacking Grid & Cash Towers)**:
   - When customers are served at the cashier station, they leave their payment on the right section of the counter.
   - Cash forms neat **3D Cash Towers** in a grid (stacks of green rupee notes).
   - Stepping on the collection zone vacuums cash bundles into the Owner's wallet with flying animations and floating `+Rs X` popups!

### 3.5 Customer AI & Queue System
- **Spawning**: Diverse cartoon characters enter through the dhaba entrance door.
- **Queuing**: Customers form a queue in front of the counter with order speech bubbles (e.g. `☕ x1`, or `🍔 x2`).
- **Transaction**: When cashier zone is occupied and required items are in the counter food towers, items transfer to the customer, cash drops onto the right cash towers, and the customer leaves happily or walks to a dining table.

### 3.6 Dine-In Tables & Cleaning
- Unlocked dining tables where customers sit down to enjoy their food.
- Customers leave larger cash payments/tips and dirty trays.
- Cleaning up trays frees up tables for new customers.

### 3.7 Staff & Workers (Cashier & Helpers/Waiters)
- **Cashier**: Can be hired to permanently occupy the green cashier spot so the Owner is free to manage and run the dhaba.
- **Helpers / Waiters (Runners & Busboys)**: Autonomous helpers who carry items from kitchen machines to counter towers and clean tables.
- **HR & Upgrades**: Upgrades Owner/Worker move speed and carry capacity.

### 3.8 Rewarded Ad Power-Ups & Offline Earnings
- **Chai Rush (2x Speed & 2x Cash)**: 3 minutes of turbo speed and double cash drops.
- **VIP Cashier / Helper**: Temporary helper for 5 minutes.
- **Offline Earnings 2x**: Doubles money collected while away.

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
    stations.dart           # ChaiStation, ServingCounter (3-part), TrashBin, InPlacePad
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
3. Keep art stylized, clean, vibrant, and fun using high-performance vector rendering on the Canvas.
4. AdMob test IDs only during testing.

---

## 6. Implementation Milestones

### **M0 — Arcade Engine & Canvas Loop** *(Completed)*
Set up the 60 FPS CustomPainter game loop, coordinate space, camera follow system, Dhaba tiled floor arena with boundary walls, and floating virtual joystick touch controls.

### **M1 — Kitchen Station & Item Stacking Physics** *(Completed)*
Add the Chai Brewing Kettle station producing hot chai cups onto an output shelf. When the Owner steps into the pickup zone, cups stack vertically above the head with wobble physics and capacity limit (with `"MAX"` badge when full).

### **M2 — Three-Part Counter Architecture, Food Towers & Cash Towers** *(Completed)*
Transform the Front Serving Counter into a full 3-part arcade counter:
1. **Left Section**: Food deposit zone where Owner unloads carried items onto the counter into neat single-item food towers.
2. **Center Section**: Cashier station with green zone where Owner must stand to activate service.
3. **Right Section**: Money stacking grid where cash bundles form neat 3D towers; stepping on the collection area vacuums the cash into wallet with flying animation.
4. **Trash Bin**: For discarding unwanted items.
*Done when: Owner can carry chai from kettle, stack it on the counter's left food towers, stand at cashier to trigger cash to right-side money towers, and collect cash towers.*

### **M3 — Customer AI, Orders & Queue Wait System** *(Completed)*
Implement full Customer AI: Customers enter from the entrance, queue up at the counter with order speech bubbles (`☕ x1`), wait for cashier attendance (with background patience timer). If cashier is present and food is on counter towers, food is handed to customer and cash is placed on the right cash towers; if unattended, customer leaves disappointed.
*Done when: Continuous customer flow lines up, requires cashier presence to be served, and pays cash onto counter cash towers.*

### **M4 — In-Place Machine Upgrade & Floor Unlock Pads** *(Completed)*
Add interactive ground rectangle pads with cash icon and pour mechanic:
1. **Machine In-Place Upgrade Pad**: Standing on the pad next to the kettle pours cash to upgrade storage capacity and brewing speed.
2. **Unlock Pads**: Pour cash to unlock dining tables and new zones with partial progress memory (stops if player runs out of cash).
*Done when: Owner can stand on pads to smoothly pour cash and upgrade machines or unlock new items.*

### **M5 — Dine-In Dining Tables & Cleaning** *(Completed)*
Add customer dine-in behavior: Customers can choose to sit at unlocked dining tables, enjoy their meal, leave larger cash tips on the table, and leave dirty trays. Owner cleans trays to keep tables open for new customers.
*Done when: Customers sit at tables, eat, tip, and tables require cleaning.*

### **M6 — Staff Hiring & Cashier Faculty** *(Completed)*
Add hiring and staff management:
1. **Hire Cashier**: Stands permanently in the center green cashier spot so the Owner is free to manage the dhaba.
2. **Hire Helpers (Waiters/Runners)**: Autonomous AI helpers who carry items from kitchen to counter towers and clean tables with specialized duties.
3. **HR Upgrades**: Upgrade Owner and Worker speed and carry capacity via left HUD glass badge.
*Done when: A hired cashier serves customers automatically, and autonomous helpers restock counter and clean tables.*

### **M6.1 — Per-Store Reputation System, Goals Overlay & Multi-Store Persistence** *(Completed)*
Implement per-store reputation progression, dynamic customer scaling, goal checklist, and JSON save/load:
1. **Configurable Per-Store Reputation & XP**:
   - Each store defines its own progression profile (`storeId`, `storeName`, `targetReputationXP`, XP gains for takeaway +2, dine-in +4, sad customer -3, upgrades +20).
   - Higher stores scale difficulty with higher target XP and longer playtime.
   - **100% Lock Rule**: Once 100% Reputation is reached, it locks permanently and never degrades. Below 100%, sad customers waiting too long deduct XP.
2. **Dynamic Customer Spawning & Queue Scaling**:
   - Customer spawn interval scales smoothly with reputation (from 4.0s down to 1.8s).
   - Counter queue capacity expanded to 8-10 customers. If full, customers arrive, react to the long line (`"Too crowded! 😤"`), and exit, creating urgency.
3. **Goals & Missions Sheet (HUD Trophy Button 🏆)**:
   - Replaces placeholder with sleek modal sheet:
     - Top Card: Store Reputation Horizontal Progress Bar (`XX% / 100%`).
     - Dynamic per-store checklist (Hire Cashier, Hire 3 Workers, Unlock Dining Tables, Max Kettle, 100% Reputation).
     - Completed missions tick off and reward XP; full completion triggers "Store Mastered! 🎉" state.
4. **Multi-Store JSON Save / Load (SharedPreferences)**:
   - Saves per-store state (independent store wallet, reputation XP, completed mission IDs, equipment levels, unlocked furniture, hired workers).
   - Auto-saves on interval & app pause; restores exact state and customer rate on game restart.
*Done when: Progress saves/loads seamlessly across restarts, HUD Trophy button displays live reputation bar & mission checklist, and reputation dynamically drives customer flow and difficulty.*

### **M7 — Food Variety (Authentic Tawa Paratha) & Audio Polish** *(Completed)*
Add authentic Pakistani Dhaba food variety with Tawa Paratha cooking station and sound/haptics:
1. **Tawa Paratha Cooking Station**:
   - In-place unlock ground pad (Rs 100) and upgrade curve (L1-L5, expanding shelf capacity from 6 to 14, and cook time from 1.6s to 0.60s).
   - Hot cast iron Tawa with circular cook progress ring, sizzling butter/oil sparks, wooden handle, and aromatic rising steam.
   - Output shelf tray holding crispy flaky golden Lachha Parathas on stainless steel plates.
2. **Three-Part Counter Dedicated Food Towers**:
   - Strictly separates food types into single-item towers: Chai cups on Chai towers (`☕ N`), and Paratha plates on dedicated Paratha towers (`🫓 N`).
3. **Customer Mixed Orders & Dynamic Dining**:
   - Customers can order Chai only, Paratha only (Rs 20 each), or Mixed Combos (`☕ xN 🫓 xM`).
   - Counter order bubbles show combined items when at front of line.
   - Customers ordering $\le 3$ Chai AND $\le 3$ Parathas sit at dining tables; bulk orders are takeaway.
   - Eating duration scales dynamically with item count (`2.0s + total_items * 1.2s`).
   - Seated diners display their actual meal (cup, plate, or side-by-side mixed meal) on table.
   - Bigger tips for mixed orders (`Rs 40` mixed, `Rs 30` paratha, `Rs 25` chai), and timeout refund calculates exact cost of items received.
4. **Autonomous Helper Restocking**:
   - Helpers automatically fetch Parathas from Tawa or Chai from Kettle based on which counter tower has fewer items.
5. **Audio & Haptic Feedback Polish**:
   - Tactile feedback and audio hooks for cooking sizzle, pickup pour, cashier serve, coin vacuum, and purchases.
6. **Multi-Store Persistence**:
   - Saves & restores Paratha Station unlock state and upgrade level in SharedPreferences JSON.
*Done when: Multiple authentic food types are cooked, stacked in distinct counter towers, sold to customers with mixed orders, and progress is saved.*

### **M8 — Goals, Shop Completion Celebration & Reward Bonus** *(Completed)*
Add full Goal/Mission completion system driven by HUD Reputation Bar and Objectives Sheet:
1. **Shop Milestones & Level Objectives**: Clear 6-goal target checklist (Hire Cashier, Hire 3 Workers, Unlock 2 Dining Tables, Unlock Tawa Paratha, Master Kadak Kettle, 100% Reputation).
2. **Level Complete Celebration**: Fireworks, confetti particle system (`ConfettiOverlay`), sound effects, and celebratory modal (`LevelCompleteDialog`) with pulsing golden trophy upon clearing all store objectives.
3. **Big Victory Reward Bonus**: Player can claim a ₹1,000 victory reward bonus with coin collection sounds, floating text, and SharedPreferences persistence.
*Done when: Completing all store goals triggers level-complete victory celebration with bonus rewards.*

### **M9 — AdMob Rewarded Deals Pad, Boosts & VIP Helper** *(Completed)*
Add AdMob Rewarded Ads monetization via interactive Ground Deal Pad and HUD Reward Badge:
1. **Dedicated Ad IDs Service (`lib/services/ad_ids.dart`)**:
   - Clean, central file with `useTestAds = true` and Google's official Test Ad IDs for easy owner replacement with real AdMob IDs before release.
   - Safe test-fallback handling so game and tests run seamlessly in all environments.
2. **Interactive Ground Deal Pad & Left HUD Reward Badge**:
   - Spawns every 75–90s when no boost is active.
   - Player can step onto the ground pad OR tap the left HUD Gift/Reward badge to open the deal preview.
3. **Deal Preview Modal Popup (`lib/ui/overlays/deal_popup.dart`)**:
   - Features a centered animated gift box / deal badge.
   - Shows deal details, top-right `✕` dismiss button, and green `"WATCH AD & CLAIM"` button.
4. **Random Dhaba Deals Pool**:
   - ⚡ **2x Staff Turbo Speed (90s)**: Boosts owner and helper movement speeds.
   - 🔥 **2x Kitchen Output & Speed (90s)**: Doubles Chai kettle and Paratha tawa cooking speeds.
   - 👥 **Customer Rush (90s)**: Spawns customers at double frequency for a bustling dhaba rush.
   - 💰 **Instant Cash Injection**: Instant ₹500–₹800 cash drop directly into wallet.
   - 👷 **Golden VIP Helper (120s / 2 Mins)**: Summons an autonomous golden turbo helper to restock and clean.
5. **Dynamic Circular Progress Clock Timer**:
   - When a deal is claimed, ground pad vanishes and HUD icon transforms into a Clock Timer with an animated green circular border that sweeps down as seconds tick away.
   - When timer expires, boost ends and cooldown begins for the next deal.
6. **Staff Speed Rebalancing**:
   - Fine-tune base and upgrade worker speed increments in `GameBalance` so 2x turbo boosts feel thrilling, smooth, and perfectly controllable without physics jitter.
7. **Strict No Ad = No Reward Rule**:
   - If ad fails to load, user is offline, or ad blocker is active, zero reward is granted and a warning is displayed.
*Done when: Ground deal pad and HUD badge spawn deals, popup opens with animated gift, watching ad activates boost with ticking green circular clock timer, and VIP helper assists for 2 minutes.*

### **M10 — VVIP Curbside Car Delivery & Gems Economy** *(Completed)*
Add two-way moving VVIP luxury cars on GT Road, curbside bulk orders, solid car obstacle physics, cinematic camera pan, and Gems reward economy:
1. **Two-Way Moving Luxury Cars & Multiple Models**:
   - Cars spawn dynamically from either Left (East-bound) or Right (West-bound) on the exterior GT Road.
   - 3 distinct car models: Executive VIP Sedan, Heavy VIP SUV, and Classic Vintage Dhaba Cruiser.
   - 6 vibrant *Burger Please!* candy colors (Crimson Red, Sapphire Blue, Saffron Gold, Cyber Violet, Midnight Black, Emerald Green).
   - Smooth drive-in, curbside braking, and forward drive-away physics.
2. **Solid Physical Car Obstacle & Curbside Loading Zone**:
   - Parked car has solid collision bounds so player, staff, and customers cannot walk through it.
   - Dedicated Curbside Loading Trunk Zone on the sidewalk where player and helpers unload carried food.
3. **Massive Bulk Orders & 15s Per-Item Reset Patience**:
   - VVIP customers order large parties (25–40 items: mixed Chai & Parathas).
   - Generous 15s patience timer that completely resets to 0 every single time an item is loaded into the car.
   - Visual loading progress indicator on car roof (`XX / YY items loaded`).
4. **Cinematic 1.8s Camera Glance & Audio Polish**:
   - Smooth camera pan down to GT Road when VIP car pulls in, with top/bottom cinematic letterbox (`"⭐ VVIP ARRIVAL!"`), then smoothly glides back to player after 1.8s.
   - Authentic sound effects: VIP car horn `🚗 📯`, hydraulic brake screech `🚗 🛑`, and motorized sliding door slide `🚪 💨`.
5. **Gems Premium Currency Economy**:
   - Fulfilling VVIP bulk orders rewards **3 GEMS (💎)** + big cash tip + reputation XP boost.
   - Gems wallet counter displayed in the top HUD alongside Rupees.
6. **Testing & Natural Spawning**:
   - Left HUD debug button `[ 🚗 CALL VIP ]` for instant on-demand testing of car models, colors, and loading.
   - Natural automatic timer spawns a VVIP car every 3–4 minutes (180s–240s) during normal gameplay.
*Done when: Two-way cars arrive at the curb with horn/brakes and camera glance, player loads 30+ items at curbside with solid collision, and earns 3 Gems with full save persistence.*

### **Phase 2 (Milestones M11–M14) — Franchise Empire, Map, Settings & Store 2 Expansion**

### **M11 — Splash / Loading Screen & Main Menu Home Screen** *(Completed)*
Build the game's launch presentation and primary entry menu matching the dhaba cartoon art style:
1. **Animated Splash / Loading Screen**:
   - Uses the custom designed app icon (`assets/icon/app_icon_512.png`) centered with a warm golden glow.
   - Deep rich Chai-brown backdrop with stylized subtle pattern.
   - Smooth animated loading progress bar (0% to 100%) with randomized dhaba loading quotes.
   - Automatically initializes save state, sound services, and transitions seamlessly to Home Screen.
2. **Clean Minimalist Main Menu Home Screen**:
   - Bold 3D cartoon game title (*Dhaba Tycoon: Arcade Idle*) with app icon badge.
   - Centered clean layout: Big glowing **PLAY** button in the center, and directly below it the **MAP** button, lifted slightly to accommodate bottom banner ad.
   - Top-right settings shortcut button.
   - Completely removed store progression card and global currency headers (clean, uncluttered mobile arcade style).
   - **AdMob Banner Ad**: Anchored at the bottom (320x50 `AdSize.banner`) with 45s auto-refresh timer, background pause/resume lifecycle observer, and safe fallback.
   - **Per-Store Isolated Economy**: Both cash (₹) and gems (💎) are strictly stored and tracked per individual store so every store starts completely fresh!
*Done when: Launching the app shows the animated splash with custom icon & loading bar, transitions to the clean Home Screen with central Play and Map buttons, bottom banner ad with 45s refresh, and tapping Play starts the game arena.*

### **M12 — Settings Modal & Audio/Haptics Controls** *(Completed)*
Add fully functional Settings modal accessible from both the Home Screen and in-game HUD:
1. **Sound FX & Haptics Toggles with SharedPreferences Persistence**:
   - Sound FX toggle (Mute / Unmute) with live persistence.
   - Haptic Feedback toggle (Vibration On / Off) with tactile feedback.
2. **Legal & Compliance (# URLs for Vercel Deployment)**:
   - Privacy Policy, Terms of Use, and Help & Player Support linked to `#` via `lib/services/legal_links.dart`.
   - In-app interactive bottom sheets providing full disclosures and bullet summaries.
   - Standalone deployment-ready HTML files in `web_legal/`:
     - `web_legal/privacy-policy.html` (Google Play & AdMob compliant).
     - `web_legal/terms-of-service.html` (In-game virtual economy and gameplay license).
     - `web_legal/support.html` (FAQ and support email contact).
     - `web_legal/index.html` (Legal Hub landing page).
     - `web_legal/vercel.json` (Vercel clean routing configuration).
3. **Game Info & Danger Zone Reset**:
   - Version `v1.0.0 (Build 1)`, package identifier, and developer attribution.
   - Reset Game Progress button with double confirmation dialog to reset store to Level 1.
*Done when: Settings button opens modal on both Home Screen and HUD, toggles persist across game restarts, legal links show # modal sheets, and standalone HTML files are prepared in web_legal/.*

### **M13 — Interactive City Travel Map Screen** *(Pending)*
Add visual franchise travel map connecting Dhaba locations:
1. Visual route map displaying:
   - 📍 **Store 1: Highway Kadak Dhaba (GT Road)** — [Active / Mastered]
   - 📍 **Store 2: City Food Street (Karachi Burns Road / Lahore Anarkali Theme)** — Unlocks via Store 1 mastery or milestone!
   - 📍 **Store 3: Mega Mall Rooftop Bistro** — [Locked preview]
2. Store information card: completion stars, reputation percentage, store wallet, and "TRAVEL" button with car journey transition.
*Done when: Player can view city travel map, inspect stores, and travel between unlocked locations.*

### **M14 — Store 2 Expansion: City Food Street Dhaba** *(Pending)*
Build the second major dhaba location with multi-room layout and new food variety:
1. **Multi-Room *Burger Please!* Vibrant Aesthetic**:
   - **Kitchen Area**: Commercial tiled floor and stainless steel counters.
   - **Main Dining Hall**: Cozy terracotta/wood tiles, booths, pendant lamps.
   - **VIP Lounge**: Luxury red carpet, golden rope dividers, executive round tables.
2. **New Food Station**:
   - Authentic **Bun Kabab / Dhaba Burger Grill** cooking station + Chai Kettle.
3. **Per-Store Fresh Economy**:
   - Each store maintains its own independent store wallet (₹), individual Gems (💎), and equipment levels for a 100% fresh progression experience!
*Done when: Player can manage Store 2 with multi-room layout, cook bun kababs, serve urban customers, and earn store gems.*

---

## 7. Current Step

Phase 2 is underway! Milestone **M12 — Settings Modal & Audio/Haptics Controls** is completed and verified with 0 analyzer issues and all 158 tests passing. Next milestone: **M13 — Interactive City Travel Map Screen**.
