import Foundation

struct TimerConfiguration {
    // Terminal countdown. Breathwork cues every 5th remaining second instead; the alarm is the
    // one deliberate iOS departure, and Solemate uses the same window.
    static let warnSeconds = 5
    static let prepSeconds = 5

    var holdTime: Int = 15
    var numberOfSets: Int = 1
    var repeatSide: Bool = false
    var restTime: Int = 5

    var totalDuration: Int {
        let totalHolds = repeatSide ? numberOfSets * 2 : numberOfSets
        let totalRests = totalHolds - 1
        return Self.prepSeconds + (totalHolds * holdTime) + (totalRests * restTime)
    }

    var formattedTotalDuration: String {
        let minutes = totalDuration / 60
        let seconds = totalDuration % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
