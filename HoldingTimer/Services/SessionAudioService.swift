import AVFoundation
import OSLog

enum Tick { case start, warn, end }

enum SessionAudioService {
    private static let logger = Logger(subsystem: "com.sy.HoldingTimer", category: "SessionAudioService")
    private static var audioEngine: AVAudioEngine?
    private static var playerNode: AVAudioPlayerNode?

    private enum Constants {
        static let sampleRate: Double = 44100.0
        static let tickDuration: Double = 0.05
        static let channels: AVAudioChannelCount = 1
    }

    private struct TickType {
        let frequency: Float
        let volume: Float
        let fadeOut: Bool
    }

    private static let startTick = TickType(frequency: 820, volume: 0.19, fadeOut: true)
    private static let warnTick = TickType(frequency: 600, volume: 0.15, fadeOut: true)
    private static let endTick = TickType(frequency: 360, volume: 0.14, fadeOut: true)

    static func prepare() {
        setupAudioEngineIfNeeded()
    }

    static func play(_ kind: Tick) {
        switch kind {
        case .start: playTick(type: startTick)
        case .warn: playTick(type: warnTick)
        case .end: playTick(type: endTick)
        }
    }

    static func release() {
        Task {
            try? await Task.sleep(for: .seconds(Constants.tickDuration))
            playerNode?.stop()
            audioEngine?.stop()
            AudioSession.deactivate()
        }
    }

    private static func playTick(type: TickType) {
        setupAudioEngineIfNeeded()
        guard let engine = audioEngine, let player = playerNode else {
            logger.error("Audio engine not initialized")
            return
        }
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                logger.error("Failed to start audio engine: \(error.localizedDescription)")
                return
            }
        }
        player.scheduleBuffer(generateTickBuffer(type: type), at: nil, options: [])
        if !player.isPlaying { player.play() }
    }

    private static func setupAudioEngineIfNeeded() {
        guard audioEngine == nil else { return }
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        let format = AVAudioFormat(
            standardFormatWithSampleRate: Constants.sampleRate,
            channels: Constants.channels
        )!
        engine.connect(player, to: engine.mainMixerNode, format: format)
        AudioSession.activatePlayback()
        audioEngine = engine
        playerNode = player
    }

    private static func generateTickBuffer(type: TickType) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(
            standardFormatWithSampleRate: Constants.sampleRate,
            channels: Constants.channels
        )!
        let frameCount = AVAudioFrameCount(Constants.sampleRate * Constants.tickDuration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        guard let channelData = buffer.floatChannelData else { return buffer }
        let samples = channelData[0]
        let angularFrequency = 2.0 * Float.pi * type.frequency / Float(Constants.sampleRate)
        for frame in 0..<Int(frameCount) {
            var amplitude = type.volume
            if type.fadeOut {
                let fadeOutStart = Int(frameCount) * 2 / 3
                if frame > fadeOutStart {
                    let fadePosition = Float(frame - fadeOutStart) / Float(Int(frameCount) - fadeOutStart)
                    amplitude *= (1.0 - fadePosition)
                }
            }
            samples[frame] = sin(angularFrequency * Float(frame)) * amplitude
        }
        return buffer
    }
}
