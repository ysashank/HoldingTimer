import UIKit

@MainActor
enum ScreenManager {
    static func disableScreenSleep() { UIApplication.shared.isIdleTimerDisabled = true }
    static func enableScreenSleep() { UIApplication.shared.isIdleTimerDisabled = false }

    static func observeBackgroundEntry(handler: @escaping @MainActor () -> Void) -> any NSObjectProtocol {
        observe(UIApplication.didEnterBackgroundNotification, handler)
    }

    static func observeForegroundEntry(handler: @escaping @MainActor () -> Void) -> any NSObjectProtocol {
        observe(UIApplication.willEnterForegroundNotification, handler)
    }

    static func removeObserver(_ token: any NSObjectProtocol) {
        NotificationCenter.default.removeObserver(token)
    }

    private static func observe(_ name: Notification.Name, _ handler: @escaping @MainActor () -> Void) -> any NSObjectProtocol {
        NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { handler() }
        }
    }
}
