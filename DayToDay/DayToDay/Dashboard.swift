// Dashboard.swift

import SwiftUI

// MARK: - Confetti

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let shape: Int   // 0 = rect, 1 = circle, 2 = triangle
    let xDrift: CGFloat
    let delay: Double
}

struct ConfettiView: View {
    let particles: [ConfettiParticle]
    @State private var fallen = false

    var body: some View {
        GeometryReader { geo in
            ForEach(particles) { p in
                Group {
                    if p.shape == 1 {
                        Circle().fill(p.color).frame(width: p.size, height: p.size)
                    } else if p.shape == 2 {
                        Triangle().fill(p.color).frame(width: p.size, height: p.size)
                    } else {
                        Rectangle().fill(p.color)
                            .frame(width: p.size * 0.6, height: p.size)
                            .rotationEffect(.degrees(p.rotation))
                    }
                }
                .offset(
                    x: p.x + (fallen ? p.xDrift * 60 : 0),
                    y: fallen ? geo.size.height + 40 : -20
                )
                .animation(
                    .easeIn(duration: Double.random(in: 1.8...2.8))
                    .delay(p.delay),
                    value: fallen
                )
                .opacity(fallen ? 0 : 1)
                .animation(
                    .easeIn(duration: 0.4)
                    .delay(p.delay + 1.6),
                    value: fallen
                )
            }
        }
        .onAppear { fallen = true }
        .allowsHitTesting(false)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

// MARK: - Root Dashboard

struct Dashboard: View {
    @EnvironmentObject var manager: WellnessManager
    @State private var confettiParticles: [ConfettiParticle] = []
    @State private var confettiID = UUID()
    @State private var showManageReminders = false
    @State private var pomodoroExpanded = true

    let confettiColors: [Color] = [
        Color(hex: "#03045e"), Color(hex: "#023e8a"), Color(hex: "#0077b6"),
        Color(hex: "#0096c7"), Color(hex: "#00b4d8"), Color(hex: "#48cae4"),
        Color(hex: "#90e0ef"), Color(hex: "#ade8f4"), Color(hex: "#caf0f8")
    ]

    func launchConfetti() {
        confettiParticles = (0..<80).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...1060),
                color: confettiColors.randomElement()!,
                size: CGFloat.random(in: 8...18),
                rotation: Double.random(in: 0...360),
                shape: Int.random(in: 0...2),
                xDrift: CGFloat.random(in: -1...1),
                delay: Double.random(in: 0...0.6)
            )
        }
        confettiID = UUID()
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "#03045e"), Color(hex: "#023e8a"), Color(hex: "#0077b6")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Soft background blobs
            Circle()
                .fill(Color(hex: "#48cae4").opacity(0.07))
                .frame(width: 350, height: 350)
                .offset(x: -180, y: -220)
                .blur(radius: 60)
            Circle()
                .fill(Color(hex: "#0096c7").opacity(0.08))
                .frame(width: 300, height: 300)
                .offset(x: 220, y: 300)
                .blur(radius: 60)

            HStack(alignment: .top, spacing: 18) {
                // Left column: header, proverb, stats
                VStack(spacing: 14) {
                    AppHeader(onConfetti: launchConfetti)
                    ProverbCard(text: manager.todayProverb)
                    SectionLabel("📊 TODAY'S STATS")
                    StatsCard()
                    Spacer()
                }
                .frame(width: 340)

                // Right column: reminders + pomodoro
                VStack(spacing: 14) {
                    // Reminders header with manage button
                    HStack {
                        Text("✨ REMINDERS")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.white.opacity(0.45))
                            .kerning(3)
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 1)
                        Button(action: { showManageReminders = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("MANAGE")
                                    .font(.system(size: 10, weight: .black))
                                    .kerning(1)
                            }
                            .foregroundColor(Color(hex: "#48cae4"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(hex: "#48cae4").opacity(0.15))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    RemindersGrid()

                    // Pomodoro header with collapse toggle
                    HStack {
                        Text("🍅 POMODORO")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.white.opacity(0.45))
                            .kerning(3)
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 1)
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                pomodoroExpanded.toggle()
                            }
                        }) {
                            Image(systemName: pomodoroExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.45))
                        }
                        .buttonStyle(.plain)
                    }

                    if pomodoroExpanded {
                        PomodoroCard()
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .padding(22)

            // Confetti overlay
            if !confettiParticles.isEmpty {
                ConfettiView(particles: confettiParticles)
                    .id(confettiID)
                    .frame(width: 1060, height: 680)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: 1060, height: 680)
        .sheet(isPresented: $showManageReminders) {
            ManageRemindersSheet()
                .environmentObject(manager)
        }
    }
}

