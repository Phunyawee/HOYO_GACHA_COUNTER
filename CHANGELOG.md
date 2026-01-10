# 📜 Changelog

All notable changes to this project will be documented in this file.
## [2.1.0] - 2025-12-25
### 🔄 Workflow & Menu Upgrades
- **Persistent Session Loop:** The script no longer exits after fetching data.
    - **Resume/Retry:** At the end of a run, simply press `ENTER` to check the same game again (perfect for updating history while playing).
    - **Menu Navigation:** Press `M` to return to the main game selection menu to switch games without restarting the script.
- **Legacy Compatibility:** Fully supports the existing `.bat` shortcuts. The script will auto-start the specified game on the first run, then fall back to the interactive menu loop.

### 🎨 Visual & Display Options
- **Display Mode Toggle (Press 'T'):** added a new toggle in the main menu to switch the history format:
    - **Date/Time Mode (Default):** Shows the full timestamp (e.g., `2025-12-24 23:56:04`).
    - **Sequence Mode (No.):** Shows the pull count order (e.g., `[No. 45]`) for cleaner tracking.
- **Synchronized Discord Report:** The Discord embed now respects the selected Display Mode. If "No." mode is active, the Discord report will also list items by number instead of date.
- **Full Timestamp Fix:** Fixed an issue where Discord timestamps were truncating the time. Now displays the full date and time (Seconds included).

### 🐛 Bug Fixes & Stability
- **API Rate Limiting Fix:** Re-tuned the `Start-Sleep` delay (600ms) between pages to strictly prevent the "Visit too frequently" error from Hoyoverse servers.
- **Variable Scope Fix:** Fixed a bug where toggled settings (like Display Mode) would reset after the first loop.

## [2.0.0] - 2025-12-12
### 🌟 Universal Update (Major Overhaul)
- 🏗️ **Unified Architecture:**
    - Consolidated all game logic (Genshin, HSR, ZZZ) into a single core script: `HoyoWish.ps1`.
    - Introduced lightweight `.bat` launchers (`Run_Genshin`, `Run_HSR`, `Run_ZZZ`) for easy access.
- 🎮 **Universal Logic Improvements:**
    - **Honkai: Star Rail:** Fixed AuthKey extraction regex to handle hybrid URL formats and updated API host to `public-operation-hkrpg`.
    - **Zenless Zone Zero:** Integrated "Brute Force" link scanning and "Real Gacha Type" override into the universal core.
    - **Genshin Impact:** Ported existing logic to the new universal structure.

### ✨ New Features
- 💬 **Enhanced Discord Integration:**
    - **Universal Webhook:** One `config.json` handles reports for all 3 games.
    - **Smart Timestamp:** Automatically switches between "Full Date" and "Short Date" formats based on message length to prevent Discord API errors (4096 char limit).
    - **Visual Upgrades:** Added game-specific thumbnails, theme colors, and clean text-based emoji indicators (🟢/🔴).
- 🔢 **Dynamic Menu System:**
    - Added interactive menu to fetch specific banners based on the selected game.
    - Added **"0 : FETCH ALL"** option (default) for one-click convenience.
- 🛠️ **Quality of Life:**
    - **Auto-Discovery:** Automatically builds banner lists based on the game profile.
    - **Safety Delays:** Added intelligent sleep timers (0.5s - 1s) to prevent API "Visit too frequently" errors.

## [1.1.0] - 2025-12-10
### Added
- 🐻 **Zenless Zone Zero (ZZZ) Support:**
    - Added **Brute Force Extractor**: Automatically scans corrupt/mixed `data_2` files to find the working AuthKey.
    - Added **Param Override Logic**: Fixes the API conflict where ZZZ servers lock the key to a specific banner type.
    - Added **Select Mode**: New interactive menu to fetch specific banners (Standard, Bangboo, Character, Weapon).
    - Added **Bangboo Channel** support.
- 🔧 **Core Improvements:**
    - Implemented `[decimal]` sorting to fix ZZZ's unstable ID timestamp ordering.
    - Added API delay warning (1 hour) for ZZZ users.

## [1.0.0] - 2025-12-09
### Added
- 🚀 Initial Release
- 📂 Genshin Impact support (Extractor & Pity Counter)
- 📂 Honkai: Star Rail support (Extractor & Pity Counter)
- 📄 Comprehensive Documentation (English/Thai)
