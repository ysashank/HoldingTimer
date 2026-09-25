import AVFoundation
import OSLog

/// Wraps the shared `AVAudioSession` so activation never blocks the main thread.
/// iOS 27 exposes a real async activate; below that, the blocking call is moved off-thread.
enum AudioSession {
    nonisolated private static let logger = Logger(subsystem: "com.sy.HoldingTimer", category: "AudioSession")

    nonisolated static func activatePlayback(mode: AVAudioSession.Mode = .default) {
        Task.detached(priority: .userInitiated) {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: mode, options: [.duckOthers])
                if #available(iOS 27.0, *) {
                    try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, any Error>) in
                        session.activate { _, error in
                            if let error { c.resume(throwing: error) } else { c.resume() }
                        }
                    }
                } else {
                    try session.setActive(true)
                }
            } catch {
                logger.error("Activate failed: \(error.localizedDescription)")
            }
        }
    }

    nonisolated static func deactivate() {
        if #available(iOS 27.0, *) {
            AVAudioSession.sharedInstance().deactivate(options: .notifyOthersOnDeactivation) { _, error in
                if let error { logger.error("Deactivate failed: \(error.localizedDescription)") }
            }
            return
        }
        Task.detached(priority: .utility) {
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                logger.error("Deactivate failed: \(error.localizedDescription)")
            }
        }
    }
}
