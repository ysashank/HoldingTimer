import SwiftUI

struct TimePickerView: View {
    @Binding var totalSeconds: Int

    @State private var minutes = 0
    @State private var seconds = 0

    var body: some View {
        HStack {
            Picker("Minutes", selection: $minutes) {
                ForEach(0..<60) { minute in
                    Text("\(minute)")
                        .foregroundColor(.foregroundPrimary)
                        .tag(minute)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 100)
            .clipped()

            Text("min")
                .foregroundColor(.foregroundSecondary)

            Picker("Seconds", selection: $seconds) {
                ForEach(0..<60) { second in
                    Text("\(second)")
                        .foregroundColor(.foregroundPrimary)
                        .tag(second)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 100)
            .clipped()

            Text("sec")
                .foregroundColor(.foregroundSecondary)
        }
        .frame(height: 180)
        .onAppear {
            minutes = totalSeconds / 60
            seconds = totalSeconds % 60
        }
        .onChange(of: minutes) {
            updateTotal()
        }
        .onChange(of: seconds) {
            updateTotal()
        }
    }

    private func updateTotal() {
        totalSeconds = max(1, min((minutes * 60) + seconds, 3599))
    }
}
