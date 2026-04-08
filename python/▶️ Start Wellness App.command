#!/bin/bash
# ╔══════════════════════════════════════════╗
# ║     Wellness Reminders — Launcher        ║
# ║  Double-click this file to start the app ║
# ╚══════════════════════════════════════════╝

# Move to the folder where this script lives
cd "$(dirname "$0")"

echo ""
echo "🌿 Wellness Reminders App"
echo "─────────────────────────"

# ── Check Python 3 ──────────────────────────────────────────────────────────
if ! command -v python3 &>/dev/null; then
    osascript -e 'display alert "Python 3 not found" message "Please download Python 3 from python.org and try again." buttons {"OK"} as critical'
    exit 1
fi

# ── Install rumps if missing ─────────────────────────────────────────────────
python3 -c "import rumps" 2>/dev/null || {
    echo "📦 First-time setup: installing required packages..."
    # Upgrade pip, setuptools, and wheel first to avoid build errors
    python3 -m pip install --upgrade pip setuptools wheel --quiet
    # Now install rumps
    python3 -m pip install rumps --quiet
    # If that still failed, try with --user flag
    python3 -c "import rumps" 2>/dev/null || {
        echo "   Trying alternate install method..."
        python3 -m pip install rumps --user --quiet
    }
    echo "✅ Done!"
}

# ── Launch the app detached (so closing this window won't stop it) ───────────
echo "✅ Starting app — look for 💙 in your menu bar!"
echo ""
echo "   • To turn reminders on/off, click 💙 in the menu bar."
echo "   • To quit, click 💙 → Quit."
echo ""
echo "You can close this window. The app will keep running."
echo ""

nohup python3 wellness_app.py > /tmp/wellness_reminders.log 2>&1 &
APP_PID=$!
echo $APP_PID > /tmp/wellness_reminders.pid

# Brief pause then show a confirmation notification
sleep 2
osascript -e 'display notification "Click 💙 in your menu bar to manage reminders." with title "Wellness Reminders is running! ✅"'
