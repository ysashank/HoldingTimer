import Foundation
import Observation
import OSLog

@Observable
final class TimerSession {
    var config = TimerConfiguration()
    private(set) var isRunning = false
    private(set) var completion: SessionCompletion?
    private(set) var feedback = Feedback(kind: .warn, id: 0)

    struct Feedback: Equatable {
        let kind: Tick
        let id: Int
    }

    var formattedTimer: String { String(format: "%02d:%02d", currentSeconds / 60, currentSeconds % 60) }
    var currentLabel: String { phase.label(sideState: sideState, repeatSide: run.repeatSide) }
    var setLabel: String { "Set \(min(currentSet, run.numberOfSets)) of \(run.numberOfSets)" }
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

    private let logger = Logger(subsystem: "com.sy.HoldingTimer", category: "Session")
    private var phase: Phase = .prep
    private var task: Task<Void, Never>?
    private var currentSeconds = 0
    private var run = TimerConfiguration()
    private var currentSet = 1
    private var sideState: SideState = .left
    private var startedAt: Date?
    private var pending: (() -> Void)?

    func startRoutine() {
        ScreenManager.disableScreenSleep()
        Health.ensureAuthorizationIfNeeded()
        SessionAudioService.prepare()
        isRunning = true
        completion = nil
        run = config
        currentSet = 1
        sideState = .left
        startedAt = Date()
        startPrep()
    }

    func stopRoutine() {
        logger.info("Routine aborted at set \(self.currentSet) of \(self.run.numberOfSets)")
        teardown()
    }

    func dismissCompletion() { completion = nil }

    func suspend() {
        task?.cancel()
        task = nil
    }

    func restore() {
        guard isRunning, pending != nil else { return }
        schedule()
    }

    private func completeRoutine() {
        let start = startedAt ?? Date()
        let end = Date()
        completion = SessionCompletion(
            duration: end.timeIntervalSince(start),
            completedAt: end,
            configuration: run
        )
        logger.info("Routine complete: \(self.run.numberOfSets) sets in \(end.timeIntervalSince(start), format: .fixed(precision: 0))s")
        Health.storeCompletedWorkout(start: start, end: end, configuration: run)
        teardown()
    }

    private func teardown() {
        ScreenManager.enableScreenSleep()
        SessionAudioService.release()
        task?.cancel()
        task = nil
        pending = nil
        isRunning = false
        currentSeconds = 0
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
        if currentSet > run.numberOfSets { completeRoutine() } else { startRest() }
    }

    private func startRest() {
        phase = .rest
        runTimer(for: run.restTime) { [weak self] in self?.startHold() }
    }

    private func runTimer(for seconds: Int, completion: @escaping () -> Void) {
        currentSeconds = seconds
        pending = completion
        if phase == .hold { cue(.start) }
        schedule()
    }

    private func schedule() {
        task?.cancel()
        task = Task { [weak self] in
            var next = ContinuousClock.now
            while !Task.isCancelled {
                next += .seconds(1)
                try? await Task.sleep(until: next, clock: .continuous)
                guard !Task.isCancelled else { return }
                self?.tick()
            }
        }
    }

    private func tick() {
        currentSeconds -= 1
        guard currentSeconds == 0 else {
            if currentSeconds <= TimerConfiguration.warnSeconds { cue(.warn) }
            return
        }
        if phase == .hold { cue(.end) }
        task?.cancel()
        task = nil
        let next = pending
        pending = nil
        next?()
    }

    private func cue(_ kind: Tick) {
        SessionAudioService.play(kind)
        if kind != .warn { feedback = Feedback(kind: kind, id: feedback.id + 1) }
    }
}
