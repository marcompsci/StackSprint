import Combine
import SwiftUI
import UserNotifications

// MARK: - Notification Manager

@MainActor final class NotificationManager: ObservableObject {
    @Published private(set) var permissionGranted = false
    @AppStorage("notifications.enabled") var enabled = true
    @AppStorage("notifications.dailyHour") var dailyHour = 19
    @AppStorage("notifications.dailyMinute") var dailyMinute = 0

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
        scheduleComeback(afterHours: 48, id: "comeback.48h",
                         title: "Your streak is at risk \u{26A0}\u{FE0F}",
                         body: "Open StackSprint for just one lesson today to keep your streak alive.")
        scheduleComeback(afterHours: 168, id: "comeback.7d",
                         title: "Bite misses you \u{1F916}",
                         body: "It\u{2019}s been a week. One tiny lesson is all it takes to come back.")
    }

    // MARK: – Daily reminder (repeating calendar trigger)

    func scheduleDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["daily.reminder"])
        guard enabled, permissionGranted else { return }
        var components = DateComponents()
        components.hour = dailyHour
        components.minute = dailyMinute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Time to build something tiny \u{1F525}"
        content.body = dailyMessages.randomElement() ?? dailyMessages[0]
        content.sound = .default
        center.add(UNNotificationRequest(identifier: "daily.reminder", content: content, trigger: trigger))
    }

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
        // Reset comeback timers so they count from NOW
        scheduleComeback(afterHours: 48, id: "comeback.48h",
                         title: "Your streak is at risk \u{26A0}\u{FE0F}",
                         body: "Open StackSprint for just one lesson today to keep your streak alive.")
        scheduleComeback(afterHours: 168, id: "comeback.7d",
                         title: "Bite misses you \u{1F916}",
                         body: "It\u{2019}s been a week. One tiny lesson is all it takes to come back.")
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
        case 25: return "Quarter done! \u{1F389}"
        case 50: return "Halfway there! \u{1F4AA}"
        case 75: return "75% complete! \u{1F31F}"
        default: return "All lessons complete! \u{1F3C6}"
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
                Text("A daily reminder at your chosen time, plus a nudge if you miss 2 or more days.")
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
