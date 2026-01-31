# 📜 Changelog

All notable changes to this project will be documented in this file.
## [7.4.1] - 2026-02-01
### 🔄 Feature: Hot-Swap Configuration Restore & State Sync

This update rewrites the backend logic of the **Data & Maintenance** module to support true hot-swap configuration restoration.  
Application restarts are no longer required—restored configurations are injected directly into memory and synchronized across disk, runtime state, and the active UI.
The system now keeps the physical **JSON file**, **global runtime variables**, and the **User Interface** perfectly in sync at all times.

### ❌ Before
- **Static File Overwrite**  
  Backup restores only replaced the physical `config.json` file on disk, leaving in-memory configuration unchanged
- **UI State Desynchronization**  
  UI controls (TextBoxes, Toggles, Sliders) continued displaying stale values after restore
- **Data Integrity Risk**  
  Clicking **"APPLY SETTINGS"** after a restore overwrote restored data with outdated UI state
- **Forced Restarts**  
  Users had to manually restart the application (`Start-Process`) or close and reopen the window to apply changes

### ✅ After
- **Live Memory Injection**  
  Restored JSON data is immediately mapped into `$script:AppConfig` and recursively propagated to all active UI controls in real time
- **Instant Theme Application**  
  The rendering engine (`Apply-Theme`) is triggered on restore, updating accent colors and opacity without delay
- **Unified Logic Architecture**  
  Input-mapping logic has been shared between **Save** and **Restore** modules, ensuring 1:1 consistency between disk state and UI state
- **Seamless UX**  
  Zero friction—no restarts, no window reloads, and no additional **Apply** actions required after restoration



## [7.4.0] - 2026-01-31
### 🎨 Feature: Vertical Navigation & UI Modernization

This major update modernizes the **Preferences & Settings** interface by replacing the legacy top-tab layout with a clean **Vertical Navigation Sidebar**.  
A custom **GDI+ rendering engine** has been introduced to improve typography clarity and eliminate long-standing layout clipping issues in complex configuration views.

### ❌ Before

- **Legacy Top-Tab Layout**  
  Limited scalability and outdated visual structure
- **Z-Order Conflicts**  
  The **"APPLY SETTINGS"** button was frequently obscured by expanding tab containers (`Dock=Fill`)
- **GDI+ Rendering Crashes**  
  `System.ArgumentException` triggered by invalid `Rectangle` → `PointF` casting during custom draw operations
- **Layout Clipping Issues**  
  The **"Show Password"** button in the Integrations tab exceeded container bounds and became unclickable
- **Vertical Text Rotation**  
  Left-aligned native tabs forced 90° text rotation, reducing readability

### ✅ After
- **Vertical Sidebar Navigation**  
  Fixed-width left sidebar using custom `OwnerDrawFixed` logic with horizontal text rendering
- **Dedicated Footer Dock**  
  Bottom-docked action panel with `BringToFront()` logic, ensuring **Save / Reset** buttons remain visible and anchored
- **Type-Safe Rendering**  
  Resolved GDI+ casting errors by explicitly using `System.Drawing.RectangleF` for text bounds
- **Optimized UI Density**  
  Refactored SMTP / Integrations layouts to fit all controls within 500px width constraints
- **Enhanced Typography**  
  Enforced **bold font weights** across navigation elements to improve hierarchy and readability



## [7.3.6] - 2026-01-31
### 🐛 Patch: Settings Persistence & Event Scope Resolution

This release focuses on stabilizing settings persistence by resolving a variable scope issue within the Appearance settings workflow.  
The update eliminates silent execution failures and ensures all UI-driven preference changes are correctly propagated and saved.

#### ❌ Before
- Changes made in the **Appearance** tab (Theme, Color, Opacity) were not persisted to the global configuration
- Event handlers relied on **detached ScriptBlocks**, causing variable scope leakage
- UI updates appeared successful, but configuration state was not updated
- Failures occurred silently with no visible errors

#### ✅ After
- Event listeners refactored to use **embedded logic**
- Enforced **script-level scope (`$script:`)** across all dynamic UI controls
- UI state changes now propagate correctly to global settings in real time
- Appearance preferences:
  - Apply instantly
  - Persist reliably
  - Remain consistent after restart



## [7.3.5] - 2026-01-30
### 🧹 Patch: Help Menu Standardization & Architectural Unity
Version **7.3.5** extends the **Modular Orchestration Pattern** to the **Help Menu**, bringing it in line with the recently refactored Tools architecture.

This update focuses on **codebase consistency**, ensuring that all major menu components (`Tools`, `Help`) now operate under the same logic-loading standard. This structure minimizes technical debt and makes future UI expansions significantly cleaner.

### 🛠️ Key Changes

- **Help Menu Orchestrator**
  - Refactored `02_HELP.ps1` to function purely as a component loader, mirroring the logic of the Tools menu.
  - Ensures a uniform loading experience across the application's top navigation bar.

- **Component Decoupling**
  - Extracted UI logic into dedicated sub-modules within the `02_HELP/` directory:
    - `01_AboutCredits.ps1` (About Window & Credits)
    - `02_CheckUpdate.ps1` (Version Control & GitHub Link)

- **Standardized Scope Management**
  - Applied strict dot-sourcing rules to ensure the Help sub-modules inherit necessary UI styles and global variables (`$script:AppVersion`, `$script:EngineVersion`) without polluting the main scope.



## [7.3.4] - 2026-01-30
### 🧩 Patch: Modular Tools Architecture & Dynamic Orchestration
Version **7.3.4** introduces a significant architectural refactor of the **Tools Menu**, transitioning from a monolithic script to a **Modular Orchestration Pattern**.

