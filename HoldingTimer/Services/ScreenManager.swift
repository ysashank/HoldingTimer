import UIKit

enum ScreenManager {
    static func disableScreenSleep() {
        UIApplication.shared.isIdleTimerDisabled = true
    }

    static func enableScreenSleep() {
        UIApplication.shared.isIdleTimerDisabled = false
    }

    @discardableResult
    static func observeBackgroundEntry(handler: @escaping () -> Void) -> any NSObjectProtocol {
        observe(UIApplication.didEnterBackgroundNotification, handler)
    }

    @discardableResult
    static func observeForegroundEntry(handler: @escaping () -> Void) -> any NSObjectProtocol {
        observe(UIApplication.willEnterForegroundNotification, handler)
    }

    static func removeObserver(_ token: any NSObjectProtocol) {
        NotificationCenter.default.removeObserver(token)
    }

    private static func observe(_ name: Notification.Name, _ handler: @escaping () -> Void) -> any NSObjectProtocol {
        NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in handler() }
    }
}
