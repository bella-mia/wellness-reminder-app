// MobileStatsView.swift
// iOS Stats tab

import SwiftUI

struct MobileStatsView: View {
    @EnvironmentObject var manager: WellnessManager

    var todayTotal: Int { manager.todayStats.values.reduce(0, +) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Today hero
                    VStack(spacing: 4) {
                        Text("\(todayTotal)")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("reminders today")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#90e0ef"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background(Color(hex: "#0096c7").opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    // Today breakdown
                    SectionHeader(title: "Today")
                    ForEach(manager.reminders) { r in
                        MobileStatRow(
                            emoji: r.emoji,
                            name: r.name,
                            count: manager.todayStats[r.id] ?? 0,
                            color: Color(hex: r.colorHex)
                        )
                    }

                    // All-time tiles
                    SectionHeader(title: "All Time")
                    HStack(spacing: 12) {
                        MobileStatTile(value: "\(manager.allTimeStats.values.reduce(0,+))", label: "Reminders")
                        MobileStatTile(value: "\(manager.allTimePomRounds)", label: "Pomodoros")
                        MobileStatTile(value: "\(manager.usageDates.count)", label: "Days active")
                    }

                    // All-time breakdown
                    ForEach(manager.reminders) { r in
                        MobileStatRow(
                            emoji: r.emoji,
                            name: r.name,
                            count: manager.allTimeStats[r.id] ?? 0,
                            color: Color(hex: r.colorHex)
                        )
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
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(Color(hex: "#48cae4"))
            Spacer()
        }
    }
}

struct MobileStatRow: View {
    let emoji: String
    let name: String
    let count: Int
    let color: Color

    var body: some View {
        HStack {
            Text(emoji).font(.title3)
            Text(name).foregroundColor(.white)
            Spacer()
            Text("\(count)")
                .font(.headline)
                .foregroundColor(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MobileStatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(Color(hex: "#90e0ef"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(hex: "#023e8a").opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
