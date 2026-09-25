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
    private let cues: any Cues
    private var tokens: [any NSObjectProtocol] = []
    private var pending: (() -> Void)?

    init(cues: any Cues = SessionCues()) { self.cues = cues }

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
        currentSeconds = seconds
        pending = completion
        if phase == .hold { cues.tick(.start) }
        schedule()
    }

    private func schedule() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
    }

    private func tick() {
        currentSeconds -= 1
        guard currentSeconds == 0 else {
            if currentSeconds <= TimerConfiguration.warnSeconds { cues.tick(.warn) }
            return
        }
        if phase == .hold { cues.tick(.end) }
        timer?.invalidate()
        timer = nil
        let next = pending
        pending = nil
        next?()
    }

}
