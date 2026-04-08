// WellnessApp.swift

import SwiftUI

// MARK: - Root navigation view

struct RootView: View {
    @EnvironmentObject var manager: WellnessManager

    var body: some View {
        ZStack {
            if manager.showProfile {
                ProfileView()
                    .environmentObject(manager)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .trailing)
                    ))
            } else {
                Dashboard()
                    .environmentObject(manager)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .leading)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: manager.showProfile)
        .frame(width: 1060, height: 680)
    }
}

@main
struct WellnessApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var manager = WellnessManager.shared

    var body: some Scene {
        WindowGroup("DaytoDay") {
            RootView()
                .environmentObject(manager)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