// MARK: - Manage Reminders Sheet

struct ManageRemindersSheet: View {
    @EnvironmentObject var manager: WellnessManager
    @Environment(\.dismiss) var dismiss
    @State private var itemToEdit: ReminderItem? = nil
    @State private var showAddNew = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Manage Reminders")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Button("Done") { dismiss() }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "#48cae4"))
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)

            Divider().background(Color.white.opacity(0.1))

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(manager.reminders) { item in
                        ReminderRow(item: item) {
                            itemToEdit = item
                        } onDelete: {
                            manager.removeReminder(id: item.id)
                        }
                    }

                    // Add button
                    Button(action: { showAddNew = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            Text("Add Reminder")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(Color(hex: "#48cae4"))
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Color(hex: "#48cae4").opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "#48cae4").opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
            }
        }
        .background(Color(hex: "#03045e"))
        .frame(width: 420, height: 480)
        .sheet(item: $itemToEdit) { item in
            EditReminderView(item: item)
                .environmentObject(manager)
        }
        .sheet(isPresented: $showAddNew) {
            EditReminderView(item: nil)
                .environmentObject(manager)
        }
    }
}

// MARK: - Reminder Row (in manage sheet)

struct ReminderRow: View {
    let item: ReminderItem
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(item.emoji)
                .font(.system(size: 26))
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Every \(item.intervalMinutes) min")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.45))
            }

            Spacer()

            HStack(spacing: 6) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#48cae4"))
                        .frame(width: 30, height: 30)
                        .background(Color(hex: "#48cae4").opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#0096c7").opacity(0.8))
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.07))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: item.colorHex).opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Edit / Add Reminder View

struct EditReminderView: View {
    @EnvironmentObject var manager: WellnessManager
    @Environment(\.dismiss) var dismiss

    let item: ReminderItem?

    @State private var name: String
    @State private var emoji: String
    @State private var intervalMinutes: Int
    @State private var selectedColor: String

    let palette = ["#00b4d8","#0096c7","#0077b6","#023e8a","#03045e",
                   "#48cae4","#90e0ef","#ade8f4","#caf0f8"]

    init(item: ReminderItem?) {
        self.item = item
        _name            = State(initialValue: item?.name ?? "")
        _emoji           = State(initialValue: item?.emoji ?? "💊")
        _intervalMinutes = State(initialValue: item?.intervalMinutes ?? 60)
        _selectedColor   = State(initialValue: item?.colorHex ?? "#0096c7")
    }

