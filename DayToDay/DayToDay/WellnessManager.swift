// WellnessManager.swift

import Foundation
import Combine
import UserNotifications

// MARK: - Reminder model

struct ReminderItem: Identifiable, Codable {
    let id: String
    let emoji: String
    let name: String
    var intervalMinutes: Int
    var isActive: Bool
    let notifTitle: String
    let notifBody: String
    let colorHex: String
}

// MARK: - Manager

class WellnessManager: ObservableObject {

    static let shared = WellnessManager()

    private let paletteColors = [
        "#00b4d8", "#023e8a", "#0077b6", "#48cae4",
        "#0096c7", "#90e0ef", "#03045e", "#ade8f4", "#caf0f8"
    ]

    private let defaultReminders: [ReminderItem] = [
        ReminderItem(id: "water",   emoji: "💧", name: "Water",
                     intervalMinutes: 60,  isActive: true,
                     notifTitle: "Hydration Time! 💧",
                     notifBody:  "Grab a glass of water — your body will thank you!",
                     colorHex: "#00b4d8"),
        ReminderItem(id: "blink",   emoji: "👁️", name: "Blink",
                     intervalMinutes: 10,  isActive: true,
                     notifTitle: "Remember to Blink! 👁️",
                     notifBody:  "Blink and look 20 ft away for 20 seconds.",
                     colorHex: "#0096c7"),
        ReminderItem(id: "posture", emoji: "🪑", name: "Posture",
                     intervalMinutes: 30,  isActive: true,
                     notifTitle: "Sit Up Straight! 🪑",
                     notifBody:  "Shoulders back, feet flat, screen at eye level!",
                     colorHex: "#0077b6"),
        ReminderItem(id: "break",   emoji: "☕", name: "Break",
                     intervalMinutes: 90,  isActive: true,
                     notifTitle: "Break Time! ☕",
                     notifBody:  "Step away 5 mins — stretch, walk, breathe. You've earned it!",
                     colorHex: "#48cae4"),
    ]

    // MARK: - Reminders & Pomodoro state
    @Published var reminders: [ReminderItem] = []
    @Published var pomSeconds: Int  = 25 * 60
    @Published var pomRunning: Bool = false
    @Published var pomOnBreak: Bool = false
    @Published var pomRound:   Int  = 1
    @Published var todayStats: [String: Int] = [:]

    // MARK: - Profile state
    @Published var showProfile: Bool = false
    @Published var profileName: String = ""
    @Published var profileEmoji: String = "🐠"
    @Published var usageDates: Set<String> = []
    @Published var allTimeStats: [String: Int] = [:]
    @Published var allTimePomRounds: Int = 0

    // MARK: - Computed profile properties

