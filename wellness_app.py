#!/usr/bin/env python3
"""
Wellness Reminders — macOS Menu Bar App
Reminds you to drink water, blink, sit up straight, and take breaks.
"""

import subprocess
import sys

# Auto-install rumps if not present
try:
    import rumps
except ImportError:
    print("Installing 'rumps' (first time only, please wait)...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "rumps", "--quiet"])
    import rumps


class WellnessApp(rumps.App):
    def __init__(self):
        super().__init__("💙", quit_button=None)

        # Intervals in seconds
        self.intervals = {
            "water":   60 * 60,   # every 1 hour
            "blink":   10 * 60,   # every 10 minutes
            "posture": 30 * 60,   # every 30 minutes
            "break":   90 * 60,   # every 90 minutes
        }

        # Which reminders are active
        self.active = {k: True for k in self.intervals}

        # Build menu items
        self.items = {
            "water":   rumps.MenuItem("💧  Water — every 60 min  ✅", callback=self.toggle_water),
            "blink":   rumps.MenuItem("👁️  Blink — every 10 min   ✅", callback=self.toggle_blink),
            "posture": rumps.MenuItem("🪑  Posture — every 30 min ✅", callback=self.toggle_posture),
            "break":   rumps.MenuItem("☕  Break — every 90 min   ✅", callback=self.toggle_break),
        }

        # Icon picker submenu
        self.icon_options = [
            "💙", "💚", "💜", "🧡", "❤️", "🩷",
            "🌿", "🌸", "⭐", "🌈", "🔔", "✨",
            "🍃", "🫧", "🕊️", "🌻",
        ]
        icon_menu = rumps.MenuItem("🎨  Change Icon")
        for icon in self.icon_options:
            icon_menu[icon] = rumps.MenuItem(icon, callback=self.change_icon)

        self.menu = [
            rumps.MenuItem("Wellness Reminders", callback=None),   # header (non-clickable)
            None,
            self.items["water"],
            self.items["blink"],
            self.items["posture"],
            self.items["break"],
            None,
            icon_menu,
            rumps.MenuItem("⚙️  Adjust Intervals", callback=self.adjust_intervals),
            None,
            rumps.MenuItem("Quit", callback=self.quit_app),
        ]

        # Callbacks map
        self._callbacks = {
            "water":   self._water_alert,
            "blink":   self._blink_alert,
            "posture": self._posture_alert,
            "break":   self._break_alert,
        }

        # Start all timers
        self.timers = {}
        for key in self.intervals:
            self._start_timer(key)

    # ── Timer helpers ──────────────────────────────────────────────────────────

    def _start_timer(self, key):
        if key in self.timers:
            self.timers[key].stop()
        t = rumps.Timer(self._callbacks[key], self.intervals[key])
        t.start()
        self.timers[key] = t

    # ── Notification alerts ────────────────────────────────────────────────────

    def _water_alert(self, _):
        if self.active["water"]:
            rumps.notification(
                title="Hydration Time! 💧",
                subtitle="",
                message="Grab a glass of water — your body will thank you!",
            )

    def _blink_alert(self, _):
        if self.active["blink"]:
            rumps.notification(
                title="Remember to Blink! 👁️",
                subtitle="",
                message="Blink several times and look 20 ft away for 20 seconds.",
            )

    def _posture_alert(self, _):
        if self.active["posture"]:
            rumps.notification(
                title="Sit Up Straight! 🪑",
                subtitle="",
                message="Shoulders back, feet flat, screen at eye level. You got this!",
            )

    def _break_alert(self, _):
        if self.active["break"]:
            rumps.notification(
                title="Break Time! ☕",
                subtitle="",
                message="Step away for 5 mins — stretch, walk around, breathe. You've earned it!",
            )

    # ── Toggle on/off from menu ────────────────────────────────────────────────

    LABELS = {
        "water":   "💧  Water — every 60 min",
        "blink":   "👁️  Blink — every 10 min  ",
        "posture": "🪑  Posture — every 30 min",
        "break":   "☕  Break — every 90 min  ",
    }

    def _toggle(self, key):
        self.active[key] = not self.active[key]
        status = "✅" if self.active[key] else "❌"
        self.items[key].title = f"{self.LABELS[key]} {status}"
        if self.active[key]:
            self._start_timer(key)
        else:
            self.timers[key].stop()

    def toggle_water(self, _):   self._toggle("water")
    def toggle_blink(self, _):   self._toggle("blink")
    def toggle_posture(self, _): self._toggle("posture")
    def toggle_break(self, _):   self._toggle("break")

    # ── Change menu bar icon ───────────────────────────────────────────────────

    def change_icon(self, sender):
        self.title = sender.title   # sender.title is the emoji that was clicked

    # ── Adjust intervals ───────────────────────────────────────────────────────

    def adjust_intervals(self, _):
        response = rumps.alert(
            title="Adjust Intervals",
            message=(
                "Current intervals:\n\n"
                f"  💧 Water:   every {self.intervals['water']  // 60} min\n"
                f"  👁️ Blink:   every {self.intervals['blink']  // 60} min\n"
                f"  🪑 Posture: every {self.intervals['posture']// 60} min\n"
                f"  ☕ Break:   every {self.intervals['break']  // 60} min\n\n"
                "To change intervals, edit wellness_app.py and\n"
                "update the numbers in the 'intervals' dictionary."
            ),
            ok="Got it!",
        )

    # ── Quit ──────────────────────────────────────────────────────────────────

    def quit_app(self, _):
        for t in self.timers.values():
            t.stop()
        rumps.quit_application()


if __name__ == "__main__":
    WellnessApp().run()