    var isNew: Bool { item == nil }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text(isNew ? "New Reminder" : "Edit Reminder")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Button("Cancel") { dismiss() }
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)

            Divider().background(Color.white.opacity(0.1))

            VStack(spacing: 20) {
                // Emoji + Name row
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("EMOJI")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.white.opacity(0.4))
                            .kerning(2)
                        TextField("", text: $emoji)
                            .textFieldStyle(.plain)
                            .font(.system(size: 28))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .frame(width: 58, height: 52)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("NAME")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.white.opacity(0.4))
                            .kerning(2)
                        TextField("e.g. Medication", text: $name)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(12)
                    }
                }

                // Interval stepper
                VStack(alignment: .leading, spacing: 6) {
                    Text("INTERVAL")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.white.opacity(0.4))
                        .kerning(2)
                    HStack {
                        Text("Every \(intervalMinutes) minutes")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        HStack(spacing: 10) {
                            Button {
                                if intervalMinutes > 5 { intervalMinutes -= 5 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(Color(hex: "#48cae4"))
                            }
                            .buttonStyle(.plain)

                            Text("\(intervalMinutes)")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .frame(minWidth: 36)
                                .multilineTextAlignment(.center)

                            Button {
                                intervalMinutes += 5
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(Color(hex: "#48cae4"))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                }

                // Color picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("COLOR")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.white.opacity(0.4))
                        .kerning(2)
                    HStack(spacing: 8) {
                        ForEach(palette, id: \.self) { hex in
                            Button(action: { selectedColor = hex }) {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == hex ? 2.5 : 0)
                                    )
                                    .shadow(color: selectedColor == hex ? Color(hex: hex) : .clear, radius: 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                }

                // Save button
                Button(action: {
                    if let existing = item {
                        manager.updateReminder(id: existing.id, name: name, emoji: emoji, intervalMinutes: intervalMinutes)
                        manager.updateColor(id: existing.id, colorHex: selectedColor)
                    } else {
                        manager.addReminder(name: name, emoji: emoji, intervalMinutes: intervalMinutes, colorHex: selectedColor)
                    }
                    dismiss()
                }) {
                    Text(isNew ? "Add Reminder" : "Save Changes")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "#03045e"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            name.isEmpty
                            ? Color(hex: "#48cae4").opacity(0.3)
                            : Color(hex: "#48cae4")
                        )
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
                .disabled(name.isEmpty)
            }
            .padding(24)
        }
        .background(Color(hex: "#023e8a"))
        .frame(width: 360)
    }
}

// MARK: - App header

struct AppHeader: View {
    @EnvironmentObject var manager: WellnessManager
    var onConfetti: () -> Void = {}

    var body: some View {
        HStack(alignment: .center) {
            Text("DAY TO DAY")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "#90e0ef"), Color(hex: "#caf0f8")],
                        startPoint: .leading, endPoint: .trailing
                    )
                )

            Spacer()

            // Confetti button
            Button(action: onConfetti) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#48cae4").opacity(0.2))
                        .frame(width: 46, height: 46)
                    Text("🎉").font(.system(size: 24))
                }
            }
            .buttonStyle(.plain)

            // Profile button
            Button(action: { manager.showProfile = true }) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#0096c7").opacity(0.3))
                        .frame(width: 46, height: 46)
                    Text(manager.profileEmoji)
                        .font(.system(size: 26))
                }
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Section label

struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        HStack {
            Text(text)
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.white.opacity(0.45))
                .kerning(3)
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
        }
    }
}

// MARK: - Proverb card

struct ProverbCard: View {
    let text: String
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#0096c7"), Color(hex: "#0077b6")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            Text("❝")
                .font(.system(size: 100, weight: .black))
                .foregroundColor(.black.opacity(0.07))
                .offset(x: -4, y: -20)
            VStack(alignment: .leading, spacing: 8) {
                Text("DAILY WISDOM")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.white.opacity(0.6))
                    .kerning(3)
                Text(text)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Reminders grid

struct RemindersGrid: View {
    @EnvironmentObject var manager: WellnessManager
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            ForEach(manager.reminders) { item in
                ReminderCard(item: item)
            }
        }
    }
}

// MARK: - Reminder card

struct ReminderCard: View {
    @EnvironmentObject var manager: WellnessManager
    let item: ReminderItem
    @State private var expanded = false

