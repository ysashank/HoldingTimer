enum Tick { case start, warn, end }

@MainActor
protocol Cues {
    func prepare()
    func tick(_ kind: Tick)
    func release()
}

struct SessionCues: Cues {
    nonisolated init() {}

    func prepare() { SoundManager.shared.prepare() }

    func tick(_ kind: Tick) {
        switch kind {
        case .start: SoundManager.shared.play(.start); Haptics.tap()
        case .warn: SoundManager.shared.play(.warn)
        case .end: SoundManager.shared.play(.end); Haptics.doubleTap()
        }
    }

    func release() { SoundManager.shared.release() }
}
