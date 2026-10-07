import Combine
import GameKit
import SwiftUI

// MARK: - Room Packet

struct RoomPacket: Codable {
    enum Kind: String, Codable { case score, finish, ready }
    var kind: Kind
    var score: Int
    var displayName: String
}

// MARK: - Study Room Manager

@MainActor final class StudyRoomManager: NSObject, ObservableObject {
    static let shared = StudyRoomManager()

    enum RoomState { case idle, authenticating, matchmaking, racing, finished }

    @Published var state: RoomState = .idle
    @Published var isAuthenticated = false
    @Published var pendingAuthVC: UIViewController?
    @Published var myScore = 0
    @Published var opponentName = ""
    @Published var opponentScore = 0
    @Published var opponentDone = false
    @Published var raceQuestions: [Lesson] = []
    @Published var currentIndex = 0
    @Published var winner: String?
    @Published var errorMessage: String?

    private var match: GKMatch?
    static let questionsPerRound = 5

    var myDisplayName: String { GKLocalPlayer.local.displayName }

    // MARK: Auth

    func authenticate() {
        guard !GKLocalPlayer.local.isAuthenticated else { isAuthenticated = true; return }
        state = .authenticating
        GKLocalPlayer.local.authenticateHandler = { [weak self] vc, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let vc {
                    self.pendingAuthVC = vc
                    return
                }
                self.pendingAuthVC = nil
                if let error {
                    self.errorMessage = error.localizedDescription
                    self.state = .idle
                    return
                }
                self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                self.state = .idle
            }
        }
    }

    // MARK: Matchmaking

    func findMatch(lessons: [Lesson]) {
        guard GKLocalPlayer.local.isAuthenticated else { authenticate(); return }
        state = .matchmaking
        errorMessage = nil

        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2

        GKMatchmaker.shared().findMatch(for: request) { [weak self] foundMatch, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    self.errorMessage = error.localizedDescription
                    self.state = .idle
                    return
                }
                guard let foundMatch else { self.state = .idle; return }
                foundMatch.delegate = self
                self.match = foundMatch
                self.raceQuestions = Array(lessons.shuffled().prefix(Self.questionsPerRound))
                self.myScore = 0
                self.opponentScore = 0
                self.opponentDone = false
                self.currentIndex = 0
                self.winner = nil
                self.state = .racing
                self.sendPacket(RoomPacket(kind: .ready, score: 0, displayName: self.myDisplayName))
            }
        }
    }

    func cancelMatchmaking() {
        GKMatchmaker.shared().cancel()
        match?.disconnect()
        match = nil
        state = .idle
    }

    // MARK: Race Actions

    func answerCorrect() {
        myScore += 1
        sendPacket(RoomPacket(kind: .score, score: myScore, displayName: myDisplayName))
        advance()
    }

    func answerWrong() {
        advance()
    }

    private func advance() {
        currentIndex += 1
        if currentIndex >= Self.questionsPerRound {
            sendPacket(RoomPacket(kind: .finish, score: myScore, displayName: myDisplayName))
            tryResolveWinner()
        }
    }

    private func tryResolveWinner() {
        let myDone = currentIndex >= Self.questionsPerRound
        guard myDone && opponentDone else { return }
        if myScore > opponentScore {
            winner = myDisplayName
        } else if opponentScore > myScore {
            winner = opponentName.isEmpty ? "Opponent" : opponentName
        } else {
            winner = "Tie!"
        }
        state = .finished
        HapticManager.shared.notification(.success)
    }

    // MARK: Networking

    private func sendPacket(_ packet: RoomPacket) {
        guard let match, let data = try? JSONEncoder().encode(packet) else { return }
        try? match.sendData(toAllPlayers: data, with: .reliable)
    }

    func resetToIdle() {
        match?.disconnect()
        match = nil
        state = .idle
        myScore = 0
        opponentScore = 0
        currentIndex = 0
        winner = nil
        opponentName = ""
        opponentDone = false
    }
}

// MARK: - GKMatchDelegate

extension StudyRoomManager: GKMatchDelegate {
    nonisolated func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        guard let packet = try? JSONDecoder().decode(RoomPacket.self, from: data) else { return }
        Task { @MainActor in
            opponentName = player.displayName
            switch packet.kind {
            case .ready:
                break
            case .score:
                opponentScore = packet.score
            case .finish:
                opponentScore = packet.score
                opponentDone = true
                tryResolveWinner()
            }
        }
    }

    nonisolated func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        if state == .disconnected {
            Task { @MainActor in
                self.errorMessage = "\(player.displayName) disconnected."
                self.match = nil
                self.state = .idle
            }
        }
    }
}

// MARK: - Auth VC Wrapper

struct GameCenterAuthSheet: UIViewControllerRepresentable {
    let viewController: UIViewController

    func makeUIViewController(context: Context) -> UIViewController { viewController }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

// MARK: - Study Room View

struct StudyRoomView: View {
    @EnvironmentObject var store: LearningStore
    @ObservedObject var room = StudyRoomManager.shared

    var body: some View {
        NavigationStack {
            Group {
                switch room.state {
                case .idle:         idleView
                case .authenticating: authenticatingView
                case .matchmaking:  matchmakingView
                case .racing:       racingView
                case .finished:     finishedView
                }
            }
            .navigationTitle("Study Room")
            .navigationBarTitleDisplayMode(.inline)
            .modifier(SprintTheme())
        }
        .sheet(item: Binding(
            get: { room.pendingAuthVC.map { IdentifiableVC($0) } },
            set: { _ in room.pendingAuthVC = nil }
        )) { wrapper in
            GameCenterAuthSheet(viewController: wrapper.vc)
        }
        .onAppear { if !room.isAuthenticated { room.authenticate() } }
    }