The `03_TOOLS.ps1` file has been reimagined as a lightweight **"Orchestrator"**, responsible solely for sequencing and loading sub-components. This change eliminates massive code blocks, improves readability, and allows for "Plug-and-Play" feature management.

### 🛠️ Key Changes

- **Tools Menu Orchestrator**
  - Transformed `03_TOOLS.ps1` into a dynamic component loader.
  - Features are now defined in a simplified **Ordered Array**, allowing for effortless menu reordering and visual separator (`-SEPARATOR-`) insertion without modifying core logic.

- **Sub-Module Atomization**
  - Deconstructed the legacy Tools script into five discrete, maintainable modules located in the `03_TOOLS/` directory:
    - `01_WishForecast.ps1` (Simulator Logic)
    - `02_HistoryTable.ps1` (Data Grid Viewer)
    - `03_JsonExport.ps1` (Raw Data Export)
    - `04_JsonImport.ps1` (Offline Mode & Import)
    - `05_SavingsPlanner.ps1` (Resource Calculator)

- **Scope-Aware Loading**
  - Implemented robust dot-sourcing logic to ensure sub-modules retain full access to the global UI context (`$menuTools`, `$script:CurrentGame`) while keeping the file structure strictly isolated.



## [7.3.3] - 2026-01-27
### 📜 Patch: Logging Architecture & Source Tracing
Version **7.3.3** introduces a major overhaul of the internal logging mechanism by fully decoupling the **GUI Logger** from the core **File Logger**.  
Critical logging components have been relocated into a centralized **Tools** directory to eliminate circular dependencies and resolve previous *double-wrapping* issues.

This release also adds **precise Source Identification**, making it immediately clear whether a log entry originates from a user action (`[App]`) or a background process (`[System]`).

### 🛠️ Key Changes

- **Decoupled Logging Core**  
  - Extracted `WriteGUI-Log` into `Tools/LogGenerator.ps1`  
  - Migrated backend file writing logic into `Tools/LogFileGenerator.ps1`  
  - Improves dependency clarity and long-term maintainability

- **Smart Source Tracing**  
  - Implemented logic to prevent log duplication  
  - User-triggered actions are automatically tagged as `[App]`  
  - Background and automated processes default to `[System]`

- **Loader Optimization**  
  - Updated `SystemLoader.ps1` to load logging tools **before** UI components  
  - Ensures no log events are missed during application startup



# [7.3.2] - 2026-01-26
🏗️ **Patch: Modular Architecture & UI Polish**
Version **7.3.2** brings a significant architectural cleanup to the **Email Settings** module. We've transitioned from a monolithic script to a clean, modular design (`Loader` → `Logic` → `UI`), improving code maintainability without sacrificing features.
This update also fine-tunes the **Live Preview** engine, ensuring that the chart visualizations (Gradients, Legends, and Color coding) match the actual output perfectly.

### 🛠️ Key Changes
*   **Refactored Email Tab:** Split `07_TabEmail.ps1` into dedicated sub-modules (`Config`, `Styles`, `UI`) for better separation of concerns.
*   **Visual Fidelity Restored:** Fixed an issue where the Chart Preview lost its gradient styling and legend details during the optimization process.
*   **Code Optimization:** Reduced script complexity and improved safe-loading mechanisms for child components.



# [7.3.1] - 2026-01-26
🐛 **Patch: Logic Precision & Report Synchronization**
Version **7.3.1** focuses on the accuracy of your data. We've overhauled the filtering engine to ensure that what you see on screen is exactly what gets delivered to Discord and Email.
This update fixes sorting discrepancies and ensures Index numbering `[No.]` correctly reflects your sorting preference (Newest vs. Oldest).

## 🛠️ Fixes & Improvements

### 🧮 Smart Sorting & Indexing
- **Correct Index Calculation**  
  The `[No. X]` indicator in reports now intelligently adapts to your sort order.
  - *Newest First:* Counts down from Max (e.g., No. 50, 49, 48...).
  - *Oldest First:* Counts up from 1 (e.g., No. 1, 2, 3...).
- **Decimal ID Sorting**  
  Fixed a potential bug where IDs were sorted as text (causing 10 to appear before 2). The engine now forces Decimal sorting for 100% accuracy.

### 📨 Report Synchronization
- **Email & Discord Parity**  
  Both Discord and Email reports now strictly obey your **"View Mode"** (Time vs. No.) and **"Sort Order"** checkboxes.
- **View Mode Fix**  
  Fixed an issue where the Email report ignored the "View: Index [No.]" toggle and always showed Timestamps.

# [7.3.0] - 2026-01-26
🎨 **Patch: Visual Analytics & Email Reporting**
Version **7.3.0** delivers a major upgrade to how you visualize and share your gacha history.  
This release introduces a brand-new **Email Manager**, a fully rewritten **Charting Engine**, and improved game name mapping for more professional reporting.

## ✨ New Features

### 📧 Email Reporting System
- **Automated Reports**  
  Send your gacha history directly to your email with a single click.

- **Theme Support**  
  Choose from three distinct presentation styles:
  - 🃏 **Premium Card** – Modern dark-themed card design with gradient headers  
  - 📟 **Terminal Mode** – Hacker-style neon green text on a black background  
  - 📝 **Classic Table** – Clean, professional white-paper layout

- **Smart Subject Lines**  
  Internal game codes are now automatically mapped to full titles  
  (e.g. `HSR` → **[Honkai: Star Rail]**) for polished email headers.

## 📊 Charting Engine Overhaul

### 🎯 Pro-Grade Visualization
- **Rate Analysis**
  - Replaced legacy Pie Charts with modern **Doughnut Charts**
  - Added **Outside Labels** to prevent overlap
  - 3-Star item labels are now hidden for better clarity

