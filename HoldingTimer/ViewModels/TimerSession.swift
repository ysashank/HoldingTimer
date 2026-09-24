import Foundation
import Observation

@MainActor
@Observable
class TimerSession {
    var config = TimerConfiguration()
    var isRunning = false
    var formattedTimer: String { String(format: "%02d:%02d", currentSeconds / 60, currentSeconds % 60) }
    var currentLabel: String { phase.label(sideState: sideState, repeatSide: run.repeatSide) }
    var isPrepPhase: Bool { phase == .prep }
    var isRestPhase: Bool { phase == .rest }

    private enum Phase {
        case prep, hold, rest

        func label(sideState: SideState, repeatSide: Bool) -> String {
            switch self {
            case .prep: "Get Ready"
            case .hold: repeatSide ? (sideState == .left ? "Hold Left Side" : "Hold Right Side") : "Hold"
            case .rest: "Rest"
            }
        }
    }

    private enum SideState { case left, right }

    private var phase: Phase = .prep
    private var timer: Timer?
    private var currentSeconds = 0
    private var run = TimerConfiguration()
    private var currentSet = 1
    private var sideState: SideState = .left
    private let cues: Cues
    private var tokens: [any NSObjectProtocol] = []
    private var pending: (() -> Void)?

    init(cues: Cues = SessionCues()) { self.cues = cues }

    func startRoutine() {
        ScreenManager.disableScreenSleep()
        cues.prepare()
        isRunning = true
        run = config
        currentSet = 1
        sideState = .left
        startPrep()
        tokens = [
            ScreenManager.observeBackgroundEntry { [weak self] in self?.suspend() },
            ScreenManager.observeForegroundEntry { [weak self] in self?.restore() },
        ]
    }

    func stopRoutine() {
        ScreenManager.enableScreenSleep()
        cues.release()
        timer?.invalidate()
        timer = nil
        pending = nil
        isRunning = false
        currentSeconds = 0
        tokens.forEach(ScreenManager.removeObserver)
        tokens = []
    }

    private func suspend() {
        timer?.invalidate()
        timer = nil
    }

    private func restore() {
        guard isRunning, pending != nil else { return }
        schedule()
    }

    private func startPrep() {
        phase = .prep
        runTimer(for: TimerConfiguration.prepSeconds) { [weak self] in self?.startHold() }
    }

    private func startHold() {
        phase = .hold
        runTimer(for: run.holdTime) { [weak self] in self?.handlePostHold() }
    }

    private func handlePostHold() {
        if run.repeatSide && sideState == .left {
            sideState = .right
            startRest()
            return
        }
        sideState = .left
        currentSet += 1
        if currentSet > run.numberOfSets { stopRoutine() } else { startRest() }
    }

    private func startRest() {
        phase = .rest
        runTimer(for: run.restTime) { [weak self] in self?.startHold() }
    }

    private func runTimer(for seconds: Int, completion: @escaping () -> Void) {
        currentSeconds = max(1, seconds)
        pending = completion
        if phase == .hold { cues.tick(.start) }
        schedule()
    }

    private func schedule() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.currentSeconds -= 1
                if self.currentSeconds == 0 {
                    if self.phase == .hold { self.cues.tick(.end) }
                    t.invalidate()
                    self.timer = nil
                    let next = self.pending
                    self.pending = nil
                    next?()
                } else if self.currentSeconds <= TimerConfiguration.warnSeconds {
                    self.cues.tick(.warn)
                }
            }
        }
    }
}
