import Combine
import SwiftUI

// MARK: - Season

struct Season: Equatable {
    let number: Int
    let startDate: Date

    static let durationDays = 70 // 10 weeks
    static let xpPerTier    = 200
    static let tiersTotal   = 10

    private static let catalog: [Season] = [
        Season(number: 1, startDate: isoDate("2026-10-01")),
        Season(number: 2, startDate: isoDate("2026-12-10")),
        Season(number: 3, startDate: isoDate("2027-02-18")),
        Season(number: 4, startDate: isoDate("2027-04-29")),
    ]

    static var current: Season {
        catalog.last(where: { $0.startDate <= Date() }) ?? catalog[0]
    }

    var endDate: Date {
        Calendar.current.date(byAdding: .day, value: Self.durationDays, to: startDate) ?? startDate
    }

    var progress: Double {
        let now  = Date()
        let span = endDate.timeIntervalSince(startDate)
        guard span > 0 else { return 1 }
        return min(1, max(0, now.timeIntervalSince(startDate) / span))
    }

    var weeksElapsed: Int {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return max(0, days / 7)
    }

    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0)
    }

    private static func isoDate(_ s: String) -> Date {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withFullDate]
        return f.date(from: s) ?? Date()
    }
}

// MARK: - Season Reward

struct SeasonReward: Identifiable, Codable {
    let id: String
    let tier: Int
    let name: String
    let icon: String
    let description: String
    let isPro: Bool

    static var all: [SeasonReward] {
        let prefix = "s\(Season.current.number)-"
        return _all.filter { $0.id.hasPrefix(prefix) }
    }

