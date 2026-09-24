import SwiftUI

struct ActiveTimerView: View {
    var session: TimerSession

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                Text(session.currentLabel)
                    .font(.title3)
                    .foregroundColor(.foregroundSecondary)
                    .padding(.top, 24)

                Spacer()

                Text(session.formattedTimer)
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundColor(timerColor)

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
                .padding()
            }
            .padding()
        }
    }

    private var timerColor: Color {
        if session.isPrepPhase { .timerPrep }
        else if session.isRestPhase { .timerRest }
        else { .foregroundPrimary }
    }
}