- **Pity Coloring Logic**
  Bars and data points dynamically change color based on luck:
  - 🟢 **Lime Green** — Early Pity (`< 50`)
  - 🟡 **Gold** — Soft Pity (`50–74`)
  - 🔴 **Crimson** — Hard Pity (`75+`)

### 🔁 Data Sorting Fixes
- Fixed a critical logic error where Line Graphs rendered backwards
- History data is now correctly sorted:
  **Oldest → Newest (Left → Right)**  
  for accurate progression tracking

### 🏷️ Labeling Improvements
- X-Axis now uses:
  - `Interval = 1`
  - `-45°` text rotation  
- Character names are always readable, even with dense history data

## 💾 Export & Utilities

### 🖼️ Advanced Image Saving
- **Watermark Editor**  
  Add your **Player Name** and **UID** directly onto exported chart images
- **Native Dark Mode Export**  
  Generated images now use a seamless dark background (`#1E1E1E`), perfectly matching the app’s UI

## 🐛 Bug Fixes
- **Outlook / Gmail Rendering**  
  Fixed white background issues by moving CSS styles inline into the `<body>` tag
- **Assembly Loading Safety**  
  Added validation to ensure  
  `.NET System.Windows.Forms.DataVisualization`  
  is fully loaded before generating reports



# [7.2.2] - 2026-01-25
🚀 Patch: Startup Synchronization & Debugging
Version 7.2.2 focuses on application stability during the launch sequence. We've resolved a persistent race condition that caused the UI to desync from your saved configuration, alongside a new low-level tracing system for easier troubleshooting.

### 🐛 Bug Fixes
- **Startup State Persistence:**
  - Fixed an issue where the application would always default to **Genshin Impact** upon launch, ignoring the `LastGame` setting in `config.json`.
  - **Technical:** Moved the initial game-switching logic to the Form's `Shown` event. This ensures all UI components and Event Listeners are fully loaded before applying the user's preferences.
- **ZZZ Table Highlighting:**
  - Adjusted the color logic in the **History Table Viewer** to correctly recognize Zenless Zone Zero's rank system (where S-Rank is internal value 4, and A-Rank is 3).

### 🛠️ System Improvements
- **Boot Trace Logging:**
  - Introduced a new `boot_trace.txt` logging mechanism.
  - Captures low-level initialization steps *before* the GUI loads, making it significantly easier to diagnose "Crash on Startup" issues or freezing events.
- **Performance:** Removed redundant data loading calls during the game-switching process, resulting in a snappier response when clicking game icons.



## [7.2.1] — 2026-01-25  
📂 **Patch: File Management & Stability**

Version **7.2.1** refines how the application handles file operations, ensuring a cleaner project structure and smarter background processes.  
We've reorganized where temporary files and exports land to keep your workspace tidy.

### 🛠️ Improvements

#### 🧠 Smarter Cache Staging
- The **Find-GameCacheFile engine** now safely creates a dedicated `temp_data` directory.
- Prevents `data_2` files from cluttering the root directory.
- Avoids relative path issues during the staging process.

#### 📑 Organized CSV Exports
- Exported **Wish History** files now land in a dedicated `\export` folder at the project root.
- The system automatically:
  - Detects the root path (stepping back from `controllers`)
  - Creates the folder if it doesn’t exist

#### 🔐 Backup Logic Refinement
- **Toggle Respect**  
  - Auto-backup now strictly follows the `EnableAutoBackup` config  
  - Backup logic is skipped entirely when disabled
- **Null Safety**  
  - Added validation to ensure actual data exists before saving  
  - Prevents creation of empty backup files when fetch fails



# [7.2.0] - 2026-01-25
📧 Major Update: Email Reporting System
Version 7.2.0 expands the application's connectivity by introducing a full-featured **Email Reporting Engine**. You can now receive detailed HTML-formatted gacha reports directly to your inbox. We also unified the sorting logic to ensure Discord and Email reports perfectly match what you see on screen.

### ✨ New Features
- **Email Reporting Module:**
  - Added "Email Report" button in the Scope & Analysis panel.
  - Generates beautiful **HTML Tables** with Gold highlighting for 5-star items.
  - Supports **Auto-Send** upon data fetch completion.
- **SMTP Configuration UI:**
  - New "SMTP Sender Config" section in **Settings > Integrations**.
  - Supports custom Host, Port, and Secure Password (TLS/SSL).
- **Unified Data Logic:**
  - Created `Get-FilteredScopeData` to centralize filter & sort logic.
  - **Result:** Discord, Email, and UI now share the exact same data order (no more reverse list bugs!).

### 🛠 Fixes & Improvements
- **Fixed:** Discord report was showing history in reverse order (Oldest first). It now correctly respects the "Newest First" checkbox.
- **Fixed:** Configuration saving mechanism now correctly writes new keys (SMTP) to `config.json` without data loss.
- **Changed:** Refined Filter Panel UI to accommodate the new Email button without overcrowding.

### 📖 GUIDE: How to Setup Email (SMTP)
Since we don't use a central server, you must use your own email to send reports.
Go to **Settings > Tab 3: Integrations** and fill in the following:

#### 1. Receiver Info
- **Receiver Email:** The email address where you want to READ the reports (e.g., `my_personal@gmail.com`).

#### 2. SMTP Sender Config (The Bot)
This is the email account that will act as the "Sender".
*(Recommended: Use a secondary Gmail account)*

- **SMTP Host:** `smtp.gmail.com` (for Gmail) or `smtp.live.com` (for Outlook).
- **Port:** `587` (Standard for TLS).
- **Sender Email:** The full email address of your bot/secondary account.
- **App Password:** **[IMPORTANT]** Do NOT use your normal login password!
  - **For Gmail Users:**
    1. Go to Google Account > Security.
    2. Enable "2-Step Verification".
    3. Search for **"App Passwords"**.
    4. Create a new one named "HoyoEngine".
    5. Copy the 16-character code (e.g., `xxxx xxxx xxxx xxxx`) and paste it here.