    private static let _all: [SeasonReward] = [
        // MARK: Season 1
        SeasonReward(id: "s1-t1-free",  tier: 1,  name: "Spark Badge",    icon: "⚡️", description: "A badge for your first sprint",         isPro: false),
        SeasonReward(id: "s1-t1-pro",   tier: 1,  name: "Dark Theme",     icon: "🌙", description: "Deep Space color scheme",               isPro: true),
        SeasonReward(id: "s1-t2-free",  tier: 2,  name: "100 XP Boost",   icon: "💎", description: "Instant 100 XP bonus",                  isPro: false),
        SeasonReward(id: "s1-t2-pro",   tier: 2,  name: "Neon Streak",    icon: "🔮", description: "Neon glow streak counter",               isPro: true),
        SeasonReward(id: "s1-t3-free",  tier: 3,  name: "Coder Title",    icon: "🏅", description: "\"Code Sprinter\" leaderboard title",    isPro: false),
        SeasonReward(id: "s1-t3-pro",   tier: 3,  name: "XP Multiplier",  icon: "✖️", description: "1.5× XP for one week",                  isPro: true),
        SeasonReward(id: "s1-t4-free",  tier: 4,  name: "Bit Sticker",    icon: "🤖", description: "Animated Bit mascot badge",              isPro: false),
        SeasonReward(id: "s1-t4-pro",   tier: 4,  name: "Galaxy Theme",   icon: "🌌", description: "Galaxy gradient UI theme",               isPro: true),
        SeasonReward(id: "s1-t5-free",  tier: 5,  name: "500 XP Boost",   icon: "🪙", description: "Mid-season XP reward",                   isPro: false),
        SeasonReward(id: "s1-t5-pro",   tier: 5,  name: "Pro Crown",      icon: "👑", description: "Gold crown on the leaderboard",          isPro: true),
        SeasonReward(id: "s1-t6-free",  tier: 6,  name: "Recall Champion",icon: "🧠", description: "\"Recall Champion\" title",              isPro: false),
        SeasonReward(id: "s1-t6-pro",   tier: 6,  name: "AI Extra Quota", icon: "✨", description: "Extra AI lesson generations",            isPro: true),
        SeasonReward(id: "s1-t7-free",  tier: 7,  name: "Bit Hoodie",     icon: "🎽", description: "Bit mascot in hoodie sticker",           isPro: false),
        SeasonReward(id: "s1-t7-pro",   tier: 7,  name: "Ocean Theme",    icon: "🌊", description: "Deep ocean UI color scheme",             isPro: true),
        SeasonReward(id: "s1-t8-free",  tier: 8,  name: "1000 XP Bonus",  icon: "💰", description: "Big XP bonus reward",                    isPro: false),
        SeasonReward(id: "s1-t8-pro",   tier: 8,  name: "Portfolio Pro",  icon: "📋", description: "Pro portfolio export template",          isPro: true),
        SeasonReward(id: "s1-t9-free",  tier: 9,  name: "Sprint Legend",  icon: "🏆", description: "\"Sprint Legend\" exclusive title",      isPro: false),
        SeasonReward(id: "s1-t9-pro",   tier: 9,  name: "Sunset Theme",   icon: "🌅", description: "Warm sunset gradient theme",             isPro: true),
        SeasonReward(id: "s1-t10-free", tier: 10, name: "Season 1 Crown", icon: "🎖️", description: "Exclusive Season 1 finisher badge",     isPro: false),
        SeasonReward(id: "s1-t10-pro",  tier: 10, name: "Infinite Boost", icon: "♾️", description: "2× XP until Season 2",                  isPro: true),
        // MARK: Season 2
        SeasonReward(id: "s2-t1-free",  tier: 1,  name: "Winter Spark",   icon: "❄️", description: "A badge for your first winter sprint",   isPro: false),
        SeasonReward(id: "s2-t1-pro",   tier: 1,  name: "Frost Theme",    icon: "🌨️", description: "Arctic frost color scheme",              isPro: true),
        SeasonReward(id: "s2-t2-free",  tier: 2,  name: "100 XP Boost",   icon: "💎", description: "Instant 100 XP bonus",                  isPro: false),
        SeasonReward(id: "s2-t2-pro",   tier: 2,  name: "Ice Streak",     icon: "🔵", description: "Ice blue streak counter",                isPro: true),
        SeasonReward(id: "s2-t3-free",  tier: 3,  name: "Dev Title",      icon: "🏅", description: "\"Winter Dev\" leaderboard title",       isPro: false),
        SeasonReward(id: "s2-t3-pro",   tier: 3,  name: "XP Multiplier",  icon: "✖️", description: "1.5× XP for one week",                  isPro: true),
        SeasonReward(id: "s2-t4-free",  tier: 4,  name: "Bit Scarf",      icon: "🧣", description: "Animated Bit mascot with scarf",         isPro: false),
        SeasonReward(id: "s2-t4-pro",   tier: 4,  name: "Aurora Theme",   icon: "🌌", description: "Aurora borealis gradient UI",            isPro: true),
        SeasonReward(id: "s2-t5-free",  tier: 5,  name: "500 XP Boost",   icon: "🪙", description: "Mid-season XP reward",                   isPro: false),
        SeasonReward(id: "s2-t5-pro",   tier: 5,  name: "Silver Crown",   icon: "🥈", description: "Silver crown on the leaderboard",        isPro: true),
        SeasonReward(id: "s2-t6-free",  tier: 6,  name: "Code Frost",     icon: "🧊", description: "\"Code Frost\" title",                   isPro: false),
        SeasonReward(id: "s2-t6-pro",   tier: 6,  name: "AI Extra Quota", icon: "✨", description: "Extra AI lesson generations",            isPro: true),
        SeasonReward(id: "s2-t7-free",  tier: 7,  name: "Bit Coat",       icon: "🧥", description: "Bit mascot in winter coat sticker",      isPro: false),
        SeasonReward(id: "s2-t7-pro",   tier: 7,  name: "Night Theme",    icon: "🌙", description: "Deep night sky color scheme",            isPro: true),
        SeasonReward(id: "s2-t8-free",  tier: 8,  name: "1000 XP Bonus",  icon: "💰", description: "Big XP bonus reward",                    isPro: false),
        SeasonReward(id: "s2-t8-pro",   tier: 8,  name: "Portfolio Pro",  icon: "📋", description: "Pro portfolio export template",          isPro: true),
        SeasonReward(id: "s2-t9-free",  tier: 9,  name: "Winter Legend",  icon: "🏆", description: "\"Winter Legend\" exclusive title",      isPro: false),
        SeasonReward(id: "s2-t9-pro",   tier: 9,  name: "Blizzard Theme", icon: "🌨️", description: "Blizzard animated theme",                isPro: true),
        SeasonReward(id: "s2-t10-free", tier: 10, name: "Season 2 Crown", icon: "🎖️", description: "Exclusive Season 2 finisher badge",     isPro: false),
        SeasonReward(id: "s2-t10-pro",  tier: 10, name: "Infinite Boost", icon: "♾️", description: "2× XP until Season 3",                  isPro: true),
    ]
}

