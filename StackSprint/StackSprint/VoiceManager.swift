import AVFoundation
import Combine
import SwiftUI

// MARK: - Voice Manager

@MainActor final class VoiceManager: ObservableObject {
    static let shared = VoiceManager()

    @Published var isSpeaking = false
    @AppStorage("voice.rate") var rate: Double = 0.5

    private let synthesizer = AVSpeechSynthesizer()
    private var delegate: SynthDelegate?

    private init() {
        let d = SynthDelegate { [weak self] in
            Task { @MainActor in self?.isSpeaking = false }
        }
        delegate = d
        synthesizer.delegate = d
    }

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        let minRate = AVSpeechUtteranceMinimumSpeechRate
        let maxRate = AVSpeechUtteranceMaximumSpeechRate
        utterance.rate = minRate + Float(rate) * (maxRate - minRate)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
        isSpeaking = true
    }

    func stop() { synthesizer.stopSpeaking(at: .immediate); isSpeaking = false }

    func toggle(_ text: String) { isSpeaking ? stop() : speak(text) }
}

private final class SynthDelegate: NSObject, AVSpeechSynthesizerDelegate {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish()
    }
}

// MARK: - Read Aloud Button

struct ReadAloudButton: View {
    @ObservedObject private var vm = VoiceManager.shared
    let text: String

    var body: some View {
        Button {
            HapticManager.shared.impact(.light)
            vm.toggle(text)
        } label: {
            Label(vm.isSpeaking ? "Stop" : "Read aloud",
                  systemImage: vm.isSpeaking ? "stop.circle.fill" : "speaker.wave.2.fill")
                .font(.caption.bold())
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(vm.isSpeaking ? Color.orange.opacity(0.12) : SprintPalette.card,
                            in: Capsule())
        }
        .buttonStyle(.plain)
        .foregroundStyle(vm.isSpeaking ? .orange : .secondary)
        .accessibilityLabel(vm.isSpeaking ? "Stop reading" : "Read lesson aloud")
    }
}

// MARK: - Voice Speed Settings Section (embed in AccountView)

struct VoiceSpeedSection: View {
    @AppStorage("voice.rate") private var rate: Double = 0.5

    private var speedLabel: String {
        switch rate {
        case ..<0.3: return "Slow"
        case 0.3..<0.6: return "Normal"
        case 0.6..<0.8: return "Fast"
        default: return "Very fast"
        }
    }

    var body: some View {
        Section {
            HStack {
                Text("Reading speed")
                Spacer()
                Text(speedLabel).foregroundStyle(.secondary).font(.subheadline)
            }
            Slider(value: $rate, in: 0...1, step: 0.1)
                .tint(.mint)
        } header: {
            Label("Voice & Accessibility", systemImage: "speaker.wave.2.fill")
        } footer: {
            Text("Tap \u{201C}Read aloud\u{201D} on any lesson to hear it spoken aloud using your device\u{2019}s voice.")
        }
    }
}