    var currentStreak: Int {
        let cal = Calendar.current
        let fmt = dateFormatter
        var streak = 0
        var date = Date()
        while usageDates.contains(fmt.string(from: date)) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }
        return streak
    }

    var bestStreak: Int {
        let cal = Calendar.current
        let fmt = dateFormatter
        let sorted = usageDates.compactMap { fmt.date(from: $0) }.sorted()
        var best = 0, current = 0
        var prevDate: Date? = nil
        for date in sorted {
            if let prev = prevDate,
               let expected = cal.date(byAdding: .day, value: 1, to: prev),
               cal.isDate(date, inSameDayAs: expected) {
                current += 1
            } else {
                current = 1
            }
            best = max(best, current)
            prevDate = date
        }
        return best
    }

    var memberSince: Date? {
        usageDates.compactMap { dateFormatter.date(from: $0) }.min()
    }

    var totalRemindersAllTime: Int {
        allTimeStats.values.reduce(0, +)
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }

    var pomTimeString: String {
        String(format: "%02d:%02d", pomSeconds / 60, pomSeconds % 60)
    }

    private let proverbs: [String] = [
        "The unexamined life is not worth living. — Socrates",
        "We suffer more in imagination than in reality. — Seneca",
        "You have power over your mind, not outside events. — Marcus Aurelius",
        "The obstacle is the path. — Zen proverb",
        "Be the change you wish to see in the world. — Gandhi",
        "Knowing yourself is the beginning of all wisdom. — Aristotle",
        "The only way out is through. — Robert Frost",
        "He who has a why to live can bear almost any how. — Nietzsche",
        "In the middle of difficulty lies opportunity. — Einstein",
        "Act as if what you do makes a difference. It does. — William James",
        "A ship in harbour is safe, but that's not what ships are for. — John Shedd",
        "Do one thing every day that scares you. — Eleanor Roosevelt",
        "Almost everything will work again if you unplug it for a few minutes — including you.",
        "Rest is not idleness. — John Lubbock",
        "Take care of your body. It's the only place you have to live.",
        "Small daily improvements lead to staggering long-term results.",
        "The body keeps the score. — Bessel van der Kolk",
        "Energy flows where attention goes.",
        "Between stimulus and response there is a space. In that space is our power. — Viktor Frankl",
        "Be patient with yourself. Nothing in nature blooms all year.",
    ]

    var todayProverb: String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return proverbs[day % proverbs.count]
    }

    private var reminderTimers: [String: Timer] = [:]
    private var pomTimer: Timer?
    private let kvStore = NSUbiquitousKeyValueStore.default

    private init() {
        reminders = loadReminders() ?? defaultReminders
        loadStats()
        loadProfile()
        setupiCloudSync()
        recordTodayUsage()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        startAllReminders()
    }

    // MARK: - iCloud Sync

    private func setupiCloudSync() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kvStore,
            queue: .main
        ) { [weak self] _ in
            self?.loadFromiCloud()
        }
        kvStore.synchronize()
        // Seed from iCloud on first launch if cloud has data
        loadFromiCloud()
    }

    private func saveToiCloud() {
        kvStore.set(profileName,  forKey: "cloud_profileName")
        kvStore.set(profileEmoji, forKey: "cloud_profileEmoji")
        if let data = try? JSONEncoder().encode(reminders) {
            kvStore.set(data, forKey: "cloud_reminders")
        }
        if let data = try? JSONEncoder().encode(Array(usageDates)) {
            kvStore.set(data, forKey: "cloud_usageDates")
        }
        if let data = try? JSONEncoder().encode(allTimeStats) {
            kvStore.set(data, forKey: "cloud_allTimeStats")
        }
        kvStore.set(Int64(allTimePomRounds), forKey: "cloud_allTimePomRounds")
        kvStore.synchronize()
    }

    private func loadFromiCloud() {
        if let name = kvStore.string(forKey: "cloud_profileName"), !name.isEmpty {
            profileName = name
        }
        if let emoji = kvStore.string(forKey: "cloud_profileEmoji"), !emoji.isEmpty {
            profileEmoji = emoji
        }
        if let data = kvStore.data(forKey: "cloud_reminders"),
           let items = try? JSONDecoder().decode([ReminderItem].self, from: data),
           !items.isEmpty {
            reminders = items
            saveReminders()
            for t in reminderTimers.values { t.invalidate() }
            reminderTimers.removeAll()
            startAllReminders()
        }
        if let data = kvStore.data(forKey: "cloud_usageDates"),
           let dates = try? JSONDecoder().decode([String].self, from: data) {
            usageDates = Set(dates)
        }
        if let data = kvStore.data(forKey: "cloud_allTimeStats"),
           let stats = try? JSONDecoder().decode([String: Int].self, from: data) {
            allTimeStats = stats
        }
        let cloudPom = Int(kvStore.longLong(forKey: "cloud_allTimePomRounds"))
        if cloudPom > allTimePomRounds { allTimePomRounds = cloudPom }
    }

    // MARK: - Profile

    func updateProfile(name: String) {
        profileName = name
        saveProfile()
    }

    func updateAvatar(emoji: String) {
        profileEmoji = emoji
        saveProfile()
    }

    func recordTodayUsage() {
        usageDates.insert(dateFormatter.string(from: Date()))
        saveProfile()
    }

    func saveProfile() {
        UserDefaults.standard.set(profileName, forKey: "profileName")
        UserDefaults.standard.set(profileEmoji, forKey: "profileEmoji")
        if let data = try? JSONEncoder().encode(Array(usageDates)) {
            UserDefaults.standard.set(data, forKey: "usageDates")
        }
        if let data = try? JSONEncoder().encode(allTimeStats) {
            UserDefaults.standard.set(data, forKey: "allTimeStats")
        }
        UserDefaults.standard.set(allTimePomRounds, forKey: "allTimePomRounds")
        saveToiCloud()
    }

    private func loadProfile() {
        profileName = UserDefaults.standard.string(forKey: "profileName") ?? ""
        profileEmoji = UserDefaults.standard.string(forKey: "profileEmoji") ?? "🐠"
        if let data = UserDefaults.standard.data(forKey: "usageDates"),
           let dates = try? JSONDecoder().decode([String].self, from: data) {
            usageDates = Set(dates)
        }
        if let data = UserDefaults.standard.data(forKey: "allTimeStats"),
           let stats = try? JSONDecoder().decode([String: Int].self, from: data) {
            allTimeStats = stats
        }
        allTimePomRounds = UserDefaults.standard.integer(forKey: "allTimePomRounds")
    }

    // MARK: - Reminders CRUD

    func addReminder(name: String, emoji: String, intervalMinutes: Int, colorHex: String? = nil) {
        let color = colorHex ?? paletteColors[reminders.count % paletteColors.count]
        let new = ReminderItem(
            id: UUID().uuidString,
            emoji: emoji,
            name: name,
            intervalMinutes: intervalMinutes,
            isActive: true,
            notifTitle: "\(emoji) \(name) Reminder",
            notifBody:  "Time for your \(name.lowercased()) reminder!",
            colorHex: color
        )
        reminders.append(new)
        saveReminders()
        if let i = reminders.firstIndex(where: { $0.id == new.id }) {
            startTimer(at: i)
        }
    }

    func removeReminder(id: String) {
        reminderTimers[id]?.invalidate()
        reminderTimers[id] = nil
        reminders.removeAll { $0.id == id }
        saveReminders()
    }

    func updateColor(id: String, colorHex: String) {
        guard let i = reminders.firstIndex(where: { $0.id == id }) else { return }
        let old = reminders[i]
        reminders[i] = ReminderItem(
            id: old.id, emoji: old.emoji, name: old.name,
            intervalMinutes: old.intervalMinutes, isActive: old.isActive,
            notifTitle: old.notifTitle, notifBody: old.notifBody,
            colorHex: colorHex
        )
        saveReminders()
    }

    func updateReminder(id: String, name: String, emoji: String, intervalMinutes: Int) {
        guard let i = reminders.firstIndex(where: { $0.id == id }) else { return }
        let old = reminders[i]
        reminders[i] = ReminderItem(
            id: old.id,
            emoji: emoji,
            name: name,
            intervalMinutes: intervalMinutes,
            isActive: old.isActive,
            notifTitle: "\(emoji) \(name) Reminder",
            notifBody:  "Time for your \(name.lowercased()) reminder!",
            colorHex: old.colorHex
        )
        saveReminders()
        if reminders[i].isActive { startTimer(at: i) }
    }

    // MARK: - Reminders timers

    func startAllReminders() {
        for i in reminders.indices { startTimer(at: i) }
    }

    func startTimer(at index: Int) {
        let id = reminders[index].id
        reminderTimers[id]?.invalidate()
        guard reminders[index].isActive else { return }
        let interval = TimeInterval(reminders[index].intervalMinutes * 60)
        reminderTimers[id] = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.fireReminder(at: index) }
        }
    }

    func fireReminder(at index: Int) {
        guard index < reminders.count, reminders[index].isActive else { return }
        let r = reminders[index]
        sendNotif(title: r.notifTitle, body: r.notifBody, id: r.id)
        todayStats[r.id, default: 0] += 1
        allTimeStats[r.id, default: 0] += 1
        saveStats()
        saveProfile()
    }

    func toggle(id: String) {
        guard let i = reminders.firstIndex(where: { $0.id == id }) else { return }
        reminders[i].isActive.toggle()
        if reminders[i].isActive { startTimer(at: i) } else { reminderTimers[id]?.invalidate() }
    }

    func setInterval(id: String, minutes: Int) {
        guard let i = reminders.firstIndex(where: { $0.id == id }) else { return }
        reminders[i].intervalMinutes = max(1, minutes)
        saveReminders()
        if reminders[i].isActive { startTimer(at: i) }
    }

    // MARK: - Pomodoro

    func pomToggle() {
        pomRunning.toggle()
        if pomRunning {
            pomTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                DispatchQueue.main.async { self?.pomTick() }
            }
        } else {
            pomTimer?.invalidate()
        }
    }

    func pomReset() {
        pomTimer?.invalidate()
        pomRunning = false
        pomOnBreak = false
        pomSeconds = 25 * 60
        pomRound   = 1
    }

    private func pomTick() {
        if pomSeconds > 0 { pomSeconds -= 1; return }
        pomTimer?.invalidate()
        pomRunning = false
        if pomOnBreak {
            pomOnBreak = false
            pomSeconds = 25 * 60
            pomRound  += 1
            allTimePomRounds += 1
            saveProfile()
            sendNotif(title: "Back to Focus! 🍅", body: "Round \(pomRound) — let's go!", id: "pom")
        } else {
            pomOnBreak = true
            pomSeconds = 5 * 60
            sendNotif(title: "Break Time! 🌿", body: "5 minutes — stretch and breathe.", id: "pom")
        }
    }

    // MARK: - Notifications

    private func sendNotif(title: String, body: String, id: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: "\(id)-\(Date().timeIntervalSince1970)",
                                  content: content, trigger: nil)
        )
    }

    // MARK: - Reminders persistence

    private func saveReminders() {
        if let data = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(data, forKey: "savedReminders")
        }
        saveToiCloud()
    }

    private func loadReminders() -> [ReminderItem]? {
        guard let data = UserDefaults.standard.data(forKey: "savedReminders"),
              let items = try? JSONDecoder().decode([ReminderItem].self, from: data) else { return nil }
        return items
    }

    // MARK: - Stats

    private func loadStats() {
        let today = Calendar.current.startOfDay(for: Date())
        if let last = UserDefaults.standard.object(forKey: "statsResetDate") as? Date,
           Calendar.current.isDate(last, inSameDayAs: today) {
            todayStats = (UserDefaults.standard.dictionary(forKey: "todayStats") as? [String: Int]) ?? [:]
        } else {
            todayStats = [:]
            UserDefaults.standard.set(today, forKey: "statsResetDate")
        }
    }

    private func saveStats() {
        UserDefaults.standard.set(todayStats, forKey: "todayStats")
    }
}