// MARK: - Daily Mission

struct DailyMission: Identifiable, Codable, Equatable {
    let id: String
    let emoji: String
    let title: String
    let description: String
    let goal: Int
    let xpReward: Int
    let type: MissionType

    enum MissionType: String, Codable { case lessons, recall, streak, quiz }

    static let pool: [DailyMission] = [
        DailyMission(id: "dm-lessons-3",  emoji: "📚", title: "Daily Dose",      description: "Complete 3 lessons",               goal: 3,  xpReward: 30,  type: .lessons),
        DailyMission(id: "dm-lessons-5",  emoji: "🔥", title: "Power Learner",   description: "Complete 5 lessons",               goal: 5,  xpReward: 60,  type: .lessons),
        DailyMission(id: "dm-recall-3",   emoji: "🧠", title: "Memory Master",   description: "Get 3 correct recall answers",     goal: 3,  xpReward: 45,  type: .recall),
        DailyMission(id: "dm-recall-5",   emoji: "🎯", title: "Recall Sprint",   description: "Get 5 correct recall answers",     goal: 5,  xpReward: 75,  type: .recall),
        DailyMission(id: "dm-streak-1",   emoji: "📅", title: "Keep It Going",   description: "Maintain your streak today",       goal: 1,  xpReward: 20,  type: .streak),
        DailyMission(id: "dm-quiz-3",     emoji: "✅", title: "Quiz Quickshot",  description: "Answer 3 adaptive quiz questions", goal: 3,  xpReward: 40,  type: .quiz),
        DailyMission(id: "dm-lessons-10", emoji: "🚀", title: "Full Sprint",     description: "Complete 10 lessons today",        goal: 10, xpReward: 120, type: .lessons),
        DailyMission(id: "dm-recall-10",  emoji: "💡", title: "Recall Ace",      description: "Get 10 correct recall answers",   goal: 10, xpReward: 150, type: .recall),
    ]

    // Deterministic rotation: 3 missions per day based on day-of-year
    static func todaysMissions() -> [DailyMission] {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let n = pool.count
        let i0 =  day      % n
        let i1 = (day + 2) % n
        let i2 = (day + 5) % n
        return [pool[i0], pool[i1], pool[i2]]
    }
}

// MARK: - Season Store

@MainActor final class SeasonStore: ObservableObject {
    @Published private(set) var tier: Int = 0
    @Published private(set) var tierXP: Int = 0
    @Published private(set) var claimedRewards: Set<String> = []
    @Published private(set) var completedMissions: Set<String> = []
    @Published private(set) var bonusXPAccumulated: Int = 0

    var season: Season { Season.current }

    private enum Keys {
        static let tier      = "ss.season.tier"
        static let tierXP    = "ss.season.tierXP"
        static let claimed   = "ss.season.claimedRewards"
        static let missions  = "ss.season.completedMissions"
        static let bonusXP   = "ss.season.bonusXP"
        static let seasonNum = "ss.season.number"
    }

    init() { load() }

    var totalXP: Int { tier * Season.xpPerTier + tierXP }

    var progressInCurrentTier: Double {
        guard tier < Season.tiersTotal else { return 1 }
        return Double(tierXP) / Double(Season.xpPerTier)
    }

    var dailyMissions: [DailyMission] { DailyMission.todaysMissions() }

    func missionCompleted(_ mission: DailyMission) -> Bool {
        completedMissions.contains(todayKey(mission.id))
    }

    func rewardUnlocked(_ reward: SeasonReward) -> Bool { tier >= reward.tier }
    func rewardClaimed(_ reward: SeasonReward)  -> Bool { claimedRewards.contains(reward.id) }

    // MARK: Mutations

    func recordXP(_ xp: Int) {
        guard tier < Season.tiersTotal else { return }
        var remaining = xp + tierXP
        while remaining >= Season.xpPerTier && tier < Season.tiersTotal {
            remaining -= Season.xpPerTier
            tier = min(tier + 1, Season.tiersTotal)
            HapticManager.shared.notification(.success)
        }
        tierXP = tier < Season.tiersTotal ? remaining : Season.xpPerTier
        bonusXPAccumulated += xp
        save()
    }

