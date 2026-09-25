import HealthKit
import OSLog

enum Health {
    nonisolated private static let logger = Logger(subsystem: "com.sy.HoldingTimer", category: "Health")
    private static let store = HKHealthStore()
    private static var askedOnce = false

    static func ensureAuthorizationIfNeeded() {
        guard HKHealthStore.isHealthDataAvailable(), !askedOnce else { return }
        askedOnce = true
        Task {
            do {
                try await store.requestAuthorization(toShare: [HKObjectType.workoutType()], read: [])
            } catch {
                logger.error("Authorization failed: \(error.localizedDescription)")
            }
        }
    }

    nonisolated static func storeCompletedWorkout(start: Date, end: Date, configuration: TimerConfiguration) {
        let store = HKHealthStore()
        guard HKHealthStore.isHealthDataAvailable(),
              store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized else {
            logger.info("Skipping workout write: not authorized")
            return
        }
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .flexibility
        let builder = HKWorkoutBuilder(healthStore: store, configuration: workoutConfiguration, device: .local())
        Task {
            do {
                try await builder.beginCollection(at: start)
                try await builder.addMetadata(metadata(for: configuration))
                try await builder.endCollection(at: end)
                try await builder.finishWorkout()
                logger.info("Logged \(configuration.numberOfSets) sets to Health")
            } catch {
                logger.error("Workout write failed: \(error.localizedDescription)")
            }
        }
    }

    nonisolated private static func metadata(for c: TimerConfiguration) -> [String: Any] {
        [
            HKMetadataKeyWorkoutBrandName: "Holding Timer",
            "holdSeconds": c.holdTime,
            "sets": c.numberOfSets,
            "restSeconds": c.restTime,
            "repeatsPerSide": c.repeatSide,
            "totalNominalSeconds": c.totalDuration,
        ]
    }
}
