// ProfileView.swift

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var manager: WellnessManager
    @State private var editingName = false
    @State private var draftName = ""
    @State private var showEmojiPicker = false

    private let avatarEmojis = [
        "🐠","🐡","🐬","🐳","🦈","🐙","🦑","🦞","🦀","🐚",
        "🌊","🦭","🐧","🦉","🦊","🐺","🐻","🐼","🌸","🌺",
        "🍀","⭐","🌙","☀️","🌈","🔮","🎯","🎨","🎸","🌵"
    ]

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#03045e"), Color(hex: "#023e8a"), Color(hex: "#0077b6")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color(hex: "#48cae4").opacity(0.06))
                .frame(width: 400, height: 400)
                .offset(x: 300, y: -200)
                .blur(radius: 80)

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: { manager.showProfile = false }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                            Text("Dashboard")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "#48cae4"))
                    }
                    .buttonStyle(.plain)

                    Spacer()
                    Text("Profile")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                    Color.clear.frame(width: 90, height: 1)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 18)

                Divider().background(Color.white.opacity(0.08))

                HStack(alignment: .top, spacing: 0) {
                    // Left panel
                    VStack(spacing: 24) {
                        // Avatar
                        Button(action: { showEmojiPicker.toggle() }) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "#0096c7").opacity(0.25))
                                    .frame(width: 120, height: 120)
                                    .overlay(Circle().stroke(Color(hex: "#48cae4"), lineWidth: 2.5))
                                Text(manager.profileEmoji)
                                    .font(.system(size: 58))
                            }
                        }
                        .buttonStyle(.plain)

                        Text("Tap to change")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.3))
                            .offset(y: -16)

                        // Emoji picker grid
                        if showEmojiPicker {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hex: "#023e8a"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color(hex: "#48cae4").opacity(0.3), lineWidth: 1)
                                    )
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                                    ForEach(avatarEmojis, id: \.self) { emoji in
                                        Button(action: {
                                            manager.updateAvatar(emoji: emoji)
                                            showEmojiPicker = false
                                        }) {
                                            Text(emoji)
                                                .font(.system(size: 26))
                                                .frame(width: 40, height: 40)
                                                .background(manager.profileEmoji == emoji
                                                    ? Color(hex: "#48cae4").opacity(0.3)
                                                    : Color.clear)
                                                .cornerRadius(8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(12)
                            }
                            .transition(.scale(scale: 0.95).combined(with: .opacity))
                        }

                        // Name
                        VStack(spacing: 8) {
                            if editingName {
                                TextField("Your name", text: $draftName)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .onSubmit {
                                        manager.updateProfile(name: draftName)
                                        editingName = false
                                    }
                                HStack(spacing: 12) {
                                    Button("Cancel") { editingName = false }
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.4))
                                        .buttonStyle(.plain)
                                    Button("Save") {
                                        manager.updateProfile(name: draftName)
                                        editingName = false
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(hex: "#48cae4"))
                                    .buttonStyle(.plain)
                                }
                            } else {
                                Text(manager.profileName.isEmpty ? "Set your name" : manager.profileName)
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                    .foregroundColor(manager.profileName.isEmpty ? .white.opacity(0.3) : .white)
                                Button(action: {
                                    draftName = manager.profileName
                                    editingName = true
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "pencil").font(.system(size: 11))
                                        Text("Edit name").font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(Color(hex: "#48cae4").opacity(0.8))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if let since = manager.memberSince {
                            VStack(spacing: 4) {
                                Text("MEMBER SINCE")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.white.opacity(0.35))
                                    .kerning(2)
                                Text(dateFormatter.string(from: since))
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }

                        Spacer()
                    }
                    .frame(width: 280)
                    .padding(.top, 30)
                    .animation(.spring(response: 0.3), value: showEmojiPicker)

                    Divider().background(Color.white.opacity(0.08)).padding(.vertical, 24)

                    // Right panel — stats
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            HStack(spacing: 14) {
                                StreakCard(icon: "🔥", label: "Current Streak",
                                           value: "\(manager.currentStreak)",
                                           unit: manager.currentStreak == 1 ? "day" : "days",
                                           color: "#00b4d8")
                                StreakCard(icon: "⭐", label: "Best Streak",
                                           value: "\(manager.bestStreak)",
                                           unit: manager.bestStreak == 1 ? "day" : "days",
                                           color: "#48cae4")
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                Text("ALL-TIME STATS")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.white.opacity(0.4))
                                    .kerning(3)
                                HStack(spacing: 14) {
                                    StatTile(emoji: "🔔", label: "Reminders", value: "\(manager.totalRemindersAllTime)", color: "#0096c7")
                                    StatTile(emoji: "🍅", label: "Pomodoro Rounds", value: "\(manager.allTimePomRounds)", color: "#0077b6")
                                    StatTile(emoji: "📅", label: "Days Used", value: "\(manager.usageDates.count)", color: "#48cae4")
                                }
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                Text("REMINDER BREAKDOWN")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.white.opacity(0.4))
                                    .kerning(3)
                                VStack(spacing: 8) {
                                    ForEach(manager.reminders) { item in
                                        ReminderStatRow(item: item, count: manager.allTimeStats[item.id, default: 0])
                                    }
                                }
                            }

                            Spacer(minLength: 24)
                        }
                        .padding(30)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(width: 1060, height: 680)
    }
}

// MARK: - Streak card

struct StreakCard: View {
    let icon: String; let label: String; let value: String; let unit: String; let color: String
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: color).opacity(0.15))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: color).opacity(0.3), lineWidth: 1))
            VStack(spacing: 8) {
                Text(icon).font(.system(size: 32))
                Text(value).font(.system(size: 42, weight: .black, design: .rounded)).foregroundColor(Color(hex: color))
                Text(unit).font(.system(size: 13, weight: .bold)).foregroundColor(.white.opacity(0.5))
                Text(label).font(.system(size: 11, weight: .black)).foregroundColor(.white.opacity(0.35)).kerning(1)
            }
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Stat tile

struct StatTile: View {
    let emoji: String; let label: String; let value: String; let color: String
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16).fill(Color(hex: color).opacity(0.12))
            VStack(spacing: 6) {
                Text(emoji).font(.system(size: 24))
                Text(value).font(.system(size: 28, weight: .black, design: .rounded)).foregroundColor(Color(hex: color))
                Text(label).font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.4)).multilineTextAlignment(.center)
            }
            .padding(.vertical, 16).padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Reminder stat row

struct ReminderStatRow: View {
    let item: ReminderItem; let count: Int
    var body: some View {
        HStack(spacing: 12) {
            Text(item.emoji).font(.system(size: 20))
            Text(item.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
            Spacer()
            Text("\(count)").font(.system(size: 15, weight: .black, design: .rounded)).foregroundColor(Color(hex: item.colorHex))
            Text("times").font(.system(size: 12)).foregroundColor(.white.opacity(0.35))
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color(hex: item.colorHex).opacity(0.08))
        .cornerRadius(12)
    }
}
