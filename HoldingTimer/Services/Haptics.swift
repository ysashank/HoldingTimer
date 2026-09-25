import UIKit

@MainActor
enum Haptics {
    private static let generator = UIImpactFeedbackGenerator(style: .heavy)

    static func tap() {
        generator.prepare()
        generator.impactOccurred()
    }

    static func doubleTap() {
        tap()
        Task {
            try? await Task.sleep(for: .seconds(0.15))
            generator.impactOccurred()
        }
    }
}
