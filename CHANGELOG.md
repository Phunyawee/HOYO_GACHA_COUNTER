# 📜 Changelog

All notable changes to this project will be documented in this file.
## [3.0.0] - 2026-01-11
### 🚀 Major Overhaul: GUI Edition
- **New Graphical User Interface (GUI):**
    - Transitioned from the legacy Console/Terminal window to a full **Windows Forms Application**.
    - **Interactive Dashboard:** Switch between games (Genshin, HSR, ZZZ) instantly with top-bar tabs without restarting the script.
    - **Real-time Log:** Added a color-coded scrolling log window to visualize the fetching process and Pity results clearly.
- **Architecture Restructuring:**
    - Split the monolithic script into two modular components:
        - `App.ps1`: Handles the UI, event listeners, and user interaction.
        - `HoyoEngine.ps1`: A dedicated library for API fetching, logic parsing, and Discord handling.
    - **Launcher Update:** Replaced individual game launchers (`Run_Genshin.bat`, etc.) with a single universal **`Start_GUI.bat`**.

### ✨ New Features
- **🔍 Smart Auto-Detect System:**
    - Added an **"Auto-Detect"** button that intelligently scans system drives to locate the elusive `data_2` cache file automatically.
    - Eliminates the need for manual drag-and-drop in most standard installations.
- **📊 CSV Export Support:**
    - Added **"Export History to CSV"** function. Users can now save their entire wish history to an Excel-compatible file (`.csv`) for offline backup or analysis.
    - *Note:* The export button unlocks automatically after a successful fetch.
- **🛑 Control & Safety:**
    - Added a **STOP Button**: Users can now safely halt the fetching process mid-way without crashing the script or freezing the window.
    - **Status Indicators:** Buttons change colors (Green/Red/Gray) to indicate active states (Running, Stopped, or Idle).

### 🐛 Improvements & Fixes
- **ZZZ Optimization:** Standardized the `real_gacha_type` parameter logic within `HoyoEngine` to ensure 100% compatibility with Zenless Zone Zero's API quirks.
- **Error Handling:** Improved "AuthKey Expired" detection. The GUI now prompts a clear MessageBox instructing the user to refresh the game history, instead of just printing a console error.
- **Config Flexibility:** The program now gracefully handles missing `config.json` files by simply disabling the Discord checkbox visually, rather than throwing script errors.

## [2.1.1] - 2026-01-11
### 🎨 Visual & Assets Fixes
- **GitHub Hosted Assets:** Changed the source of Discord Bot Icons (Paimon, Pom-Pom, Bangboo) to use **GitHub Raw Links** (`raw.githubusercontent.com`).
    - This fixes the issue where bot avatars would revert to the default Discord logo due to hotlinking protection or expired URLs.
    - Icons are now permanently hosted within the repository for 100% uptime reliability.
- **Link Logic Update:** Updated `HoyoWish.ps1` to dynamically construct image URLs based on the `main` branch, ensuring users always see the latest assets without needing script updates.

### 🐛 Bug Fixes
- Fixed a syntax error in the image URL path construction.
- Minor adjustments to the `Start-Sleep` timing for better stability during sequential fetches.

## [2.1.0] - 2026-01-11
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
