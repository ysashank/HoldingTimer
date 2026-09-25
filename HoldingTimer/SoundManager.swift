import AVFoundation

final class SoundManager: @unchecked Sendable {
    static let shared = SoundManager()
    private var players: [SoundType: AVAudioPlayer] = [:]
    private let queue = DispatchQueue(label: "audio.players")

    private init() {}

    func prepare() {
        AudioSession.activatePlayback()
        queue.async {
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
        queue.async {
            guard let p = self.players[type] else { return }
            p.currentTime = 0
            p.play()
        }
    }

    func release() {
        queue.async {
            let tail = self.players.values.filter(\.isPlaying).map { $0.duration - $0.currentTime }.max() ?? 0
            self.queue.asyncAfter(deadline: .now() + tail) { AudioSession.deactivate() }
        }
    }

    enum SoundType: String, CaseIterable {
        case start
        case warn
        case end
    }
}
