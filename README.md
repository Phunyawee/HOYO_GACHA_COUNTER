<div align="center">

# 🌠 Universal HOYO Gacha Counter

[![Thai Badge](https://img.shields.io/badge/Lang-Thai-blue)](./README_TH.md)
[![English Badge](https://img.shields.io/badge/Lang-English-red)](./README.md)

</div>

A simple, safe, and lightweight tool to extract Gacha Links and calculate Pity History for **Genshin Impact**, **Honkai: Star Rail**, and **Zenless Zone Zero**.

> 💡 **Why use this?** Unlike other tools, this script reads local cache files directly. **No Admin permission required**, **No password needed**, and **No external API calls** for extracting keys. Everything runs locally on your machine.

## ✨ Universal Version Features (Recommended)
- 🎮 **3-in-1 Support:** One app works for all 3 games.
- 🖥️ **Modern GUI:** User-friendly interface (Windows Forms). No more command line typing.
- 🔍 **Auto-Detect:** Automatically finds the game cache file for you.
- 📊 **Smart Tracker:** View 5-Star/S-Rank history, pity count, and **Export to CSV**.
- 💬 **Discord Integration:** Sends beautiful reports to your Discord Webhook.

## 📸 Preview
![GUI Preview](./HoyoWishCounter/screenshots/GUI_Result.png)
*(New Graphical User Interface with instant calculation and Discord reporting)*

## 🚀 Choose Your Version

### ⭐ Option 1: Universal Tool (Recommended)
The latest version featuring a **Full GUI**, **Auto-Detect Cache**, **CSV Export**, and **Discord Support** for all 3 games.

#### 📂 [CLICK HERE to Open Universal Tool](./HoyoWishCounter)
*(Go here for the best experience)*

---

### 📜 Option 2: Standalone Versions (Legacy)
Simple, separate console scripts for each game. Useful if you want to inspect specific source code or don't need the GUI/Discord features.

- 📂 **[Genshin Impact (Standalone)](./Genshin)**
- 📂 **[Honkai: Star Rail (Standalone)](./StarRail)**
- 📂 **[Zenless Zone Zero (Standalone)](./zzz)**

---

## ⚠️ Limitation
Please note that game servers only keep your wish history for the last **6 months** (or 1 year for some banners).
* This tool **cannot** retrieve data older than what is stored on the server.
* If you haven't pulled in a long time, your history list might appear empty.

### 🤝 Credits
- Parsing logic inspired by [paimon.moe](https://paimon.moe)
- Refactored for simplicity, safety, and universal compatibility.

## 🙏 Acknowledgements
This project builds upon and is inspired by established community tools for HoYoverse games.
👉 **[View Full List of References & Credits](./REFERENCES.md)**