*Note: Your password is saved locally in `config.json` and is never shared with anyone.*



# [7.1.0] - 2026-01-24
🚀 Highlights
Version 7.1.0 introduces the **Advanced Configuration** module. We have added a dedicated "Power User" interface allowing direct manipulation of the core configuration via a raw JSON editor. This update features a **Hot Reload** engine, enabling real-time visual updates (Theme & Opacity) immediately after saving, without the need to restart the application.

### ✨ Added
- **New "Advanced" Tab:** A dedicated section in Settings for direct configuration management.
- **Raw JSON Editor:**
  - **Hacker-Style UI:** Implemented a high-contrast coding environment (Lime Green text on Dark background) using Consolas font.
  - **Live Syntax Editing:** Edit your configuration structure directly.
- **Hot Reload System:**
  - **"SAVE & APPLY" Button:** Instantly saves `config.json` and updates the application's global state.
  - **Real-time UI Update:** Theme colors and opacity settings apply immediately upon save.
- **Safety & Utilities:**
  - **JSON Validation:** Automatic syntax checking prevents saving corrupted configuration files.
  - **Revert Changes:** A quick "Undo" button to reload the last saved config if you make a mistake.
  - **Open Folder:** Shortcut button to directly access the `Settings` directory.



# [7.0.0] - 2026-01-24

## 🌟 Highlights
Version 7.0.0 marks the **"Architectural Rebirth"** of the project. We have performed a complete code rewrite, transitioning from a monolithic script to a fully **Modular Architecture**. This structure ensures better performance, easier maintenance, and prepares the application for advanced features in the future.

---

## ⚠️ Breaking Changes & Deprecation

### 🛑 Legacy GUI Discontinued
*   **`GUI_VERSION` is now Deprecated:** The old folder structure (where all logic lived inside a single root folder) has been officially discontinued.
*   **End of Support:** We will no longer provide updates or fixes for the `GUI_VERSION` folder.
*   **Migration:** All development effort has shifted entirely to the new **`GUI_REFACTOR`** structure.

---

## 🏗️ Structural Overhaul (The Great Refactor)

The application logic has been decoupled and organized into specialized directories to follow separation of concerns principles:

### 🧩 New Folder Structure
*   **📂 Engine:** Core processing units are now isolated (e.g., `ApiManager`, `AuthManager`, `GachaStatsManager`).
*   **📂 Views:** UI components are split into individual files for better rendering performance (e.g., `PityMeter.ps1`, `LogWindow.ps1`, `FilterPanel.ps1`).
*   **📂 Controllers:** Dedicated logic handlers (`MainLogic.ps1`, `ChartLogic.ps1`) to bridge the gap between data and the UI.
*   **📂 System:** Essential system utilities like `SoundPlayer`, `ThemeManager`, and `SettingsWindow` now have their own dedicated space.
*   **📂 UserData:** All database files (`MasterDB_*.json`) are now strictly organized within this directory to keep the root clean.

### ⚡ Improvements
*   **Clean Codebase:** Removed the clutter of loose CSV and script files from the root directory.
*   **Enhanced Maintainability:** Bugs can now be tracked down to specific modules rather than searching through a massive single script file.


# [6.5.0] - 2026-01-22

## 🌟 Highlights
Version 6.5.0 is the **"Multimedia & Stability"** update. The application now features a robust **Audio Feedback System**, providing sound effects for startup, errors, and—most importantly—a special "Legendary" sound when a 5-star is detected during a fetch! We also rewrote the log rendering engine to eliminate visual flickering and ghosting.

---

## 🆕 New Features

### 🔊 Audio Feedback System (Sound Engine)
*   **Interactive Audio:** The app can now play `.wav` sound effects located in the `Sounds` folder to provide instant feedback.
*   **Smart Triggers:**
    *   **Startup:** System ready sound.
    *   **Success:** Notification when data fetching/loading completes.
    *   **Error:** Auditory warning when validation fails or a crash is caught.
    *   **✨ Legendary Drop:** A special sound effect plays automatically when a new 5-Star item is detected during a fetch session!
*   **Settings Toggle:** Added an "Enable Audio Feedback" option in **Settings > General** for users who prefer silence.

### ⚡ Visual Core (Anti-Flicker)
*   **Instant Rendering:** Rewrote the Log Window rendering logic using `SuspendLayout` and `ResumeLayout`. The history list now appears instantly as a complete block, eliminating the "scrolling numbers" artifact and screen flickering.
*   **Loading Indicators:** Replaced the distracting "..." animation with a cleaner, faster loading phase for better performance on large databases.


# [6.4.0] - 2026-01-22

## 🌟 Highlights
Version 6.4.0 focuses on **"System Integrity & Polish."** We have completely redesigned the **System Health Monitor** into a modern dashboard style, added robust **Input Validation** to prevent user errors, and fixed critical variable scope issues in the UI engine.

---

## 🆕 New Features & Improvements

### 🏥 System Health Dashboard 2.0
*   **Modern Grid Layout:** completely overhauled the **Settings > Data** interface into a clean table view (Component | Filename | Size | Status).
*   **File Size Intelligence:** The dashboard now reads and displays file sizes (auto-formatting to KB/MB) to help you monitor database growth.
*   **Dynamic Scroll:** Fixed UI clipping issues by implementing dynamic height calculation and a "Ghost Anchor," ensuring the scrollbar always reaches the bottom regardless of how many games are installed.

