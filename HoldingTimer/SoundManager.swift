import AVFoundation
import UIKit

final class SoundManager {
    static let shared = SoundManager()
    private var players: [SoundType: AVAudioPlayer] = [:]
    private let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
    private let session = DispatchQueue(label: "audio.session")

    private init() {}

    func prepare() {
        session.async {
            let s = AVAudioSession.sharedInstance()
            try? s.setCategory(.playback, mode: .default, options: [.duckOthers])
            try? s.setActive(true)
            guard self.players.isEmpty else { return }
            for type in SoundType.allCases {
                guard let url = Bundle.main.url(forResource: type.rawValue, withExtension: "wav"),
                      let p = try? AVAudioPlayer(contentsOf: url) else { continue }
                p.prepareToPlay()
                self.players[type] = p
            }
        }
    }

    func play(_ type: SoundType) {
        session.async {
            guard let p = self.players[type] else { return }
            p.currentTime = 0
            p.play()
        }
    }

    func release() {
        session.async { self.players.values.forEach { $0.stop() } }
        session.async { try? AVAudioSession.sharedInstance().setActive(false) }
    }

    @MainActor func vibrate() {
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }

    @MainActor func vibrateDouble() {
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.15))
            impactFeedback.impactOccurred()
        }
    }

    enum SoundType: String, CaseIterable {
        case start
        case warn
        case end
    }
}
