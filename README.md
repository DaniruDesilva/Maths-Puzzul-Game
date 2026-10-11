# Word Haven: Cozy Village 🌾✨

> **Swipe letters, solve word puzzles, and build your relaxing cozy woodland village!**

---

## 📖 Overview

**Word Haven: Cozy Village** is a relaxing hybrid mobile game built with **Flutter** and the **Flame 2D Game Engine**. It combines tactile hexagonal word search mechanics with a cozy, idle woodland village builder.

- **Genre:** Word Puzzle × Cozy Simulation / Town Builder
- **Target Audience:** Fans of *Wordscapes*, *Township*, and *Animal Crossing*
- **Platforms:** Android, iOS, Windows, macOS, Linux, Web

---

## 🌟 Key Features

### 🧩 1. Hexagonal Word Connect Engine
- **Tactile 6-Direction Swipes:** Fluid trace gestures connecting adjacent hexagonal tiles.
- **280 Handcrafted Procedural Levels:** 7 unique biomes with guaranteed zero repeated words across the entire campaign.
- **Strict Anti-Conflict DFS Placement:** Guarantees that every target word has exactly one unique solution path on the board.
- **Full 168k Word Dictionary Engine:** Background isolate dictionary parser validates secret bonus words.
- **The Bonus Jar:** Discover hidden bonus words to earn extra coins and fill the jar for free hints!

### 🏡 2. Oakheart Village Simulation (Flame Engine)
- **Cozy Isometric World:** Interactive 2D island map with smooth pan, zoom, and dynamic camera bounds.
- **5 Upgradable Buildings:** Construct and upgrade the Cottage, Bakery, Windmill, Library, and Tower through 3 distinct stages.
- **Autonomous Animal Villagers:** Meet Bramble the Bunny, Fern the Fox, and Professor Hoot—featuring unique physics-based locomotion (hop, trot, and waddle), waypoint navigation, and interactive dialogue.
- **Idle Timers & Rewards:** Buildings generate coins, regular hints, and mega hints on real-time timers with interactive bobbing collection bubbles.
- **Visual VFX:** Rotating windmill blades, animated chimney smoke particles, and confetti spell build celebrations!

### 📅 3. Daily Challenges & Custom Puzzles
- **Deterministic Daily Challenges:** A fresh puzzle generated every calendar day with milestone rewards (14-day and 30-day streak bonuses).
- **Custom Puzzle Creator:** Design puzzles with custom words and share them with friends via encoded share links.

---

## 📱 Storefront Metadata Package

- **App Title (30-char limit):** `Word Haven: Cozy Village` (25 chars)
- **Short Description (80-char limit):** `Swipe letters, solve word puzzles, and build your relaxing cozy woodland village!` (79 chars)
- **Target Keywords:** `word puzzle, cozy game, hex word connect, offline word games, village builder, brain puzzle, relaxing puzzle, daily challenge`

---

## 🛠️ Architecture & Tech Stack

- **UI Framework:** Flutter 3.13+ (Material 3 with custom rustic wood/parchment styling)
- **Game Engine:** Flame 1.38+ (Component-based architecture)
- **State Management:** Provider (`UserProvider`, `GameProvider`)
- **Persistence:** SQLite (`sqflite` v5) + `SharedPreferences` mirror fallback
- **Audio:** `audioplayers` with a 5-player low-latency pool & procedurally generated audio waves
- **Notifications:** `flutter_local_notifications` with timezone-scheduled daily reminders

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.13.3` or newer
- Dart SDK `^3.13.3`

### Run Locally
```bash
# Get dependencies
flutter pub get

# Run on your connected device
flutter run
```

### Run Tests
```bash
# Execute the comprehensive test suite
flutter test
```
