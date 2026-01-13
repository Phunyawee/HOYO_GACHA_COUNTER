<div align="center">

# 🌠 Zenless Zone Zero Signal Search Tool

[![Thai Badge](https://img.shields.io/badge/ภาษา-ไทย-blue)](./README_TH.md)
[![English Badge](https://img.shields.io/badge/Language-English-red)](./README.md)

</div>

This folder contains scripts to extract your Signal Search (Gacha) history URL and calculate your pity counter.

## 📂 File List
| File Name | Description |
| :--- | :--- |
| **1_GetLink.bat** | 🔑 **STEP 1:** Advanced Link Extractor. Scans the local cache file using **Brute Force** method to find the working AuthKey. |
| **2_Calc_ZZZ_Character.bat** | 🧮 **STEP 2 (Select Mode):** Interactive menu. You can choose to fetch **Specific Banners** (Character, Weapon, Bangboo) or ALL. |
| **2_Calc_ZZZ_All.bat** | 📊 **STEP 2 (Auto All):** Automatically fetches and calculates pity for **ALL Channels** in one go. |



## 🚀 Usage Guide

Since this tool runs in **Safe Mode** (local file reading), you need to manually provide the cache file.

### 📌 PHASE 1: Find the `data_2` file

#### 1️⃣ Open History in Game
Go to the **Signal Search** menu, click **"Details"**, then select the **"History"** tab. Wait for the list to load.
*(This action generates a fresh key in your storage).*

![Open History](./screenshots/Find_data_2_Step1.png)

#### 2️⃣ Find the Cache Folder
Go to your ZZZ Installation folder:
`ZenlessZoneZero Game` ➔ `ZenlessZoneZero_Data` ➔ `webCaches`

Look for the folder with the **Latest Version Number** (or latest Date Modified).

![Select Version](./screenshots/Find_data_2_Step2.png)

#### 3️⃣ Get 'data_2' & Check Date ⚠️
Go deeper into: `.../Cache/Cache_Data/`
Find the file named **`data_2`**.

**🚨 CRITICAL CHECK:** Look at the **"Date Modified"**. It must match **RIGHT NOW**.
*(If the time is old, delete the file, go back to Step 1 and open History again).*

![Check Date Modified](./screenshots/Find_data_2_Step3.png)

#### 4️⃣ Place the File
Copy the `data_2` file and paste it into this **ZZZ** folder (where the scripts are).
**Make sure your folder looks like this:**

![Folder Setup](./screenshots/Setup_Place_file.png)

---

### ⚡ PHASE 2: Run the Tool

#### Step 1: Get the Link 🔑
Run **`1_GetLink.bat`**. It will scan the file and copy the valid link to your clipboard.

![Get Link Console Output](./screenshots/step1_getlink.png)

#### Step 2: Calculate Pity 🧮
Run **`2_Calc_ZZZ_All.bat`** (Recommended) or **`2_Calc_ZZZ_Character.bat`** (Select Mode).

**Option A: Select Mode (Interactive Menu)**
![Select Mode Result](./screenshots/step2_select.png)

**Option B: All Banners (Timeline)**
![All Banners Result](./screenshots/step2_all.png)

---

## 🛠️ Troubleshooting

**Q: Script says "Clipboard is empty" or "Invalid URL"**
A: Run `1_GetLink.bat` first. If it fails, delete `data_2` and open the game history again to generate a fresh file.

**Q: The list is empty or missing recent pulls?**
A: **Wait 1 hour.** ZZZ API is slower than Genshin/HSR.

**Q: Pity count seems wrong (jumping numbers)?**
A: The script uses a special sorting algorithm (`Decimal Sort`) to fix ZZZ's chaotic ID timestamps. Ensure you are using the latest version of this script.

---

## 📜 Credits
* **AuthKey Extraction:** Logic adapted for ZZZ's binary file structure using Brute Force method.
* **Param Override:** Implemented special logic to bypass ZZZ's `real_gacha_type` restrictions.
* **Development:** Developed, refactored, and reviewed with the assistance of AI.