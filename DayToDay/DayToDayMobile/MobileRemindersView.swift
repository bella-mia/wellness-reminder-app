// MobileRemindersView.swift
// iOS Reminders tab

import SwiftUI

// MARK: - Main view

struct MobileRemindersView: View {
    @EnvironmentObject var manager: WellnessManager
    @State private var showManage = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(manager.reminders) { reminder in
                        MobileReminderCard(reminder: reminder)
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
            .navigationTitle("Day to Day")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Manage") { showManage = true }
                        .foregroundColor(Color(hex: "#48cae4"))
                }
            }
            .sheet(isPresented: $showManage) {
                MobileManageRemindersSheet()
                    .environmentObject(manager)
            }
        }
    }
}

// MARK: - Reminder card

struct MobileReminderCard: View {
    @EnvironmentObject var manager: WellnessManager
    let reminder: ReminderItem

    var body: some View {
        HStack(spacing: 14) {
            Text(reminder.emoji)
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Every \(reminder.intervalMinutes) min")
                    .font(.caption)
                    .foregroundColor(Color(hex: "#90e0ef"))
            }

            Spacer()

            // Fire button
            Button {
                if let index = manager.reminders.firstIndex(where: { $0.id == reminder.id }) {
                    manager.fireReminder(at: index)
                }
            } label: {
                Image(systemName: "bell.fill")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color(hex: reminder.colorHex).opacity(0.8))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color(hex: reminder.colorHex).opacity(0.25))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: reminder.colorHex).opacity(0.6), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Manage sheet

struct MobileManageRemindersSheet: View {
    @EnvironmentObject var manager: WellnessManager
    @Environment(\.dismiss) private var dismiss
    @State private var showAdd = false
    @State private var editingReminder: ReminderItem? = nil

    var body: some View {
        NavigationStack {
            List {
                ForEach(manager.reminders) { reminder in
                    HStack {
                        Text(reminder.emoji).font(.title2)
                        VStack(alignment: .leading) {
                            Text(reminder.name).foregroundColor(.primary)
                            Text("Every \(reminder.intervalMinutes) min").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button { editingReminder = reminder } label: {
                            Image(systemName: "pencil").foregroundColor(Color(hex: "#48cae4"))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { manager.removeReminder(id: manager.reminders[$0].id) }
                }
            }
            .navigationTitle("Manage Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                MobileEditReminderView(reminder: nil)
                    .environmentObject(manager)
            }
            .sheet(item: $editingReminder) { r in
                MobileEditReminderView(reminder: r)
                    .environmentObject(manager)
            }
        }
    }
}

// MARK: - Edit / Add reminder

struct MobileEditReminderView: View {
    @EnvironmentObject var manager: WellnessManager
    @Environment(\.dismiss) private var dismiss

    let reminder: ReminderItem?

    @State private var emoji: String = "💧"
    @State private var name: String = ""
    @State private var interval: Int = 30
    @State private var colorHex: String = "#0096c7"

    private let palette = ["#03045e","#023e8a","#0077b6","#0096c7","#00b4d8","#48cae4","#90e0ef","#ade8f4","#caf0f8"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Emoji") {
                    TextField("Emoji", text: $emoji)
                }
                Section("Name") {
                    TextField("Reminder name", text: $name)
                }
                Section("Interval") {
                    Stepper("Every \(interval) min", value: $interval, in: 5...240, step: 5)
                }
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 9), spacing: 8) {
                        ForEach(palette, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle().stroke(Color.white, lineWidth: colorHex == hex ? 3 : 0)
                                )
                                .onTapGesture { colorHex = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(reminder == nil ? "Add Reminder" : "Edit Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let r = reminder {
                            manager.updateReminder(id: r.id, name: name, emoji: emoji, intervalMinutes: interval)
                            manager.updateColor(id: r.id, colorHex: colorHex)
                        } else {
                            manager.addReminder(name: name, emoji: emoji,
                                               intervalMinutes: interval, colorHex: colorHex)
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let r = reminder {
                    emoji = r.emoji; name = r.name
                    interval = r.intervalMinutes; colorHex = r.colorHex
                }
            }
        }
    }
}