### 🛡️ Safety & Validation
*   **Smart Input Validation:** The "Start Fetching" button now strictly checks if a file is selected and exists. It provides clear warning popups instead of crashing if the input is empty or invalid.
*   **Deep Reset:** The "Reset / Clear All" function now wipes the **File Path Input** and **Max/Min Statistics** to ensure a truly clean slate, preventing accidental fetches from the wrong file.

---

## 🐛 Bug Fixes

*   **Critical:** Fixed a `Runtime Exception` in the Settings window caused by variable scope issues in the button hover effect (Corrected logic to use `$this`).
*   **Fixed:** ZZZ/HSR Local History filter bug where data types (Integer vs String) caused mismatches, resulting in empty graphs when loading from JSON.
*   **Fixed:** Genshin Impact "Character Event" view missing the specific header tag (`[Character Event Only]`) in the log window.
*   **Fixed:** Formatting overlap issues in the System Health Monitor when displaying long filenames.



# [6.3.0] - 2026-01-21

## 🌟 Highlights
Version 6.3.0 refines the **"Infinity Database"** experience by introducing **Auto-Load Logic**—your history now appears instantly upon opening the app or switching games, no fetching required. We also addressed visual artifacts, improved the Luck Analysis dashboard, and fixed critical UI bugs related to date selection and ZZZ data types.

---

## 🆕 New Features

### ⚡ Instant Auto-Load
*   **Zero-Wait Startup:** The application now automatically loads your local `MasterDB` history immediately upon launch.
*   **Seamless Game Switching:** Switching between Genshin, HSR, and ZZZ now instantly swaps the data view without requiring a re-fetch.
*   **Visual Feedback:** The window title now dynamically displays **"Infinity DB"** status and record counts (e.g., `Showing: 50 / 1500 pulls`).

### 📊 Enhanced Analytics
*   **Max/Min Pity Indicators:** Added a new section in the Luck Analysis dashboard to track your **Luckiest (Min)** and **Unluckiest (Max)** pulls historically.
*   **Visual Polish:**
    *   **Anti-Flicker Rendering:** Implemented `SuspendLayout` and `ResumeLayout` logic during log generation. The list now "snaps" into place instantly without ghosting or visible number scrolling.
    *   **Instant Pity Reset:** Switching banners now visually resets the Pity Meter to 0 immediately before calculation begins, preventing confusing "leftover" numbers.

### 🏥 System Monitor Upgrades
*   **Smart "OPEN" Buttons:** In **Settings > Data**, clicking "OPEN" now launches Explorer and **highlights** the specific file (instead of just opening the folder).
*   **Dynamic Layout:** The Health Monitor now hides database checks for games you aren't currently viewing to reduce clutter.
*   **Scrollable Interface:** Added auto-scroll support to the Data tab to accommodate the expanded monitoring tools.

---

## ⚡ Improvements

*   **Pro Splash Screen:**
    *   **Dual Mode:** Displays simplified text for users ("Loading...") but detailed file paths when in Debug Mode.
    *   **Visuals:** Changed text color to Black/Contrast for better readability on light backgrounds.
*   **Audit Logging:** Added specific logs for Manual Config Backup and Restore operations (Console + UI + File).
*   **Global Versioning:** Centralized version control variables (`$AppVersion`, `$EngineVersion`) for consistent display across the Title Bar, Credits, and System Status window.

---

## 🐛 Bug Fixes

*   **Critical:** Fixed an infinite loop bug in the **Date Filter (Calendar)** caused by `DoEvents()` interfering with mouse click events.
*   **Critical:** Fixed **ZZZ Banner Filter** not updating correctly due to Data Type mismatches (Integer vs. String comparison logic normalized).
*   **Fixed:** Startup Crash (`NullReferenceException`) caused by the Banner Dropdown event listener initializing before the UI control was created.
*   **Fixed:** Missing Tooltips for the Luck Grade section.
*   **Fixed:** Restore Config not updating the internal temporary color variable, causing the next Save to revert changes.



# [6.2.0] - 2026-01-20

## 🌟 Highlights
Version 6.2.0 is the **"Stability & Audit"** update. We have introduced a professional-grade **System Health Monitor**, a robust **Backup/Restore ecosystem** with hot-reloading, and deep **Audit Logging** to track every user action and system error. The UI has been refined for instant feedback, eliminating the need for manual refreshes.

---

## 🆕 New Features

### 🏥 System Health Monitor
*   **Dashboard:** Added a dedicated section in **Settings > Data** that monitors critical files (`config.json`, `HoyoEngine.ps1`, Databases, Logs).
*   **Smart Open:** Clicking "OPEN" now launches Windows Explorer with the specific file **highlighted**, resolving issues with relative paths and spaces in folder names.
*   **Auto-Layout:** The monitor dynamically adjusts its layout based on installed games (only showing databases for games you play).

### ♻️ Advanced Backup & Restore
*   **Hot-Reload Restore:** The new "Restore Config" button allows users to load a previous `.json` backup. The app instantly updates themes, opacity, and settings without restarting.
*   **Safety Logic:** Restoring a config automatically creates a `.old` backup of the current settings before overwriting, preventing accidental data loss.
*   **Manual Backup:** Added a "Force Backup" button with detailed audit logging.

### 🕵️‍♂️ Deep Audit Logging (Telemetry)
*   **Audit Trails:** The system now logs critical user actions to `Logs\debug_xxxx.log` (e.g., "Settings updated," "Cache cleared," "Backup created," "Application Shutdown").
*   **Crash Catcher:** Implemented a global error trap that catches startup crashes and logic errors, saving the stack trace to the log file instead of silently failing.
*   **Log Rotation:** Logs are organized by date and automatically cleaned up after 7 days to save disk space.

