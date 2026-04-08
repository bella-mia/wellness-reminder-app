// DayToDayMobileApp.swift
// iOS entry point

import SwiftUI

@main
struct DayToDayMobileApp: App {
    @StateObject private var manager = WellnessManager.shared

    var body: some Scene {
        WindowGroup {
            MobileContentView()
                .environmentObject(manager)
        }
    }
}
