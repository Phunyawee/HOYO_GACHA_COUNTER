# 📜 Changelog

All notable changes to this project will be documented in this file.

## [4.1.0] - 2026-01-14
### ✨ The "Visual Analytics" Update

### 📊 Deep Analytics & Visualization
#### Advanced Charting Options
- Added a **Chart Type Selector** to the analytics panel.
- Users can now switch visualization modes dynamically:
  - **Column / Bar:** Classic view for Pity distribution.
  - **Line / Spline:** Best for viewing trends over time.
  - **Drop Rate Analysis:** A new **Doughnut Chart** mode visualizing the ratio of 5★, 4★, and 3★ pulls with detailed percentages.
#### Luck Grading System (Tier List)
- Introduced a **Luck Grade Evaluation** in the stats dashboard.
- Automatically assigns a rank (**SS, A, B, C, F**) based on your global average Pity.
- Includes a tooltip explaining the grading criteria (e.g., Avg < 50 = SS).
#### 50/50 Win/Loss Indicators
- Implemented **Standard Banner Logic** detection for Genshin, HSR, and ZZZ.
- The text log now visually highlights character names in **Crimson (Red)** if they are "Standard" characters pulled on an Event Banner (indicating a **50/50 Loss**).

### 💾 Social Sharing & Flexing
#### Smart Image Export
- Added a **Save IMG** button to the chart panel.
- Captures the current graph state (works for both Pity and Rate Analysis charts).
- Generates a high-quality **PNG/JPG** with a professional footer.
#### Professional Watermark System
- Automatically appends a non-intrusive **Footer Strip** containing:
  - **Player Name & UID** (Customizable input).
  - **App Branding** and Generation Date.
- Features **Smart Text Truncation**: Automatically shortens long player names to ensure they never overlap with the UID or branding.
#### Live Preview Workflow
- Implemented a **"Preview Before Save"** window.
- Users can review the generated image with the watermark before writing to disk.
- Includes a **"< Back to Edit"** button that preserves previous inputs, allowing for quick corrections without re-typing.

### 🛠️ UX & Technical Polish
#### Credits & About Screen
- Added a **Help > About & Credits** menu.
- Features a stylized, center-aligned animation in the main log window (Hacker/Matrix style).
#### Enhanced Debugging & Logging
- Refactored the internal logging engine.
- Setting `$DebugMode = $true` now provides detailed, timestamped console logs for user actions (e.g., changing chart types, expanding panels, saving images).
#### 📂 Project Structure
- **Reorganization:** Restructured the project directory by moving specific internal folders into dedicated subdirectories.
- This cleanup improves the root folder organization without affecting the script's functionality.
#### Bug Fixes
- **Fixed:** Chart data sorting now correctly mirrors the "Newest/Oldest" filter checkbox.
- **Fixed:** Pie Chart (Doughnut) percentage labels now correctly display counts and formatted percentages.
- **Optimized:** Improved the `Update-Chart` logic to cache data, preventing "No Data" errors when switching chart types.
- **Refactored:** Centralized logic via `Reset-LogWindow` helper to prevent style conflicts when switching between Credits and Fetch views.

## [4.0.0] - 2026-01-13  
### ✨ The "Time Machine" Update
### 🚀 Major Features
#### SRS Auto-Detection (Smart Path Finding)
- Implemented intelligent log parsing logic inspired by **Star Rail Station (SRS)**.
- Automatically scans game logs (`output_log.txt` / `Player.log`) to detect:
  - Exact game installation path  
  - Cache location
- Resolves issues for users with **custom install directories**, especially for:
  - Zenless Zone Zero (ZZZ)
  - Honkai: Star Rail (HSR)
#### Time Machine (Scope & Filter Analysis)
- Added an advanced **Filter Panel** that appears after data is fetched.
- Users can now filter wish history by **specific date ranges**.
- **True Pity Calculation**:
  - Even when filtering a limited date range, the engine backtracks through the full history.
  - Ensures Pity counters remain **accurate and consistent with in-game state**.
#### Interactive Analytics Graph
- Introduced a responsive **Side Panel** with a dynamic column chart.
- Visualizes **5★ pull history** with color-coded luck indicators:
  - 🟢 Green — Early pull  
  - 🟡 Gold — Soft pity  
  - 🔴 Red — Hard pity
- Added `>> Show Graph` toggle in the Menu Bar to expand or collapse the chart.
- Supports **real-time updates** when filters are adjusted.
### 🛠️ UX & Quality of Life
#### Smart Snap Reset
- Added a **[SNAP] Find Reset** button.
- Automatically finds the nearest past 5★ pull and:
  - Snaps the **From** date to the next pull (Pity = 0)
