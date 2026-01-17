<div align="center">

# 🌠 Universal Hoyo Wish Counter (GUI V4)

[![Thai Badge](https://img.shields.io/badge/Lang-Thai-blue)](./README_TH.md)
[![English Badge](https://img.shields.io/badge/Lang-English-red)](./README.md)
[![Release](https://img.shields.io/badge/Release-v4.0.0-gold)](./App.ps1)

**The Ultimate Gacha Tracker for Genshin Impact, Honkai: Star Rail, and Zenless Zone Zero.**
Now featuring "Time Machine" analytics, Interactive Graphs, and SRS Auto-Detection.

![Graph Analytics](../screenshots/GUI_V4_Graph.png)
*(New in v4.0: Expandable Analytics Graph & Time Machine Filter)*

</div>

---

## ✨ What's New in v4.0?
*   **🧠 SRS Auto-Detect:** Smarter engine that finds your game cache automatically, even if installed on custom drives (Logic powered by SRS method).
*   **⏳ Time Machine:** Filter your history by date range to analyze specific banners or months.
*   **📊 Interactive Graph:** Visualizes your pull history with color-coded bars representing luck (Green/Gold/Red).
*   **⚡ Smart Snap:** Instantly finds the nearest Pity Reset point in the past for accurate "current banner" tracking.
*   **📱 Manual Discord Report:** Send custom reports for specific date ranges directly to your server.

---

## 📂 File List
| File Name | Description |
| :--- | :--- |
| **Start_GUI.bat** | ▶️ **Launcher:** Double-click this to start the tool safely. |
| **App.ps1** | 🖼️ **GUI Interface:** The main application window. |
| **HoyoEngine.ps1** | ⚙️ **Core Engine:** Handles SRS logic, API fetching, and Pity math (Do not run directly). |
| **config.json** | 📝 **Settings:** Stores your Discord Webhook URL. |

---

## 🚀 Usage Guide

### 📌 PHASE 1: Generate the Key
The tool reads the official game cache. You must generate a fresh link first.

1.  **Open the Game** (Genshin, HSR, or ZZZ).
2.  Open the **History (Wish/Warp/Signal)** menu in-game.
3.  Wait for the list to load, then **close the menu**.
    *   *This generates a fresh `data_2` file with a valid 1-hour token.*

---

### ⚡ PHASE 2: Run & Analyze

#### 1️⃣ Launch & Detect
Double-click **`Start_GUI.bat`**.
1.  Select your game (Buttons at top).
2.  Click **"Auto-Detect"** (Blue button).
    *   *v4.0 Engine will scan your game logs to find the exact path automatically.*

![Main Interface](../screenshots/GUI_V4_Main.png)

#### 2️⃣ Fetch Data
Click **"START FETCHING"**. The tool will download your history.
*   Once finished, the **Filter Panel** and **Graph Toggle** will unlock.

#### 3️⃣ Use Time Machine (Filter)
Want to check pulls from a specific month?
1.  Check **"Enable Filter"**.
2.  Select **From** and **To** dates.
3.  Click **"[SNAP] Find Reset"** to auto-align the start date to the nearest Pity 0.
4.  **True Pity Mode:** Even when filtering, the tool calculates Pity based on your *entire* history, ensuring accuracy.

![Filter Panel](../screenshots/GUI_V4_Filter.png)

#### 4️⃣ Visual Analytics
Click **`>> Show Graph`** in the top menu bar.
*   A side panel will expand showing your 5-Star history.
*   **Colors:** <span style="color:green">Green (Early)</span>, <span style="color:gold">Gold (Soft Pity)</span>, <span style="color:red">Red (Hard Pity)</span>.

---

## 💬 Discord Integration
Send stylish embed reports to your own Discord server.

1.  Create `config.json` in the app folder:
    ```json
    {
        "webhook_url": "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL..."
    }
    ```
2.  **Auto Send:** Sends a full summary after fetching.
3.  **Manual Send:** Click **"Discord Report"** in the Filter Panel to send a custom report based on your selected date range.

![Discord Embed](../screenshots/Discord_V4_Embed.png)

---

## 🔮 v5.0.0 - Wish Forecast (Simulator) Update
> *"Stop guessing, start calculating. Mathematics doesn't lie."*

We are proud to introduce a powerful new tool integrated directly into the application: **The Monte Carlo Wish Simulator**. Unlike simple calculators, this engine runs **100,000 simulations** based on your actual resources to predict your specific success rate.

![Forecast Menu](../screenshots/GUI_V5_Menu.png)

### ✨ Key Features
*   **🧠 Smart Auto-Detect:** The simulator automatically pulls your **Current Pity**, **Guaranteed Status (50/50)**, and **Banner Mode** (Character 90 / Weapon 80) from your latest fetch data. No manual entry required!
*   **📊 Probability Histogram (New!):** Visualize your luck distribution! The new interactive graph shows exactly *when* you are most likely to get the 5-star character.
    *   **🟩 Lucky Zone:** Early pulls before soft pity.
    *   **🟨 Soft Pity Zone:** The high-probability range (74-85 pulls), clearly marked.
    *   **🟥 Hard Pity Zone:** The "Salty" range for worst-case scenarios.
    *   **Markers:** Visual lines indicating exactly where Soft Pity and Hard Pity kick in relative to your current status.
*   **🎲 Monte Carlo Engine:** It simulates pulling gacha **100,000 times** using official game rules to ensure statistical accuracy.
*   **🛑 User Control:** Run the simulation or **Stop** it at any time if you need to adjust inputs.

### 🚀 How to Use
1.  Fetch your latest history in the main window.
2.  Go to **Tools > 🔮 Wish Forecast (Simulator)** or press **F8**.
3.  Enter your available **Primogems** or **Fates**.
4.  Click **RUN SIMULATION** and watch the probability graph generate in real-time!

![Simulator Window](../screenshots/GUI_V5_Simulator2.png)

---

## 🛠️ Troubleshooting

**Q: Auto-Detect cannot find the file?**
A: Ensure you opened the Wish History in-game *recently*. If it still fails, use **"Browse..."** to find `data_2` in your game's `webCaches` folder manually.

**Q: The Graph or Discord button is disabled.**
A: You must click **"START FETCHING"** successfully at least once to unlock these features.

**Q: "AuthKey timeout" / "Link Expired"**
A: The game's link only lasts for 1 hour. Re-open the History menu in-game to refresh it.

---

## 📜 Credits
*   **Development:** PowerShell & .NET Windows Forms
*   **Logic Inspiration:** Paimon.moe & Star Rail Station (SRS) for log parsing techniques.
*   **Icons:** Official Hoyoverse Assets.