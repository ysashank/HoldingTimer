import UIKit

enum ScreenManager {
    static func disableScreenSleep() { UIApplication.shared.isIdleTimerDisabled = true }
    static func enableScreenSleep() { UIApplication.shared.isIdleTimerDisabled = false }
}