    var body: some View {
        let cardColor = Color(hex: item.colorHex)

        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(cardColor.opacity(item.isActive ? 1.0 : 0.3))

            Text(item.emoji)
                .font(.system(size: 72))
                .opacity(0.12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .offset(x: 14, y: 14)
                .clipped()

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Text(item.emoji).font(.system(size: 32))
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { item.isActive },
                        set: { _ in manager.toggle(id: item.id) }
                    ))
                    .toggleStyle(.switch)
                    .scaleEffect(0.82)
                    .tint(Color.white.opacity(0.9))
                }

                Text(item.name.uppercased())
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Button {
                    withAnimation(.spring(response: 0.3)) { expanded.toggle() }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "clock").font(.system(size: 11, weight: .semibold))
                        Text("Every \(item.intervalMinutes) min").font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.22))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                if expanded {
                    HStack {
                        Text("Interval").font(.system(size: 11, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                        Spacer()
                        HStack(spacing: 12) {
                            Button {
                                manager.setInterval(id: item.id, minutes: item.intervalMinutes - 5)
                            } label: {
                                Image(systemName: "minus.circle.fill").font(.system(size: 24)).foregroundColor(.white)
                            }
                            .buttonStyle(.plain)

                            Text("\(item.intervalMinutes)")
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .frame(minWidth: 30)

                            Button {
                                manager.setInterval(id: item.id, minutes: item.intervalMinutes + 5)
                            } label: {
                                Image(systemName: "plus.circle.fill").font(.system(size: 24)).foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(16)
        }
        .animation(.easeInOut(duration: 0.2), value: item.isActive)
    }
}

// MARK: - Pomodoro card

struct PomodoroCard: View {
    @EnvironmentObject var manager: WellnessManager

    var body: some View {
        let colors: [Color] = manager.pomOnBreak
            ? [Color(hex: "#0077b6"), Color(hex: "#0096c7")]
            : [Color(hex: "#03045e"), Color(hex: "#023e8a")]

        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))

            Text(manager.pomOnBreak ? "🌿" : "🍅")
                .font(.system(size: 90))
                .opacity(0.12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .offset(x: 10, y: 10)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(manager.pomOnBreak ? "BREAK 🌿" : "FOCUS 🍅")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white.opacity(0.65))
                        .kerning(2)

                    Text(manager.pomTimeString)
                        .font(.system(size: 56, weight: .black, design: .monospaced))
                        .foregroundColor(.white)

                    HStack(spacing: 6) {
                        ForEach(1...4, id: \.self) { i in
                            Circle()
                                .fill(i <= (manager.pomRound % 5 == 0 ? 4 : manager.pomRound % 5)
                                      ? Color.white : Color.white.opacity(0.25))
                                .frame(width: 8, height: 8)
                        }
                        Text("Round \(manager.pomRound)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }
                .padding(.leading, 24)

                Spacer()

                VStack(spacing: 14) {
                    Button { manager.pomToggle() } label: {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.22)).frame(width: 60, height: 60)
                            Image(systemName: manager.pomRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 24)).foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)

                    Button { manager.pomReset() } label: {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.14)).frame(width: 40, height: 40)
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 16)).foregroundColor(.white.opacity(0.85))
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.trailing, 24)
            }
            .padding(.vertical, 24)
        }
        .animation(.easeInOut(duration: 0.6), value: manager.pomOnBreak)
    }
}

// MARK: - Stats card

struct StatsCard: View {
    @EnvironmentObject var manager: WellnessManager

    var total: Int { manager.todayStats.values.reduce(0, +) }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.11), lineWidth: 1)
                )

            VStack(spacing: 12) {
                HStack {
                    Text("Reminders fired today")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.55))
                    Spacer()
                    Text("\(total) total")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(manager.reminders) { item in
                        HStack(spacing: 6) {
                            Text(item.emoji).font(.system(size: 16))
                            Text("\(manager.todayStats[item.id, default: 0])")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundColor(Color(hex: item.colorHex))
                            Text(item.name)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.45))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color(hex: item.colorHex).opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
            .padding(18)
        }
    }
}