    func completeMission(_ mission: DailyMission) {
        let key = todayKey(mission.id)
        guard !completedMissions.contains(key) else { return }
        completedMissions.insert(key)
        recordXP(mission.xpReward)
        save()
    }

    func claimReward(_ reward: SeasonReward) {
        guard rewardUnlocked(reward), !rewardClaimed(reward) else { return }
        claimedRewards.insert(reward.id)
        HapticManager.shared.notification(.success)
        save()
    }

    // MARK: Persistence

    private func todayKey(_ missionID: String) -> String {
        let d = ISO8601DateFormatter()
        d.formatOptions = [.withFullDate]
        return "\(d.string(from: Date()))-\(missionID)"
    }

    private func load() {
        let ud = UserDefaults.standard
        let savedSeasonNum = ud.integer(forKey: Keys.seasonNum)
        // Season transition: reset all progress when a new season begins
        if savedSeasonNum != 0 && savedSeasonNum != season.number {
            tier = 0; tierXP = 0; bonusXPAccumulated = 0
            claimedRewards = []; completedMissions = []
            save()
            return
        }
        tier    = ud.integer(forKey: Keys.tier)
        tierXP  = ud.integer(forKey: Keys.tierXP)
        bonusXPAccumulated = ud.integer(forKey: Keys.bonusXP)
        if let data = ud.data(forKey: Keys.claimed),
           let set = try? JSONDecoder().decode(Set<String>.self, from: data) {
            claimedRewards = set
        }
        if let data = ud.data(forKey: Keys.missions),
           let set = try? JSONDecoder().decode(Set<String>.self, from: data) {
            completedMissions = set
        }
    }

    private func save() {
        let ud = UserDefaults.standard
        ud.set(tier,          forKey: Keys.tier)
        ud.set(tierXP,        forKey: Keys.tierXP)
        ud.set(bonusXPAccumulated, forKey: Keys.bonusXP)
        ud.set(season.number, forKey: Keys.seasonNum)
        if let data = try? JSONEncoder().encode(claimedRewards) { ud.set(data, forKey: Keys.claimed) }
        if let data = try? JSONEncoder().encode(completedMissions) { ud.set(data, forKey: Keys.missions) }
    }
}

// MARK: - Season View

struct SeasonView: View {
    @EnvironmentObject var seasonStore: SeasonStore
    @EnvironmentObject var premiumStore: PremiumStore

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                seasonHeader
                dailyMissionsSection
                rewardTrackSection
            }
            .padding(20)
        }
        .navigationTitle("Season \(seasonStore.season.number)")
        .navigationBarTitleDisplayMode(.inline)
        .modifier(SprintTheme())
    }

    // MARK: Season Header

    private var seasonHeader: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SEASON \(seasonStore.season.number)")
                        .font(.system(.caption, design: .monospaced, weight: .heavy))
                        .tracking(3).foregroundStyle(.orange)
                    Text("Code Sprint Pass")
                        .font(.title2.bold())
                    Text("\(seasonStore.season.daysRemaining) days remaining")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Tier \(seasonStore.tier)")
                        .font(.headline.bold()).foregroundStyle(.orange)
                    Text("\(seasonStore.tierXP)/\(Season.xpPerTier) XP")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            // Season progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08)).frame(height: 10)
                    Capsule().fill(LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * seasonStore.season.progress, height: 10)
                }
            }
            .frame(height: 10)

            // Tier progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Tier \(seasonStore.tier) Progress").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(seasonStore.progressInCurrentTier * 100))%").font(.caption.bold()).foregroundStyle(.orange)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.08)).frame(height: 6)
                        Capsule().fill(Color.orange)
                            .frame(width: geo.size.width * seasonStore.progressInCurrentTier, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(18)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: Daily Missions

    private var dailyMissionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Today's Missions", systemImage: "flag.fill")
                .font(.headline).foregroundStyle(.orange)

            ForEach(seasonStore.dailyMissions) { mission in
                MissionRow(mission: mission,
                           isCompleted: seasonStore.missionCompleted(mission)) {
                    seasonStore.completeMission(mission)
                }
            }
        }
    }

    // MARK: Reward Track

    private var rewardTrackSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Reward Track", systemImage: "gift.fill")
                .font(.headline).foregroundStyle(.purple)
            if !premiumStore.isPro {
                Text("Upgrade to Pro to unlock the premium reward track.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            ForEach(1...Season.tiersTotal, id: \.self) { tier in
                let freeReward = SeasonReward.all.first(where: { $0.tier == tier && !$0.isPro })
                let proReward  = SeasonReward.all.first(where: { $0.tier == tier && $0.isPro })
                TierRow(tier: tier,
                        freeReward: freeReward,
                        proReward: proReward,
                        currentTier: seasonStore.tier,
                        claimedFree: freeReward.map { seasonStore.rewardClaimed($0) } ?? false,
                        claimedPro:  proReward.map  { seasonStore.rewardClaimed($0) } ?? false,
                        isPro: premiumStore.isPro) {
                    if let r = freeReward { seasonStore.claimReward(r) }
                } claimPro: {
                    if let r = proReward { seasonStore.claimReward(r) }
                }
            }
        }
    }
}