### 🖥️ "System Status" Dashboard
*   **New Popup Window:** The "Check for Updates" menu now opens a dedicated, non-intrusive window displaying the **UI Version** and **Engine Version** separately, with a direct link to the GitHub repository.

---

## ⚡ Improvements

*   **Dual-Mode Splash Screen:**
    *   **User Mode:** Displays clean, simple loading text.
    *   **Debug Mode:** Displays detailed technical paths and file operations for developers.
*   **Dynamic Pity Meter:** The Pity Meter logic has been moved to the core View Engine. It now updates its maximum scale (80 vs 90) and color instantly when switching between Character and Weapon banners.
*   **Smart Window Title:** The application title now displays the **Total Database count** vs. **Filtered View count** (e.g., `Showing: 50 / 1500 pulls`).
*   **Settings UX:** Added auto-scroll support for the Data tab using a "Ghost Label" technique to prevent UI elements from being cut off.

---

## 🐛 Bug Fixes

*   **Fixed:** `NullReferenceException` on startup caused by event listeners attaching to the Banner Dropdown before it was created.
*   **Fixed:** Banner Dropdown requiring a window resize/refresh to update the graph. It now triggers a force refresh immediately upon selection.
*   **Fixed:** Restore Config not applying the "Accent Color" immediately (requiring a second save).
*   **Fixed:** `CsvSeparator` missing from the default Engine config, causing crashes on new installations.
*   **Fixed:** "Clear Cache" button logic to correctly target `temp_data_2` alongside `.tmp` files.



# [6.1.0] - 2026-01-19

## 🌟 Highlights
This update focuses on **Data Persistence** and **Offline Capabilities**. We introduced the **"Infinity Database"** engine, allowing users to keep their wish history forever (even after game logs expire). We also added an **Offline JSON Viewer**, a **System Health Dashboard**, and significant visual improvements to the Pity Meter and Splash Screen.

---

## 🆕 New Features

### 💾 Infinity Database (Smart Merge Engine)
*   **True Data Persistence:** The app now uses a "Merge & Deduplicate" logic instead of simply replacing data. This means your history grows indefinitely over time, preserving data even after the game deletes old logs (6+ months).
*   **MasterDB Architecture:** Data is now stored securely in `UserData\MasterDB_[Game].json`, acting as a permanent local archive.
*   **Audit-Trail Logging:** The merge process logs detailed statistics (new items vs duplicates) to the system log for full transparency.

### 🛠️ Offline Capabilities & Tools
*   **Offline JSON Viewer:** Added `Tools > Import History from JSON` (Ctrl+O). You can now load and analyze external JSON files without needing to open the game or fetch data.
*   **System Health Monitor:** A new dashboard in **Settings > Data** that visualizes the status of essential files (Config, Engine, DB, Logs). Includes "Smart Open" buttons that highlight the specific file in Windows Explorer.
*   **Smart Log Rotation:** System logs are now organized in a `Logs` folder. The system automatically cleans up logs older than 7 days to save space.

### 📊 Visual & Logic Enhancements
*   **Dynamic Pity Meter:** The Pity bar now automatically adjusts its maximum scale (80 for Weapons, 90 for Characters) based on the selected banner filter.
*   **Real-time Banner Filtering:** Switching the banner dropdown now instantly refreshes the Graph and Logs to show *only* that specific banner type (no more mixed data).
*   **Smart Window Title:** The title bar now displays real-time database statistics (e.g., `Infinity DB | Showing: 50 / 1500 pulls`).

---

## 💅 UI/UX Polish
*   **System Status Popup:** The "Check for Updates" menu now opens a modern, dark-themed dashboard displaying both UI and Engine versions clearly.
*   **Dual-Mode Splash Screen:** The startup screen now displays simplified messages for users ("Loading...") but detailed technical paths when in Debug Mode.
*   **Visual Tweaks:** Changed Splash Screen text color to Black for better visibility. Added auto-scroll support to the Data Settings tab.

---

## 🐛 Bug Fixes
*   **Fixed:** Banner Dropdown not refreshing the view immediately (required a window resize/refresh previously).
*   **Fixed:** "Open File" buttons in Settings failing on paths with spaces or relative paths.
*   **Fixed:** `ShowDialog` cancel action in the Import menu causing script errors.
*   **Fixed:** Filter Logic where selecting "Weapon Event" would still display Character data in the graph.



# [6.0.0] - 2026-01-19
## 🌟 Highlights
This update introduces a complete overhaul of the **Preferences / Settings** system, transforming it into a professional-grade dashboard. We've added robust **Data Management tools**, **Real-time UI customization**, **System Telemetry**, and **Excel compatibility options**, alongside critical bug fixes.

---

## 🆕 New Features

### ⚙️ Ultimate Preferences Window (Redesigned)
The Settings menu (F2) has been rebuilt with a Tab-based interface for better navigation:
*   **Tab: General:** Redesigned layout with GroupBoxes to separate "Storage & Export" from "System & Troubleshooting".
*   **Tab: Appearance:**
    *   **Theme Presets:** Quickly switch between game-themed colors (Cyber Cyan, Genshin Gold, HSR Purple, ZZZ Orange).
    *   **Real-time Ghost Mode:** Window opacity now updates instantly while dragging the slider (no save required).
*   **Tab: Data & Storage (New!):**
    *   **Open Data Folder:** One-click access to local app files.
    *   **Force Backup:** Manually trigger a config backup.
    *   **Maintenance Zone:** Specialized button to clear temporary cache files (`temp_data_2`, `*.tmp`) without affecting your backups.