    // MARK: Idle

    private var idleView: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "person.2.fill")
                .font(.system(size: 60)).foregroundStyle(.blue)
            VStack(spacing: 8) {
                Text("Study Room").font(.title.bold())
                Text("Race a friend through 5 coding flashcards.\nWhoever gets the most right wins!")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if !room.isAuthenticated {
                Button("Connect with Game Center") { room.authenticate() }
                    .buttonStyle(.borderedProminent).tint(.blue)
                    .accessibilityLabel("Connect with Game Center to play multiplayer")
            } else {
                Button {
                    if let lessons = store.curriculum?.lessons {
                        room.findMatch(lessons: lessons)
                    }
                } label: {
                    Label("Find a Match", systemImage: "magnifyingglass")
                        .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent).tint(.blue)
            }
            if let err = room.errorMessage {
                Text(err).font(.caption).foregroundStyle(.red).multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(32)
    }

    private var authenticatingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView().scaleEffect(1.5)
            Text("Connecting to Game Center…").font(.subheadline).foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: Matchmaking

    private var matchmakingView: some View {
        VStack(spacing: 24) {
            Spacer()
            ProgressView().scaleEffect(1.5).tint(.blue)
            Text("Finding a match…").font(.title3.bold())
            Text("Waiting for another player to join").font(.subheadline).foregroundStyle(.secondary)
            Button("Cancel") { room.cancelMatchmaking() }.buttonStyle(.bordered).tint(.red)
            Spacer()
        }
    }

    // MARK: Racing

    @ViewBuilder private var racingView: some View {
        if room.raceQuestions.indices.contains(room.currentIndex) {
            let lesson = room.raceQuestions[room.currentIndex]
            VStack(spacing: 0) {
                scoreHeader
                    .padding([.horizontal, .top], 20)
                Spacer()
                VStack(spacing: 16) {
                    Text("Question \(room.currentIndex + 1) of \(StudyRoomManager.questionsPerRound)")
                        .font(.caption.bold()).foregroundStyle(.secondary)
                    Text(lesson.term)
                        .font(.title.bold()).multilineTextAlignment(.center)
                    Text(lesson.clue)
                        .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .padding(24)
                .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 22))
                .padding(.horizontal, 24)
                Spacer()
                HStack(spacing: 14) {
                    Button("I knew it ✓") {
                        HapticManager.shared.impact()
                        room.answerCorrect()
                    }
                    .buttonStyle(.borderedProminent).tint(.mint).font(.headline)
                    .frame(maxWidth: .infinity)

                    Button("Not yet ✗") {
                        HapticManager.shared.impact()
                        room.answerWrong()
                    }
                    .buttonStyle(.borderedProminent).tint(.orange.opacity(0.8)).font(.headline)
                    .frame(maxWidth: .infinity)
                }
                .padding(24)
            }
        } else {
            VStack { ProgressView(); Text("Waiting for results…").font(.subheadline).foregroundStyle(.secondary) }
        }
    }

    private var scoreHeader: some View {
        HStack {
            VStack {
                Text("You").font(.caption.bold()).foregroundStyle(.secondary)
                Text("\(room.myScore)").font(.title.bold()).foregroundStyle(.mint)
            }
            .frame(maxWidth: .infinity)
            Text("vs").font(.headline).foregroundStyle(.secondary)
            VStack {
                Text(room.opponentName.isEmpty ? "Opponent" : room.opponentName)
                    .font(.caption.bold()).foregroundStyle(.secondary).lineLimit(1)
                Text("\(room.opponentScore)").font(.title.bold()).foregroundStyle(.orange)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Finished

    private var finishedView: some View {
        VStack(spacing: 28) {
            Spacer()
            let isWinner = room.winner == room.myDisplayName
            let isTie    = room.winner == "Tie!"

            Image(systemName: isTie ? "equal.circle.fill" : isWinner ? "trophy.fill" : "star.fill")
                .font(.system(size: 70))
                .foregroundStyle(isTie ? .yellow : isWinner ? .yellow : .orange)

            VStack(spacing: 8) {
                Text(isTie ? "It's a Tie!" : isWinner ? "You Won!" : "\(room.winner ?? "Opponent") Wins!")
                    .font(.largeTitle.bold())
                HStack(spacing: 24) {
                    VStack {
                        Text("You").font(.caption).foregroundStyle(.secondary)
                        Text("\(room.myScore)/\(StudyRoomManager.questionsPerRound)").font(.title2.bold()).foregroundStyle(.mint)
                    }
                    VStack {
                        Text(room.opponentName.isEmpty ? "Opponent" : room.opponentName)
                            .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        Text("\(room.opponentScore)/\(StudyRoomManager.questionsPerRound)").font(.title2.bold()).foregroundStyle(.orange)
                    }
                }
            }
            Button("Play Again") {
                HapticManager.shared.impact()
                if let lessons = store.curriculum?.lessons { room.findMatch(lessons: lessons) }
            }
            .buttonStyle(.borderedProminent).tint(.blue).font(.headline)
            Button("Exit Room") { room.resetToIdle() }.foregroundStyle(.secondary)
            Spacer()
        }
        .padding(32)
    }
}

// MARK: - Helpers

private struct IdentifiableVC: Identifiable {
    let id = UUID()
    let vc: UIViewController
    init(_ vc: UIViewController) { self.vc = vc }
}
