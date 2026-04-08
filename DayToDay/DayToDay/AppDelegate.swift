// AppDelegate.swift

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "💙"
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    // Rebuild menu fresh each time so toggles always show current state
    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()

        let open = NSMenuItem(title: "💙  Open Dashboard", action: #selector(openDashboard), keyEquivalent: "")
        open.target = self
        menu.addItem(open)
        menu.addItem(.separator())

        let mgr = WellnessManager.shared
        for (i, r) in mgr.reminders.enumerated() {
            let check = r.isActive ? "✅" : "❌"
            let item = NSMenuItem(
                title: "\(r.emoji)  \(r.name) — every \(r.intervalMinutes) min  \(check)",
                action: #selector(toggleReminder(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = i
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let pomTitle = mgr.pomRunning
            ? "🍅  Pause (\(mgr.pomTimeString) left)"
            : "🍅  Start Pomodoro"
        let pom = NSMenuItem(title: pomTitle, action: #selector(togglePomodoro), keyEquivalent: "")
        pom.target = self
        menu.addItem(pom)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc func openDashboard() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }

    @objc func toggleReminder(_ sender: NSMenuItem) {
        let id = WellnessManager.shared.reminders[sender.tag].id
        DispatchQueue.main.async { WellnessManager.shared.toggle(id: id) }
    }

    @objc func togglePomodoro() {
        DispatchQueue.main.async { WellnessManager.shared.pomToggle() }
    }
}
