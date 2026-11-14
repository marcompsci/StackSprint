import Combine
import SwiftUI
import UserNotifications

// MARK: - Notification Manager

@MainActor final class NotificationManager: ObservableObject {
    @Published private(set) var permissionGranted = false
    @AppStorage("notifications.enabled") var enabled = true
    @AppStorage("notifications.dailyHour") var dailyHour = 19
    @AppStorage("notifications.dailyMinute") var dailyMinute = 0
    @AppStorage("notifications.streakNudge") var streakNudge = true
    @AppStorage("notifications.weeklyRecap") var weeklyRecap = true

    private let center = UNUserNotificationCenter.current()

    init() { Task { await checkStatus() } }

    // MARK: – Permission

    func requestPermission() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            permissionGranted = granted
            if granted { scheduleAll() }
        } catch {}
    }

    func checkStatus() async {
        let settings = await center.notificationSettings()
        permissionGranted = settings.authorizationStatus == .authorized
    }

    // MARK: – Schedule all

    func scheduleAll() {
        guard enabled, permissionGranted else { return }
        scheduleDailyReminder()
        // A streak lasts until the end of the day after you practice, so the nudge
        // comes a day later, while there's still time to keep it.
        center.removePendingNotificationRequests(withIdentifiers: ["comeback.48h", "comeback.24h"])
        if streakNudge { scheduleComeback(afterHours: 23, id: "comeback.24h",
                         title: "Keep your streak going",
                         body: "One small lesson or review before midnight keeps it alive.") }
        scheduleComeback(afterHours: 168, id: "comeback.7d",
                         title: "Pick up where you left off",
                         body: "Your next lesson takes about two minutes.")
    }

    // MARK: – Daily reminder (repeating calendar trigger)

    /// Whether today already counts as practiced; set by the app so reminders skip it.
    var practicedToday: () -> Bool = { false }
    /// The lesson "Continue" would open, so the next reminder can name it.
    var nextLessonTitle: () -> String? = { nil }

    /// One reminder a day for the next week at the chosen time, skipping today once
    /// you've practiced. (A repeating trigger can't skip a day, so it nagged even
    /// after you'd done your lesson.) Rescheduled on launch and after every practice.
    func scheduleDailyReminder() {
        let ids = ["daily.reminder"] + (0..<Self.reminderDays).map { "daily.reminder.\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        guard enabled, permissionGranted else { return }
        for (offset, date) in Self.reminderDates(hour: dailyHour, minute: dailyMinute, now: Date(),
                                                  skipToday: practicedToday()).enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Daily practice"
            // The first reminder names your actual next lesson; later ones may be out of date by then.
            if offset == 0, let next = nextLessonTitle() {
                content.body = "Next up: \(next). It takes about two minutes."
            } else {
                content.body = dailyMessages.randomElement() ?? dailyMessages[0]
            }
            content.sound = .default
            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            center.add(UNNotificationRequest(identifier: "daily.reminder.\(offset)", content: content, trigger: trigger))
        }
    }

    nonisolated static let reminderDays = 7

    /// The next reminder times, today included only if it's still ahead and not yet practiced.
    nonisolated static func reminderDates(hour: Int, minute: Int, now: Date, skipToday: Bool,
                                          calendar: Calendar = .current) -> [Date] {
        let today = calendar.startOfDay(for: now)
        return (0...reminderDays).compactMap { offset -> Date? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                  let time = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) else { return nil }
            if offset == 0 && (skipToday || time <= now) { return nil }
            return time
        }
        .prefix(reminderDays)
        .map { $0 }
    }

    // MARK: – Weekly recap

    /// A short recap on the last evening of the week. It's rescheduled after every practice,
    /// so the numbers are current as of your latest lesson.
    func scheduleWeeklyRecap(lessons: Int, streak: Int) {
        center.removePendingNotificationRequests(withIdentifiers: ["weekly.recap"])
        guard enabled, weeklyRecap, permissionGranted, lessons > 0,
              let fire = Self.weeklyRecapDate(now: Date()) else { return }
        let content = UNMutableNotificationContent()
        content.title = "Your week in StackSprint"
        content.body = "\(lessons) \(lessons == 1 ? "lesson" : "lessons") this week"
            + (streak > 1 ? " and a \(streak)-day streak." : ".") + " Nice work."
        content.sound = .default
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        center.add(UNNotificationRequest(identifier: "weekly.recap", content: content,
                                         trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)))
    }

    /// 6 pm on the last day of the current week, if that's still ahead.
    nonisolated static func weeklyRecapDate(now: Date, calendar: Calendar = .current) -> Date? {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now),
              let lastDay = calendar.date(byAdding: .day, value: -1, to: week.end),
              let fire = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: lastDay),
              fire > now else { return nil }
        return fire
    }

    func cancelWeeklyRecap() { center.removePendingNotificationRequests(withIdentifiers: ["weekly.recap"]) }

    // MARK: – Comeback (one-shot, rescheduled after practice)

    private func scheduleComeback(afterHours hours: Double, id: String, title: String, body: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: hours * 3600, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    // MARK: – Called after each practice session

    func refreshAfterPractice() {
        guard enabled, permissionGranted else { return }
        scheduleDailyReminder()
        // Reset comeback timers so they count from NOW
        center.removePendingNotificationRequests(withIdentifiers: ["comeback.48h", "comeback.24h"])
        if streakNudge { scheduleComeback(afterHours: 23, id: "comeback.24h",
                         title: "Keep your streak going",
                         body: "One small lesson or review before midnight keeps it alive.") }
        scheduleComeback(afterHours: 168, id: "comeback.7d",
                         title: "Pick up where you left off",
                         body: "Your next lesson takes about two minutes.")
    }

    // MARK: – Milestone alert (call when crossing 25 / 50 / 75 / 100 %)

    func fireMilestone(pct: Int) {
        guard enabled, permissionGranted else { return }
        let id = "milestone.\(pct)"
        center.getPendingNotificationRequests { [weak self] pending in
            // Only fire once per milestone
            guard let self, !pending.contains(where: { $0.identifier == id }) else { return }
            let content = UNMutableNotificationContent()
            content.title = self.milestoneTitle(pct)
            content.body = self.milestoneBody(pct)
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            self.center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }

    // MARK: – Cancel

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    // MARK: – Messages

    private let dailyMessages = [
        "One tiny lesson keeps the spark going. Bite\u{2019}s ready.",
        "Your coding streak is worth 2 minutes. Come build something.",
        "Small steps stack up. What will you learn today?",
        "Bite\u{2019}s waiting with a new hint. Come say hi.",
        "Your future self will thank you for today\u{2019}s one lesson.",
        "Open one card. That\u{2019}s all it takes.",
        "Even 90 seconds of practice counts. Let\u{2019}s go."
    ]

    private func milestoneTitle(_ pct: Int) -> String {
        switch pct {
        case 25: return "25% of lessons done"
        case 50: return "Halfway through"
        case 75: return "75% of lessons done"
        default: return "Every lesson done"
        }
    }

    private func milestoneBody(_ pct: Int) -> String {
        switch pct {
        case 25: return "You\u{2019}ve finished 25% of StackSprint. Keep building."
        case 50: return "Past the halfway mark! You\u{2019}re on a roll."
        case 75: return "Almost there. Just a few cards left."
        default: return "You completed every lesson in StackSprint. Now build something real."
        }
    }
}

// MARK: - Notification Settings View (embed in AccountView)

struct NotificationSettingsSection: View {
    @ObservedObject var notifications: NotificationManager
    @State private var showTimePicker = false

    var body: some View {
        Section {
            if !notifications.permissionGranted {
                Button {
                    Task { await notifications.requestPermission() }
                } label: {
                    Label("Enable notifications", systemImage: "bell.badge")
                }
            } else {
                Toggle("Daily practice reminder", isOn: $notifications.enabled)
                    .onChange(of: notifications.enabled) { _, on in
                        if on { notifications.scheduleAll() } else { notifications.cancelAll() }
                    }

                if notifications.enabled {
                    Toggle("Streak reminder", isOn: $notifications.streakNudge)
                        .onChange(of: notifications.streakNudge) { _, _ in notifications.refreshAfterPractice() }
                    Toggle("Weekly recap", isOn: $notifications.weeklyRecap)
                        .onChange(of: notifications.weeklyRecap) { _, on in
                            if !on { notifications.cancelWeeklyRecap() }
                        }
                    Button {
                        showTimePicker.toggle()
                    } label: {
                        HStack {
                            Label("Reminder time", systemImage: "clock")
                            Spacer()
                            Text(reminderTimeLabel)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            if notifications.permissionGranted {
                Text("Daily reminders skip days you've already practiced. The streak reminder comes the day after you practice, while there's still time; the weekly recap comes on the last evening of the week. Everything is scheduled on your phone.")
            }
        }
        .sheet(isPresented: $showTimePicker) {
            NotificationTimePicker(notifications: notifications, isPresented: $showTimePicker)
        }
    }

    private var reminderTimeLabel: String {
        let h = notifications.dailyHour
        let m = notifications.dailyMinute
        let suffix = h < 12 ? "AM" : "PM"
        let hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        return String(format: "%d:%02d %@", hour12, m, suffix)
    }
}

private struct NotificationTimePicker: View {
    @ObservedObject var notifications: NotificationManager
    @Binding var isPresented: Bool
    @State private var selection = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                DatePicker("Reminder time", selection: $selection, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()

                Text("You\u{2019}ll get a daily practice reminder at this time.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal)
            }
            .navigationTitle("Set reminder time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let comps = Calendar.current.dateComponents([.hour, .minute], from: selection)
                        notifications.dailyHour = comps.hour ?? 19
                        notifications.dailyMinute = comps.minute ?? 0
                        notifications.scheduleDailyReminder()
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
        .onAppear {
            var comps = DateComponents()
            comps.hour = notifications.dailyHour
            comps.minute = notifications.dailyMinute
            selection = Calendar.current.date(from: comps) ?? Date()
        }
        .presentationDetents([.medium])
    }
}