- Makes analyzing the **current banner cycle** effortless.
#### Manual Discord Reporting
- Added a dedicated **Discord Report** button inside the Filter Panel.
- Allows sending **targeted reports** (e.g. “My pulls this month”).
- Maintains correct **True Pity** values even for partial datasets.
- Includes a **Sort Order** option:
  - Newest First
  - Oldest First
- Controls how data is displayed in the Discord embed.
#### UI Refinements
- Reorganized the Filter Panel into a clean **two-row layout** with grouped controls.
- Removed emojis from critical UI elements to ensure:
  - Full compatibility across all Windows versions
  - Consistent rendering across system locales
- Integrated the graph toggle directly into the **Top Menu Bar**.
### 🐛 Bug Fixes & Optimizations
- **Fixed:** Export CSV now respects the active filter and exports only visible data.
- **Fixed:** Discord report sorting issue where manual reports could appear in reverse order.
- **Optimized:** Reworked the Pity calculation engine:
  - Display Logic: Newest → Oldest
  - Calculation Logic: Oldest → Newest
- Prevents calculation errors during complex filtering and time-based analysis.



## [3.1.2] - 2026-01-12
### 🎨 Visual Overhaul (Modern UI)
- **Flat Design System:**
    - Updated all controls to match the Windows 10/11 aesthetic using Segoe UI fonts and borderless inputs.
    - Added Interactive Hover Effects to buttons: colors now brighten dynamically, and the cursor transforms into a hand pointer (Cursors.Hand), providing a responsive, web-like feel.
- **Cinematic Splash Screen:**
    - Introduced a professional Loading Sequence on startup.
    - Displays a custom splash.png (if available) with a synchronized progress bar animation while the core engine loads in the background.
    - Gracefully transitions to the main application once initialization is complete.
### 🛠️ UX Improvements
- **Console-Style Logging:**
    - Restored the Fixed-Border look for the log window but switched to a pure black background with green text, mimicking a classic terminal/CMD interface.
- **Global Font Management:**
    - Refactored font definitions into Global Variables  `($fontNormal, $fontHeader, $fontLog)`, making future theme adjustments instant and consistent across the entire app.
- **Start Button Consistency:**
    - Reverted the "START FETCHING" button to its original high-contrast Forest Green style for better visibility, while retaining the new hover mechanics.



## [3.1.1] - 2026-01-12
### 🔧 System & Maintenance
- **Developer Debug Mode:**
    - Introduced a configuration toggle ($script:DebugMode) at the top of App.ps1.
    - When enabled ($true), the script mirrors all GUI logs to the background PowerShell console,       allowing for real-time troubleshooting even if the UI freezes.
    - Smart Color Translation: Automatically converts GUI-specific colors (e.g., Lime, Gold) into compatible Console colors (Green, Yellow) for readable text in the black window.
- **Enhanced Reset Feedback:**
    - The Reset / Clear All function now explicitly logs the action ("User requested RESET" ... "System Reset Complete").
    - In Debug Mode, this preserves the reset history in the console log even after the GUI wipes the visual data.

## [3.1.0] - 2026-01-11
### 🎨 Visual & UI Updates
- **Luck Analysis Dashboard (New):**
    - Added a dedicated stats panel showing **Total Pulls**, **Average Pity**, and **Estimated Cost** (in Primogems/Jades).
    - **Dynamic Coloring:** The "Avg. Pity" text changes color based on your luck (Lime=Lucky, Gold=Average, Red=Salty).
- **Visual Pity Meter:**
    - Introduced a progress bar that visualizes your current pity status towards the 90-pull hard pity.
    - Includes a **"Current Pity"** counter positioned clearly above the gauge.
- **Menu Bar Integration:**
    - Added `File > Reset / Clear All` (F5) to instantly wipe data, reset stats, and clear logs without restarting the app.

### ⚙️ Core Logic Upgrades
- **"Trinity" Auto-Detect Logic:**
    - Implemented a robust hybrid detection system handling all 3 games uniquely:
        - **Genshin Impact:** Uses Legacy Regex parsing on `output_log.txt`.
        - **Zenless Zone Zero:** Uses specific `[Subsystems]` parsing on `Player.log`.
        - **Honkai: Star Rail:** Uses standard SRS logic on `Player.log`.
- **Universal Drive Support:**
    - Now correctly locates game installations on **ANY drive** (C:, D:, M:, Network Drives) by reading the official logs.
- **Recursive Cache Search:**
    - Replaced version-number guessing with a **Recursive Sort-by-Date** method. This ensures the script always grabs the latest `data_2` file, regardless of folder structure changes or ZZZ's version padding.

### 🐛 Bug Fixes
- **Console Cleanliness:** Suppressed output noise (e.g., `0`, `1` list indexes) in the background console.
- **Path Handling:** Fixed "Illegal Path Form" errors when copying files to custom staging directories.

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
