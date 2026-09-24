import SwiftUI

struct HomeView: View {
    @State private var session = TimerSession()

    var body: some View {
        @Bindable var session = session
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        TimePickerView(totalSeconds: $session.config.holdTime)
                            .frame(height: 180)

                        Stepper(value: $session.config.numberOfSets, in: 1...9) {
                            Text("Sets: \(session.config.numberOfSets)")
                                .foregroundColor(.foregroundPrimary)
                        }
                        .padding(.horizontal)

                        if session.config.numberOfSets > 1 {
                            VStack(spacing: 8) {
                                Text("Rest Between Sets")
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.foregroundPrimary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 8)

                                TimePickerView(totalSeconds: $session.config.restTime)
                                    .frame(height: 180)
                            }
                        }

                        Toggle(isOn: $session.config.repeatSide) {
                            Text("Repeat on Both Sides")
                                .foregroundColor(.foregroundPrimary)
                        }
                        .padding(.horizontal)

                        HStack {
                            Text("Total Duration")
                                .foregroundColor(.foregroundSecondary)
                            Spacer()
                            Text(session.config.formattedTotalDuration)
                                .fontWeight(.bold)
                                .foregroundColor(.foregroundPrimary)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }

                Button {
                    session.startRoutine()
                } label: {
                    Text("Start")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.foregroundPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 26)
                        .background(Color.buttonSurface, in: Capsule())
                }
                .padding()
            }
            .navigationTitle("Holding Timer")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.backgroundPrimary)
            .padding(.horizontal)
            .fullScreenCover(isPresented: $session.isRunning) {
                ActiveTimerView(session: session)
            }
        }
    }
}
