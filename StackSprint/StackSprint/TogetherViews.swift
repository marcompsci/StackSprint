import SwiftUI

// MARK: - Social Hub (replaces the basic TogetherView content)

struct SocialHubView: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var socialAuth: SocialAuthManager
    @State private var completedQuestIDs: Set<String> = {
        Set(UserDefaults.standard.stringArray(forKey: "together.completedQuests") ?? [])
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                heroSection
                streakCard
                coopQuestsSection
                streakChallengeSection
                friendInviteSection
                privacyNote
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
            .frame(maxWidth: 640)
        }
        .navigationTitle("Together")
        .modifier(SprintTheme())
    }

    // MARK: – Hero

    private var heroSection: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("BETTER WITH A BUDDY")
                    .font(.caption.bold()).tracking(1.3).foregroundStyle(.mint)
                Text("Build a little.\nCheer loud.")
                    .font(.system(.title, design: .rounded).bold())
                Text("Learning with someone makes both of you more consistent. One friend doubles completion rates.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "heart.fill")
                .font(.system(size: 48)).foregroundStyle(.pink.opacity(0.75))
                .padding(.top, 4)
        }
    }

    // MARK: – Streak Card

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("YOUR STREAK", systemImage: "flame.fill")
                .font(.caption.bold()).foregroundStyle(.orange)

            HStack(spacing: 20) {
                VStack(spacing: 2) {
                    Text("\(store.currentStreak)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                    Text("days").font(.caption).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text(streakMessage).font(.subheadline)
                    ShareLink(item: streakShareText) {
                        Label("Share my streak", systemImage: "square.and.arrow.up")
                            .font(.subheadline.bold())
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                Spacer()
            }

            // Week mini-calendar
            weekCalendar
        }
        .padding(18)
        .background(Color.orange.opacity(0.07), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.orange.opacity(0.18)))
    }

    private var weekCalendar: some View {
        HStack(spacing: 8) {
            ForEach(last7Days, id: \.self) { date in
                let practiced = store.practicedDays.contains(date)
                VStack(spacing: 4) {
                    Circle()
                        .fill(practiced ? Color.orange : Color.secondary.opacity(0.2))
                        .frame(width: 28, height: 28)
                        .overlay {
                            if practiced {
                                Image(systemName: "flame.fill")
                                    .font(.caption2).foregroundStyle(.white)
                            }
                        }
                    Text(dayLabel(date))
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    private var last7Days: [String] {
        (0..<7).reversed().compactMap { offset in
            Calendar.current.date(byAdding: .day, value: -offset, to: Date())
        }.map { date in
            let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
            return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
        }
    }

    private func dayLabel(_ key: String) -> String {
        let parts = key.split(separator: "-")
        guard parts.count == 3, let d = Int(parts[2]) else { return "" }
        return String(d)
    }

    private var streakMessage: String {
        switch store.currentStreak {
        case 0: return "Start today — your buddy is waiting."
        case 1...2: return "Nice start! Build momentum."
        case 3...6: return "Growing strong — keep it up!"
        case 7...13: return "A full week! Share it."
        default: return "\(store.currentStreak) days! You're an inspiration."
        }
    }

    private var streakShareText: String {
        "I've been coding for \(store.currentStreak) day\(store.currentStreak == 1 ? "" : "s") in a row with StackSprint! 🔥 Come join me."
    }

    // MARK: – Co-op Quests

    private var coopQuestsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("CO-OP QUESTS", systemImage: "person.2.fill")
                .font(.caption.bold()).foregroundStyle(.mint)
            Text("Complete these together. Pick one, send the message, and compare notes after.")
                .font(.subheadline).foregroundStyle(.secondary)

            ForEach(CoopQuest.all) { quest in
                CoopQuestCard(
                    quest: quest,
                    done: completedQuestIDs.contains(quest.id)
                ) {
                    completedQuestIDs.insert(quest.id)
                    UserDefaults.standard.set(Array(completedQuestIDs),
                                              forKey: "together.completedQuests")
                }
            }
        }
    }

    // MARK: – Streak Challenge

    private var streakChallengeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("STREAK CHALLENGE", systemImage: "trophy.fill")
                .font(.caption.bold()).foregroundStyle(.yellow)
            Text("Issue a 7-day streak challenge. Both parties check in every day. First to miss a day buys the coffee.")
                .font(.subheadline).foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ShareLink(item: challengeText(days: 7)) {
                    Label("7-day challenge", systemImage: "bolt.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent).tint(.yellow)
                .foregroundStyle(.black)

                ShareLink(item: challengeText(days: 30)) {
                    Label("30-day challenge", systemImage: "flame.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent).tint(.orange)
                .foregroundStyle(.white)
            }
        }
        .padding(18)
        .background(Color.yellow.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.yellow.opacity(0.18)))
    }

    private func challengeText(days: Int) -> String {
        "I'm issuing you a \(days)-day coding streak challenge! 🏆\n\nPractice every day for \(days) days in StackSprint. I'm at \(store.currentStreak) days — can you beat me? Let's go."
    }

    // MARK: – Friend Invite

    private var friendInviteSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("INVITE A FRIEND", systemImage: "person.badge.plus")
                .font(.caption.bold()).foregroundStyle(.mint)
            Text("No in-app friend accounts yet — share through something you already use.")
                .font(.subheadline).foregroundStyle(.secondary)

            VStack(spacing: 10) {
                ShareLink(item: "I've been learning to code with StackSprint — \(store.completed.count) lessons done! It's free and has no hearts to lose. Come try it with me.") {
                    HStack {
                        Image(systemName: "square.and.arrow.up").font(.headline)
                        Text("Share StackSprint").font(.subheadline.bold())
                        Spacer()
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                ShareLink(item: progressShareText) {
                    HStack {
                        Image(systemName: "chart.bar.fill").font(.headline).foregroundStyle(.mint)
                        Text("Share my progress").font(.subheadline.bold())
                        Spacer()
                        Text("\(store.completed.count) lessons · \(store.currentStreak) day streak")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                if socialAuth.authProvider == .github, let user = socialAuth.gitHubUser {
                    ShareLink(item: "Check out my coding practice on GitHub: github.com/\(user.login) — I've been building with StackSprint!") {
                        HStack {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .font(.headline)
                            Text("Share GitHub activity").font(.subheadline.bold())
                            Spacer()
                            Text("@\(user.login)").font(.caption.monospaced()).foregroundStyle(.secondary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0.09, green: 0.09, blue: 0.09).opacity(0.5),
                                    in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var progressShareText: String {
        var parts = ["I've completed \(store.completed.count) coding lessons in StackSprint"]
        if store.currentStreak > 0 { parts.append("and I'm on a \(store.currentStreak)-day streak") }
        if socialAuth.authProvider == .github, let u = socialAuth.gitHubUser {
            parts.append("My practice pushes to github.com/\(u.login)")
        }
        return parts.joined(separator: " — ") + "."
    }

    // MARK: – Privacy

    private var privacyNote: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Private by default", systemImage: "lock.fill")
                .font(.caption.bold()).foregroundStyle(.secondary)
            Text("We do not upload contacts. All sharing goes through your device's share sheet. In-app friend accounts, live chat, and leaderboards are not included in this version.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Co-op Quest Model + Card

struct CoopQuest: Identifiable {
    let id: String
    let emoji: String
    let title: String
    let instruction: String
    let shareMessage: String

    static let all: [CoopQuest] = [
        CoopQuest(id: "python", emoji: "🐍", title: "Python buddy run",
                  instruction: "Practice Python for 5 minutes each. Share one thing you learned.",
                  shareMessage: "🐍 Python buddy quest: practice for 5 minutes then show each other something you made! I'm using StackSprint."),
        CoopQuest(id: "css", emoji: "🎨", title: "CSS colour swap",
                  instruction: "Pick a colour palette and share a screenshot of your design card.",
                  shareMessage: "🎨 CSS quest: build a colour palette for a mini-game. Share your screenshot! I'll share mine too."),
        CoopQuest(id: "quiz", emoji: "🔐", title: "Cybersecurity duel",
                  instruction: "Both take the cybersecurity quiz and compare scores.",
                  shareMessage: "🔐 Security quiz duel! Take the cybersecurity quiz in StackSprint and let's compare scores. Go!"),
        CoopQuest(id: "explain", emoji: "💬", title: "Explain it simply",
                  instruction: "Pick any concept card and explain it in plain English to your buddy.",
                  shareMessage: "Quiz: what is a variable? Explain it in one sentence without using the word 'container.' I'll share mine if you share yours 😄"),
        CoopQuest(id: "build", emoji: "🏗️", title: "Build something together",
                  instruction: "Each pick a Studio track. Share your finished code at the end.",
                  shareMessage: "🏗️ Co-op build! Pick a Studio mission in StackSprint and share your code when you're done. I'll share mine too."),
    ]
}

private struct CoopQuestCard: View {
    let quest: CoopQuest
    let done: Bool
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(quest.emoji).font(.title2)
                Text(quest.title).font(.headline)
                Spacer()
                if done {
                    Label("Done", systemImage: "checkmark.circle.fill")
                        .font(.caption.bold()).foregroundStyle(.mint)
                }
            }
            Text(quest.instruction).font(.subheadline).foregroundStyle(.secondary)
            HStack(spacing: 10) {
                ShareLink(item: quest.shareMessage) {
                    Label("Send quest", systemImage: "paperplane.fill")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderedProminent).tint(.mint)
                .foregroundStyle(Color(red: 0.06, green: 0.16, blue: 0.15))
                .controlSize(.small)

                if !done {
                    Button { onDone() } label: {
                        Label("Mark done", systemImage: "checkmark")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(16)
        .background(done ? Color.mint.opacity(0.06) : SprintPalette.card,
                    in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(done ? Color.mint.opacity(0.3) : Color.clear, lineWidth: 1.5))
    }
}
