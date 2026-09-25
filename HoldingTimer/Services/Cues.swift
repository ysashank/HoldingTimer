enum Tick { case start, warn, end }

protocol Cues {
    func prepare()
    func tick(_ kind: Tick)
    func release()
}

struct SessionCues: Cues {
    func prepare() { SessionAudioService.prepare() }

    func tick(_ kind: Tick) {
        SessionAudioService.play(kind)
        switch kind {
        case .start: Haptics.tap()
        case .end: Haptics.doubleTap()
        case .warn: break
        }
    }

    func release() { SessionAudioService.release() }
}
