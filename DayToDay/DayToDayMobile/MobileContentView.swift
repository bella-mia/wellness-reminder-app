// MobileContentView.swift
// iOS tab bar shell

import SwiftUI

struct MobileContentView: View {
    var body: some View {
        TabView {
            MobileRemindersView()
                .tabItem { Label("Reminders", systemImage: "bell.fill") }

            MobileStatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }

            MobileProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(Color(hex: "#48cae4"))
        .preferredColorScheme(.dark)
    }
}
