# 💙 Wellness Reminders

A lightweight macOS menu bar app that keeps your health in check while you work — reminding you to drink water, blink, sit up straight, and take breaks.

---

## Features

- 💧 **Water** — reminder every 60 minutes
- 👁️ **Blink** — reminder every 10 minutes
- 🪑 **Posture** — reminder every 30 minutes
- ☕ **Break** — reminder every 90 minutes
- 🎨 **16 icon choices** — pick your vibe from the menu bar
- Toggle any reminder on/off with a single click
- Runs quietly in the background — no dock icon, no fuss

---

## Requirements

- macOS 10.14 or later
- Python 3 (comes pre-installed on most Macs)

---

## Installation

1. Clone or download this repo
2. Open the `python/` folder
3. Double-click **`▶️ Start Wellness App.command`**
4. If macOS blocks it the first time: right-click → **Open** → **Open**
5. Allow notifications when prompted
6. Look for **💙** in your menu bar — you're all set!

The first launch installs the one required package (`rumps`) automatically.

---

## Usage

Click the **💙** icon in your menu bar to:

- **Toggle reminders** on or off (✅ = on, ❌ = off)
- **Change the icon** under 🎨 Change Icon
- **Quit** the app when you're done for the day

To restart, just double-click `start.command` again.

---

## Customizing Intervals

Open `python/wellness_app.py` and edit the `intervals` dictionary near the top:

```python
self.intervals = {
    "water":   60 * 60,   # change 60 to any number of minutes
    "blink":   10 * 60,
    "posture": 30 * 60,
    "break":   90 * 60,
}
```

---

## Troubleshooting

**"Failed building wheel" error on first launch**
The launcher automatically upgrades pip and build tools to fix this. If it persists, run in Terminal:
```bash
pip3 install --upgrade pip setuptools wheel
pip3 install rumps
```

**No notifications appearing**
Go to System Settings → Notifications → Terminal (or Python) → turn on Allow Notifications.

---

## 🛠️ Swift / iOS Expansion

Alongside the original Python menu bar app, I've been building native Swift versions:

* **DayToDay (macOS)** — a SwiftUI rewrite of the menu bar experience with a dashboard view, profile, and wellness manager
* **DayToDay Mobile (iOS)** — a companion iOS app with dedicated reminders, stats, and profile views built in SwiftUI
* **WellnessReminders** — an earlier SwiftUI prototype that informed the current architecture

Both Xcode projects live in the `DayToDay/` directory.

## License

© 2026 Isabella Castillo. All rights reserved.

This repository is public for portfolio and demonstration purposes only. No permission is granted to use, copy, modify, or distribute this code without explicit written permission from the author.
