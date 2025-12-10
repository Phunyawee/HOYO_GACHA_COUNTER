<div align="center">

# 🌠 HOYO Gacha Counter & Tool

[![Thai Badge](https://img.shields.io/badge/Lang-Thai-blue)](./README_TH.md)
[![English Badge](https://img.shields.io/badge/Lang-English-red)](./README.md)

</div>

A simple, safe, and lightweight tool to **extract Gacha Link** and **calculate Pity History** for **Genshin Impact** & **Honkai: Star Rail**.

> 💡 **Why use this?** Unlike other tools, this script reads local cache files directly. **No Admin permission required** and **No external API calls** for extracting keys. Everything runs locally on your machine.

## ✨ Features
- 📊 **Pity Tracker:** View your 5-Star history, current pity count, and timeline.
- 🔒 **Safe & Local:** Logic reads directly from game cache files. No password needed.
- 🚀 **Simple:** Just point to the cache file. No complex setup.
- 🛡️ **No Admin Needed:** Runs safely without elevated privileges.

## 📸 Preview
![Result Preview](./Genshin/screenshots/step2_all.png)
*(Example output showing 5-star timeline and pity count)*

## ⚠️ Limitation
Please note that game servers only keep your wish history for the last **6 months** (or 1 year for some banners).
* This tool **cannot** retrieve data older than what is stored on the server.
* If you haven't pulled in a long time, your history list might appear empty.

## 🎮 Supported Games & Instructions
Please click on the game folder below to see how to use:

- 📂 **[Genshin Impact](./Genshin)**
- 📂 **[Honkai: Star Rail](./StarRail)**
- 📂 **[Zenless Zone Zero](./zzz)**

---

### 🤝 Credits
- Parsing logic inspired by [paimon.moe](https://paimon.moe)
- Refactored for simplicity, safety, and local file reading.