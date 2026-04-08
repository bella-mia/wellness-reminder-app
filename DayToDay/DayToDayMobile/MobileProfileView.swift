// MobileProfileView.swift
// iOS Profile tab

import SwiftUI

struct MobileProfileView: View {
    @EnvironmentObject var manager: WellnessManager
    @State private var editingName = false
    @State private var draftName = ""
    @State private var showEmojiPicker = false

    private let emojiOptions = ["🧘","🏃","💪","🌊","🐠","🐡","🐬","🐳","🦈","🐙",
                                "🌸","🌻","🌴","🦋","🐝","🌈","⭐️","🔥","💎","🧠",
                                "🎯","🚀","🎵","📚","🌙","☀️","❄️","🍃","🐾","✨"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Avatar
                    Button { showEmojiPicker = true } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#0096c7"), Color(hex: "#03045e")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 110, height: 110)
                            Text(manager.profileEmoji)
                                .font(.system(size: 52))
                        }
                    }

                    // Name
                    if editingName {
                        HStack {
                            TextField("Your name", text: $draftName)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 220)
                            Button("Save") {
                                manager.profileName = draftName
                                manager.saveProfile()
                                editingName = false
                            }
                            .foregroundColor(Color(hex: "#48cae4"))
                            Button("Cancel") { editingName = false }
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack(spacing: 8) {
                            Text(manager.profileName.isEmpty ? "Add your name" : manager.profileName)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            Button { draftName = manager.profileName; editingName = true } label: {
                                Image(systemName: "pencil")
                                    .foregroundColor(Color(hex: "#48cae4"))
                            }
                        }
                    }

                    Text("Member since \(manager.memberSince)")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#90e0ef"))

                    // Streaks
                    HStack(spacing: 16) {
                        MobileStreakCard(value: manager.currentStreak, label: "Day Streak 🔥")
                        MobileStreakCard(value: manager.bestStreak, label: "Best Streak ⭐️")
                    }

                    // All-time stats tiles
                    HStack(spacing: 12) {
                        MobileStatTile(value: "\(manager.allTimeStats.values.reduce(0,+))", label: "Reminders")
                        MobileStatTile(value: "\(manager.allTimePomRounds)", label: "Pomodoros")
                        MobileStatTile(value: "\(manager.usageDates.count)", label: "Days active")
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color(hex: "#03045e"), Color(hex: "#0077b6")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showEmojiPicker) {
                EmojiPickerSheet(selection: $manager.profileEmoji)
                    .presentationDetents([.medium])
            }
        }
    }
}

struct MobileStreakCard: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(Color(hex: "#90e0ef"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(hex: "#023e8a").opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct EmojiPickerSheet: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss

    private let options = ["🧘","🏃","💪","🌊","🐠","🐡","🐬","🐳","🦈","🐙",
                           "🌸","🌻","🌴","🦋","🐝","🌈","⭐️","🔥","💎","🧠",
                           "🎯","🚀","🎵","📚","🌙","☀️","❄️","🍃","🐾","✨"]

    var body: some View {
        VStack(spacing: 16) {
            Text("Choose Avatar")
                .font(.headline)
                .padding(.top)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(options, id: \.self) { e in
                    Text(e)
                        .font(.system(size: 36))
                        .padding(6)
                        .background(selection == e ? Color(hex: "#0096c7").opacity(0.4) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture {
                            selection = e
                            dismiss()
                        }
                }
            }
            .padding()
        }
    }
}