### 💾 Data Safety & Export
*   **Active Auto-Backup:** The Auto-Backup feature is now fully functional. Fetching data will automatically create a timestamped backup JSON in your selected folder.
*   **Excel Compatibility:** Added a **CSV Separator** option in Settings. You can now choose between Comma (`,`) or Semicolon (`;`) to prevent formatting issues in Excel based on your region.
*   **JSON Export:** Added a dedicated button to export raw history data to JSON format.

### 🛡️ System & Telemetry
*   **System Logger (Black Box):** Implemented a comprehensive logging system. Actions and errors are now recorded to `debug_session.log` for easier troubleshooting.
*   **Crash Catcher:** Added a Global Error Trap to catch unhandled exceptions and log the stack trace instead of silently crashing the application.
*   **Restore Defaults:** Added a button to safely reset all settings to factory defaults.

---

## 🐛 Bug Fixes
*   **Fixed:** `NullReferenceException` crash when switching from a Custom Color to a Preset Theme.
*   **Fixed:** Window Opacity not updating correctly due to variable scope issues.
*   **Fixed:** "Clear Cache" button failing to delete the main `temp_data_2` file (it only deleted `.tmp` files previously).
*   **Fixed:** `DebugConsole` setting ignoring the config file on startup due to variable initialization order.
*   **Fixed:** CSV Export ignoring the user-defined separator setting.

---

## 💅 UI/UX Improvements
*   Improved button labels and tooltips for better clarity.
*   Smoother splash screen transition upon exit.
*   Unified styling for all input fields and dropdowns in the Settings window.



## [5.2.0] - 2026-01-17
### 💰 The "Master Planner" Update

This update completes the ecosystem by introducing a **Resource Planner**, along with significant visual upgrades to the Simulator Graph to make data easier to read at a glance.

### 🚀 New Features
*   **💰 Resource Planner (Savings Calculator):**
    *   **New Tool (F10):** A dedicated calculator to estimate your future Primogems/Fates stash.
    *   **Flexible Inputs:** Calculate based on Target Date, Daily Income (Customizable rate), and Lump Sum estimates (Abyss, Events, Shop).
    *   **Simulator Integration:** One-click transfer of your calculated budget directly into the Wish Forecast Simulator.
*   **📊 Enhanced Graph Visuals:**
    *   **Context Markers:** Added vertical strip lines to indicate exactly where **Soft Pity** and **Hard Pity** begin relative to your start point.
    *   **Visual Legend:** Added a clear legend explaining the color coding (Green/Gold/Red).
    *   **Y-Axis Label:** Added "Frequency" label to clarify what the bar height represents.
    *   **Improved Scaling:** The graph now always starts at 0 to prevent visual distortion when data is sparse.
*   **🛑 Simulator Controls:**
    *   **Stop Button:** Added a panic button to cancel the simulation immediately if you entered the wrong inputs.
    *   **Action Logs:** The main log window now displays clear `[Action]` tags when simulations start or stop.

### 🔧 Improvements
*   **Privacy Mode:** Sensitive file paths in the logs are now hidden (`[PATH HIDDEN]`) when Debug Mode is disabled.
*   **Encoding Fixes:** Standardized internal data handling to prevent "Mojibake" (garbled text) issues with Thai characters in JSON exports and Tables.



## [5.1.1] - 2026-01-17
### 💾 The "Data Management" Update

This update focuses on data accessibility and standardization. Users can now view their history in a detailed grid view and export raw data for backups or external use.

### 🚀 New Features
*   **📄 History Table Viewer (F9):**
    *   Added a dedicated **Grid View** accessible via **Menu > Tools** or **F9**.
    *   **Features:** Sortable columns, real-time name search/filtering, and color-coded rows for 5★ (Gold) and 4★ (Purple) items.
    *   **Context-Aware:** The table respects the Date Filters applied in the main window.
*   **💾 Raw JSON Export:**
    *   Added an option to export the full, raw API data structure to a `.json` file.
    *   Useful for data backups or importing into other analytics sites (e.g., Paimon.moe).

### 🔧 Fixes & Optimizations
*   **Data Standardization (Encoding Fix):**
    *   The Engine now automatically detects and fixes **Mojibake (garbled text)** or non-English terms in the `item_type` field (e.g., transforming `à¸...` or `อาวุธ` to `Weapon`).
    *   This ensures that all exported data (JSON/CSV) uses standard English terms ("Character"/"Weapon"), making it universally compatible with other tools.



## [5.1.0] - 2026-01-17
### 🔮 The "Visual Oracle" Update

This update introduces a comprehensive **Gacha Simulation Engine** paired with **Advanced Data Visualization**. It shifts the tool from a simple tracker to a predictive analytics powerhouse.

### 🚀 New Features
*   **Wish Forecast (Monte Carlo Simulator):**
    *   **Simulation Engine:** Runs **100,000 simulations** based on your specific resources to predict outcomes with high statistical accuracy.
    *   **Auto-Detect:** Automatically pulls `Current Pity`, `Guaranteed Status` (Win/Loss), and `Banner Mode` (Character 90 / Weapon 80) from your fetch history.
    *   **Stop Button:** Added a user-controllable **STOP** button to cancel the simulation at any time.
    *   **Action Logging:** Added clear visual delimiters (`---`) and Action Tags in the main log window when simulations start or stop.
*   **Probability Histogram (Graph):**
    *   **Visual Distribution:** A new bar chart showing exactly *when* (at which pull count) you are most likely to get the character.
    *   **Smart Coloring:** Bars are color-coded based on total pity reached:
        *   🟩 **Lucky (<74):** Early wins.
        *   🟨 **Soft Pity (74-85):** The standard range.
        *   🟥 **Hard Pity (>85):** The unlucky range.
    *   **Context Markers:** Visual strip lines indicating the exact start of **Soft Pity** and **Hard Pity** relative to your current progress.
    *   **Dynamic Scaling:** The graph axis automatically adjusts to your budget (starts at 0, scales up if >100 pulls).
