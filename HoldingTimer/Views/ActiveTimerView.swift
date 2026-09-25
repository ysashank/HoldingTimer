import SwiftUI

struct ActiveTimerView: View {
    var session: TimerSession
    @Environment(\.scenePhase) private var scenePhase
    @State private var resumeOnActive = false

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text(session.currentLabel)
                        .font(.title3)
                        .foregroundStyle(Color.foregroundSecondary)
                    Text(session.setLabel)
                        .font(.subheadline)
                        .foregroundStyle(Color.foregroundSecondary.opacity(0.7))
                }
                .padding(.top, 24)

                Spacer()

                Text(session.formattedTimer)
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundStyle(timerColor)
                    .monospacedDigit()
                    .accessibilityLabel("\(session.formattedTimer) remaining, \(session.currentLabel), \(session.setLabel)")

                Spacer()

                Button {
                    session.stopRoutine()
                } label: {
                    Text("Stop")
                        .foregroundStyle(Color.destructive)
                        .frame(width: 84, height: 84)
                        .overlay {
                            Circle()
                                .stroke(Color.destructive, lineWidth: 1)
                        }
                }
                .opacity(0.56)
                .accessibilityLabel("Stop routine")
                .padding()
            }
            .padding()
        }
        .onChange(of: scenePhase) { _, p in
            if p == .background, session.isRunning { resumeOnActive = true; session.suspend() }
            else if p == .active, resumeOnActive { resumeOnActive = false; session.restore() }
        }
        .sensoryFeedback(trigger: session.feedback) { _, new in
            switch new.kind {
            case .start: .impact(weight: .heavy)
            case .end: .success
            case .warn: nil
            }
        }
    }

    private var timerColor: Color {
        if session.isPrepPhase { .timerPrep }
        else if session.isRestPhase { .timerRest }
        else { .foregroundPrimary }
    }
}