// MARK: - Mission Row

private struct MissionRow: View {
    let mission: DailyMission
    let isCompleted: Bool
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(mission.emoji).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(mission.title).font(.subheadline.bold())
                Text(mission.description).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if isCompleted {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.mint).font(.title3)
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("+\(mission.xpReward) XP").font(.caption.bold()).foregroundStyle(.orange)
                    Button("Done") { withAnimation { onComplete() } }
                        .font(.caption.bold()).buttonStyle(.borderedProminent).tint(.orange)
                        .controlSize(.mini)
                }
            }
        }
        .padding(14)
        .background(isCompleted ? Color.mint.opacity(0.07) : SprintPalette.card,
                    in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mission.title): \(mission.description), \(mission.xpReward) XP. \(isCompleted ? "Completed" : "Not completed")")
    }
}

// MARK: - Tier Row

private struct TierRow: View {
    let tier: Int
    let freeReward: SeasonReward?
    let proReward: SeasonReward?
    let currentTier: Int
    let claimedFree: Bool
    let claimedPro: Bool
    let isPro: Bool
    let claimFree: () -> Void
    let claimPro: () -> Void

    var unlocked: Bool { currentTier >= tier }

    var body: some View {
        HStack(spacing: 0) {
            // Tier indicator
            VStack(spacing: 4) {
                ZStack {
                    Circle().fill(unlocked ? Color.orange : Color.white.opacity(0.08)).frame(width: 34, height: 34)
                    if unlocked {
                        Text("\(tier)").font(.caption.bold()).foregroundStyle(.white)
                    } else {
                        Image(systemName: "lock.fill").font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 44)

            // Free reward
            if let free = freeReward {
                rewardCell(reward: free, claimed: claimedFree, isPro: false, action: claimFree)
            }

            // Pro reward
            if let pro = proReward {
                rewardCell(reward: pro, claimed: claimedPro, isPro: true, action: claimPro)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func rewardCell(reward: SeasonReward, claimed: Bool, isPro: Bool, action: @escaping () -> Void) -> some View {
        let locked = !unlocked || (isPro && !self.isPro)
        VStack(spacing: 4) {
            Text(reward.icon).font(.title3)
            Text(reward.name).font(.system(size: 10, weight: .medium)).multilineTextAlignment(.center).lineLimit(2)
            if claimed {
                Text("Claimed").font(.system(size: 9)).foregroundStyle(.mint)
            } else if locked {
                Image(systemName: isPro ? "crown.fill" : "lock.fill")
                    .font(.system(size: 10)).foregroundStyle(isPro ? .yellow.opacity(0.6) : .secondary)
            } else {
                Button("Claim") { action() }
                    .font(.system(size: 10, weight: .bold))
                    .buttonStyle(.borderedProminent).tint(isPro ? .purple : .orange).controlSize(.mini)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(claimed ? Color.mint.opacity(0.07) : locked ? Color.white.opacity(0.03) : SprintPalette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isPro ? Color.purple.opacity(0.3) : Color.orange.opacity(0.2), lineWidth: 1)
        )
        .padding(4)
        .opacity(locked ? 0.5 : 1)
    }
}