*   **Privacy & Security:**
    *   **Privacy Mode:** When `DebugMode` is off, sensitive file paths (e.g., User folder names) are now hidden in the logs as `[PATH HIDDEN]`.

### 🎨 UI/UX Improvements
*   **Menu Bar Integration:** Moved the Forecast tool to **Tools > Wish Forecast (F8)** for a cleaner main interface.
*   **Dark Theme Menu:** Fixed an issue where menu items would turn white (unreadable) when clicked; applied a custom dark renderer.
*   **Interactive Tooltips:** Hovering over graph bars now displays precise probability percentages and total pity count.
*   **Help System:** Added a `?` button to explain the simulation logic to users.

### 🔧 Fixes
*   **Graph Logic:** Fixed an issue where the graph would show a single distorted bar when data was highly concentrated.
*   **Text Orientation:** Fixed a crash related to vertical text rendering on chart strip lines.


## [5.0.0] - 2026-01-17
### 🔮 The "Prophecy" Update (Wish Simulator)

This major update transforms the application from a "History Tracker" into a **"Future Predictor"**. We have introduced a mathematical simulation engine to help users plan their resources with statistical confidence.

### 🚀 New Features
*   **Wish Forecast (Simulator Tool):**
    *   **New Interface:** Accessible via **Menu > Tools > Wish Forecast (F8)**.
    *   **Smart Auto-Detect:** Automatically pulls `Current Pity`, `Guaranteed Status` (Win/Loss), and `Banner Mode` (Character/Weapon) from your local data.
    *   **Visual Feedback:** Real-time progress bar and percentage display during simulation.
    *   **Insightful Results:** Displays "Success Chance %" and "Average Cost" calculated from your exact budget.

### 🧠 Deep Dive: The Monte Carlo Engine
We moved away from simple probability formulas (which struggle to account for HoYoverse's complex Soft Pity and Guarantee systems). Instead, we implemented a **Monte Carlo Method**.

**How it works:**
The engine virtually "pulls" gacha for you **100,000 times** using the exact game rules (0.6% base rate, ramping soft pity, 50/50 logic). By aggregating these parallel universes, we derive a highly accurate probability.

**The Algorithm (Core Logic):**
Below is the actual logic used in `HoyoEngine.ps1` to simulate the rates dynamically:

```powershell
# --- Core Monte Carlo Logic (Snippet) ---
for ($round = 1; $round -le 100000; $round++) {
    $CurrentPity = $StartPity
    $Guaranteed = $IsGuaranteed
    
    # Simulate pulls based on user budget
    for ($i = 1; $i -le $MyPulls; $i++) {
        $CurrentPity++
        
        # 1. Calculate Rate (Implementing Soft Pity Rules)
        # 0.6% Base Rate -> Increases by ~6% per pull after Soft Pity (74)
        $CurrentRate = 0.6
        if ($CurrentPity -ge 74) {
            $CurrentRate = 0.6 + (($CurrentPity - 74) * 6.0)
        }
        # Hard Pity Cap (90 for Char, 80 for Weapon)
        if ($CurrentPity -ge $HardPityCap) { $CurrentRate = 100.0 }

        # 2. Roll the Dice (RNG)
        $Roll = (Get-Random -Minimum 0.0 -Maximum 100.0)

        if ($Roll -le $CurrentRate) {
            # 3. Check 50/50 vs Guaranteed
            if ($Guaranteed -or (Get-Random -Min 0 -Max 2) -eq 0) {
                $SuccessCount++ 
                break # Won the 5-Star
            } else {
                $Guaranteed = $true # Lost 50/50, next is guaranteed
                $CurrentPity = 0 
            }
        }
    }
}
```
## 🎨 UI/UX Improvements

- **Menu Bar Integration**  
  Moved the **Forecast** tool into a standard top `MenuStrip` for a cleaner and more professional layout.

- **Help System**  
  Added an interactive **?** button in the simulation result panel to explain the statistical meaning of the results.

- **Compact Layout**  
  Optimized the main window size to prevent UI overflow on smaller laptop screens.

---

## 🔧 Fixes & Optimizations

- **Smart Pity Cap**  
  The engine now strictly distinguishes pity limits based on the latest `gacha_type`.
  - **Character Banner:** 90 Pity
  - **Weapon Banner:** 80 Pity

- **Thread Safety & UI Responsiveness**  
  - Improved UI responsiveness during the simulation loop using `Application::DoEvents()`.

## [4.2.0] - 2026-01-16
### ✨ The "Modern UI & Precision" Update

### 🎨 UI/UX Redesign (Modernized)
#### Interactive Toggle Switches
- Replaced traditional checkboxes in the Settings panel with **Modern Toggle Buttons**.
- States are now clearly color-coded (e.g., Purple for Discord ON, Gold for View Mode) for better visual feedback.
#### Clean Dashboard Layout
- Redesigned the **Configuration Group** with a structured Grid Layout for better readability.
- Removed the legacy **Loading/Progress Bar** to reduce visual clutter and improve performance.
- **Sleek Pity Meter:** Redesigned the visual gauge to be slimmer and more aesthetically pleasing.

### 🧠 Core Logic Improvements
#### Smart Pity Cap Detection
- The engine now **automatically detects the banner type** based on the latest pull data.
- Adjusts the Pity Meter calculation dynamically:
  - **90 Pity** for Character Banners.
  - **80 Pity** for Weapon / Light Cone / W-Engine Banners.
#### Real-Time View Updating
- Toggling between **"Timestamp"** and **"Index [No.]"** modes now triggers an **Instant Refresh** of the Log and Graph.
- No need to press "Start Fetching" again just to change the display format.

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
